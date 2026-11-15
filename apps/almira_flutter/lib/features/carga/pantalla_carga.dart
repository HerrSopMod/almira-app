import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/componentes.dart';

/// Pantalla de carga: turquesa completo con el logo blanco y «Almira» al centro, mientras se
/// inicia el servicio y se recupera la sesión. Sigue al splash nativo con el mismo fondo y el
/// ícono en el mismo lugar y tamaño, así no hay parpadeo blanco. Las barras del sistema van en
/// el mismo turquesa.
///
/// Es una app aparte, mínima: se muestra con `runApp` antes de que exista la app real.
class PantallaCarga extends StatelessWidget {
  const PantallaCarga({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Almira',
    theme: AppTheme.claro,
    home: const _ContenidoCarga(),
  );
}

class _ContenidoCarga extends StatelessWidget {
  const _ContenidoCarga();

  @override
  Widget build(BuildContext context) {
    final nombre = Theme.of(context).textTheme.headlineMedium!.copyWith(color: AppColors.onPrimary);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: barraCarga,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Semantics(
          label: 'Almira. Cargando',
          child: ExcludeSemantics(
            // Dos espacios iguales arriba y abajo: el ícono queda justo al centro, como en el
            // splash nativo, y el nombre va debajo sin importar el tamaño de la letra.
            child: SizedBox.expand(
              child: Column(
                children: [
                  const Spacer(),
                  const LogoAlmira(lado: AppSpacing.logoCarga, blanco: true),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.lg),
                        child: Text('Almira', style: nombre),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
