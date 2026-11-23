// Detalle de obra: una finalizada no muestra avance y un monto en 0 (sin dato) no se muestra.
import 'dart:io';

import 'package:almira_flutter/app/app.dart';
import 'package:almira_flutter/app/router.dart';
import 'package:almira_flutter/features/auth/servicio_auth.dart';
import 'package:almira_flutter/features/public_works/obras_screen.dart';
import 'package:almira_flutter/shared/models/modelos.dart';
import 'package:almira_flutter/shared/services/proveedores.dart';
import 'package:almira_flutter/shared/services/repositorio_demo.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _hoy = DateTime(2026, 11, 11, 10);

const _ingresoJson =
    '{"municipalidadId":"demo-lince","consentimientos":{"asistenteIa":false,"avisosWhatsapp":false,"avisosSms":false},'
    '"consentimientoAceptadoEn":"2026-11-11T10:00:00.000Z"}';

/// Datos de demostración más una obra finalizada sin montos ni coordenadas, como las de Infobras.
class _ConObraSinMontos extends RepositorioDemo {
  _ConObraSinMontos(super.preferencias, {super.reloj});

  @override
  Future<FuenteDatos> cargar() async {
    final base = await super.cargar();
    return FuenteDatos(
      municipalidades: base.municipalidades,
      vecinos: base.vecinos,
      predios: base.predios,
      deudas: base.deudas,
      pagos: base.pagos,
      recordatorios: base.recordatorios,
      reclamos: base.reclamos,
      obras: [
        ...base.obras,
        Obra(
          id: 'obra-sin-montos',
          municipalidadId: base.obras.first.municipalidadId,
          nombre: 'Renovación del vivero municipal',
          ubicacion: 'Parque Ramón Castilla',
          estado: EstadoObra.finalizada,
          avancePct: 75.24,
          meta: 'jul 2022',
          montoAsignado: 0,
          montoEjecutado: 0,
          publicada: true,
        ),
      ],
    );
  }
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => Directory.systemTemp.path,
    );
  });

  testWidgets('finalizada sin montos: sin avance ni presupuesto; en ejecución: con los dos', (tester) async {
    SharedPreferences.setMockInitialValues({'demo.sesion': true, 'demo.ingreso': _ingresoJson});
    final p = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferenciasProvider.overrideWithValue(p),
          repositorioProvider.overrideWithValue(_ConObraSinMontos(p, reloj: () => _hoy)),
          servicioAuthProvider.overrideWithValue(ServicioAuthDemo(p)),
          relojProvider.overrideWithValue(() => _hoy),
        ],
        child: const AlmiraApp(),
      ),
    );
    await tester.pumpAndSettle();
    final router = ProviderScope.containerOf(tester.element(find.byType(AlmiraApp))).read(routerProvider);

    router.go(Rutas.obra('obra-sin-montos'));
    await tester.pumpAndSettle();
    expect(find.text('Renovación del vivero municipal'), findsOneWidget);
    expect(find.byType(AvanceFisico), findsNothing);
    expect(find.text('Presupuesto'), findsNothing);
    expect(find.textContaining('S/'), findsNothing);

    router.go(Rutas.obra('demo-obra-parque'));
    await tester.pumpAndSettle();
    expect(find.byType(AvanceFisico), findsOneWidget);
    expect(find.text('Presupuesto'), findsOneWidget);
  });
}
