import '../../app/router.dart';
import '../../core/utils/formato.dart';
import '../../shared/models/modelos.dart';
import '../../shared/services/proveedores.dart';
import '../complaints/reclamos_logica.dart';
import '../payments/pagos_logica.dart';

/// El asistente no usa IA: responde con reglas fijas sobre los datos que la
/// app ya tiene del vecino. No inventa deudas, expedientes ni decisiones.
const preguntasSugeridas = [
  '¿Cuánto debo?',
  '¿Cuándo vence?',
  '¿Cómo pago?',
  '¿Cómo va mi reclamo?',
  '¿Qué obras hay?',
];

class Respuesta {
  const Respuesta(this.texto, {this.accion, this.ruta});

  final String texto;

  /// Botón opcional que lleva a la pantalla donde se resuelve.
  final String? accion;
  final String? ruta;
}

const saludoAsistente =
    'Hola. Respondo preguntas sobre tus tributos, reclamos y obras con los datos de tu cuenta. '
    'Es orientación: las decisiones son de tu municipalidad.';

Respuesta responder(String pregunta, VistaMunicipal v, DateTime hoy) {
  final texto = normalizar(pregunta);
  bool tiene(String patron) => RegExp(patron).hasMatch(texto);

  if (v.vecino == null && tiene(r'deb|deuda|venc|pag|tribut|arbitr|predial|multa|reclam|cuota|fraccion')) {
    return const Respuesta(
      'Aún no vinculaste tu código de contribuyente, así que no puedo ver tus tributos ni reclamos.',
      accion: 'Vincular código',
      ruta: Rutas.vincular,
    );
  }

  final resumen = resumirDeuda(v.deudas, hoy);

  if (tiene(r'cuota|fraccion')) {
    return Respuesta(
      resumen.alDia
          ? 'No tienes obligaciones pendientes para fraccionar.'
          : 'El pago en cuotas lo evalúa y aprueba tu municipalidad; Almira no puede tramitarlo. '
              'Tu total pendiente es ${soles(resumen.total)}.',
      accion: resumen.alDia ? null : 'Ver mis obligaciones',
      ruta: resumen.alDia ? null : Rutas.pagos,
    );
  }

  if (tiene(r'multa')) {
    final multas = v.pendientes.where((d) => d.tipo == TipoDeuda.multa).toList();
    if (multas.isEmpty) return const Respuesta('No tienes multas pendientes en esta municipalidad.');
    final detalle = multas
        .map((m) => '${m.concepto} por ${soles(m.total)} (${vencimientoDe(m, hoy).toLowerCase()})')
        .join('; ');
    return Respuesta(
      'Tu municipalidad registra: $detalle. Si crees que no corresponde, puedes enviar un reclamo.',
      accion: 'Nuevo reclamo',
      ruta: Rutas.nuevoReclamo,
    );
  }

  if (tiene(r'venc|cuando|fecha|plazo de pago')) {
    if (resumen.alDia) return const Respuesta('Estás al día: no tienes vencimientos pendientes.');
    final partes = <String>[
      if (resumen.cantidadVencidas > 0)
        'Tienes ${plural(resumen.cantidadVencidas, 'obligación vencida', 'obligaciones vencidas')} '
            'por ${soles(resumen.montoVencido)}.',
      if (resumen.proximoVencimiento != null)
        'Tu próximo vencimiento es el ${fechaLarga(resumen.proximoVencimiento!)}.',
    ];
    return Respuesta(partes.join(' '), accion: 'Ver mis obligaciones', ruta: Rutas.pagos);
  }

  if (tiene(r'como pag|donde pag|pagar|pago')) {
    final url = v.municipalidad?.urlPago;
    return Respuesta(
      url == null || url.isEmpty
          ? 'Tu municipalidad aún no tiene un portal de pago enlazado en Almira. '
              'Puedes pagar en sus canales habituales.'
          : 'Se paga en el portal de tu municipalidad. En Pagar eliges la obligación y te llevamos allí. '
              'Almira no cobra ni confirma el pago.',
      accion: 'Ir a Pagar',
      ruta: Rutas.pagos,
    );
  }

  if (tiene(r'deb|deuda|pendiente|tribut|arbitr|predial|cuanto')) {
    if (resumen.alDia) return const Respuesta('Estás al día: no tienes obligaciones pendientes.');
    final lista = filtrarDeudas(v.deudas, FiltroDeuda.pendientes, hoy)
        .map((d) => '${d.concepto}: ${soles(d.total)}')
        .join('; ');
    return Respuesta(
      'Tu total pendiente es ${soles(resumen.total)} en '
      '${plural(resumen.cantidad, 'obligación', 'obligaciones')}. $lista.',
      accion: 'Ver detalle',
      ruta: Rutas.pagos,
    );
  }

  if (tiene(r'reclam|queja|denuncia|reporte|report')) {
    final abierto = v.reclamos.where((r) => !r.resuelto).firstOrNull;
    if (abierto == null) {
      return const Respuesta(
        'No tienes reclamos en curso. Puedes reportar un problema con una foto y su ubicación.',
        accion: 'Nuevo reclamo',
        ruta: Rutas.nuevoReclamo,
      );
    }
    final plazo = plazoDe(abierto, hoy);
    return Respuesta(
      'Tu reclamo ${abierto.codigo} («${abierto.titulo}») está ${abierto.estado.etiqueta.toLowerCase()}'
      '${plazo == null ? '' : '. ${plazo.etiqueta}'}.',
      accion: 'Ver seguimiento',
      ruta: Rutas.reclamo(abierto.id),
    );
  }

  if (tiene(r'obra|parque|pista|vereda|construccion')) {
    final enCurso = v.obras.where((o) => o.estado == EstadoObra.enEjecucion).toList();
    if (v.obras.isEmpty) {
      return const Respuesta('Tu municipalidad aún no publicó obras en Almira.');
    }
    return Respuesta(
      enCurso.isEmpty
          ? 'No hay obras en ejecución publicadas. Hay ${plural(v.obras.length, 'obra concluida', 'obras concluidas')}.'
          : 'Hay ${plural(enCurso.length, 'obra en ejecución', 'obras en ejecución')}: '
              '${enCurso.map((o) => '${o.nombre} (${o.avancePct.round()} % de avance físico)').join('; ')}.',
      accion: 'Ver obras',
      ruta: Rutas.obras,
    );
  }

  if (tiene(r'persona|humano|telefono|llamar|atencion|ayuda|contact')) {
    return const Respuesta(
      'Te muestro los canales de atención que publicó tu municipalidad.',
      accion: 'Ver atención',
      ruta: Rutas.atencion,
    );
  }

  return const Respuesta(
    'No tengo una respuesta para eso. Puedo ayudarte con tu deuda, vencimientos, cómo pagar, '
    'tus reclamos y las obras de tu distrito.',
  );
}
