/// Versión del texto de consentimiento que acepta la persona. Si cambias el texto de
/// [textoConsentimientoWhatsapp], sube esta versión (queda guardada junto con la aceptación).
const versionConsentimientoWhatsapp = 'wa-2026-11-12-v1';

const textoConsentimientoWhatsapp =
    'Acepto recibir recordatorios de pago de mi Municipalidad por WhatsApp. Puedo desactivarlos cuando quiera.';

/// Estado de los recordatorios por WhatsApp de la cuenta.
class PreferenciaWhatsapp {
  const PreferenciaWhatsapp({required this.activo, this.numero});

  final bool activo;

  /// En formato E.164, por ejemplo +51987654321.
  final String? numero;

  /// Los 9 dígitos del celular, o null si no hay número.
  String? get celular {
    final digitos = (numero ?? '').replaceAll(RegExp(r'\D'), '');
    return RegExp(r'^519\d{8}$').hasMatch(digitos) ? digitos.substring(2) : null;
  }

  /// "+51 9** *** 123": nunca se muestra el número completo.
  String get numeroEnmascarado => enmascararCelular(numero);
}

String enmascararCelular(String? numero) {
  final digitos = (numero ?? '').replaceAll(RegExp(r'\D'), '');
  if (RegExp(r'^519\d{8}$').hasMatch(digitos)) return '+51 9** *** ${digitos.substring(digitos.length - 3)}';
  return '***';
}

/// Resultado de activar los recordatorios (guardar la preferencia y mandar la bienvenida).
enum ResultadoWhatsapp {
  activado,

  /// La cuenta todavía no tiene un contribuyente vinculado.
  sinVinculo,

  /// El mensaje de bienvenida no llegó a ese número.
  noSeEnvio,

  /// Demasiados intentos en el día.
  limite,
}

final _celularValido = RegExp(r'^9\d{8}$');

/// Valida un celular peruano de 9 dígitos que empieza con 9. Devuelve el mensaje o null.
String? validarCelularWhatsapp(String? valor) {
  final texto = (valor ?? '').trim();
  if (texto.isEmpty) return 'Escribe tu celular.';
  return _celularValido.hasMatch(texto) ? null : 'Escribe los 9 dígitos de tu celular, empezando con 9.';
}
