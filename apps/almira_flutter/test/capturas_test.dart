// Capturas de las pantallas principales para revisar el diseño a simple vista, en dos tamaños
// de teléfono (360×640 y 393×852) y con el texto del sistema al 100 % y al 130 %.
//
// Cada corrida vuelve a escribir las capturas en docs/capturas/rediseno/ (no se comparan píxel
// a píxel: sirven para revisar a simple vista). Si una pantalla se desborda, el test falla.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:almira_flutter/app/app.dart';
import 'package:almira_flutter/app/router.dart';
import 'package:almira_flutter/features/assistant/chat_modelo.dart';
import 'package:almira_flutter/features/assistant/servicio_asistente.dart';
import 'package:almira_flutter/features/auth/servicio_auth.dart';
import 'package:almira_flutter/shared/services/proveedores.dart';
import 'package:almira_flutter/shared/services/repositorio_demo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _hoy = DateTime(2026, 11, 11, 10);

/// Guarda cada captura en vez de compararla con la anterior.
class _GuardarCapturas extends LocalFileComparator {
  _GuardarCapturas(super.testFile);

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    await update(golden, imageBytes);
    return true;
  }
}

/// Repositorio de ejemplo que se presenta como el real, para ver el ingreso con cuenta.
class _RepositorioConectado extends RepositorioDemo {
  _RepositorioConectado(super.preferencias, {super.reloj});

  @override
  bool get esDemo => false;
}

Future<void> _cargarInter() async {
  final cargador = FontLoader('Inter');
  for (final peso in ['400Regular', '500Medium', '600SemiBold', '700Bold']) {
    cargador.addFont(rootBundle.load('assets/fonts/Inter_$peso.ttf'));
  }
  await cargador.load();

  // Íconos de Material, para que las capturas muestren los íconos y no cuadros.
  final raiz = Platform.environment['FLUTTER_ROOT'];
  if (raiz != null) {
    final archivo = File('$raiz/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    if (archivo.existsSync()) {
      final iconos = FontLoader('MaterialIcons')
        ..addFont(Future.value(ByteData.sublistView(archivo.readAsBytesSync())));
      await iconos.load();
    }
  }
}

Future<SharedPreferences> _preferencias() async {
  SharedPreferences.setMockInitialValues({});
  return SharedPreferences.getInstance();
}

Widget _app(SharedPreferences p, {required bool conectado}) => ProviderScope(
      overrides: [
        preferenciasProvider.overrideWithValue(p),
        repositorioProvider.overrideWithValue(
          conectado ? _RepositorioConectado(p, reloj: () => _hoy) : RepositorioDemo(p, reloj: () => _hoy),
        ),
        servicioAuthProvider.overrideWithValue(ServicioAuthDemo(p)),
        relojProvider.overrideWithValue(() => _hoy),
      ],
      child: const AlmiraApp(),
    );

void _pantalla(WidgetTester tester, double ancho, double alto, double escala) {
  tester.view.physicalSize = Size(ancho * 2, alto * 2);
  tester.view.devicePixelRatio = 2;
  tester.platformDispatcher.textScaleFactorTestValue = escala;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
}

