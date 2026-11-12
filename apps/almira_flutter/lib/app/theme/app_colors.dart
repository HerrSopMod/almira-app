import 'package:flutter/material.dart';

/// Colores de Almira. Parten de los tokens turquesa del repo
/// (`packages/shared/src/tokens.ts`) y de la propuesta del rediseño.
/// Contrastes sobre blanco comprobados (WCAG AA): primary 4.9:1,
/// textPrimary 15:1, textSecondary 5.6:1, success 5.4:1, warning 5.9:1, error 6.2:1.
abstract final class AppColors {
  static const primary = Color(0xFF0B7F86);
  static const primaryDark = Color(0xFF00646A);
  static const primarySoft = Color(0xFFE6F5F4);
  static const onPrimary = Color(0xFFFFFFFF);

  /// Acompañan al turquesa en degradados y detalles: una menta más clara y un coral cálido
  /// (el complementario del turquesa). El coral es decorativo: no se usa para texto pequeño.
  static const menta = Color(0xFF38B2A6);
  static const mentaSuave = Color(0xFFD7F0EC);
  static const coral = Color(0xFFF2785C);
  static const coralSuave = Color(0xFFFFEDE7);
  static const noche = Color(0xFF053F44);

  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSubtle = Color(0xFFF6FAFA);

  /// Fondo de los campos de texto: un gris verdoso apenas visible.
  static const campo = Color(0xFFF1F7F7);

  static const textPrimary = Color(0xFF0F2A2E);
  static const textSecondary = Color(0xFF5B6B70);
  static const border = Color(0xFFE2EAEA);
  static const track = Color(0xFFE6EFF0);

  /// Borde de un campo con el foco: un turquesa suave, sin cambiar el relleno.
  static const foco = menta;

  /// Borde de controles que deben distinguirse a primera vista (chips, selector): contraste
  /// 3,4:1 sobre blanco.
  static const bordeControl = Color(0xFF7F8E92);

  /// Colores de acento de los accesos rápidos del inicio. Solo van en el ícono y su círculo
  /// (al 12 %). Contraste del ícono sobre su círculo: 3:1 o más.
  static const accesoPagar = Color(0xFF15803D);
  static const accesoEstado = Color(0xFF2563EB);
  static const accesoCuponera = Color(0xFF7C3AED);
  static const accesoHistorial = Color(0xFFB45309);

  /// Un color por tributo, distinto de los de los accesos rápidos. Impuesto predial: magenta;
  /// arbitrios (tasas por servicios): cian; multas: ladrillo; cobranza coactiva: pizarra.
  static const tributoPredial = Color(0xFFBE185D);
  static const tributoArbitrios = Color(0xFF0E7490);
  static const tributoMulta = Color(0xFF9A3412);
  static const tributoCoactivo = Color(0xFF475569);
  static const tributoOtros = Color(0xFF6B7280);

  static const success = Color(0xFF1F7A50);
  static const successSoft = Color(0xFFEAF6F0);
  static const warning = Color(0xFF8A5E00);
  static const warningSoft = Color(0xFFFBF5E6);
  static const error = Color(0xFFB42F2F);
  static const errorSoft = Color(0xFFFAEAEA);
}
