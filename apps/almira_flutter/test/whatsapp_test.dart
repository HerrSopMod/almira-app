// Recordatorios por WhatsApp en Mi perfil: validación del celular, consentimiento, mensajes
// amables ante un fallo, estado enmascarado y capturas de la hoja con el teclado abierto.
import 'dart:io';
import 'dart:typed_data';

import 'package:almira_flutter/app/app.dart';
import 'package:almira_flutter/app/router.dart';
import 'package:almira_flutter/app/theme/app_theme.dart';
import 'package:almira_flutter/features/auth/servicio_auth.dart';
import 'package:almira_flutter/features/profile/whatsapp_opcion.dart';
import 'package:almira_flutter/shared/models/preferencia_whatsapp.dart';
import 'package:almira_flutter/shared/services/proveedores.dart';
import 'package:almira_flutter/shared/services/repositorio_demo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _hoy = DateTime(2026, 11, 12, 10);
const _alturaTeclado = 300.0;

/// Repositorio de ejemplo que se presenta como el real y recuerda lo que pasa con WhatsApp.
class _Repo extends RepositorioDemo {
  _Repo(super.preferencias, {this.resultado = ResultadoWhatsapp.activado, PreferenciaWhatsapp? inicial, super.reloj})
      : preferencia = inicial;

  ResultadoWhatsapp resultado;
  PreferenciaWhatsapp? preferencia;
  final celulares = <String>[];
  var apagados = 0;

  @override
  bool get esDemo => false;

  @override
  Future<PreferenciaWhatsapp?> preferenciaWhatsapp() async => preferencia;

  @override
  Future<ResultadoWhatsapp> activarWhatsapp(String celular) async {
    celulares.add(celular);
    if (resultado == ResultadoWhatsapp.activado) {
      preferencia = PreferenciaWhatsapp(activo: true, numero: '+51$celular');
    }
    return resultado;
  }

  @override
  Future<void> desactivarWhatsapp() async {
    apagados++;
    preferencia = const PreferenciaWhatsapp(activo: false);
  }
}

class _SesionDePrueba extends SesionNotifier {
  @override
  Sesion build() => const Sesion(cuenta: Cuenta(id: 'u1'));
}

class _GuardarCapturas extends LocalFileComparator {
  _GuardarCapturas(super.testFile);

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    await update(golden, imageBytes);
    return true;
  }
}

Future<void> _cargarFuentes() async {
  final cargador = FontLoader('Inter');
  for (final peso in ['400Regular', '500Medium', '600SemiBold', '700Bold']) {
    cargador.addFont(rootBundle.load('assets/fonts/Inter_$peso.ttf'));
  }
  await cargador.load();
  final raiz = Platform.environment['FLUTTER_ROOT'];
  if (raiz != null) {
    final archivo = File('$raiz/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    if (archivo.existsSync()) {
      final iconos = FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(archivo.readAsBytesSync())));
      await iconos.load();
    }
  }
}

Future<_Repo> _repo({ResultadoWhatsapp resultado = ResultadoWhatsapp.activado, PreferenciaWhatsapp? inicial}) async {
  SharedPreferences.setMockInitialValues({});
  return _Repo(await SharedPreferences.getInstance(), resultado: resultado, inicial: inicial, reloj: () => _hoy);
}

/// La opción sola, dentro de un Scaffold, para probar su comportamiento.
Widget _opcion(_Repo repo) => ProviderScope(
      overrides: [
        repositorioProvider.overrideWithValue(repo),
        sesionProvider.overrideWith(() => _SesionDePrueba()),
      ],
      child: MaterialApp(theme: AppTheme.claro, home: const Scaffold(body: OpcionWhatsapp())),
    );

Future<void> _abrirHoja(WidgetTester tester) async {
  await tester.tap(find.byType(Switch));
  await tester.pumpAndSettle();
}

