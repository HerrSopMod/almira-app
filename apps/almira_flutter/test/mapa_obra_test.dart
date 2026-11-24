// Ubicación de la obra: la dirección exacta arriba del mapa, el mapa completo para moverse entre
// las calles y «Cómo llegar». Sin punto en el mapa, solo la dirección.
import 'package:almira_flutter/app/theme/app_theme.dart';
import 'package:almira_flutter/features/public_works/mapa_obra.dart';
import 'package:almira_flutter/shared/models/modelos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Obra _obra({double? latitud = -12.0503, double? longitud = -77.0298}) => Obra(
  id: 'o1',
  municipalidadId: 'm1',
  nombre: 'Recuperación del Antiguo Real Hospital de San Andrés',
  ubicacion: 'Jirón Huallaga 846',
  estado: EstadoObra.enEjecucion,
  avancePct: 7,
  meta: 'sep 2028',
  montoAsignado: 0,
  montoEjecutado: 0,
  publicada: true,
  latitud: latitud,
  longitud: longitud,
);

Future<void> _mostrar(WidgetTester tester, Obra obra) async {
  tester.view.physicalSize = const Size(393 * 3, 852 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.claro,
      home: Scaffold(
        body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: UbicacionObra(obra: obra)),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('muestra la dirección exacta, el aviso para ver las calles y «Cómo llegar»', (tester) async {
    await _mostrar(tester, _obra());
    expect(find.text('Jirón Huallaga 846'), findsOneWidget);
    expect(find.text('Toca para ver las calles'), findsOneWidget);
    expect(find.text('Cómo llegar'), findsOneWidget);
  });

  testWidgets('al tocar el mapa se abre el mapa completo, con zoom y la dirección', (tester) async {
    await _mostrar(tester, _obra());
    await tester.tap(find.bySemanticsLabel('Ver el mapa completo'));
    // La ruta nueva se arma en un cuadro y entra en los siguientes.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byType(MapaObraScreen), findsOneWidget);
    expect(find.text('Ubicación'), findsOneWidget);
    expect(find.byTooltip('Acercar'), findsOneWidget);
    expect(find.byTooltip('Alejar'), findsOneWidget);
    expect(find.byTooltip('Volver a la obra'), findsOneWidget);
    // La dirección sigue a la vista en el mapa completo.
    expect(find.descendant(of: find.byType(MapaObraScreen), matching: find.text('Jirón Huallaga 846')), findsOneWidget);

    // Acercar no rompe nada.
    await tester.tap(find.byTooltip('Acercar'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });

  testWidgets('sin coordenadas: solo la dirección, sin mapa ni «Cómo llegar»', (tester) async {
    await _mostrar(tester, _obra(latitud: null, longitud: null));
    expect(find.text('Jirón Huallaga 846'), findsOneWidget);
    expect(find.text('Sin punto en el mapa.'), findsOneWidget);
    expect(find.text('Cómo llegar'), findsNothing);
  });
}
