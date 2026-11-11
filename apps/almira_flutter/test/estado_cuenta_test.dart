import 'package:almira_flutter/app/router.dart';
import 'package:almira_flutter/features/account/estado_cuenta_logica.dart';
import 'package:almira_flutter/features/auth/servicio_auth.dart';
import 'package:almira_flutter/shared/models/modelos.dart';
import 'package:almira_flutter/shared/services/proveedores.dart';
import 'package:flutter_test/flutter_test.dart';

Deuda _deuda(
  String id, {
  TipoDeuda tipo = TipoDeuda.predial,
  int anio = 2026,
  int trimestre = 1,
  double insoluto = 20,
  double ge = 0,
  double interes = 0,
  double descuento = 0,
  double pagos = 0,
  bool pagada = false,
  double? saldo,
}) =>
    Deuda(
      id: id,
      municipalidadId: 'm',
      vecinoId: 'v',
      tipo: tipo,
      concepto: tipo.etiqueta,
      periodo: '$anio-TRIM.$trimestre',
      montoInsoluto: insoluto,
      interesMoratorio: 0,
      vencimiento: DateTime(anio, trimestre * 3 - 1, 28),
      estado: pagada ? EstadoDeuda.pagada : EstadoDeuda.vigente,
      anio: anio,
      trimestre: trimestre,
      gastosEmision: ge,
      interesActualizacion: interes,
      descuento: descuento,
      pagosAplicados: pagos,
      saldo: saldo,
    );

