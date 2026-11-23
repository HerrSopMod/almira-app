import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/componentes.dart';

/// Ícono grande de la carga y de la entrada al ingreso. Es la misma imagen del splash (PNG), no el
/// SVG: una imagen precargada se dibuja desde el primer cuadro, mientras que el SVG queda en blanco
/// un instante cada vez que aparece una pantalla nueva, y eso se veía como un parpadeo.
/// La imagen tiene margen alrededor: a 8/7 de [lado] el dibujo mide lo mismo que [LogoAlmira].
class IconoCarga extends StatelessWidget {
  const IconoCarga({super.key, required this.lado});

  final double lado;

  static const imagen = AssetImage('assets/marca/splash.png');

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: lado,
    child: OverflowBox(
      maxWidth: lado * 8 / 7,
      maxHeight: lado * 8 / 7,
      child: Image(image: imagen, width: lado * 8 / 7, height: lado * 8 / 7, gaplessPlayback: true),
    ),
  );
}

/// Deja el [IconoCarga] decodificado en la caché antes de mostrar la primera pantalla.
Future<void> precargarIconoCarga() {
  final listo = Completer<void>();
  final flujo = IconoCarga.imagen.resolve(ImageConfiguration.empty);
  late final ImageStreamListener oyente;
  oyente = ImageStreamListener(
    (_, _) {
      if (!listo.isCompleted) listo.complete();
      flujo.removeListener(oyente);
    },
    onError: (_, _) {
      if (!listo.isCompleted) listo.complete();
      flujo.removeListener(oyente);
    },
  );
  flujo.addListener(oyente);
  return listo.future;
}

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
                  const IconoCarga(lado: AppSpacing.logoCarga),
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
