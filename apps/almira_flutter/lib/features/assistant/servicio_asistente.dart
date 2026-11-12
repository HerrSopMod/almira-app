import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/services/proveedores.dart';
import 'asistente_logica.dart';
import 'chat_modelo.dart';

const _maximoHistorial = 10;
const _maximoTexto = 500;

/// Lo que responde el asistente.
class RespuestaAsistente {
  const RespuestaAsistente(this.texto, {this.acciones = const [], this.fallo = false});

  final String texto;
  final List<AccionChat> acciones;

  /// true si no pudo responder y conviene ofrecer «Reintentar».
  final bool fallo;
}

/// Quien responde al chat. Con Supabase es la función `asistente` (Gemini); sin él, reglas
/// fijas sobre los datos de la app.
abstract class ServicioAsistente {
  /// [historial]: los mensajes anteriores (sin el que se está enviando).
  Future<RespuestaAsistente> preguntar(String mensaje, List<MensajeChat> historial);
}

/// Función `asistente` de Supabase. Recibe el mensaje y los últimos 10 del historial; los datos
/// del vecino los lee ella con la sesión de la persona.
class ServicioAsistenteSupabase implements ServicioAsistente {
  ServicioAsistenteSupabase(this._cliente);

  final SupabaseClient _cliente;

  static const _mensajeFallo =
      'Ahora mismo no puedo responderte. Revisa tu conexión e inténtalo de nuevo.';

  @override
  Future<RespuestaAsistente> preguntar(String mensaje, List<MensajeChat> historial) async {
    final recientes = historial.where((m) => !m.fallo).toList();
    final ultimos = recientes.length > _maximoHistorial
        ? recientes.sublist(recientes.length - _maximoHistorial)
        : recientes;
    try {
      final respuesta = await _cliente.functions.invoke('asistente', body: {
        'mensaje': mensaje.length > _maximoTexto ? mensaje.substring(0, _maximoTexto) : mensaje,
        'historial': [
          for (final m in ultimos)
            {
              'rol': m.mio ? 'usuario' : 'asistente',
              'texto': m.texto.length > _maximoTexto ? m.texto.substring(0, _maximoTexto) : m.texto,
            },
        ],
      }).timeout(const Duration(seconds: 40));
      final datos = respuesta.data;
      if (datos is! Map || datos['respuesta'] is! String) return const RespuestaAsistente(_mensajeFallo, fallo: true);
      final acciones = [
        if (datos['acciones'] is List)
          for (final a in datos['acciones'] as List) ?AccionChat.deServidor(a),
      ];
      // Fallo del servicio (clave, cuota, caída): se ofrece reintentar. El límite de uso y la
      // falta de vínculo son respuestas normales.
      return RespuestaAsistente(
        datos['respuesta'] as String,
        acciones: acciones,
        fallo: datos['error'] == 'servicio',
      );
    } catch (_) {
      return const RespuestaAsistente(_mensajeFallo, fallo: true);
    }
  }
}

/// Reglas fijas sobre los datos que la app ya tiene. Es el respaldo sin Supabase.
class ServicioAsistenteLocal implements ServicioAsistente {
  ServicioAsistenteLocal(this._vista, this._hoy);

  final VistaMunicipal? Function() _vista;
  final DateTime Function() _hoy;

  @override
  Future<RespuestaAsistente> preguntar(String mensaje, List<MensajeChat> historial) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final vista = _vista();
    if (vista == null) {
      return const RespuestaAsistente(
        'No pude leer tus datos en este momento. Revisa tu conexión e inténtalo de nuevo.',
        fallo: true,
      );
    }
    final r = responder(mensaje, vista, _hoy());
    return RespuestaAsistente(
      r.texto,
      acciones: [if (r.accion != null && r.ruta != null) AccionChat(r.accion!, r.ruta!)],
    );
  }
}

/// Servicio en uso: la función de Supabase cuando hay conexión con el servicio; si no, el local.
/// `main.dart` pone el de Supabase.
final servicioAsistenteProvider = Provider<ServicioAsistente>(
  (ref) => ServicioAsistenteLocal(
    () => ref.read(vistaProvider).valueOrNull,
    () => ref.read(relojProvider)(),
  ),
);
