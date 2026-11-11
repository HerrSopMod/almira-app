import 'package:almira_flutter/app/app.dart';
import 'package:almira_flutter/features/auth/servicio_auth.dart';
import 'package:almira_flutter/shared/models/modelos.dart';
import 'package:almira_flutter/shared/services/datos_demo.dart';
import 'package:almira_flutter/shared/services/proveedores.dart';
import 'package:almira_flutter/shared/services/repositorio_demo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _hoy = DateTime(2026, 11, 11, 10);

Future<SharedPreferences> _preferencias([Map<String, Object> iniciales = const {}]) async {
  SharedPreferences.setMockInitialValues(iniciales);
  return SharedPreferences.getInstance();
}

Widget _app(SharedPreferences preferencias) => ProviderScope(
      overrides: [
        preferenciasProvider.overrideWithValue(preferencias),
        repositorioProvider.overrideWithValue(RepositorioDemo(preferencias, reloj: () => _hoy)),
        servicioAuthProvider.overrideWithValue(ServicioAuthDemo(preferencias)),
        relojProvider.overrideWithValue(() => _hoy),
      ],
      child: const AlmiraApp(),
    );

/// Teléfono pequeño (360 × 640 dp).
void _telefono(WidgetTester tester, {double escalaTexto = 1}) {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = escalaTexto;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
}

Future<void> _entrar(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Entrar a la demostración'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Entrar a la demostración'));
  await tester.pumpAndSettle();
  expect(find.text('Configura tu cuenta'), findsOneWidget);
  await tester.scrollUntilVisible(find.text('Continuar'), 200);
  await tester.tap(find.text('Continuar'));
  await tester.pumpAndSettle();
  expect(find.text('Paso 2 de 2'), findsOneWidget);
}

void main() {
  testWidgets('primer ingreso: lo opcional empieza apagado y «Continuar» no lo activa', (tester) async {
    _telefono(tester);
    final preferencias = await _preferencias();
    await tester.pumpWidget(_app(preferencias));
    await tester.pumpAndSettle();

    // Sin cuenta, abre en el ingreso, marcado como demostración.
    expect(find.text('Entrar a la demostración'), findsOneWidget);
    expect(find.text('Demostración'), findsOneWidget);
    await _entrar(tester);

    final interruptores = tester.widgetList<SwitchListTile>(find.byType(SwitchListTile));
    expect(interruptores, hasLength(3));
    expect(interruptores.every((i) => i.value == false), isTrue);

    await tester.scrollUntilVisible(find.text('Continuar'), 200);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    // Entra a Inicio con todo lo opcional apagado.
    expect(find.text('Hola, Rosa'), findsOneWidget);
    final guardado = ServicioAuthDemo(preferencias).cuenta!.ingreso!;
    expect(guardado.consentimientos.asistente, isFalse);
    expect(guardado.consentimientos.whatsapp, isFalse);
    expect(guardado.consentimientos.sms, isFalse);
  });

  testWidgets('Inicio: el total es la suma de las obligaciones y las pestañas navegan', (tester) async {
    _telefono(tester);
    final preferencias = await _preferencias();
    await tester.pumpWidget(_app(preferencias));
    await tester.pumpAndSettle();
    await _entrar(tester);
    await tester.scrollUntilVisible(find.text('Continuar'), 200);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('Total pendiente'), findsOneWidget);
    expect(find.text('S/ 120.50'), findsOneWidget);
    expect(find.textContaining('2 obligaciones'), findsOneWidget);
    expect(find.text('S/ 40.00'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('S/ 80.50'), 200);
    expect(find.text('S/ 80.50'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    // Las cinco pestañas, ida y vuelta, sin errores ni pantallas superpuestas.
    for (var vuelta = 0; vuelta < 2; vuelta++) {
      for (final (pestana, titulo) in [
        ('Pagar', 'Pagar'),
        ('Reclamos', 'Nuevo reclamo'),
        ('Asistente', 'Escribe tu pregunta'),
        ('Inicio', 'Hola, Rosa'),
      ]) {
        await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(pestana)));
        await tester.pumpAndSettle();
        expect(find.text(titulo), findsWidgets);
        expect(tester.takeException(), isNull);
      }
    }

    // Reclamos: ningún contador contradictorio.
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Reclamos')));
    await tester.pumpAndSettle();
    expect(find.text('Poste sin luz en la esquina'), findsOneWidget);
    expect(find.text('Quedan 5 días hábiles'), findsOneWidget);
    expect(find.text('Resuelto'), findsOneWidget);
    expect(find.textContaining(' de 10 días'), findsNothing);
  });

  testWidgets('segunda apertura: con el ingreso hecho va directo a Inicio', (tester) async {
    _telefono(tester);
    final preferencias = await _preferencias();
    await tester.pumpWidget(_app(preferencias));
    await tester.pumpAndSettle();
    await _entrar(tester);
    await tester.scrollUntilVisible(find.text('Continuar'), 200);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    // Se cierra y se vuelve a abrir la app con lo guardado en el teléfono.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(_app(preferencias));
    await tester.pumpAndSettle();
    expect(find.text('Hola, Rosa'), findsOneWidget);
    expect(find.text('Entrar a la demostración'), findsNothing);
    expect(find.text('Paso 2 de 2'), findsNothing);
  });

  testWidgets('con el texto del sistema al máximo no hay desbordes', (tester) async {
    _telefono(tester, escalaTexto: 2);
    final preferencias = await _preferencias();
    await tester.pumpWidget(_app(preferencias));
    await tester.pumpAndSettle();
    await _entrar(tester);
    await tester.scrollUntilVisible(find.text('Continuar'), 200);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Hola, Rosa'), findsOneWidget);
    for (final pestana in ['Pagar', 'Reclamos', 'Asistente', 'Inicio']) {
      await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(pestana)));
      await tester.pumpAndSettle();
      // Un desborde de diseño se reporta como excepción.
      expect(tester.takeException(), isNull);
    }
  });

  test('un reclamo nuevo persiste con su ubicación al volver a abrir', () async {
    final preferencias = await _preferencias();
    final id = await RepositorioDemo(preferencias, reloj: () => _hoy).crearReclamo(
      const NuevoReclamo(
        tipo: TipoReclamo.limpieza,
        titulo: 'Basura acumulada en la esquina',
        descripcion: 'Hay bolsas de basura desde hace tres días.',
        direccion: 'Av. Risso 310',
        latitud: -12.0852,
        longitud: -77.0309,
      ),
      municipalidadId: DatosDemo.municipalidadId,
      vecinoId: DatosDemo.vecinoId,
    );

    // Otra instancia: como abrir la app de nuevo.
    final datos = await RepositorioDemo(preferencias, reloj: () => _hoy).cargar();
    final guardado = datos.reclamos.firstWhere((r) => r.id == id);
    expect(guardado.codigo, 'R-01843');
    expect(guardado.titulo, 'Basura acumulada en la esquina');
    expect(guardado.latitud, -12.0852);
    expect(guardado.longitud, -77.0309);
    expect(guardado.tieneUbicacion, isTrue);
    expect(guardado.estado, EstadoReclamo.enAtencion);
    expect(datos.reclamos, hasLength(3));
  });
}
