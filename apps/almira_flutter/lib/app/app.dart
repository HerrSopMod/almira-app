import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/services/proveedores.dart';
import 'router.dart';
import 'theme/app_theme.dart';

/// Tope del tamaño de letra: por encima, la barra inferior y los botones
/// dejarían de caber en teléfonos pequeños.
const _escalaMaxima = 1.6;
const _aumentoTextoGrande = 1.15;

class AlmiraApp extends ConsumerWidget {
  const AlmiraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textoGrande = ref.watch(textoGrandeProvider);
    return MaterialApp.router(
      title: 'Almira',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.claro,
      routerConfig: ref.watch(routerProvider),
      locale: const Locale('es', 'PE'),
      supportedLocales: const [Locale('es', 'PE'), Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) {
        // Respeta el tamaño de letra del sistema y suma «Texto más grande».
        final medios = MediaQuery.of(context);
        final escala = (medios.textScaler.scale(1) * (textoGrande ? _aumentoTextoGrande : 1))
            .clamp(0.85, _escalaMaxima)
            .toDouble();
        return MediaQuery(
          data: medios.copyWith(textScaler: TextScaler.linear(escala)),
          child: child!,
        );
      },
    );
  }
}