void _pantalla(WidgetTester tester, {double ancho = 360, double alto = 640, bool teclado = false}) {
  tester.view.physicalSize = Size(ancho * 2, alto * 2);
  tester.view.devicePixelRatio = 2;
  tester.view.viewInsets = FakeViewPadding(bottom: teclado ? _alturaTeclado * 2 : 0);
  addTearDown(tester.view.reset);
}

FilledButton _botonActivar(WidgetTester tester) => tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Activar'));

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _cargarFuentes();
    Directory('docs/capturas/rediseno').createSync(recursive: true);
    goldenFileComparator = _GuardarCapturas(Uri.parse('test/whatsapp_test.dart'));
  });

  group('celular y texto', () {
    test('valida 9 dígitos que empiecen con 9', () {
      expect(validarCelularWhatsapp(''), isNotNull);
      expect(validarCelularWhatsapp('12345'), isNotNull);
      expect(validarCelularWhatsapp('887654321'), isNotNull);
      expect(validarCelularWhatsapp('9876543210'), isNotNull);
      expect(validarCelularWhatsapp('987654321'), isNull);
    });

    test('el número se muestra enmascarado', () {
      const p = PreferenciaWhatsapp(activo: true, numero: '+51987654321');
      expect(p.numeroEnmascarado, '+51 9** *** 321');
      expect(p.celular, '987654321');
      expect(enmascararCelular(null), '***');
      expect(p.numeroEnmascarado, isNot(contains('87654')));
    });

    test('el texto de consentimiento es el acordado y está versionado', () {
      expect(
        textoConsentimientoWhatsapp,
        'Acepto recibir recordatorios de pago de mi Municipalidad por WhatsApp. Puedo desactivarlos cuando quiera.',
      );
      expect(versionConsentimientoWhatsapp, matches(RegExp(r'^[a-z0-9._-]{3,40}$')));
    });
  });

  group('hoja de activación', () {
    testWidgets('el botón espera un celular válido y el consentimiento', (tester) async {
      final repo = await _repo();
      await tester.pumpWidget(_opcion(repo));
      await tester.pumpAndSettle();
      await _abrirHoja(tester);

      expect(find.text('Recordatorios por WhatsApp'), findsNWidgets(2)); // fila y hoja
      expect(find.textContaining('Acepto recibir recordatorios de pago de mi Municipalidad'), findsOneWidget);
      expect(_botonActivar(tester).onPressed, isNull);

      await tester.enterText(find.byType(TextFormField), '12345');
      await tester.pump();
      expect(find.text('Escribe los 9 dígitos de tu celular, empezando con 9.'), findsOneWidget);
      expect(_botonActivar(tester).onPressed, isNull);

      await tester.enterText(find.byType(TextFormField), '987654321');
      await tester.pump();
      expect(find.text('Escribe los 9 dígitos de tu celular, empezando con 9.'), findsNothing);
      // Con el celular bien pero sin consentimiento, sigue apagado.
      expect(_botonActivar(tester).onPressed, isNull);

      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      expect(_botonActivar(tester).onPressed, isNotNull);
    });

    testWidgets('solo acepta dígitos y 9 como máximo', (tester) async {
      await tester.pumpWidget(_opcion(await _repo()));
      await tester.pumpAndSettle();
      await _abrirHoja(tester);
      await tester.enterText(find.byType(TextFormField), '98a76-54321 99');
      await tester.pump();
      expect(tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text, '987654321');
    });

    testWidgets('al confirmar guarda el celular, cierra la hoja y muestra el estado enmascarado', (tester) async {
      final repo = await _repo();
      await tester.pumpWidget(_opcion(repo));
      await tester.pumpAndSettle();
      expect(find.textContaining('Activo en'), findsNothing);

      await _abrirHoja(tester);
      await tester.enterText(find.byType(TextFormField), '987654123');
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Activar'));
      await tester.pumpAndSettle();

      expect(repo.celulares, ['987654123']);
      expect(find.byType(HojaActivarWhatsapp), findsNothing);
      expect(find.text('Activo en +51 9** *** 123'), findsOneWidget);
      expect(find.textContaining('987654123'), findsNothing);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    });

    for (final (resultado, mensaje) in [
      (
        ResultadoWhatsapp.noSeEnvio,
        'No pudimos enviar el mensaje a ese número. Revisa que tenga WhatsApp activo e intenta de nuevo.',
      ),
      (ResultadoWhatsapp.sinVinculo, 'Vincula tu cuponera para activar los recordatorios.'),
      (ResultadoWhatsapp.limite, 'Hiciste varios intentos hoy. Inténtalo de nuevo mañana.'),
    ]) {
      testWidgets('si falla (${resultado.name}), mensaje amable y la hoja sigue abierta', (tester) async {
        final repo = await _repo(resultado: resultado);
        await tester.pumpWidget(_opcion(repo));
        await tester.pumpAndSettle();
        await _abrirHoja(tester);
        await tester.enterText(find.byType(TextFormField), '987654321');
        await tester.tap(find.byType(CheckboxListTile));
        await tester.pump();
        await tester.tap(find.widgetWithText(FilledButton, 'Activar'));
        await tester.pumpAndSettle();

        expect(find.text(mensaje), findsOneWidget);
        expect(find.byType(HojaActivarWhatsapp), findsOneWidget);
        // Sin detalles técnicos.
        expect(find.textContaining(RegExp('exception|error|meta|131|http', caseSensitive: false)), findsNothing);
        expect(find.textContaining('Activo en'), findsNothing);
        // Se puede volver a intentar.
        expect(_botonActivar(tester).onPressed, isNotNull);
      });
    }
  });

  group('recordatorios ya activos', () {
    const activo = PreferenciaWhatsapp(activo: true, numero: '+51987654123');

    testWidgets('muestra «Activo en +51 9** *** 123»', (tester) async {
      await tester.pumpWidget(_opcion(await _repo(inicial: activo)));
      await tester.pumpAndSettle();
      expect(find.text('Activo en +51 9** *** 123'), findsOneWidget);
    });

    testWidgets('apagar el interruptor pide confirmar y desactiva', (tester) async {
      final repo = await _repo(inicial: activo);
      await tester.pumpWidget(_opcion(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.text('¿Dejar de recibir recordatorios?'), findsOneWidget);
      // Cancelar no cambia nada.
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(repo.apagados, 0);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Desactivar'));
      await tester.pumpAndSettle();
      expect(repo.apagados, 1);
      expect(find.textContaining('Activo en'), findsNothing);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    });

    testWidgets('tocar la fila ofrece cambiar el número o desactivar', (tester) async {
      final repo = await _repo(inicial: activo);
      await tester.pumpWidget(_opcion(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Recordatorios por WhatsApp'));
      await tester.pumpAndSettle();
      expect(find.text('Cambiar número'), findsOneWidget);
      expect(find.text('Desactivar'), findsOneWidget);

      await tester.tap(find.text('Cambiar número'));
      await tester.pumpAndSettle();
      // La hoja abre con el número actual y pide aceptar de nuevo.
      expect(tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text, '987654123');
      expect(_botonActivar(tester).onPressed, isNull);
    });
  });

  group('en Mi perfil y con el teclado abierto', () {
    Widget app(SharedPreferences p, _Repo repo) => ProviderScope(
          overrides: [
            preferenciasProvider.overrideWithValue(p),
            repositorioProvider.overrideWithValue(repo),
            servicioAuthProvider.overrideWithValue(ServicioAuthDemo(p)),
            relojProvider.overrideWithValue(() => _hoy),
          ],
          child: const AlmiraApp(),
        );

    Future<_Repo> abrirPerfil(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'demo.sesion': true,
        'demo.ingreso': '{"municipalidadId":"demo-lince","consentimientos":{"asistenteIa":false,"avisosWhatsapp":false,"avisosSms":false},'
            '"consentimientoAceptadoEn":"2026-11-12T10:00:00.000Z"}',
      });
      final p = await SharedPreferences.getInstance();
      final repo = _Repo(p, reloj: () => _hoy);
      await tester.pumpWidget(app(p, repo));
      await tester.pumpAndSettle();
      ProviderScope.containerOf(tester.element(find.byType(AlmiraApp))).read(routerProvider).go(Rutas.perfil);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Recordatorios por WhatsApp'), 200);
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('360x640: la hoja, con el celular enfocado, deja visibles el campo, el consentimiento y «Activar»', (tester) async {
      _pantalla(tester);
      await abrirPerfil(tester);
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextFormField));
      tester.view.viewInsets = const FakeViewPadding(bottom: _alturaTeclado * 2);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '9876');
      await tester.pumpAndSettle();

      const visible = 640 - _alturaTeclado;
      for (final f in [
        find.byType(TextFormField),
        find.byType(CheckboxListTile),
        find.widgetWithText(FilledButton, 'Activar'),
      ]) {
        final r = tester.getRect(f);
        expect(r.top, greaterThanOrEqualTo(0));
        expect(r.bottom, lessThanOrEqualTo(visible), reason: 'queda tapado por el teclado');
      }
      expect(tester.takeException(), isNull);
      await expectLater(find.byType(AlmiraApp), matchesGoldenFile('../docs/capturas/rediseno/whatsapp-hoja-teclado-360x640.png'));
    });

    testWidgets('360x640 con letra al 130 %: se puede llegar a «Activar» deslizando la hoja', (tester) async {
      _pantalla(tester);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      await abrirPerfil(tester);
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextFormField));
      tester.view.viewInsets = const FakeViewPadding(bottom: _alturaTeclado * 2);
      await tester.pumpAndSettle();
      await tester.drag(find.byType(SingleChildScrollView).last, const Offset(0, -300));
      await tester.pumpAndSettle();
      final r = tester.getRect(find.widgetWithText(FilledButton, 'Activar'));
      expect(r.bottom, lessThanOrEqualTo(640 - _alturaTeclado));
      expect(tester.takeException(), isNull);
      await expectLater(find.byType(AlmiraApp), matchesGoldenFile('../docs/capturas/rediseno/whatsapp-hoja-teclado-360x640-letra130.png'));
    });

    testWidgets('393x852 sin teclado y con un error amable', (tester) async {
      _pantalla(tester, ancho: 393, alto: 852);
      final repo = await abrirPerfil(tester);
      repo.resultado = ResultadoWhatsapp.noSeEnvio;
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '987654321');
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Activar'));
      await tester.pumpAndSettle();
      expect(find.textContaining('No pudimos enviar el mensaje a ese número'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(find.byType(AlmiraApp), matchesGoldenFile('../docs/capturas/rediseno/whatsapp-hoja-error-393x852.png'));
    });

    testWidgets('activo: la fila de Mi perfil muestra el número enmascarado', (tester) async {
      _pantalla(tester);
      final repo = await abrirPerfil(tester);
      repo.preferencia = const PreferenciaWhatsapp(activo: true, numero: '+51987654123');
      ProviderScope.containerOf(tester.element(find.byType(AlmiraApp))).invalidate(preferenciaWhatsappProvider);
      await tester.pumpAndSettle();
      expect(find.text('Activo en +51 9** *** 123'), findsOneWidget);
      await expectLater(find.byType(AlmiraApp), matchesGoldenFile('../docs/capturas/rediseno/whatsapp-perfil-activo-360x640.png'));
    });
  });

  testWidgets('ningún texto de la hoja dice demo, prueba o simulado', (tester) async {
    await tester.pumpWidget(_opcion(await _repo()));
    await tester.pumpAndSettle();
    await _abrirHoja(tester);
    final textos = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? '').join(' ');
    expect(textos.toLowerCase(), isNot(contains('demo')));
    expect(textos.toLowerCase(), isNot(contains('prueba')));
    expect(textos.toLowerCase(), isNot(contains('simulad')));
    expect(GoRouter, isNotNull);
  });
}