Future<void> _capturar(WidgetTester tester, String nombre) async {
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull, reason: 'se desborda: $nombre');
  await expectLater(find.byType(AlmiraApp), matchesGoldenFile('../docs/capturas/rediseno/$nombre.png'));
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _cargarInter();
    Directory('docs/capturas/rediseno').createSync(recursive: true);
    goldenFileComparator = _GuardarCapturas(Uri.parse('test/capturas_test.dart'));
  });

  final tamanos = [
    ('360x640', 360.0, 640.0, 1.0),
    ('393x852', 393.0, 852.0, 1.0),
    ('360x640-letra130', 360.0, 640.0, 1.3),
  ];

  for (final (etiqueta, ancho, alto, escala) in tamanos) {
    testWidgets('ingreso con cuenta $etiqueta', (tester) async {
      _pantalla(tester, ancho, alto, escala);
      await tester.pumpWidget(_app(await _preferencias(), conectado: true));
      await _capturar(tester, 'ingreso-$etiqueta');
    });

    testWidgets('pantallas con sesión $etiqueta', (tester) async {
      _pantalla(tester, ancho, alto, escala);
      await tester.pumpWidget(_app(await _preferencias(), conectado: false));
      await tester.pumpAndSettle();

      // Entra con la sesión de ejemplo y completa el ingreso.
      await tester.tap(find.text('Entrar a la demostración'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Continuar'), 200);
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
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      final router = ProviderScope.containerOf(tester.element(find.byType(AlmiraApp))).read(routerProvider);
      await _capturar(tester, 'inicio-$etiqueta');
      for (final (nombre, ruta) in [
        ('pagar', Rutas.pagos),
        ('pago-en-linea', Rutas.pagoEnLinea),
        ('estado-de-cuenta', Rutas.estadoCuenta),
        ('cuponera', Rutas.cuponera),
        ('perfil', Rutas.perfil),
      ]) {
        router.go(ruta);
        await _capturar(tester, '$nombre-$etiqueta');
      }
    });
  }

  testWidgets('registro por pasos 360x640', (tester) async {
    _pantalla(tester, 360, 640, 1);
    await tester.pumpWidget(_app(await _preferencias(), conectado: true));
    await tester.pumpAndSettle();
    final router = ProviderScope.containerOf(tester.element(find.byType(AlmiraApp))).read(routerProvider);
    router.go(Rutas.registro);
    await tester.pumpAndSettle();
    await _capturar(tester, 'registro-360x640');
  });

  // --- Chat con el asistente ---
  const ingresoJson =
      '{"municipalidadId":"demo-lince","consentimientos":{"asistenteIa":false,"avisosWhatsapp":false,"avisosSms":false},'
      '"consentimientoAceptadoEn":"2026-11-11T10:00:00.000Z"}';

  Widget appChat(SharedPreferences p, ServicioAsistente servicio) => ProviderScope(
        overrides: [
          preferenciasProvider.overrideWithValue(p),
          repositorioProvider.overrideWithValue(RepositorioDemo(p, reloj: () => _hoy)),
          servicioAuthProvider.overrideWithValue(ServicioAuthDemo(p)),
          relojProvider.overrideWithValue(() => _hoy),
          servicioAsistenteProvider.overrideWithValue(servicio),
        ],
        child: const AlmiraApp(),
      );

  Future<SharedPreferences> prefsConSesion() async {
    SharedPreferences.setMockInitialValues({'demo.sesion': true, 'demo.ingreso': ingresoJson});
    return SharedPreferences.getInstance();
  }

  Future<void> abrirChat(WidgetTester tester) async {
    await tester.pumpAndSettle();
    ProviderScope.containerOf(tester.element(find.byType(AlmiraApp))).read(routerProvider).go(Rutas.asistente);
    await tester.pumpAndSettle();
  }

  for (final (etiqueta, ancho, alto, escala) in tamanos) {
    testWidgets('chat del asistente $etiqueta', (tester) async {
      _pantalla(tester, ancho, alto, escala);
      var turno = 0;
      final servicio = _Respondedor((mensaje, _) async {
        turno++;
        return switch (turno) {
          1 => const RespuestaAsistente(
              'Tu total pendiente es S/ 120.50 en 2 obligaciones. Una está vencida desde el 15 de octubre '
              'y la otra vence el 30 de noviembre.',
              acciones: [
                AccionChat('Pagar en línea', Rutas.pagoEnLinea),
                AccionChat('Ver estado de cuenta', Rutas.estadoCuenta),
              ],
            ),
          2 => const RespuestaAsistente('Tu último pago fue de S/ 186.40 el 28 de octubre de 2026, con Yape.'),
          _ => const RespuestaAsistente(
              'Ahora mismo no puedo responderte. Revisa tu conexión e inténtalo de nuevo.',
              fallo: true,
            ),
        };
      });
      await tester.pumpWidget(appChat(await prefsConSesion(), servicio));
      await abrirChat(tester);
      await _capturar(tester, 'chat-bienvenida-$etiqueta');

      await tester.tap(find.text('¿Cuánto debo?'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Mi último pago');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Gracias, ¿y cuándo vence lo que falta?');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pumpAndSettle();
      await _capturar(tester, 'chat-conversacion-$etiqueta');
    });

    testWidgets('chat escribiendo $etiqueta', (tester) async {
      _pantalla(tester, ancho, alto, escala);
      final espera = Completer<RespuestaAsistente>();
      await tester.pumpWidget(appChat(await prefsConSesion(), _Respondedor((_, _) => espera.future)));
      await abrirChat(tester);
      await tester.tap(find.text('¿Cómo pago?'));
      await tester.pump(const Duration(milliseconds: 450));
      expect(tester.takeException(), isNull);
      await expectLater(find.byType(AlmiraApp), matchesGoldenFile('../docs/capturas/rediseno/chat-escribiendo-$etiqueta.png'));
      espera.complete(const RespuestaAsistente('Listo.'));
      await tester.pumpAndSettle();
    });
  }
}

/// Asistente de mentira para las capturas.
class _Respondedor implements ServicioAsistente {
  _Respondedor(this._responder);

  final Future<RespuestaAsistente> Function(String mensaje, List<MensajeChat> historial) _responder;

  @override
  Future<RespuestaAsistente> preguntar(String mensaje, List<MensajeChat> historial) =>
      _responder(mensaje, historial);
}
