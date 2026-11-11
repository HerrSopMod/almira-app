import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/utils/formato.dart';
import '../../core/utils/plazos.dart';
import '../../core/widgets/mapa_almira.dart';
import '../../shared/models/modelos.dart';
import '../../shared/services/proveedores.dart';
import '../../shared/services/repositorio.dart';

/// Límites del formulario, visibles para el vecino.
const asuntoMinimo = 8;
const asuntoMaximo = 60;
const descripcionMinima = 20;
const descripcionMaxima = 500;
const direccionMaxima = 120;

/// Tamaño máximo de la foto ya reducida (el bucket acepta hasta 10 MB).
const fotoMaximaBytes = 8 * 1024 * 1024;

/// Palabras que delatan cada categoría (sin tildes). Son reglas fijas, no IA:
/// solo sugieren, y el vecino puede cambiar la categoría.
final _palabras = <TipoReclamo, RegExp>{
  TipoReclamo.pistasVeredas: RegExp(r'bache|hueco|pista|vereda|asfalto|pavimento|sardinel'),
  TipoReclamo.alumbrado: RegExp(r'poste|luz|foco|alumbrado|luminaria|oscur'),
  TipoReclamo.limpieza: RegExp(r'basura|residuo|desmonte|desperdicio|sucio|limpieza|barr(en|ido)'),
  TipoReclamo.vehiculoMalEstacionado: RegExp(r'estaciona|parquea|bloquea|rampa|cochera'),
  TipoReclamo.depositoVehicular: RegExp(r'deposito|grua|remolc'),
  TipoReclamo.cobroIndebido: RegExp(r'cobr|pague|pagad|recibo|arbitrio|predial|deuda'),
};

/// Categoría sugerida por el texto; si nada coincide, «Otro».
TipoReclamo clasificarReclamo(String texto) {
  final limpio = normalizar(texto);
  for (final entrada in _palabras.entries) {
    if (entrada.value.hasMatch(limpio)) return entrada.key;
  }
  return TipoReclamo.otro;
}

final _vocal = RegExp(r'[aeiouáéíóúü]', caseSensitive: false);
final _letra = RegExp(r'[a-záéíóúüñ]', caseSensitive: false);

/// Valida el asunto. Rechaza textos de prueba como «Jjkkk»: pide al menos dos
/// palabras, con vocales, y sin la misma letra repetida tres veces seguidas.
String? validarAsunto(String? valor) {
  final texto = (valor ?? '').trim();
  if (texto.length < asuntoMinimo) return 'Escribe al menos $asuntoMinimo caracteres.';
  if (texto.length > asuntoMaximo) return 'Usa como máximo $asuntoMaximo caracteres.';
  final palabras = texto.split(RegExp(r'\s+')).where((p) => _letra.hasMatch(p)).toList();
  final legible = palabras.length >= 2 &&
      palabras.every((p) => p.length < 4 || _vocal.hasMatch(p)) &&
      !RegExp(r'(.)\1\1', caseSensitive: false).hasMatch(texto);
  return legible ? null : 'Describe el problema en pocas palabras. Ejemplo: «Poste sin luz».';
}

String? validarDescripcion(String? valor) {
  final texto = (valor ?? '').trim();
  if (texto.length < descripcionMinima) {
    return 'Cuenta qué pasa en al menos $descripcionMinima caracteres.';
  }
  if (texto.length > descripcionMaxima) return 'Usa como máximo $descripcionMaxima caracteres.';
  return null;
}

String? validarDireccion(String? valor) {
  final texto = (valor ?? '').trim();
  if (texto.length < 5) return 'Escribe la calle y un número o referencia.';
  return null;
}

/// Plazo de atención del reclamo, con la fecha real de hoy.
Plazo? plazoDe(Reclamo reclamo, DateTime hoy) => calcularPlazo(
      creadoEn: reclamo.creadoEn,
      plazoDias: reclamo.plazoDias,
      resuelto: reclamo.resuelto,
      hoy: hoy,
    );

enum EstadoPaso { hecho, actual, pendiente }

class PasoSeguimiento {
  const PasoSeguimiento(this.titulo, this.estado, [this.detalle]);

  final String titulo;
  final EstadoPaso estado;
  final String? detalle;
}

/// Línea de tiempo del reclamo. Solo marca como hecho lo que los datos
/// respaldan: la base guarda la fecha de registro, la categoría, el área (si
/// ya se derivó) y el estado actual; no guarda la fecha de cada etapa.
List<PasoSeguimiento> pasosDe(Reclamo reclamo) {
  final creado = reclamo.creadoEn;
  final area = reclamo.area?.trim();
  final derivado = area != null && area.isNotEmpty;
  final estado = reclamo.estado;

  return [
    PasoSeguimiento(
      'Recibido',
      EstadoPaso.hecho,
      creado == null ? null : '${fechaLarga(creado)}, ${hora(creado)}',
    ),
    PasoSeguimiento('Clasificado', EstadoPaso.hecho, reclamo.tipo.etiqueta),
    // Solo aparece si hay un área asignada o el estado lo dice.
    if (derivado || estado == EstadoReclamo.derivado)
      PasoSeguimiento(
        'Derivado al área',
        estado == EstadoReclamo.derivado ? EstadoPaso.actual : EstadoPaso.hecho,
        derivado ? area : null,
      ),
    PasoSeguimiento(
      'En atención',
      switch (estado) {
        EstadoReclamo.enAtencion => EstadoPaso.actual,
        EstadoReclamo.derivado => EstadoPaso.pendiente,
        EstadoReclamo.resuelto => EstadoPaso.hecho,
      },
    ),
    PasoSeguimiento('Resuelto', reclamo.resuelto ? EstadoPaso.hecho : EstadoPaso.pendiente),
  ];
}

/// Centro del mapa para una municipalidad: el promedio de sus obras ubicadas.
/// La base no guarda el centro del distrito; sin obras, se usa una vista
/// amplia de Lima y el vecino mueve el mapa.
({LatLng centro, double zoom}) centroDe(VistaMunicipal vista) {
  final puntos = vista.obras
      .where((o) => o.tieneUbicacion)
      .map((o) => LatLng(o.latitud!, o.longitud!))
      .toList();
  if (puntos.isEmpty) return (centro: ConfigMapa.centroLima, zoom: ConfigMapa.zoomCiudad);
  final lat = puntos.fold<double>(0, (s, p) => s + p.latitude) / puntos.length;
  final lon = puntos.fold<double>(0, (s, p) => s + p.longitude) / puntos.length;
  return (centro: LatLng(lat, lon), zoom: 15);
}

/// Foto de un reclamo guardado. Se pide una vez por reclamo y se puede
/// reintentar con `ref.invalidate`.
final fotoReclamoProvider = FutureProvider.autoDispose.family<FotoReclamo?, String>((ref, id) async {
  final datos = await ref.watch(datosProvider.future);
  final reclamo = datos.reclamos.where((r) => r.id == id).firstOrNull;
  if (reclamo == null) return null;
  return ref.watch(repositorioProvider).fotoDe(reclamo);
});
