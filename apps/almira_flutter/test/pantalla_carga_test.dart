// La pantalla de carga sigue al splash nativo: fondo turquesa completo, el logo blanco con
// «Almira» al centro y las barras del sistema en el mismo color, sin desbordes con letra grande.
import 'package:almira_flutter/app/theme/app_colors.dart';
import 'package:almira_flutter/app/theme/app_spacing.dart';
import 'package:almira_flutter/app/theme/app_theme.dart';
import 'package:almira_flutter/core/widgets/componentes.dart';
import 'package:almira_flutter/features/carga/pantalla_carga.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final escala in [1.0, 1.3, 2.0]) {
    testWidgets('turquesa, logo blanco y nombre al centro (texto ×$escala)', (tester) async {
      tester.view.physicalSize = const Size(720, 1280);
      tester.view.devicePixelRatio = 2;
      tester.platformDispatcher.textScaleFactorTestValue = escala;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      await tester.pumpWidget(const PantallaCarga());
      expect(tester.takeException(), isNull);
      expect(tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor, AppColors.primary);
      expect(tester.widget<LogoAlmira>(find.byType(LogoAlmira)).blanco, isTrue);
      expect(find.text('Almira'), findsOneWidget);
      // El ícono queda al centro de la pantalla, donde estaba el del splash nativo.
      expect(tester.getCenter(find.byType(LogoAlmira)), const Offset(180, 320));
      expect(tester.getSize(find.byType(LogoAlmira)), const Size.square(AppSpacing.logoCarga));
      // El nombre va debajo del ícono, también centrado.
      expect(tester.getCenter(find.text('Almira')).dx, 180);
      expect(tester.getTopLeft(find.text('Almira')).dy, greaterThan(320 + AppSpacing.logoCarga / 2));
      final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.byWidgetPredicate((w) => w is AnnotatedRegion<SystemUiOverlayStyle>).first,
      );
      expect(region.value, barraCarga);
    });
  }
}