void main() {
  final hoy = DateTime(2026, 11, 11, 10);

  group('saldo de una deuda', () {
    test('saldo = insoluto + gastos + intereses - descuento - pagos', () {
      final d = _deuda('a', insoluto: 100, ge: 7.1, interes: 2.5, descuento: 1.5, pagos: 20);
      expect(d.saldo, closeTo(88.1, 0.001));
      expect(d.importe, closeTo(108.1, 0.001));
    });

    test('pendiente muestra el saldo; pagada, el importe pagado', () {
      final pendiente = _deuda('a', insoluto: 50);
      final pagada = _deuda('b', insoluto: 50, pagos: 50, pagada: true, saldo: 0);
      expect(pendiente.total, 50);
      expect(pagada.total, 50);
      expect(pagada.saldo, 0);
    });

    test('si la base calculó el saldo, se usa ese valor', () {
      expect(_deuda('a', insoluto: 10, saldo: 3).saldo, 3);
    });
  });

  group('estado de cuenta', () {
    final deudas = [
      _deuda('p1', anio: 2025, trimestre: 1, insoluto: 21, ge: 7, pagos: 28, pagada: true, saldo: 0),
      _deuda('p2', anio: 2025, trimestre: 2, insoluto: 21, pagos: 21, pagada: true, saldo: 0),
      _deuda('p3', anio: 2026, trimestre: 1, insoluto: 27),
      _deuda('a1', tipo: TipoDeuda.arbitrios, anio: 2026, trimestre: 4, insoluto: 50, interes: 2),
      _deuda('c1', tipo: TipoDeuda.coactivo, anio: 2023, trimestre: 4, insoluto: 400, ge: 38.5, interes: 70),
    ];

    test('agrupa por tributo y año, en orden', () {
      final estado = construirEstadoCuenta(deudas);
      expect(estado.tributos.map((t) => t.tipo), [TipoDeuda.predial, TipoDeuda.arbitrios, TipoDeuda.coactivo]);
      expect(estado.tributos.first.anios.map((a) => a.anio), [2025, 2026]);
    });

    test('subtotal por año, total acumulado y total general', () {
      final estado = construirEstadoCuenta(deudas);
      final predial = estado.tributos.first;
      expect(predial.anios.first.subtotal.insoluto, 42);
      expect(predial.anios.first.subtotal.pagos, 49);
      expect(predial.anios.first.subtotal.saldo, 0);
      expect(predial.acumulado.insoluto, 69);
      expect(predial.acumulado.saldo, 27);
      expect(estado.general.saldo, closeTo(27 + 52 + 508.5, 0.001));
    });

    test('«Pag» o «Pen» y el trimestre con dos dígitos', () {
      expect(estadoCorto(deudas.first), 'Pag');
      expect(estadoCorto(deudas[2]), 'Pen');
      expect(etiquetaPeriodo(deudas[1]), 'Trimestre 02');
    });

    test('sin deudas el estado está vacío', () {
      expect(construirEstadoCuenta(const []).vacio, isTrue);
    });
  });

  group('pagos en línea', () {
    final deudas = [
      _deuda('p-2025', anio: 2025, trimestre: 4),
      _deuda('p-2026', anio: 2026, trimestre: 4),
      _deuda('pagada', anio: 2026, trimestre: 1, pagos: 20, pagada: true, saldo: 0),
      _deuda('a-2026', tipo: TipoDeuda.arbitrios, anio: 2026, trimestre: 3),
      _deuda('multa', tipo: TipoDeuda.multa, anio: 2026, trimestre: 2),
    ];

    test('«Deuda general» ofrece todos los periodos pendientes del tributo', () {
      final lista = deudasParaPagar(deudas, TipoDeuda.predial, beneficio: false, hoy: hoy);
      expect(lista.map((d) => d.id), ['p-2025', 'p-2026']);
    });

    test('«Beneficio al vencimiento» ofrece solo los del año en curso', () {
      final lista = deudasParaPagar(deudas, TipoDeuda.predial, beneficio: true, hoy: hoy);
      expect(lista.map((d) => d.id), ['p-2026']);
    });

    test('la pestaña Otros incluye las multas', () {
      final lista = deudasParaPagar(deudas, TipoDeuda.otros, beneficio: false, hoy: hoy);
      expect(lista.map((d) => d.id), ['multa']);
    });

    test('el total es la suma de los saldos elegidos', () {
      expect(sumarSaldos([deudas[0], deudas[1]]), 40);
    });
  });

  group('historial de pagos', () {
    final deudas = [
      _deuda('a', anio: 2025, pagos: 20, pagada: true, saldo: 0),
      _deuda('b', tipo: TipoDeuda.arbitrios, anio: 2026, pagos: 50, pagada: true, saldo: 0),
    ];
    final pagos = [
      Pago(id: '1', municipalidadId: 'm', vecinoId: 'v', deudaId: 'a', monto: 20, estado: EstadoPago.confirmado, creadoEn: DateTime(2025, 2, 20), medio: 'yape'),
      Pago(id: '2', municipalidadId: 'm', vecinoId: 'v', deudaId: 'b', monto: 50, estado: EstadoPago.confirmado, creadoEn: DateTime(2026, 8, 20), medio: 'tarjeta'),
      Pago(id: '3', municipalidadId: 'm', vecinoId: 'v', deudaId: 'b', monto: 9, estado: EstadoPago.rechazado, creadoEn: DateTime(2026, 9, 1)),
    ];

    test('del más reciente al más antiguo, sin los rechazados', () {
      final lista = historialDePagos(pagos, deudas);
      expect(lista.map((p) => p.pago.id), ['2', '1']);
    });

    test('se filtra por año y por tributo', () {
      expect(historialDePagos(pagos, deudas, anio: 2025).map((p) => p.pago.id), ['1']);
      expect(historialDePagos(pagos, deudas, tributo: TipoDeuda.arbitrios).map((p) => p.pago.id), ['2']);
    });

    test('el medio se lee como etiqueta', () {
      expect(pagos.first.etiquetaMedio, 'Yape');
      expect(pagos[1].etiquetaMedio, 'Tarjeta');
    });
  });

  group('registro por cuponera', () {
    test('sin cuenta se puede abrir el registro, pero no Inicio', () {
      const sinCuenta = Sesion();
      expect(redirigir(sinCuenta, Rutas.registro), isNull);
      expect(redirigir(sinCuenta, Rutas.inicio), Rutas.ingreso);
    });

    test('con la municipalidad ya elegida solo falta el consentimiento', () {
      const cuenta = Cuenta(id: 'u');
      const aMedias = Sesion(cuenta: cuenta, municipalidadElegida: 'm');
      expect(redirigir(aMedias, Rutas.inicio), Rutas.consentimiento);
      const sinMunicipalidad = Sesion(cuenta: cuenta);
      expect(redirigir(sinMunicipalidad, Rutas.inicio), Rutas.configurar);
    });
  });

  group('contribuyente', () {
    test('el nombre del estado de cuenta va en mayúsculas, apellidos primero', () {
      const v = Vecino(
        id: 'v',
        municipalidadId: 'm',
        userId: null,
        nombre: 'Mario Alberto Cárdenas Tello',
        nombres: 'Mario Alberto',
        apellidos: 'Cárdenas Tello',
      );
      expect(v.nombreCompleto, 'CÁRDENAS TELLO MARIO ALBERTO');
    });
  });
}
