// Las insignias de estado no desbordan sus filas en las pantallas donde aparecen
// (reclamos, deudas, obras e inicio), en un teléfono de 360 × 640 con la tipografía
// real y el texto del sistema al 100 %, 130 % y 200 %.
import 'package:almira_flutter/app/app.dart';
import 'package:almira_flutter/app/router.dart';
import 'package:almira_flutter/app/theme/app_spacing.dart';
import 'package:almira_flutter/core/widgets/componentes.dart';
import 'package:almira_flutter/features/auth/servicio_auth.dart';
import 'package:almira_flutter/shared/services/proveedores.dart';
import 'package:almira_flutter/shared/services/repositorio_demo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _hoy = DateTime(2026, 11, 11, 10);

Widget _app(SharedPreferences preferencias) => ProviderScope(
      overrides: [
        preferenciasProvider.overrideWithValue(preferencias),
        repositorioProvider.overrideWithValue(RepositorioDemo(preferencias, reloj: () => _hoy)),
        servicioAuthProvider.overrideWithValue(ServicioAuthDemo(preferencias)),
        relojProvider.overrideWithValue(() => _hoy),
      ],
      child: const AlmiraApp(),
    );

/// Con la tipografía real: la de prueba dibuja cada letra como un cuadrado y desborda sola.
Future<void> _cargarInter() async {
  final cargador = FontLoader('Inter');
  for (final peso in ['400Regular', '500Medium', '600SemiBold', '700Bold']) {
    cargador.addFont(rootBundle.load('assets/fonts/Inter_$peso.ttf'));
  }
  await cargador.load();
}

/// Completa el ingreso de la demostración con el texto al 100 %.
Future<void> _entrar(WidgetTester tester, SharedPreferences preferencias) async {
  await tester.pumpWidget(_app(preferencias));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Entrar a la demostración'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Entrar a la demostración'));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(find.text('Continuar'), 200);
  await tester.ensureVisible(find.text('Continuar'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Continuar'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Ahora no'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).first, '987654321');
  await tester.tap(find.text('Recibir código'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).last, '123456');
  await tester.tap(find.text('Verificar'));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(find.text('Continuar'), 200);
  // Entero en pantalla antes de tocarlo: puede quedar asomando por el borde inferior.
  await tester.ensureVisible(find.text('Continuar'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Continuar'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(_cargarInter);

  for (final escala in [1.0, 1.3, 2.0]) {
    testWidgets('insignias sin desbordes (texto ×$escala)', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      SharedPreferences.setMockInitialValues({});
      final preferencias = await SharedPreferences.getInstance();
      await _entrar(tester, preferencias);

      // Vuelve a abrir la app, ya con el ingreso hecho, con el tamaño de texto a probar.
      tester.platformDispatcher.textScaleFactorTestValue = escala;
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(_app(preferencias));
      await tester.pumpAndSettle();
      expect(find.text('Hola, Rosa'), findsOneWidget);

      final router = ProviderScope.containerOf(tester.element(find.byType(AlmiraApp))).read(routerProvider);
      for (final ruta in [
        Rutas.inicio,
        Rutas.reclamos,
        Rutas.reclamo('demo-reclamo-1842'),
        Rutas.reclamo('demo-reclamo-1790'),
        Rutas.pagos,
        Rutas.deuda('demo-multa'),
        Rutas.deuda('demo-predial'),
        Rutas.obras,
        Rutas.obra('demo-obra-pistas'),
        Rutas.obra('demo-obra-parque'),
      ]) {
        router.go(ruta);
        await tester.pumpAndSettle();
        // Un desborde de diseño se reporta como excepción.
        expect(tester.takeException(), isNull, reason: ruta);
        final insignias = find.byType(Insignia);
        expect(insignias, findsWidgets, reason: ruta);
        if (escala == 1.0) {
          for (final elemento in insignias.evaluate()) {
            expect(elemento.size!.height, AppSpacing.altoInsignia, reason: ruta);
          }
        }
      }
    });
  }
}
