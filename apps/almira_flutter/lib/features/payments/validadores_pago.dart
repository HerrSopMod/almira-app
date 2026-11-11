import 'payment_gateway.dart';

/// Solo se comprueba el formato de lo que escribe el vecino. Nada se guarda.
final _soloDigitos = RegExp(r'\D');

String _digitos(String texto) => texto.replaceAll(_soloDigitos, '');

String? validarNumeroTarjeta(String? valor) {
  final n = _digitos(valor ?? '');
  return n.length >= 13 && n.length <= 19 ? null : 'Escribe el número de tu tarjeta.';
}

/// MM/AA, con un mes válido y que la tarjeta no esté vencida.
String? validarVencimiento(String? valor, DateTime hoy) {
  final d = _digitos(valor ?? '');
  if (d.length != 4) return 'Escribe el vencimiento como MM/AA.';
  final mes = int.parse(d.substring(0, 2));
  final anio = 2000 + int.parse(d.substring(2));
  if (mes < 1 || mes > 12) return 'El mes no es válido.';
  final vence = DateTime(anio, mes + 1); // primer día del mes siguiente
  return vence.isAfter(DateTime(hoy.year, hoy.month)) ? null : 'La tarjeta está vencida.';
}

String? validarCvv(String? valor) {
  final n = _digitos(valor ?? '');
  return n.length == 3 || n.length == 4 ? null : 'Escribe el código de seguridad.';
}

String? validarTitular(String? valor) {
  final t = (valor ?? '').trim();
  return t.length >= 3 && RegExp(r"^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ' .-]+$").hasMatch(t)
      ? null
      : 'Escribe el nombre como figura en la tarjeta.';
}

String? validarCelularYape(String? valor) =>
    RegExp(r'^9\d{8}$').hasMatch(valor ?? '') ? null : 'Escribe los 9 dígitos de tu celular.';

String? validarCodigoAprobacion(String? valor) =>
    (valor ?? '').length == 6 && RegExp(r'^\d{6}$').hasMatch(valor!)
        ? null
        : 'Escribe el código de 6 dígitos.';

/// Primer error de formato en los datos del medio, o null si están bien.
String? validarDatosPago(DatosPago datos, DateTime hoy) => switch (datos) {
      DatosTarjeta d => validarNumeroTarjeta(d.numero) ??
          validarVencimiento(d.vencimiento, hoy) ??
          validarCvv(d.cvv) ??
          validarTitular(d.titular),
      DatosYape d => validarCelularYape(d.celular) ?? validarCodigoAprobacion(d.codigoAprobacion),
    };
