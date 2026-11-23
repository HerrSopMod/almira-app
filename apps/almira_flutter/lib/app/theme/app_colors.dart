import 'package:flutter/material.dart';

/// Colores de Almira (rediseño de noviembre de 2026, `Diseno/tokens/tokens.css`).
///
/// Turquesa como color principal, coral como acento (Nuevo reclamo, etapa en curso), sol para
/// avisos y resaltes, lima para «al día» y «concluido», y rojo para lo vencido. Fondo crema y
/// tarjetas blancas. Los nombres antiguos se conservan para no romper las pantallas: cambian los
/// valores, no el sentido.
///
/// Contraste (WCAG AA): el texto sobre coral va en tinta, nunca en blanco; tampoco va texto
/// blanco sobre [primary500].
abstract final class AppColors {
  // Marca
  static const primary = Color(0xFF0A6E72);

  /// Turquesa 500: gráficos y apoyo. Sin texto blanco encima.
  static const primary500 = Color(0xFF14A39A);
  static const primary100 = Color(0xFFDDF1EE);
  static const primary50 = Color(0xFFEEF8F6);

  /// Botón presionado y título del bloque Destacado.
  static const primaryDark = Color(0xFF08585C);

  /// Botón primario deshabilitado (texto blanco).
  static const primaryDisabled = Color(0xFFA7CFCF);

  /// Fondo turquesa claro (bloque Destacado, chips activos, cajas de ícono turquesa).
  static const primarySoft = primary100;

  /// Lo que va sobre el encabezado turquesa (texto, íconos, logo).
  static const onPrimary = Color(0xFFFFFFFF);

  /// Texto secundario sobre el encabezado.
  static const subtextoCabecera = Color(0xFFCDEFEA);

  // Acento y tonos de apoyo
  static const coral = Color(0xFFFF7A59);
  static const coral100 = Color(0xFFFFE4DC);
  static const coralTexto = Color(0xFFB83F22);
  static const sol = Color(0xFFFFC94A);
  static const sol100 = Color(0xFFFFF1CC);
  static const solTexto = Color(0xFF7A4E00);
  static const lima = Color(0xFFB8E07A);
  static const lima100 = Color(0xFFEAF6D6);
  static const limaTexto = Color(0xFF3D6A12);

  /// Encabezado: degradado turquesa de 155°.
  static const degradadoCabecera = LinearGradient(
    begin: Alignment(-0.6, -1),
    end: Alignment(0.6, 1),
    colors: [Color(0xFF0E8A86), primary, primaryDark],
    stops: [0, 0.55, 1],
  );

  /// Botón central del Asistente.
  static const degradadoAsistente = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary500, primary],
  );

  /// Sombra de tarjetas (dos capas muy suaves en tinta).
  static const sombraTarjeta = Color(0x1212393A);
  static const sombraCard = [
    BoxShadow(color: Color(0x0F12393A), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x1212393A), blurRadius: 18, offset: Offset(0, 6)),
  ];

  /// Sombra del botón principal y del botón del Asistente.
  static const sombraPrimaria = [BoxShadow(color: Color(0x470A6E72), blurRadius: 18, offset: Offset(0, 8))];

  /// Sombra del botón coral.
  static const sombraCoral = [BoxShadow(color: Color(0x59FF7A59), blurRadius: 22, offset: Offset(0, 10))];

  // Neutros
  /// Fondo de las pantallas: crema.
  static const background = Color(0xFFF7F3EC);
  static const surface = Color(0xFFFFFFFF);

  /// Fondo suave (burbujas recibidas, riel de barras, esqueletos).
  static const surfaceSubtle = primary50;

  /// Fondo de los campos de texto: blanco, con borde.
  static const campo = surface;

  static const textPrimary = Color(0xFF12393A);
  static const textSecondary = Color(0xFF5A7472);

  /// Divisores y bordes suaves.
  static const border = Color(0xFFE6EEEC);

  /// Borde de los campos.
  static const bordeCampo = Color(0xFFD5E2E0);

  /// Riel de barras de avance.
  static const track = primary50;

  /// Borde de un campo con el foco.
  static const foco = primary;

  /// Borde de controles que deben distinguirse a primera vista (casillas, radios).
  static const bordeControl = Color(0xFF8FA5A3);

  /// Acentos de los íconos con color. El ícono va en tinta y el color se usa para su fondo
  /// pastel (ver [fondoPastel]); no pinta tarjetas enteras.
  static const acentoVerde = lima;
  static const acentoAzul = primary500;
  static const acentoVioleta = primary500;
  static const acentoAmbar = sol;
  static const acentoRosa = coral;

  /// Fondo pastel de un [acento]: turquesa, sol, coral o lima al 100.
  static Color fondoPastel(Color acento) => switch (acento) {
    lima || limaTexto || success => lima100,
    sol || solTexto || warning => sol100,
    coral || coralTexto => coral100,
    error => errorSoft,
    _ => primary100,
  };

  /// Colores de Mastercard, dibujada en `marcas_pago.dart`. Solo se usan ahí.
  static const marcaMastercardRojo = Color(0xFFEB001B);
  static const marcaMastercardNaranja = Color(0xFFF79E1B);

  static const success = limaTexto;
  static const successSoft = lima100;
  static const warning = solTexto;
  static const warningSoft = sol100;
  static const error = Color(0xFFB42318);
  static const errorSoft = Color(0xFFFDE2E0);

  /// Opacidad del color de estado en el fondo de una insignia, cuando no hay pastel propio.
  static const double alfaFondoInsignia = 0.12;
}
