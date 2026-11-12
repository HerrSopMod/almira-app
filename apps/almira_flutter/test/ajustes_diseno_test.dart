// Ajustes de diseño, ronda 2: diálogo de confirmación, chips de filtro, teclado abierto y
// capturas de las pantallas tocadas (docs/capturas/rediseno/).
import 'dart:io';
import 'dart:typed_data';

import 'package:almira_flutter/app/app.dart';
import 'package:almira_flutter/app/router.dart';
import 'package:almira_flutter/app/theme/app_colors.dart';
import 'package:almira_flutter/app/theme/app_theme.dart';
import 'package:almira_flutter/core/widgets/app_confirm_dialog.dart';
import 'package:almira_flutter/core/widgets/filtros.dart';
import 'package:almira_flutter/core/widgets/scroll_formulario.dart';
import 'package:almira_flutter/features/assistant/chat_modelo.dart';
import 'package:almira_flutter/features/assistant/servicio_asistente.dart';
import 'package:almira_flutter/features/auth/servicio_auth.dart';
import 'package:almira_flutter/shared/services/proveedores.dart';
import 'package:almira_flutter/shared/services/repositorio_demo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _hoy = DateTime(2026, 11, 11, 10);
const _alturaTeclado = 300.0;

class _GuardarCapturas extends LocalFileComparator {
  _GuardarCapturas(super.testFile);

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    await update(golden, imageBytes);
    return true;
  }
}

class _RepositorioConectado extends RepositorioDemo {
  _RepositorioConectado(super.preferencias, {super.reloj});

  @override
  bool get esDemo => false;
}

/// Auth de ejemplo que además lista municipalidades, para ver el registro con sus campos.
class _AuthConMunicipios extends ServicioAuthDemo {
  _AuthConMunicipios(super.preferencias);

  @override
  Future<List<MunicipalidadRegistro>> municipalidadesRegistro() async => const [
        MunicipalidadRegistro(id: 'm1', slug: 'lince', nombre: 'Municipalidad de Lince'),
      ];
}

class _Respondedor implements ServicioAsistente {
  @override
  Future<RespuestaAsistente> preguntar(String mensaje, List<MensajeChat> historial) async =>
      const RespuestaAsistente('Tu total pendiente es S/ 120.50.');
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

const _ingresoJson =
    '{"municipalidadId":"demo-lince","consentimientos":{"asistenteIa":false,"avisosWhatsapp":false,"avisosSms":false},'
    '"consentimientoAceptadoEn":"2026-11-11T10:00:00.000Z"}';

Future<SharedPreferences> _preferencias({bool sesion = false}) async {
  SharedPreferences.setMockInitialValues(sesion ? {'demo.sesion': true, 'demo.ingreso': _ingresoJson} : {});
  return SharedPreferences.getInstance();
}

Widget _app(SharedPreferences p, {bool conectado = false, ServicioAuth? auth}) => ProviderScope(
      overrides: [
        preferenciasProvider.overrideWithValue(p),
        repositorioProvider.overrideWithValue(
          conectado ? _RepositorioConectado(p, reloj: () => _hoy) : RepositorioDemo(p, reloj: () => _hoy),
        ),
        servicioAuthProvider.overrideWithValue(auth ?? ServicioAuthDemo(p)),
        relojProvider.overrideWithValue(() => _hoy),
        servicioAsistenteProvider.overrideWithValue(_Respondedor()),
      ],
      child: const AlmiraApp(),
    );

void _pantalla(WidgetTester tester, double ancho, double alto, {double escala = 1, bool teclado = false}) {
  tester.view.physicalSize = Size(ancho * 2, alto * 2);
  tester.view.devicePixelRatio = 2;
  tester.view.viewInsets = FakeViewPadding(bottom: teclado ? _alturaTeclado * 2 : 0);
  tester.platformDispatcher.textScaleFactorTestValue = escala;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
}

void _abrirTeclado(WidgetTester tester) {
  tester.view.viewInsets = const FakeViewPadding(bottom: _alturaTeclado * 2);
}

Future<void> _capturar(WidgetTester tester, String nombre) async {
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull, reason: 'se desborda: $nombre');
  await expectLater(find.byType(AlmiraApp), matchesGoldenFile('../docs/capturas/rediseno/$nombre.png'));
}

