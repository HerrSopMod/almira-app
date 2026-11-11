import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/error_app.dart';
import '../../shared/models/modelos.dart';
import '../../shared/services/proveedores.dart';
import '../../shared/services/repositorio.dart';
import 'validadores_pago.dart';

/// Datos que el vecino escribe para pagar. Viven solo en la pantalla mientras paga:
/// no se guardan, no se registran y `toString` no los muestra.
sealed class DatosPago {
  const DatosPago();

  MedioPago get medio;
}

final class DatosTarjeta extends DatosPago {
  const DatosTarjeta({
    required this.numero,
    required this.vencimiento,
    required this.cvv,
    required this.titular,
  });

  final String numero;
  final String vencimiento;
  final String cvv;
  final String titular;

  @override
  MedioPago get medio => MedioPago.tarjeta;

  @override
  String toString() => 'DatosTarjeta(•••)';
}

final class DatosYape extends DatosPago {
  const DatosYape({required this.celular, required this.codigoAprobacion});

  final String celular;
  final String codigoAprobacion;

  @override
  MedioPago get medio => MedioPago.yape;

  @override
  String toString() => 'DatosYape(•••)';
}

/// Qué se quiere cobrar: las deudas elegidas y los datos del medio. Nunca un importe:
/// el monto lo toma el servidor de la base.
class SolicitudCobro {
  const SolicitudCobro({required this.deudaIds, required this.datos});

  final List<String> deudaIds;
  final DatosPago datos;

  @override
  String toString() => 'SolicitudCobro(${deudaIds.length} deudas)';
}

class ResultadoCobro {
  const ResultadoCobro({required this.operacion, required this.fecha});

  final String operacion;
  final DateTime fecha;
}

/// Cobro de un pago. Hay una implementación hoy ([PasarelaServidor]) y otra pensada para
/// conectar la pasarela real de la municipalidad ([PasarelaMunicipal]): la pantalla no cambia.
abstract interface class PaymentGateway {
  Future<ResultadoCobro> cobrar(SolicitudCobro solicitud);
}

/// Implementación actual: comprueba el formato de los datos en el teléfono y le pide al
/// servidor de Almira que confirme el pago (función `registrar_pago`). Los datos de la
/// tarjeta o de Yape no salen del teléfono: al servidor solo viajan las deudas y el medio.
class PasarelaServidor implements PaymentGateway {
  PasarelaServidor(this._repositorio, this._reloj);

  final Repositorio _repositorio;
  final DateTime Function() _reloj;

  @override
  Future<ResultadoCobro> cobrar(SolicitudCobro solicitud) async {
    final error = validarDatosPago(solicitud.datos, _reloj());
    if (error != null) throw ErrorApp(TipoError.servidor, error);
    final operacion = await _repositorio.pagar(solicitud.deudaIds, solicitud.datos.medio);
    return ResultadoCobro(operacion: operacion, fecha: _reloj());
  }
}

/// Lugar reservado para la pasarela real de la municipalidad. Aquí iría: enviar los datos
/// al proveedor de pagos (con su SDK, sin tocarlos ni guardarlos), esperar su aprobación y
/// recién entonces pedirle al servidor que confirme el pago. Mientras no esté contratada,
/// no hay cobro por esta vía.
class PasarelaMunicipal implements PaymentGateway {
  const PasarelaMunicipal();

  @override
  Future<ResultadoCobro> cobrar(SolicitudCobro solicitud) async =>
      throw const ErrorApp(TipoError.servidor, 'Este medio de pago no está disponible por ahora.');
}

/// Pasarela en uso. Para conectar la real, se devuelve aquí [PasarelaMunicipal].
final paymentGatewayProvider = Provider<PaymentGateway>(
  (ref) => PasarelaServidor(ref.watch(repositorioProvider), ref.watch(relojProvider)),
);
