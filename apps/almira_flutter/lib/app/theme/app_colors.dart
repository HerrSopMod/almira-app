import 'package:flutter/material.dart';

/// Colores de Almira, según `docs/design/turquesa/LEEME.md`: turquesa, texto oscuro, grises y
/// tres colores de estado. Nada más.
/// Contrastes sobre blanco comprobados (WCAG AA): primary 4.9:1, textPrimary 15:1,
/// textSecondary 5.6:1, success 5.4:1, warning 5.9:1, error 6.2:1.
abstract final class AppColors {
  static const primary = Color(0xFF0B7F86);

  /// Botón presionado y título del bloque Destacado.
  static const primaryDark = Color(0xFF00646A);

  /// Botón primario deshabilitado (texto blanco).
  static const primaryDisabled = Color(0xFFA9D2D4);

  /// Fondo del bloque Destacado y de los círculos de los accesos rápidos: máximo un Destacado
  /// por pantalla.
  static const primarySoft = Color(0xFFE3F6F5);

  /// Todo lo que va sobre la cabecera turquesa (texto, íconos, logo): blanco, 5,1:1 (AA).
  static const onPrimary = Color(0xFFFFFFFF);

  /// Sombra de la tarjeta que flota sobre la unión entre la cabecera y la hoja blanca: la única
  /// sombra de la app, muy suave (texto al 8 %).
  static const sombraTarjeta = Color(0x140F2A2E);

  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFFFFFF);

  /// Fondo de cajas de ícono, burbujas recibidas y campos.
  static const surfaceSubtle = Color(0xFFF2F8F8);

  /// Fondo de los campos de texto.
  static const campo = surfaceSubtle;

  static const textPrimary = Color(0xFF0F2A2E);
  static const textSecondary = Color(0xFF5B6B70);

  /// Bordes de 1 px y divisores.
  static const border = Color(0xFFD6E3E4);

  /// Riel de barras de avance.
  static const track = Color(0xFFE6EFF0);

  /// Borde de un campo con el foco: 1.5 px turquesa.
  static const foco = primary;

  /// Borde de controles que deben distinguirse a primera vista (chips, selector): contraste
  /// 3,4:1 sobre blanco.
  static const bordeControl = Color(0xFF7F8E92);

  /// Colores de acento para los íconos con color (accesos de Inicio, filas del perfil): solo van
  /// en el ícono y en su círculo al 12 %, nunca en toda una tarjeta. Contraste del ícono sobre su
  /// círculo: 4,2:1 o más.
  static const acentoVerde = Color(0xFF15803D);
  static const acentoAzul = Color(0xFF2563EB);
  static const acentoVioleta = Color(0xFF7C3AED);
  static const acentoAmbar = Color(0xFFB45309);
  static const acentoRosa = Color(0xFFBE185D);

  /// Colores de las marcas de pago de `marcas_pago.dart` (Yape, Visa, Mastercard). Solo se usan ahí.
  static const marcaYape = Color(0xFF742284);
  static const marcaVisa = Color(0xFF1A1F71);
  static const marcaMastercardRojo = Color(0xFFEB001B);
  static const marcaMastercardNaranja = Color(0xFFF79E1B);

  static const success = Color(0xFF1F7A50);
  static const successSoft = Color(0xFFEAF6F0);
  static const warning = Color(0xFF8A5E00);
  static const warningSoft = Color(0xFFFBF5E6);
  static const error = Color(0xFFB42F2F);
  static const errorSoft = Color(0xFFFAEAEA);

  /// Opacidad del color de estado en el fondo de una insignia (12 %).
  static const double alfaFondoInsignia = 0.12;
}
