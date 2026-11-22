// Filtro por fechas con calendario y foto de perfil.
import 'package:almira_flutter/app/theme/app_theme.dart';
import 'package:almira_flutter/app/theme/iconos.dart';
import 'package:almira_flutter/core/utils/rango_fechas.dart';
import 'package:almira_flutter/core/widgets/filtros.dart';
import 'package:almira_flutter/features/profile/foto_perfil.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _hoy = DateTime(2026, 11, 15, 10);

Widget _app(Widget hijo, {List<Override> overrides = const []}) => ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: AppTheme.claro,
        locale: const Locale('es', 'PE'),
        supportedLocales: const [Locale('es', 'PE'), Locale('es')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: hijo)),
      ),
    );

void main() {
  group('FiltroFechas', () {
    test('sin filtro todo entra, incluso una fecha vacía', () {
      expect(FiltroFechas.todas.rango(_hoy), isNull);
      expect(FiltroFechas.todas.contiene(null, _hoy), isTrue);
      expect(FiltroFechas.todas.contiene(DateTime(2020, 1, 1), _hoy), isTrue);
    });

    test('este mes va del 1 a hoy, con los dos extremos incluidos', () {
      final f = FiltroFechas.todas.conPeriodo(PeriodoFecha.esteMes);
      expect(f.rango(_hoy), DateTimeRange(start: DateTime(2026, 11, 1), end: DateTime(2026, 11, 15)));
      expect(f.contiene(DateTime(2026, 11, 1, 8), _hoy), isTrue);
      expect(f.contiene(DateTime(2026, 11, 15, 23, 59), _hoy), isTrue);
      expect(f.contiene(DateTime(2026, 10, 31), _hoy), isFalse);
      expect(f.contiene(DateTime(2026, 11, 16), _hoy), isFalse);
    });

    test('3 meses cuenta el mes en curso y los dos anteriores', () {
      final f = FiltroFechas.todas.conPeriodo(PeriodoFecha.tresMeses);
      expect(f.rango(_hoy)!.start, DateTime(2026, 9, 1));
      // Con enero de hoy, retrocede al año anterior.
      expect(f.rango(DateTime(2027, 1, 20))!.start, DateTime(2026, 11, 1));
    });

    test('este año va desde el 1 de enero', () {
      final f = FiltroFechas.todas.conPeriodo(PeriodoFecha.esteAnio);
      expect(f.rango(_hoy)!.start, DateTime(2026, 1, 1));
      expect(f.contiene(DateTime(2025, 12, 31), _hoy), isFalse);
    });

    test('con filtro, una fecha vacía no entra', () {
      expect(FiltroFechas.todas.conPeriodo(PeriodoFecha.esteAnio).contiene(null, _hoy), isFalse);
    });

    test('un rango del calendario se usa tal cual', () {
      final f = FiltroFechas.todas.conRango(DateTimeRange(start: DateTime(2026, 8, 1), end: DateTime(2026, 8, 31)));
      expect(f.activo, isTrue);
      expect(f.contiene(DateTime(2026, 8, 15), _hoy), isTrue);
      expect(f.contiene(DateTime(2026, 9, 1), _hoy), isFalse);
    });
  });

  group('GrupoFiltroFechas', () {
    testWidgets('muestra los periodos y el calendario, y avisa el que se toca', (tester) async {
      FiltroFechas? ultimo;
      await tester.pumpWidget(_app(GrupoFiltroFechas(filtro: FiltroFechas.todas, hoy: _hoy, alCambiar: (f) => ultimo = f)));
      expect(find.text('Fechas'), findsOneWidget);
      for (final t in ['Todas', 'Elegir fechas', 'Este mes']) {
        expect(find.text(t), findsOneWidget);
      }
      expect(find.byIcon(Phosphor.calendarBlank), findsOneWidget);

      await tester.tap(find.text('Este mes'));
      expect(ultimo?.periodo, PeriodoFecha.esteMes);
    });

    testWidgets('el botón del calendario abre el selector de rango y devuelve lo elegido', (tester) async {
      FiltroFechas? ultimo;
      await tester.pumpWidget(_app(GrupoFiltroFechas(filtro: FiltroFechas.todas, hoy: _hoy, alCambiar: (f) => ultimo = f)));
      await tester.tap(find.text('Elegir fechas'));
      await tester.pumpAndSettle();
      expect(find.text('Elige las fechas'), findsOneWidget);

      // Se elige del 10 al 12 del mes en curso y se aplica.
      await tester.tap(find.text('10').first);
      await tester.pump();
      await tester.tap(find.text('12').first);
      await tester.pump();
      await tester.tap(find.text('Aplicar'));
      await tester.pumpAndSettle();
      expect(ultimo?.periodo, PeriodoFecha.elegido);
      expect(ultimo?.elegido?.start, DateTime(2026, 11, 10));
      expect(ultimo?.elegido?.end, DateTime(2026, 11, 12));
    });

    testWidgets('con un rango elegido, el botón muestra las fechas y queda activo', (tester) async {
      final filtro = FiltroFechas.todas.conRango(DateTimeRange(start: DateTime(2026, 10, 3), end: DateTime(2026, 10, 20)));
      await tester.pumpWidget(_app(GrupoFiltroFechas(filtro: filtro, hoy: _hoy, alCambiar: (_) {})));
      expect(find.text('3 oct 2026 – 20 oct 2026'), findsOneWidget);
      expect(find.text('Elegir fechas'), findsNothing);
    });
  });

  group('foto de perfil', () {
    testWidgets('sin foto muestra las iniciales', (tester) async {
      await tester.pumpWidget(_app(
        const AvatarPerfil(lado: 56, nombre: 'Andrea Torres'),
        overrides: [fotoPerfilProvider.overrideWith((ref) async => null)],
      ));
      await tester.pumpAndSettle();
      expect(find.text('AT'), findsOneWidget);
    });

    testWidgets('si la foto no carga, vuelven las iniciales (sin error en pantalla)', (tester) async {
      await tester.pumpWidget(_app(
        const AvatarPerfil(lado: 56, nombre: 'Andrea Torres'),
        overrides: [fotoPerfilProvider.overrideWith((ref) async => 'https://ejemplo.invalid/foto.jpg')],
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('AT'), findsOneWidget);
    });

    testWidgets('el avatar editable tiene insignia de cámara y abre las opciones', (tester) async {
      await tester.pumpWidget(_app(
        const AvatarEditable(lado: 56, nombre: 'Andrea Torres'),
        overrides: [fotoPerfilProvider.overrideWith((ref) async => null)],
      ));
      await tester.pumpAndSettle();
      expect(find.byIcon(Phosphor.camera), findsOneWidget);
      await tester.tap(find.byType(AvatarEditable));
      await tester.pumpAndSettle();
      expect(find.text('Tomar foto'), findsOneWidget);
      expect(find.text('Elegir de la galería'), findsOneWidget);
      // Sin foto no se ofrece quitarla.
      expect(find.text('Quitar foto'), findsNothing);
    });

    testWidgets('con foto se ofrece quitarla', (tester) async {
      await tester.pumpWidget(_app(
        const AvatarEditable(lado: 56, nombre: 'Andrea Torres'),
        overrides: [fotoPerfilProvider.overrideWith((ref) async => 'https://ejemplo.invalid/foto.jpg')],
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(AvatarEditable));
      await tester.pumpAndSettle();
      expect(find.text('Quitar foto'), findsOneWidget);
    });

    testWidgets('en modo demostración no se puede cambiar', (tester) async {
      await tester.pumpWidget(_app(
        const AvatarEditable(lado: 56, nombre: 'Andrea Torres', editable: false),
        overrides: [fotoPerfilProvider.overrideWith((ref) async => null)],
      ));
      await tester.pumpAndSettle();
      expect(find.byIcon(Phosphor.camera), findsNothing);
    });
  });
}
