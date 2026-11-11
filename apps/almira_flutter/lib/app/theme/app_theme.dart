
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Cifras tabulares para montos y fechas alineadas.
const cifrasTabulares = [FontFeature.tabularFigures()];

/// Barra del sistema sobre un encabezado turquesa: íconos claros.
const barraSobreTurquesa = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
  systemNavigationBarColor: Colors.transparent,
  systemNavigationBarIconBrightness: Brightness.dark,
  systemNavigationBarContrastEnforced: false,
);

/// Barra del sistema sobre fondo blanco (ingreso, bienvenida): íconos oscuros.
const barraSobreBlanco = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
  systemNavigationBarColor: Colors.transparent,
  systemNavigationBarIconBrightness: Brightness.dark,
  systemNavigationBarContrastEnforced: false,
);

abstract final class AppTheme {
  static ThemeData get claro {
    const esquema = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primarySoft,
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.primaryDark,
      onSecondary: AppColors.onPrimary,
      secondaryContainer: AppColors.primarySoft,
      onSecondaryContainer: AppColors.primaryDark,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.errorSoft,
      onErrorContainer: AppColors.error,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
      surfaceContainerLowest: AppColors.surface,
      surfaceContainerLow: AppColors.surfaceSubtle,
      surfaceContainer: AppColors.surfaceSubtle,
      surfaceContainerHigh: AppColors.surfaceSubtle,
      surfaceContainerHighest: AppColors.track,
      surfaceTint: Colors.transparent,
    );

    const base = TextStyle(
      fontFamily: 'Inter',
      color: AppColors.textPrimary,
      letterSpacing: 0,
    );
    final textos = TextTheme(
      // Monto destacado.
      displaySmall: base.copyWith(
        fontSize: 34,
        height: 1.15,
        fontWeight: FontWeight.w700,
        fontFeatures: cifrasTabulares,
      ),
      headlineSmall: base.copyWith(fontSize: 22, height: 1.25, fontWeight: FontWeight.w700),
      titleLarge: base.copyWith(fontSize: 19, height: 1.3, fontWeight: FontWeight.w600),
      titleMedium: base.copyWith(fontSize: 16, height: 1.35, fontWeight: FontWeight.w600),
      titleSmall: base.copyWith(fontSize: 14, height: 1.35, fontWeight: FontWeight.w600),
      bodyLarge: base.copyWith(fontSize: 16, height: 1.45, fontWeight: FontWeight.w400),
      bodyMedium: base.copyWith(
        fontSize: 14,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ),
      bodySmall: base.copyWith(
        fontSize: 13,
        height: 1.4,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ),
      labelLarge: base.copyWith(fontSize: 16, height: 1.25, fontWeight: FontWeight.w600),
      labelMedium: base.copyWith(fontSize: 13, height: 1.25, fontWeight: FontWeight.w600),
      labelSmall: base.copyWith(fontSize: 12, height: 1.25, fontWeight: FontWeight.w500),
    );

    final formaBoton = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.boton),
    );
    const altoBoton = Size.fromHeight(52);

    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      fontFamily: 'Inter',
      textTheme: textos,
      scaffoldBackgroundColor: AppColors.background,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: AppSpacing.margen,
        systemOverlayStyle: barraSobreTurquesa,
        titleTextStyle: textos.titleLarge!.copyWith(color: AppColors.onPrimary),
        iconTheme: const IconThemeData(color: AppColors.onPrimary),
        actionsIconTheme: const IconThemeData(color: AppColors.onPrimary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: altoBoton,
          shape: formaBoton,
          textStyle: textos.labelLarge,
          disabledBackgroundColor: AppColors.track,
          disabledForegroundColor: AppColors.textSecondary,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: altoBoton,
          shape: formaBoton,
          textStyle: textos.labelLarge,
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(AppSpacing.toque, AppSpacing.toque),
          shape: formaBoton,
          textStyle: textos.labelLarge,
          foregroundColor: AppColors.primary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: textos.bodyLarge!.copyWith(color: AppColors.textSecondary),
        floatingLabelStyle: textos.bodyLarge!.copyWith(color: AppColors.primary),
        hintStyle: textos.bodyLarge!.copyWith(color: AppColors.textSecondary),
        helperStyle: textos.bodySmall,
        errorStyle: textos.bodySmall!.copyWith(color: AppColors.error),
        errorMaxLines: 3,
        helperMaxLines: 3,
        border: _borde(AppColors.border),
        enabledBorder: _borde(AppColors.border),
        focusedBorder: _borde(AppColors.primary, 2),
        errorBorder: _borde(AppColors.error),
        focusedErrorBorder: _borde(AppColors.error, 2),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.tarjeta),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        indicatorColor: AppColors.primarySoft,
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (estados) => textos.labelSmall!.copyWith(
            fontWeight: estados.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: estados.contains(WidgetState.selected)
                ? AppColors.primaryDark
                : AppColors.textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (estados) => IconThemeData(
            size: 24,
            color: estados.contains(WidgetState.selected)
                ? AppColors.primaryDark
                : AppColors.textSecondary,
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (e) => e.contains(WidgetState.selected) ? Colors.white : AppColors.textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (e) => e.contains(WidgetState.selected) ? AppColors.primary : AppColors.track,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primarySoft,
        side: const BorderSide(color: AppColors.border),
        shape: const StadiumBorder(),
        labelStyle: textos.labelMedium,
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: textos.bodyMedium!.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.track,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.primary,
        titleTextStyle: textos.bodyLarge,
        subtitleTextStyle: textos.bodyMedium,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        minVerticalPadding: 12,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  static OutlineInputBorder _borde(Color color, [double ancho = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.campo),
        borderSide: BorderSide(color: color, width: ancho),
      );
}
