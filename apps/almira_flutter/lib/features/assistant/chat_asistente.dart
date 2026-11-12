import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/services/proveedores.dart';
import 'chat_modelo.dart';
import 'servicio_asistente.dart';

/// Estado del chat: los mensajes de esta sesión (no se guardan en la base) y si se espera una
/// respuesta.
class EstadoChat {
  const EstadoChat({this.mensajes = const [], this.enviando = false});

  final List<MensajeChat> mensajes;
  final bool enviando;

  bool get hayMensajesDelVecino => mensajes.any((m) => m.mio);

  EstadoChat con({List<MensajeChat>? mensajes, bool? enviando}) =>
      EstadoChat(mensajes: mensajes ?? this.mensajes, enviando: enviando ?? this.enviando);
}

/// Conversación con el asistente. Vive en memoria mientras dura la sesión y se borra al cambiar
/// de cuenta.
class ChatNotifier extends Notifier<EstadoChat> {
  @override
  EstadoChat build() {
    // Otra cuenta, otro chat.
    ref.watch(sesionProvider.select((s) => s.usuarioId));
    return const EstadoChat();
  }

  DateTime get _ahora => ref.read(relojProvider)();

  Future<void> enviar(String texto) async {
    final limpio = texto.trim();
    if (limpio.isEmpty || state.enviando) return;
    state = state.con(
      mensajes: [...state.mensajes, MensajeChat(texto: limpio, mio: true, hora: _ahora)],
    );
    await _responder(limpio);
  }

  /// Vuelve a pedir la respuesta que falló, sin repetir el mensaje del vecino.
  Future<void> reintentar() async {
    if (state.enviando || state.mensajes.isEmpty || !state.mensajes.last.fallo) return;
    final sinFallo = state.mensajes.sublist(0, state.mensajes.length - 1);
    final ultimoDelVecino = sinFallo.lastWhere((m) => m.mio, orElse: () => sinFallo.last);
    state = state.con(mensajes: sinFallo);
    await _responder(ultimoDelVecino.texto);
  }

  Future<void> _responder(String pregunta) async {
    state = state.con(enviando: true);
    final servicio = ref.read(servicioAsistenteProvider);
    // El historial es lo anterior a la pregunta (que ya está al final de la lista).
    final anteriores = state.mensajes.sublist(0, state.mensajes.length - 1);
    RespuestaAsistente respuesta;
    try {
      respuesta = await servicio.preguntar(pregunta, anteriores);
    } catch (_) {
      respuesta = const RespuestaAsistente(
        'Ahora mismo no puedo responderte. Revisa tu conexión e inténtalo de nuevo.',
        fallo: true,
      );
    }
    state = state.con(
      enviando: false,
      mensajes: [
        ...state.mensajes,
        MensajeChat(
          texto: respuesta.texto,
          mio: false,
          hora: _ahora,
          acciones: respuesta.acciones,
          fallo: respuesta.fallo,
        ),
      ],
    );
  }
}

final chatAsistenteProvider = NotifierProvider<ChatNotifier, EstadoChat>(ChatNotifier.new);
