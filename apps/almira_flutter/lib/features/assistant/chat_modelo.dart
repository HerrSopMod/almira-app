import '../../app/router.dart';

/// Acceso rápido que el asistente ofrece bajo una respuesta: un botón que abre una pantalla.
class AccionChat {
  const AccionChat(this.etiqueta, this.ruta);

  final String etiqueta;
  final String ruta;

  /// Las que devuelve la función del servidor (`acciones`). Cualquier otra se ignora.
  static const _deServidor = {
    'ver_estado_cuenta': AccionChat('Ver estado de cuenta', Rutas.estadoCuenta),
    'pagar': AccionChat('Pagar en línea', Rutas.pagoEnLinea),
    'ver_historial': AccionChat('Ver historial de pagos', Rutas.estadoCuenta),
    'descargar_cuponera': AccionChat('Descargar cuponera', Rutas.cuponera),
  };

  static AccionChat? deServidor(Object? clave) => _deServidor[clave];
}

/// Un mensaje del chat.
class MensajeChat {
  const MensajeChat({
    required this.texto,
    required this.mio,
    required this.hora,
    this.acciones = const [],
    this.fallo = false,
  });

  final String texto;

  /// true si lo escribió el vecino; false si es del asistente.
  final bool mio;
  final DateTime hora;
  final List<AccionChat> acciones;

  /// El asistente no pudo responder: la burbuja ofrece «Reintentar».
  final bool fallo;
}

/// Posición de un mensaje dentro de su grupo de mensajes seguidos del mismo autor.
class PosicionEnGrupo {
  const PosicionEnGrupo({required this.primero, required this.ultimo});

  final bool primero;
  final bool ultimo;
}

/// Agrupa los mensajes seguidos del mismo autor: el primero lleva el avatar del asistente y el
/// último, la hora; entre ellos el espacio es menor y las esquinas se unen.
List<PosicionEnGrupo> agruparMensajes(List<MensajeChat> mensajes) => [
      for (var i = 0; i < mensajes.length; i++)
        PosicionEnGrupo(
          primero: i == 0 || mensajes[i - 1].mio != mensajes[i].mio,
          ultimo: i == mensajes.length - 1 || mensajes[i + 1].mio != mensajes[i].mio,
        ),
    ];
