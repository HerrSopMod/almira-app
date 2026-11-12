import 'dart:typed_data';

import '../models/modelos.dart';
import '../models/preferencia_whatsapp.dart';

/// Etapas del envío de un reclamo, para mostrar el progreso real.
enum EtapaEnvio { subiendoFoto, guardando }

/// Fotografía de un reclamo ya guardado: una dirección temporal firmada
/// (bucket privado) o su contenido, si está en el teléfono.
class FotoReclamo {
  const FotoReclamo.url(String this.url) : bytes = null;
  const FotoReclamo.bytes(Uint8List this.bytes) : url = null;

  final String? url;
  final Uint8List? bytes;
}

/// Acceso a los datos. Hay dos implementaciones: Supabase (la real) y la de
/// demostración, que funciona sin conexión con registros de ejemplo.
abstract class Repositorio {
  bool get esDemo;

  /// Lee todo lo que el vecino puede ver. Lanza `ErrorApp` si falla: la
  /// pantalla muestra el error en vez de datos a medias.
  Future<FuenteDatos> cargar();

  /// Sube la foto, guarda el reclamo y devuelve su id.
  Future<String> crearReclamo(
    NuevoReclamo reclamo, {
    required String municipalidadId,
    required String vecinoId,
    void Function(EtapaEnvio etapa)? alAvanzar,
  });

  /// Fotografía del reclamo, o null si no tiene.
  Future<FotoReclamo?> fotoDe(Reclamo reclamo);

  Future<void> cambiarCanal(String vecinoId, CanalAviso canal);

  /// Vincula un código de contribuyente con su DNI. Devuelve un mensaje de
  /// error para mostrar, o null si quedó vinculado.
  Future<String?> vincularCodigo(String municipalidadId, String codigo, String dni);

  /// Guarda el celular de los avisos de la cuenta (9 dígitos). Devuelve false si la cuenta
  /// todavía no tiene un contribuyente vinculado.
  Future<bool> guardarCelular(String celular);

  /// Estado de los recordatorios por WhatsApp de la cuenta, o null si nunca los configuró.
  Future<PreferenciaWhatsapp?> preferenciaWhatsapp();

  /// Guarda el número y el consentimiento y pide la bienvenida. Si el mensaje no llega, deja los
  /// recordatorios apagados: no se activa un número al que no se pudo escribir.
  Future<ResultadoWhatsapp> activarWhatsapp(String celular);

  /// Apaga los recordatorios por WhatsApp.
  Future<void> desactivarWhatsapp();

  /// Registra el pago de las deudas elegidas, con el medio indicado, y
  /// devuelve el número de operación. El servidor toma los montos de la base y
  /// confirma el pago: el cliente no manda importes.
  Future<String> pagar(List<String> deudaIds, MedioPago medio);

  /// Avisa cada vez que cambia una deuda del vecino (por ejemplo, tras un
  /// pago), para que la pantalla se actualice sola.
  Stream<void> get cambiosDeudas;
}
