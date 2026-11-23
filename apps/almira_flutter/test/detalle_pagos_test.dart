// Mejora del Detalle de deuda y de la hoja de Trimestre: estados pagado a tiempo, pagado tarde,
// vencido y por vencer; deudas con y sin cobranza coactiva; conceptos en 0; y que nada se
// desborde con la letra grande.
import 'package:almira_flutter/app/theme/app_theme.dart';
import 'package:almira_flutter/features/account/hoja_trimestre.dart';
import 'package:almira_flutter/features/payments/deuda_detalle_screen.dart';
import 'package:almira_flutter/features/payments/detalle_deuda_logica.dart';
import 'package:almira_flutter/shared/models/modelos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _hoy = DateTime(2026, 11, 22);

Deuda _deuda({
  String id = 'd1',
  TipoDeuda tipo = TipoDeuda.predial,
  String concepto = 'IMPUESTO PREDIAL',
  int? anio = 2026,
  int? trimestre = 2,
  double insoluto = 27.80,
  double gastos = 0,
  double interes = 0,
  double pagos = 0,
  DateTime? vence,
  EstadoDeuda estado = EstadoDeuda.vigente,
  DateTime? fechaPago,
  String? nroValor,
  String? expCoactivo,
}) => Deuda(
  id: id,
  municipalidadId: 'm',
  vecinoId: 'v',
  tipo: tipo,
  concepto: concepto,
  periodo: 'Trimestre ${trimestre ?? ''}',
  montoInsoluto: insoluto,
  interesMoratorio: 0,
  interesActualizacion: interes,
  gastosEmision: gastos,
  pagosAplicados: pagos,
  vencimiento: vence,
  estado: estado,
  anio: anio,
  trimestre: trimestre,
  fechaPago: fechaPago,
  nroValor: nroValor,
  expCoactivo: expCoactivo,
);

Pago _pago(String deudaId, {String? medio = 'yape', String? referencia = 'OP-1', DateTime? fecha}) => Pago(
  id: 'p-$deudaId',
  municipalidadId: 'm',
  vecinoId: 'v',
  deudaId: deudaId,
  monto: 27.80,
  estado: EstadoPago.confirmado,
  creadoEn: fecha ?? DateTime(2026, 5, 23),
  referencia: referencia,
  medio: medio,
);

void _telefono(WidgetTester tester, {double escala = 1}) {
  tester.view.physicalSize = const Size(393 * 3, 852 * 3);
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = escala;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
}

