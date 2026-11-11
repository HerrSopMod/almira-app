import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errors/error_app.dart';
import '../models/modelos.dart';
import 'datos_demo.dart';
import 'repositorio.dart';

const _claveReclamos = 'demo.reclamos';
const _claveCanal = 'demo.canal';
const _prefijoFoto = 'demo.foto.';

/// Modo demostración: registros ficticios y nada sale del teléfono. Los
/// reclamos que el vecino crea (con su foto y su ubicación) se guardan en el
/// dispositivo, para que sigan ahí al volver a abrir la app.
class RepositorioDemo implements Repositorio {
  RepositorioDemo(this._preferencias, {DateTime Function()? reloj})
      : _reloj = reloj ?? DateTime.now;

  final SharedPreferences _preferencias;
  final DateTime Function() _reloj;

  @override
  bool get esDemo => true;

  List<Reclamo> _guardados() {
    final texto = _preferencias.getString(_claveReclamos);
    if (texto == null) return [];
    try {
      return (jsonDecode(texto) as List)
          .map((f) => Reclamo.deFila(Map<String, dynamic>.from(f as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<FuenteDatos> cargar() async {
    final base = DatosDemo.crear(_reloj());
    final canal = _preferencias.getString(_claveCanal);
    return base.con(
      reclamos: [..._guardados(), ...base.reclamos],
      vecinos: canal == null
          ? null
          : base.vecinos.map((v) => v.conCanal(CanalAviso.de(canal))).toList(),
    );
  }

  @override
  Future<String> crearReclamo(
    NuevoReclamo reclamo, {
    required String municipalidadId,
    required String vecinoId,
    void Function(EtapaEnvio etapa)? alAvanzar,
  }) async {
    final ahora = _reloj();
    final id = 'demo-nuevo-${ahora.millisecondsSinceEpoch}';
    final previos = _guardados();

    String? fotoRuta;
    final bytes = reclamo.fotoBytes;
    if (bytes != null && bytes.isNotEmpty) {
      alAvanzar?.call(EtapaEnvio.subiendoFoto);
      try {
        fotoRuta = await _guardarFoto(id, Uint8List.fromList(bytes));
      } catch (_) {
        throw const ErrorApp(
          TipoError.servidor,
          'No pudimos guardar la foto en el teléfono. Inténtalo de nuevo.',
        );
      }
    }

    alAvanzar?.call(EtapaEnvio.guardando);
    // "R-01842" -> siguiente número libre.
    final mayor = [...previos, ...DatosDemo.crear(ahora).reclamos].fold<int>(0, (maximo, r) {
      final n = int.tryParse(RegExp(r'^R-(\d+)$').firstMatch(r.codigo)?.group(1) ?? '') ?? 0;
      return n > maximo ? n : maximo;
    });
    final nuevo = Reclamo(
      id: id,
      municipalidadId: municipalidadId,
      vecinoId: vecinoId,
      codigo: 'R-${(mayor + 1).toString().padLeft(5, '0')}',
      tipo: reclamo.tipo,
      titulo: reclamo.titulo,
      descripcion: reclamo.descripcion,
      // Igual que la base: entra «En atención» y sin área hasta que la
      // municipalidad lo derive.
      estado: EstadoReclamo.enAtencion,
      fotoRuta: fotoRuta,
      direccion: reclamo.direccion,
      latitud: reclamo.latitud,
      longitud: reclamo.longitud,
      plazoDias: 10,
      creadoEn: ahora,
    );
    await _preferencias.setString(
      _claveReclamos,
      jsonEncode([nuevo.aFila(), ...previos.map((r) => r.aFila())]),
    );
    return id;
  }

  /// En el teléfono, la foto va a la carpeta privada de la app. En la web no
  /// hay archivos: se guarda en el almacenamiento del navegador.
  Future<String> _guardarFoto(String id, Uint8List bytes) async {
    if (kIsWeb) {
      await _preferencias.setString('$_prefijoFoto$id', base64Encode(bytes));
      return '$_prefijoFoto$id';
    }
    final carpeta = Directory('${(await getApplicationDocumentsDirectory()).path}/reclamos');
    await carpeta.create(recursive: true);
    final archivo = File('${carpeta.path}/$id.jpg');
    await archivo.writeAsBytes(bytes, flush: true);
    return archivo.path;
  }

  @override
  Future<FotoReclamo?> fotoDe(Reclamo reclamo) async {
    if (!reclamo.tieneFoto) return null;
    final ruta = reclamo.fotoRuta!;
    if (ruta.startsWith(_prefijoFoto)) {
      final texto = _preferencias.getString(ruta);
      return texto == null ? null : FotoReclamo.bytes(base64Decode(texto));
    }
    if (kIsWeb) return null;
    final archivo = File(ruta);
    if (!await archivo.exists()) return null;
    return FotoReclamo.bytes(await archivo.readAsBytes());
  }

  @override
  Future<void> cambiarCanal(String vecinoId, CanalAviso canal) =>
      _preferencias.setString(_claveCanal, canal.name);

  @override
  Future<bool> guardarCelular(String celular) async => true;

  @override
  Future<String> pagar(List<String> deudaIds, MedioPago medio) async =>
      throw const ErrorApp(TipoError.servidor, 'El pago necesita conexión con el servicio.');

  @override
  Stream<void> get cambiosDeudas => const Stream.empty();

  @override
  Future<String?> vincularCodigo(String municipalidadId, String codigo, String dni) async {
    final coincide = municipalidadId == DatosDemo.municipalidadId &&
        codigo.trim().toUpperCase() == DatosDemo.codigoContribuyente &&
        dni.trim() == DatosDemo.dni;
    return coincide ? null : 'No encontramos ese código con ese DNI en el padrón.';
  }
}