/// El elemento está entero en la zona que deja libre el teclado.
void _visibleConTeclado(WidgetTester tester, Finder f, double alto, String que) {
  final r = tester.getRect(f.first);
  expect(r.top, greaterThanOrEqualTo(0), reason: '$que queda arriba, fuera de la pantalla');
  expect(r.bottom, lessThanOrEqualTo(alto - _alturaTeclado), reason: '$que queda tapado por el teclado');
}

GoRouter _router(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(AlmiraApp))).read(routerProvider);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _cargarFuentes();
    // El mapa guarda mosaicos en la caché; en el test basta con una carpeta temporal.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => Directory.systemTemp.path,
    );
    Directory('docs/capturas/rediseno').createSync(recursive: true);
    goldenFileComparator = _GuardarCapturas(Uri.parse('test/ajustes_diseno_test.dart'));
  });

  group('AppConfirmDialog', () {
    Future<void> abrir(WidgetTester tester, {required bool destructivo, void Function(bool)? alCerrar}) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.claro,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () async {
                    final acepta = await confirmar(
                      context,
                      titulo: '¿Cerrar sesión?',
                      mensaje: 'Tendrás que volver a ingresar para ver tu información.',
                      textoConfirmar: 'Cerrar sesión',
                      destructivo: destructivo,
                    );
                    alCerrar?.call(acepta);
                  },
                  child: const Text('Abrir'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
    }

    testWidgets('título y mensaje centrados, dos botones del mismo ancho y 48 de alto', (tester) async {
      await abrir(tester, destructivo: true);
      expect(tester.widget<Text>(find.text('¿Cerrar sesión?')).textAlign, TextAlign.center);
      expect(
        tester.widget<Text>(find.text('Tendrás que volver a ingresar para ver tu información.')).textAlign,
        TextAlign.center,
      );
      final cancelar = tester.getSize(find.widgetWithText(OutlinedButton, 'Cancelar'));
      final aceptar = tester.getSize(find.widgetWithText(FilledButton, 'Cerrar sesión'));
      expect(cancelar.width, aceptar.width);
      expect(cancelar.height, 48);
      expect(aceptar.height, 48);
      // Esquinas del diálogo de 24.
      final forma = tester.widget<Dialog>(find.byType(Dialog)).shape! as RoundedRectangleBorder;
      expect(forma.borderRadius, BorderRadius.circular(24));
    });

    testWidgets('la acción destructiva va en rojo con texto blanco; «Cancelar» con borde turquesa', (tester) async {
      await abrir(tester, destructivo: true);
      final relleno = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Cerrar sesión'));
      expect(relleno.style!.backgroundColor!.resolve({}), AppColors.error);
      expect(relleno.style!.foregroundColor!.resolve({}), Colors.white);
      final borde = tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Cancelar'));
      expect(borde.style!.side!.resolve({})!.color, AppColors.primary);
      expect(borde.style!.foregroundColor!.resolve({}), AppColors.primary);
    });

    testWidgets('devuelve true al aceptar y false al cancelar', (tester) async {
      bool? resultado;
      await abrir(tester, destructivo: false, alCerrar: (v) => resultado = v);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(resultado, isFalse);

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(resultado, isTrue);
    });
  });

  group('chips de filtro', () {
    Widget envoltura(Widget hijo) => MaterialApp(theme: AppTheme.claro, home: Scaffold(body: hijo));

    testWidgets('activo: relleno turquesa, texto blanco y check; inactivo: blanco con borde gris', (tester) async {
      await tester.pumpWidget(
        envoltura(
          Column(
            children: [
              ChipFiltro(texto: 'Activo', activo: true, alTocar: () {}),
              ChipFiltro(texto: 'Inactivo', activo: false, alTocar: () {}),
            ],
          ),
        ),
      );
      final activo = tester.widget<Material>(find.descendant(of: find.byType(ChipFiltro).first, matching: find.byType(Material)).first);
      final inactivo = tester.widget<Material>(find.descendant(of: find.byType(ChipFiltro).last, matching: find.byType(Material)).first);
      expect(activo.color, AppColors.primary);
      expect(inactivo.color, AppColors.surface);
      expect((inactivo.shape! as StadiumBorder).side.color, AppColors.bordeControl);
      expect(tester.widget<Text>(find.text('Activo')).style!.color, Colors.white);
      expect(tester.widget<Text>(find.text('Inactivo')).style!.color, AppColors.textPrimary);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      // Altura táctil de 44 como mínimo.
      expect(tester.getSize(find.byType(ChipFiltro).first).height, greaterThanOrEqualTo(44));
    });

    testWidgets('el grupo va en una sola fila con scroll horizontal', (tester) async {
      await tester.pumpWidget(
        envoltura(
          SizedBox(
            width: 320,
            child: GrupoFiltros(
              titulo: 'Año',
              chips: [for (final a in [2026, 2025, 2024, 2023, 2022, 2021]) ChipFiltro(texto: '$a', activo: a == 2026, alTocar: () {})],
            ),
          ),
        ),
      );
      expect(find.text('Año'), findsOneWidget);
      expect(tester.widget<ListView>(find.byType(ListView)).scrollDirection, Axis.horizontal);
      // Todos los chips que se ven están en la misma fila.
      final ys = {for (final a in ['2026', '2025', '2024']) tester.getTopLeft(find.text(a)).dy};
      expect(ys.length, 1);
    });

    testWidgets('tocar un chip llama a su acción', (tester) async {
      var toques = 0;
      await tester.pumpWidget(envoltura(ChipFiltro(texto: 'Arbitrios', activo: false, alTocar: () => toques++)));
      await tester.tap(find.text('Arbitrios'));
      expect(toques, 1);
    });
  });

  group('con el teclado abierto', () {
    testWidgets('ingreso 360x640: los dos campos y «Ingresar» quedan visibles sin scroll', (tester) async {
      _pantalla(tester, 360, 640);
      await tester.pumpWidget(_app(await _preferencias(), conectado: true));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextFormField).first);
      _abrirTeclado(tester);
      await tester.pumpAndSettle();
      for (final f in [find.byType(TextFormField).first, find.byType(TextFormField).last, find.text('Ingresar')]) {
        _visibleConTeclado(tester, f, 640, 'un elemento del ingreso');
      }
      // El encabezado (logo y frase) se oculta para dar lugar.
      expect(find.text('Tus pagos, reclamos y obras municipales en un solo lugar.'), findsNothing);
      await _capturar(tester, 'ingreso-teclado-360x640');
    });

    testWidgets('ingreso 360x640 con letra 130 %: también caben con el teclado abierto', (tester) async {
      _pantalla(tester, 360, 640, escala: 1.3);
      await tester.pumpWidget(_app(await _preferencias(), conectado: true));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextFormField).last);
      _abrirTeclado(tester);
      await tester.pumpAndSettle();
      _visibleConTeclado(tester, find.byType(TextFormField).last, 640, 'la clave');
      // «Ingresar» se alcanza con un deslizamiento mínimo.
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -120));
      await tester.pumpAndSettle();
      _visibleConTeclado(tester, find.text('Ingresar'), 640, '«Ingresar»');
      await _capturar(tester, 'ingreso-teclado-360x640-letra130');
    });

    testWidgets('ingreso 393x852', (tester) async {
      _pantalla(tester, 393, 852);
      await tester.pumpWidget(_app(await _preferencias(), conectado: true));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextFormField).first);
      _abrirTeclado(tester);
      await tester.pumpAndSettle();
      _visibleConTeclado(tester, find.text('Ingresar'), 852, '«Ingresar»');
      await _capturar(tester, 'ingreso-teclado-393x852');
    });

    testWidgets('registro: el campo enfocado se ve entero', (tester) async {
      _pantalla(tester, 360, 640);
      final p = await _preferencias();
      await tester.pumpWidget(_app(p, conectado: true, auth: _AuthConMunicipios(p)));
      await tester.pumpAndSettle();
      _router(tester).go(Rutas.registro);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextFormField).first);
      _abrirTeclado(tester);
      await tester.pump(); // el teclado ya está puesto
      // El formulario se desplaza cuando el campo recibe el foco (300 ms después, 150 ms de animación).
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      _visibleConTeclado(tester, find.byType(TextFormField).first, 640, 'el campo de cuponera');
      final desplazamiento = tester.state<ScrollableState>(find.descendant(of: find.byType(ScrollFormulario), matching: find.byType(Scrollable)).first);
      expect(desplazamiento.position.pixels, greaterThan(0), reason: "el formulario debe subir el campo");
      await _capturar(tester, 'registro-teclado-360x640');
    });

    testWidgets('crear clave y verificar celular: campo y botón visibles', (tester) async {
      _pantalla(tester, 360, 640);
      await tester.pumpWidget(_app(await _preferencias()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Entrar a la demostración'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Continuar'), 200);
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      // Crear clave.
      await tester.tap(find.byType(TextFormField).first);
      _abrirTeclado(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      _visibleConTeclado(tester, find.byType(TextFormField).first, 640, 'la clave');
      await _capturar(tester, 'crear-clave-teclado-360x640');

      // Verificar celular.
      tester.view.viewInsets = FakeViewPadding.zero;
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ahora no'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextFormField).first);
      _abrirTeclado(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      _visibleConTeclado(tester, find.byType(TextFormField).first, 640, 'el celular');
      _visibleConTeclado(tester, find.text('Recibir código'), 640, '«Recibir código»');
      await _capturar(tester, 'verificar-celular-teclado-360x640');
    });

    testWidgets('chat: la barra de escribir queda sobre el teclado', (tester) async {
      _pantalla(tester, 360, 640);
      await tester.pumpWidget(_app(await _preferencias(sesion: true)));
      await tester.pumpAndSettle();
      _router(tester).go(Rutas.asistente);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextField));
      _abrirTeclado(tester);
      await tester.pumpAndSettle();
      _visibleConTeclado(tester, find.byType(TextField), 640, 'el campo del chat');
      await _capturar(tester, 'chat-teclado-360x640');
    });
  });

  group('capturas de las pantallas ajustadas', () {
    for (final (etiqueta, ancho, alto, escala) in [
      ('360x640', 360.0, 640.0, 1.0),
      ('393x852', 393.0, 852.0, 1.0),
      ('360x640-letra130', 360.0, 640.0, 1.3),
    ]) {
      testWidgets('obra, estado de cuenta, historial y perfil $etiqueta', (tester) async {
        _pantalla(tester, ancho, alto, escala: escala);
        await tester.pumpWidget(_app(await _preferencias(sesion: true)));
        await tester.pumpAndSettle();
        final router = _router(tester);

        await _capturar(tester, 'inicio-r2-$etiqueta');
        router.go(Rutas.obra('demo-obra-parque'));
        await _capturar(tester, 'obra-detalle-$etiqueta');

        router.go(Rutas.estadoCuenta);
        await _capturar(tester, 'estado-de-cuenta-r2-$etiqueta');
        await tester.tap(find.text('Historial de pagos'));
        await _capturar(tester, 'historial-pagos-$etiqueta');

        router.go(Rutas.perfil);
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.text('Salir de la demostración'), 200);
        await _capturar(tester, 'perfil-r2-$etiqueta');
      });
    }

    testWidgets('diálogo de cerrar sesión 360x640', (tester) async {
      _pantalla(tester, 360, 640);
      await tester.pumpWidget(_app(await _preferencias(sesion: true)));
      await tester.pumpAndSettle();
      _router(tester).go(Rutas.perfil);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Salir de la demostración'), 200);
      await tester.tap(find.text('Salir de la demostración'));
      await _capturar(tester, 'dialogo-cerrar-sesion-360x640');
    });
  });
}