Future<void> _mostrar(WidgetTester tester, Widget hijo) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.claro,
      home: Scaffold(
        body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: hijo),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('estado de la cuota', () {
    test('pagado a tiempo: días antes del vencimiento', () {
      final d = _deuda(vence: DateTime(2026, 5, 31), estado: EstadoDeuda.pagada, fechaPago: DateTime(2026, 5, 23));
      final e = estadoCuota(d, _hoy, pagadoEl: d.fechaPago);
      expect(e.situacion, SituacionCuota.pagadaATiempo);
      expect(e.titulo, 'Pagado a tiempo');
      expect(e.detalle, '8 días antes del vencimiento');
    });

    test('pagado el mismo día del vencimiento cuenta como a tiempo', () {
      final d = _deuda(vence: DateTime(2026, 5, 31), estado: EstadoDeuda.pagada);
      final e = estadoCuota(d, _hoy, pagadoEl: DateTime(2026, 5, 31));
      expect(e.situacion, SituacionCuota.pagadaATiempo);
      expect(e.detalle, 'el mismo día del vencimiento');
    });

    test('pagado tarde: días después del vencimiento', () {
      final d = _deuda(vence: DateTime(2026, 5, 31), estado: EstadoDeuda.pagada);
      final e = estadoCuota(d, _hoy, pagadoEl: DateTime(2026, 6, 5));
      expect(e.situacion, SituacionCuota.pagadaTarde);
      expect(e.titulo, 'Pagado');
      expect(e.detalle, '5 días después del vencimiento');
    });

    test('vencido con intereses: tiempo relativo y «suma intereses»', () {
      final d = _deuda(vence: DateTime(2025, 11, 30), interes: 2.95, estado: EstadoDeuda.vencida);
      final e = estadoCuota(d, _hoy);
      expect(e.situacion, SituacionCuota.vencida);
      expect(e.titulo, 'Vencido');
      expect(e.detalle, 'hace casi 1 año, suma intereses');
    });

    test('vencido sin intereses no dice que suma intereses', () {
      // Vigente en la base, pero la fecha ya pasó: se toma como vencida.
      final d = _deuda(vence: DateTime(2026, 9, 30));
      final e = estadoCuota(d, _hoy);
      expect(e.situacion, SituacionCuota.vencida);
      expect(e.detalle, 'hace 1 mes');
    });

    test('por vencer: días que faltan', () {
      final e = estadoCuota(_deuda(vence: DateTime(2026, 12, 11)), _hoy);
      expect(e.situacion, SituacionCuota.porVencer);
      expect(e.detalle, 'vence en 19 días');
    });

    test('la fecha de pago sale de la base o, si falta, del pago confirmado', () {
      final d = _deuda(estado: EstadoDeuda.pagada);
      expect(fechaDePago(d, [_pago('d1', fecha: DateTime(2026, 5, 20))]), DateTime(2026, 5, 20));
      expect(fechaDePago(d, const []), isNull);
    });
  });

  group('datos del detalle', () {
    test('coactiva: por tipo o por expediente', () {
      expect(enCoactiva(_deuda(tipo: TipoDeuda.coactivo)), isTrue);
      expect(enCoactiva(_deuda(expCoactivo: 'EXP-2024-118')), isTrue);
      expect(enCoactiva(_deuda()), isFalse);
      expect(enCoactiva(_deuda(expCoactivo: '  ')), isFalse);
    });

    test('título en tipo oración con el año, y bajada con periodo y código', () {
      final d = _deuda(anio: 2023, trimestre: 4, nroValor: '2023-TRIM.4');
      expect(tituloDeuda(d), 'Impuesto predial 2023');
      expect(bajadaDeuda(d), '4.º trimestre · Código 2023-TRIM.4');
      expect(tipoOracion('Arbitrios de Lince'), 'Arbitrios de Lince');
    });

    test('título de la cuota sin repetir el año', () {
      expect(tituloCuota(_deuda(trimestre: 4, anio: 2025)), 'Trimestre 04 · 2025');
      final cuota = Deuda(
        id: 'c',
        municipalidadId: 'm',
        vecinoId: 'v',
        tipo: TipoDeuda.predial,
        concepto: 'Impuesto predial',
        periodo: '4.ª cuota 2026',
        montoInsoluto: 10,
        interesMoratorio: 0,
        vencimiento: null,
        estado: EstadoDeuda.pagada,
        anio: 2026,
      );
      expect(tituloCuota(cuota), '4.ª cuota 2026');
    });

    test('tiempo relativo', () {
      expect(haceTiempo(DateTime(2023, 11, 30), _hoy), 'hace 2 años');
      expect(haceTiempo(DateTime(2026, 11, 17), _hoy), 'hace 5 días');
      expect(haceTiempo(DateTime(2026, 7, 1), _hoy), 'hace 4 meses');
    });

    test('los conceptos en 0 no entran a la composición, salvo el importe', () {
      final nombres = conceptosDe(_deuda(gastos: 0, interes: 3)).map((c) => c.nombre);
      expect(nombres, ['Importe', 'Intereses']);
    });

    test('pagada sin monto de pagos: la cuenta cuadra con el importe', () {
      final d = _deuda(estado: EstadoDeuda.pagada);
      expect(pagosDe(d), d.importe);
      expect(d.saldo, 0);
    });

    test('la constancia solo existe con número de operación y medio conocido', () {
      final d = _deuda(estado: EstadoDeuda.pagada);
      expect(pagoConConstancia(d, [_pago('d1')]), isNotNull);
      expect(pagoConConstancia(d, [_pago('d1', medio: null)]), isNull);
      expect(pagoConConstancia(d, [_pago('d1', referencia: null)]), isNull);
    });
  });

  group('pantalla de Detalle de deuda', () {
    testWidgets('vencida y en coactiva: chips, franja roja, desglose y nota', (tester) async {
      _telefono(tester);
      final d = _deuda(
        tipo: TipoDeuda.coactivo,
        concepto: 'IMPUESTO PREDIAL',
        anio: 2023,
        trimestre: 4,
        insoluto: 412.30,
        gastos: 38.50,
        interes: 71.20,
        vence: DateTime(2023, 11, 30),
        estado: EstadoDeuda.vencida,
        nroValor: '2023-TRIM.4',
        expCoactivo: 'EXP-2024-118',
      );
      await _mostrar(tester, ContenidoDetalleDeuda(deuda: d, hoy: _hoy, alIrAAtencion: () {}));

      expect(find.text('Cobranza coactiva'), findsOneWidget);
      expect(find.text('Vencida'), findsOneWidget);
      expect(find.text('Impuesto predial 2023'), findsOneWidget);
      expect(find.text('4.º trimestre · Código 2023-TRIM.4'), findsOneWidget);
      expect(find.textContaining('hace 2 años'), findsOneWidget);
      // Composición con su porcentaje y el saldo.
      expect(find.text('Gastos de emisión'), findsOneWidget);
      expect(find.text('79%'), findsOneWidget);
      expect(find.text('S/ 522.00'), findsWidgets);
      expect(find.textContaining('cobranza coactiva'), findsOneWidget);
      expect(find.text('Ir a Atención'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sin coactiva: sin chip ni nota; gastos en 0 fuera de la composición', (tester) async {
      _telefono(tester);
      final d = _deuda(insoluto: 30.75, vence: DateTime(2026, 12, 11));
      await _mostrar(tester, ContenidoDetalleDeuda(deuda: d, hoy: _hoy));

      expect(find.text('Cobranza coactiva'), findsNothing);
      expect(find.textContaining('cobranza coactiva'), findsNothing);
      expect(find.text('Vencida'), findsNothing);
      expect(find.text('Gastos de emisión'), findsNothing);
      expect(find.text('Saldo a pagar'), findsOneWidget);
    });

    testWidgets('pagada: «Total pagado» y la insignia Pagada', (tester) async {
      _telefono(tester);
      final d = _deuda(vence: DateTime(2026, 5, 31), estado: EstadoDeuda.pagada);
      await _mostrar(tester, ContenidoDetalleDeuda(deuda: d, hoy: _hoy));
      expect(find.text('Pagada'), findsOneWidget);
      expect(find.text('Total pagado'), findsWidgets);
    });

    testWidgets('con letra al 130 % no se desborda', (tester) async {
      _telefono(tester, escala: 1.3);
      final d = _deuda(
        tipo: TipoDeuda.coactivo,
        insoluto: 412.30,
        gastos: 38.50,
        interes: 71.20,
        vence: DateTime(2023, 11, 30),
        estado: EstadoDeuda.vencida,
      );
      await _mostrar(tester, ContenidoDetalleDeuda(deuda: d, hoy: _hoy, alIrAAtencion: () {}));
      expect(tester.takeException(), isNull);
    });
  });

  group('hoja de Trimestre', () {
    testWidgets('pagado a tiempo: banner lima, «Sin deuda» y constancia', (tester) async {
      _telefono(tester);
      final d = _deuda(vence: DateTime(2026, 5, 31), estado: EstadoDeuda.pagada, fechaPago: DateTime(2026, 5, 23));
      await _mostrar(tester, HojaTrimestre(deuda: d, hoy: _hoy, pagos: [_pago('d1')]));

      expect(find.text('Trimestre 02 · 2026'), findsOneWidget);
      expect(find.text('Impuesto predial'), findsOneWidget);
      expect(find.textContaining('Pagado a tiempo'), findsOneWidget);
      expect(find.textContaining('8 días antes del vencimiento'), findsOneWidget);
      expect(find.text('23 may 2026'), findsOneWidget);
      expect(find.text('Sin deuda'), findsOneWidget);
      expect(find.text('Descargar constancia de pago'), findsOneWidget);
      expect(find.textContaining('Pagar S/'), findsNothing);
    });

    testWidgets('pagado tarde: «Pagado · N días después»; sin documento no hay constancia', (tester) async {
      _telefono(tester);
      final d = _deuda(vence: DateTime(2026, 5, 31), estado: EstadoDeuda.pagada, fechaPago: DateTime(2026, 6, 10));
      await _mostrar(tester, HojaTrimestre(deuda: d, hoy: _hoy, pagos: [_pago('d1', medio: null)]));

      expect(find.textContaining('Pagado a tiempo'), findsNothing);
      expect(find.textContaining('10 días después del vencimiento'), findsOneWidget);
      expect(find.text('Descargar constancia de pago'), findsNothing);
    });

    testWidgets('vencido: banner rojo, «Sin pago», «Por pagar» y acciones', (tester) async {
      _telefono(tester);
      var pagar = 0;
      var detalle = 0;
      final d = _deuda(
        trimestre: 4,
        anio: 2025,
        insoluto: 27.80,
        interes: 2.95,
        vence: DateTime(2025, 11, 30),
        estado: EstadoDeuda.vencida,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.claro,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => HojaTrimestre(
                      deuda: d,
                      hoy: _hoy,
                      pagos: const [],
                      alPagar: () => pagar++,
                      alVerDetalle: () => detalle++,
                    ),
                  ),
                  child: const Text('Abrir'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Trimestre 04 · 2025'), findsOneWidget);
      expect(find.textContaining('hace casi 1 año, suma intereses'), findsOneWidget);
      expect(find.text('Sin pago'), findsOneWidget);
      expect(find.text('Por pagar'), findsOneWidget);
      expect(find.text('S/ 30.75'), findsOneWidget);
      expect(find.text('Pagar S/ 30.75'), findsOneWidget);

      // «Pagar» cierra la hoja y abre el pago.
      await tester.ensureVisible(find.text('Pagar S/ 30.75'));
      await tester.tap(find.text('Pagar S/ 30.75'));
      await tester.pumpAndSettle();
      expect(pagar, 1);
      expect(find.text('Trimestre 04 · 2025'), findsNothing);

      // «Ver detalle completo» también cierra la hoja.
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Ver detalle completo'));
      await tester.tap(find.text('Ver detalle completo'));
      await tester.pumpAndSettle();
      expect(detalle, 1);
    });

    testWidgets('en demostración, «Pagar» queda desactivado', (tester) async {
      _telefono(tester);
      final d = _deuda(insoluto: 30.75, vence: DateTime(2025, 11, 30), estado: EstadoDeuda.vencida);
      await _mostrar(tester, HojaTrimestre(deuda: d, hoy: _hoy, pagos: const [], esDemo: true));
      final boton = tester.widget<FilledButton>(
        find.ancestor(of: find.text('Pagar S/ 30.75'), matching: find.byType(FilledButton)),
      );
      expect(boton.onPressed, isNull);
    });

    testWidgets('con letra al 130 % no se desborda', (tester) async {
      _telefono(tester, escala: 1.3);
      final d = _deuda(insoluto: 27.80, interes: 2.95, vence: DateTime(2025, 11, 30), estado: EstadoDeuda.vencida);
      await _mostrar(tester, HojaTrimestre(deuda: d, hoy: _hoy, pagos: const []));
      expect(tester.takeException(), isNull);
    });
  });
}
