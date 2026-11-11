import 'package:almira_flutter/core/errors/error_app.dart';
import 'package:almira_flutter/features/payments/payment_gateway.dart';
import 'package:almira_flutter/features/payments/validadores_pago.dart';
import 'package:almira_flutter/shared/models/modelos.dart';
import 'package:almira_flutter/shared/services/repositorio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Repositorio que solo anota qué le pidieron pagar.
class _RepositorioFalso implements Repositorio {
  List<String>? ids;
  MedioPago? medio;
  int llamadas = 0;

  @override
  Future<String> pagar(List<String> deudaIds, MedioPago medio) async {
    llamadas++;
    ids = deudaIds;
    this.medio = medio;
    return 'OP-90501';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final hoy = DateTime(2026, 11, 11, 10);

  group('validación de formato', () {
    test('número de tarjeta: de 13 a 19 dígitos', () {
      expect(validarNumeroTarjeta('4111 1111 1111 1111'), isNull);
      expect(validarNumeroTarjeta('1234'), isNotNull);
      expect(validarNumeroTarjeta(''), isNotNull);
    });

    test('vencimiento: mes válido y tarjeta vigente', () {
      expect(validarVencimiento('12/28', hoy), isNull);
      expect(validarVencimiento('11/26', hoy), isNull);
      expect(validarVencimiento('10/26', hoy), 'La tarjeta está vencida.');
      expect(validarVencimiento('13/28', hoy), 'El mes no es válido.');
      expect(validarVencimiento('1/2', hoy), isNotNull);
    });

    test('CVV de 3 o 4 dígitos y titular con letras', () {
      expect(validarCvv('123'), isNull);
      expect(validarCvv('1234'), isNull);
      expect(validarCvv('12'), isNotNull);
      expect(validarTitular('MARIO CARDENAS'), isNull);
      expect(validarTitular('M4'), isNotNull);
    });

    test('Yape: celular de 9 dígitos y código de 6', () {
      expect(validarCelularYape('987654321'), isNull);
      expect(validarCelularYape('887654321'), isNotNull);
      expect(validarCodigoAprobacion('123456'), isNull);
      expect(validarCodigoAprobacion('12345'), isNotNull);
    });
  });

  group('pasarela de pago', () {
    const tarjeta = DatosTarjeta(
      numero: '4111 1111 1111 1111',
      vencimiento: '12/28',
      cvv: '123',
      titular: 'MARIO CARDENAS',
    );

    test('al servidor solo viajan las deudas y el medio, nunca los datos de la tarjeta', () async {
      final repo = _RepositorioFalso();
      final resultado = await PasarelaServidor(repo, () => hoy)
          .cobrar(const SolicitudCobro(deudaIds: ['d1', 'd2'], datos: tarjeta));
      expect(repo.ids, ['d1', 'd2']);
      expect(repo.medio, MedioPago.tarjeta);
      expect(resultado.operacion, 'OP-90501');
    });

    test('con Yape el medio es yape', () async {
      final repo = _RepositorioFalso();
      await PasarelaServidor(repo, () => hoy).cobrar(
        const SolicitudCobro(
          deudaIds: ['d1'],
          datos: DatosYape(celular: '987654321', codigoAprobacion: '123456'),
        ),
      );
      expect(repo.medio, MedioPago.yape);
    });

    test('con datos mal escritos no se cobra', () async {
      final repo = _RepositorioFalso();
      const mala = DatosTarjeta(numero: '12', vencimiento: '12/28', cvv: '123', titular: 'MARIO');
      await expectLater(
        PasarelaServidor(repo, () => hoy).cobrar(const SolicitudCobro(deudaIds: ['d1'], datos: mala)),
        throwsA(isA<ErrorApp>()),
      );
      expect(repo.llamadas, 0);
    });

    test('los datos del medio no aparecen al imprimirlos', () {
      expect(tarjeta.toString(), isNot(contains('4111')));
      expect(tarjeta.toString(), isNot(contains('123')));
      expect(const SolicitudCobro(deudaIds: ['d1'], datos: tarjeta).toString(), isNot(contains('4111')));
      expect(const DatosYape(celular: '987654321', codigoAprobacion: '123456').toString(), isNot(contains('987')));
    });

    test('la pasarela municipal aún no cobra', () async {
      await expectLater(
        const PasarelaMunicipal().cobrar(const SolicitudCobro(deudaIds: ['d1'], datos: tarjeta)),
        throwsA(isA<ErrorApp>()),
      );
    });
  });
}
