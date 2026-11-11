// Recorrido completo en un teléfono o emulador, en modo demostración:
//
//   flutter test integration_test/flujo_demo_test.dart -d <dispositivo>
//
// Compila sin SUPABASE_URL para que la app abra con los datos de ejemplo.
import 'package:almira_flutter/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ingreso, reclamo con ubicación y seguimiento', (tester) async {
    // Empieza de cero: sin sesión ni reclamos guardados.
    await (await SharedPreferences.getInstance()).clear();
    await app.main();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Entrar a la demostración'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Continuar'), 200);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Continuar'), 200);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Total pendiente'), findsOneWidget);

    // Nuevo reclamo: en la demostración la foto es opcional.
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Reclamos')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nuevo reclamo'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Asunto'), 'Poste sin luz en mi cuadra');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Descripción'),
      'El poste lleva varios días apagado y la cuadra queda a oscuras.',
    );
    await tester.pumpAndSettle();

    // Ubica el pin a mano: no hace falta el permiso de ubicación.
    await tester.scrollUntilVisible(find.text('Elegir en mapa'), 200);
    await tester.tap(find.text('Elegir en mapa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar ubicación'));
    await tester.pumpAndSettle();
    expect(find.text('Mover pin'), findsOneWidget);

    await tester.scrollUntilVisible(find.widgetWithText(TextFormField, 'Dirección o referencia'), 200);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Dirección o referencia'),
      'Jr. Pumacahua 1450',
    );
    await tester.scrollUntilVisible(find.text('Enviar reclamo'), 200);
    await tester.tap(find.text('Enviar reclamo'));
    await tester.pumpAndSettle();

    // Abre el seguimiento del reclamo recién creado.
    expect(find.text('Seguimiento'), findsWidgets);
    expect(find.text('Poste sin luz en mi cuadra'), findsOneWidget);
    expect(find.textContaining('días hábiles'), findsWidgets);
    expect(find.textContaining(' de 10 días'), findsNothing);
    expect(find.text('Sin fotografía adjunta'), findsOneWidget);
  });
}
