import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Cifras tabulares para montos y fechas alineadas.
const cifrasTabulares = [FontFeature.tabularFigures()];

/// Barra del sistema: la cabecera turquesa empieza detrás de la barra de estado, así que sus
/// íconos van claros. La barra de navegación del sistema sigue sobre blanco, con íconos oscuros.
const barraSobreTurquesa = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
  systemNavigationBarColor: Colors.transparent,
  systemNavigationBarIconBrightness: Brightness.dark,
  systemNavigationBarContrastEnforced: false,
);

/// Barra del sistema sobre fondo blanco (íconos oscuros). Se mantiene por compatibilidad para
/// pantallas sin cabecera turquesa; las pantallas nuevas usan [barraSobreTurquesa].
const barraSobreBlanco = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
  systemNavigationBarColor: Colors.transparent,
  systemNavigationBarIconBrightness: Brightness.dark,
  systemNavigationBarContrastEnforced: false,
);

/// Barras del sistema durante la carga: todo turquesa, sin franja blanca.
const barraCarga = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
  systemNavigationBarColor: AppColors.primary,
  systemNavigationBarIconBrightness: Brightness.light,
  systemNavigationBarContrastEnforced: false,
);

/// Rótulo de un grupo o de una ficha («Cuenta y predio», «Fecha límite»): 13 en gris, en tipo
/// oración. Sin mayúsculas sostenidas.
TextStyle estiloRotulo(BuildContext context) =>
    Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w500);

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
      fontFamily: 'PlusJakartaSans',
      color: AppColors.textPrimary,
      letterSpacing: 0,
    );
    // Escala corta: monto principal 32, título 20, cuerpo 15 y secundario 13. Dentro de una
    // tarjeta se usan como máximo dos tamaños.
    final textos = TextTheme(
      // Monto principal de una pantalla (cabecera, detalle, comprobante): 32.
      displayMedium: base.copyWith(
        fontSize: 32,
        height: 38 / 32,
        letterSpacing: -0.64,
        fontWeight: FontWeight.w700,
        fontFeatures: cifrasTabulares,
      ),
      // Monto destacado dentro de una tarjeta: 32, igual que el principal.
      displaySmall: base.copyWith(
        fontSize: 32,
        height: 38 / 32,
        letterSpacing: -0.64,
        fontWeight: FontWeight.w700,
        fontFeatures: cifrasTabulares,
      ),
      // Nombre de la app en el ingreso: 28.
      headlineMedium: base.copyWith(
        fontSize: 28,
        height: 34 / 28,
        letterSpacing: -0.56,
        fontWeight: FontWeight.w700,
      ),
      // Saludo de la cabecera: 24.
      headlineSmall: base.copyWith(
        fontSize: 24,
        height: 30 / 24,
        letterSpacing: -0.24,
        fontWeight: FontWeight.w700,
      ),
      // Título de pantalla, de la barra superior y de sección: 20.
      titleLarge: base.copyWith(fontSize: 20, height: 26 / 20, fontWeight: FontWeight.w600),
      // Nombre en una fila o tarjeta: 15 en peso medio.
      titleMedium: base.copyWith(fontSize: 15, height: 22 / 15, fontWeight: FontWeight.w500),
      // Rótulos cortos con peso (pestañas, etiquetas de acceso): 13.
      titleSmall: base.copyWith(fontSize: 13, height: 18 / 13, fontWeight: FontWeight.w600),
      // Cuerpo: texto de trámite, valores de ficha y lo que se escribe en un campo: 15.
      bodyLarge: base.copyWith(fontSize: 15, height: 22 / 15, fontWeight: FontWeight.w400),
      // Secundario: rótulos, fechas y descripciones: 13, en gris.
      bodyMedium: base.copyWith(
        fontSize: 13,
        height: 18 / 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ),
      // Pies y ayudas: 12, en gris.
      bodySmall: base.copyWith(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ),
      // Botones: 16.
      labelLarge: base.copyWith(fontSize: 16, height: 20 / 16, fontWeight: FontWeight.w600),
      // Insignias y rótulos: 12.
      labelMedium: base.copyWith(
        fontSize: 12,
        height: 16 / 12,
        letterSpacing: 0.24,
        fontWeight: FontWeight.w600,
      ),
      // Etiquetas de la barra inferior: 11.
      labelSmall: base.copyWith(fontSize: 11, height: 14 / 11, fontWeight: FontWeight.w500),
    );

    final formaBoton = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.boton),
    );
    const altoBoton = Size.fromHeight(AppSpacing.boton);

    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      fontFamily: 'PlusJakartaSans',
      textTheme: textos,
      scaffoldBackgroundColor: AppColors.background,
      splashFactory: InkSparkle.splashFactory,
      iconTheme: const IconThemeData(color: AppColors.textPrimary, size: AppIconos.navegacion),
      // Barra superior de las pantallas de detalle: turquesa compacta, flecha y título en
      // blanco, sin línea. Las pestañas raíz usan [CabeceraMarca] en vez de esta barra.
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        toolbarHeight: AppSpacing.barraSuperior,
        systemOverlayStyle: barraSobreTurquesa,
        titleTextStyle: textos.titleLarge!.copyWith(color: AppColors.onPrimary),
        iconTheme: const IconThemeData(color: AppColors.onPrimary, size: AppIconos.navegacion),
        actionsIconTheme: const IconThemeData(color: AppColors.onPrimary, size: AppIconos.navegacion),
      ),
      // Pestañas con subrayado, para pantallas con dos vistas (Estado de cuenta / Historial).
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: AppColors.border,
        labelStyle: textos.titleMedium!.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: textos.titleMedium,
        splashFactory: NoSplash.splashFactory,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: altoBoton,
          shape: formaBoton,
          textStyle: textos.labelLarge,
          disabledBackgroundColor: AppColors.primaryDisabled,
          disabledForegroundColor: Colors.white,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: altoBoton,
          shape: formaBoton,
          textStyle: textos.labelLarge,
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(AppSpacing.toque, AppSpacing.toque),
          shape: formaBoton,
          textStyle: textos.labelLarge!.copyWith(fontWeight: FontWeight.w500),
          foregroundColor: AppColors.primary,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(AppSpacing.toque, AppSpacing.toque),
          foregroundColor: AppColors.textPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.campo,
        // Con texto de 16 y 24 de interlineado, el campo mide 52.
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
        prefixIconColor: WidgetStateColor.resolveWith(
          (e) => e.contains(WidgetState.focused) ? AppColors.primary : AppColors.textSecondary,
        ),
        suffixIconColor: AppColors.textSecondary,
        labelStyle: textos.bodyLarge!.copyWith(color: AppColors.textSecondary),
        floatingLabelStyle: textos.titleSmall!.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        hintStyle: textos.bodyLarge!.copyWith(color: AppColors.textSecondary),
        helperStyle: textos.bodySmall,
        errorStyle: textos.bodySmall!.copyWith(color: AppColors.error),
        errorMaxLines: 3,
        helperMaxLines: 3,
        border: _borde(AppColors.border),
        enabledBorder: _borde(AppColors.border),
        disabledBorder: _borde(AppColors.border),
        // La etiqueta ya está arriba desde el inicio: al enfocar no se mueve. El foco solo
        // engrosa el borde en turquesa.
        floatingLabelBehavior: FloatingLabelBehavior.always,
        focusedBorder: _borde(AppColors.foco, 1.5),
        errorBorder: _borde(AppColors.error, 1.5),
        focusedErrorBorder: _borde(AppColors.error, 1.5),
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
      // Barra inferior: sin píldora. La pestaña activa va en turquesa con el ícono relleno.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: AppSpacing.barraInferior,
        indicatorColor: Colors.transparent,
        indicatorShape: const RoundedRectangleBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (estados) => textos.labelSmall!.copyWith(
            fontWeight: estados.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
            color: estados.contains(WidgetState.selected) ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (estados) => IconThemeData(
            size: AppIconos.navegacion,
            color: estados.contains(WidgetState.selected) ? AppColors.primary : AppColors.textSecondary,
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
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.insignia)),
        side: const BorderSide(color: AppColors.bordeControl, width: 1.5),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (e) => e.contains(WidgetState.selected) ? AppColors.primary : AppColors.bordeControl,
        ),
      ),
      // Selector segmentado: la opción activa va rellena en turquesa con texto blanco; la
      // inactiva, en blanco con borde. Se distingue a primera vista.
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(0, AppSpacing.toque)),
          textStyle: WidgetStatePropertyAll(textos.titleSmall),
          backgroundColor: WidgetStateProperty.resolveWith(
            (e) => e.contains(WidgetState.selected) ? AppColors.primary : AppColors.surface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (e) => e.contains(WidgetState.selected) ? Colors.white : AppColors.textPrimary,
          ),
          side: const WidgetStatePropertyAll(BorderSide(color: AppColors.bordeControl)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.boton)),
          ),
        ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.campo)),
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
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.dialogo)),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.primary,
        titleTextStyle: textos.bodyLarge!.copyWith(fontWeight: FontWeight.w500),
        subtitleTextStyle: textos.bodyMedium,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        minVerticalPadding: 12,
        minTileHeight: AppSpacing.cajaGrande,
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
