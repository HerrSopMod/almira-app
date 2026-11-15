// Pantallas de Reclamos, Obras, Asistente y Perfil en 360×640 y 393×852, con el texto del
// sistema al 100 % y al 130 %: nada se desborda ni se corta.
//
// Con `--dart-define=CAPTURAS_PULIDO=<carpeta>` guarda además una captura de cada pantalla en
// esa carpeta, para revisarlas a simple vista. Sin la variable no escribe nada.
import 'dart:io';

import 'package:almira_flutter/app/app.dart';
import 'package:almira_flutter/app/router.dart';
import 'package:almira_flutter/app/theme/iconos.dart';
import 'package:almira_flutter/features/assistant/chat_modelo.dart';
import 'package:almira_flutter/features/assistant/servicio_asistente.dart';
import 'package:almira_flutter/features/auth/servicio_auth.dart';
import 'package:almira_flutter/features/complaints/selector_ubicacion_screen.dart';
import 'package:almira_flutter/shared/services/proveedores.dart';
import 'package:almira_flutter/shared/services/repositorio_demo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _hoy = DateTime(2026, 11, 11, 10);
const _carpeta = String.fromEnvironment('CAPTURAS_PULIDO');

const _ingresoJson =
    '{"municipalidadId":"demo-lince","consentimientos":{"asistenteIa":false,"avisosWhatsapp":false,"avisosSms":false},'
    '"consentimientoAceptadoEn":"2026-11-11T10:00:00.000Z"}';

/// Escribe cada captura en [_carpeta] con el nombre del archivo, sin comparar.
class _GuardarFuera extends GoldenFileComparator {
  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    await update(golden, imageBytes);
    return true;
  }

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async {
    final archivo = File('$_carpeta/${golden.pathSegments.last}');
    await archivo.parent.create(recursive: true);
    await archivo.writeAsBytes(imageBytes);
  }
}

class _Respondedor implements ServicioAsistente {
  @override
  Future<RespuestaAsistente> preguntar(String mensaje, List<MensajeChat> historial) async =>
      const RespuestaAsistente(
        'Tu total pendiente es S/ 120.50 en 2 obligaciones. Una está vencida desde el 15 de octubre.',
        acciones: [AccionChat('Pagar en línea', Rutas.pagoEnLinea)],
      );
}

Future<void> _cargarFuentes() async {
  final inter = FontLoader('PlusJakartaSans')..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
  await inter.load();
  // Íconos Iconsax de la app (línea y rellenos).
  await (FontLoader('packages/iconsax_flutter/FlutterIconsax')
        ..addFont(rootBundle.load('packages/iconsax_flutter/fonts/FlutterIconsax.ttf')))
      .load();
  final raiz = Platform.environment['FLUTTER_ROOT'];
  final material = File('$raiz/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (raiz != null && material.existsSync()) {
    await (FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(material.readAsBytesSync())))).load();
  }
}

Widget _app(SharedPreferences p) => ProviderScope(
      overrides: [
        preferenciasProvider.overrideWithValue(p),
        repositorioProvider.overrideWithValue(RepositorioDemo(p, reloj: () => _hoy)),
        servicioAuthProvider.overrideWithValue(ServicioAuthDemo(p)),
        relojProvider.overrideWithValue(() => _hoy),
        servicioAsistenteProvider.overrideWithValue(_Respondedor()),
      ],
      child: const AlmiraApp(),
    );

Future<void> _revisar(WidgetTester tester, String nombre) async {
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull, reason: 'se desborda: $nombre');
  if (_carpeta.isNotEmpty) {
    await expectLater(find.byType(AlmiraApp), matchesGoldenFile('$nombre.png'));
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _cargarFuentes();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => Directory.systemTemp.path,
    );
    if (_carpeta.isNotEmpty) goldenFileComparator = _GuardarFuera();
  });

  for (final (etiqueta, ancho, alto, escala) in [
    ('360x640', 360.0, 640.0, 1.0),
    ('360x640-letra130', 360.0, 640.0, 1.3),
    ('393x852', 393.0, 852.0, 1.0),
    ('393x852-letra130', 393.0, 852.0, 1.3),
  ]) {
    testWidgets('mis pantallas sin desbordes $etiqueta', (tester) async {
      tester.view.physicalSize = Size(ancho * 2, alto * 2);
      tester.view.devicePixelRatio = 2;
      tester.platformDispatcher.textScaleFactorTestValue = escala;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      SharedPreferences.setMockInitialValues({'demo.sesion': true, 'demo.ingreso': _ingresoJson});
      await tester.pumpWidget(_app(await SharedPreferences.getInstance()));
      await tester.pumpAndSettle();
      final router = ProviderScope.containerOf(tester.element(find.byType(AlmiraApp))).read(routerProvider);

      for (final (nombre, ruta) in [
        ('reclamos', Rutas.reclamos),
        ('reclamo-abierto', Rutas.reclamo('demo-reclamo-1842')),
        ('reclamo-resuelto', Rutas.reclamo('demo-reclamo-1790')),
        ('nuevo-reclamo', Rutas.nuevoReclamo),
        ('obras', Rutas.obras),
        ('obra-pistas', Rutas.obra('demo-obra-pistas')),
        ('obra-parque', Rutas.obra('demo-obra-parque')),
        ('asistente', Rutas.asistente),
        ('perfil', Rutas.perfil),
        ('privacidad', Rutas.privacidad),
      ]) {
        router.go(ruta);
        await _revisar(tester, '$nombre-$etiqueta');
      }

      // Asistente con una respuesta, y con el teclado abierto.
      router.go(Rutas.asistente);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '¿Cuánto debo?');
      await tester.pump();
      await tester.tap(find.byIcon(Phosphor.arrowUp));
      await tester.pumpAndSettle();
      await _revisar(tester, 'asistente-respuesta-$etiqueta');
      tester.view.viewInsets = const FakeViewPadding(bottom: 600);
      await _revisar(tester, 'asistente-teclado-$etiqueta');
      final campo = tester.getRect(find.byType(TextField));
      expect(campo.bottom, lessThanOrEqualTo(alto - 300), reason: 'el campo queda bajo el teclado');
      tester.view.viewInsets = FakeViewPadding.zero;

      // Selector de ubicación (se abre encima de todo, sin ruta propia).
      router.go(Rutas.reclamos);
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.byType(Scaffold).first), rootNavigator: true).push(
        MaterialPageRoute<void>(
          builder: (_) => const SelectorUbicacionScreen(centro: LatLng(-12.0839, -77.0343), zoom: 15),
        ),
      );
      await _revisar(tester, 'selector-ubicacion-$etiqueta');
    });
  }
}
