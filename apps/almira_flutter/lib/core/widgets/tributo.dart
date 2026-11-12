import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../shared/models/modelos.dart';

/// Cómo se ve cada tributo en toda la app: nombre, ícono y color propios.
///
/// El impuesto predial es un impuesto sobre el predio; los arbitrios son tasas por servicios
/// públicos (limpieza, parques, serenazgo). Por eso se nombran y se ven distintos.
extension EstiloTributo on TipoDeuda {
  String get nombre => switch (this) {
        TipoDeuda.predial => 'Impuesto predial',
        TipoDeuda.arbitrios => 'Arbitrios municipales',
        TipoDeuda.multa => 'Multas',
        TipoDeuda.coactivo => 'Cobranza coactiva',
        TipoDeuda.otros => 'Otros',
      };

  /// Nombre corto para filtros.
  String get nombreCorto => switch (this) {
        TipoDeuda.predial => 'Impuesto predial',
        TipoDeuda.arbitrios => 'Arbitrios',
        TipoDeuda.multa => 'Multas',
        TipoDeuda.coactivo => 'Coactivo',
        TipoDeuda.otros => 'Otros',
      };

  IconData get icono => switch (this) {
        TipoDeuda.predial => Icons.home_work_outlined,
        TipoDeuda.arbitrios => Icons.cleaning_services_outlined,
        TipoDeuda.multa => Icons.gavel_rounded,
        TipoDeuda.coactivo => Icons.balance_rounded,
        TipoDeuda.otros => Icons.receipt_long_outlined,
      };

  Color get color => switch (this) {
        TipoDeuda.predial => AppColors.tributoPredial,
        TipoDeuda.arbitrios => AppColors.tributoArbitrios,
        TipoDeuda.multa => AppColors.tributoMulta,
        TipoDeuda.coactivo => AppColors.tributoCoactivo,
        TipoDeuda.otros => AppColors.tributoOtros,
      };

  /// Los impuestos y las tasas se agrupan por separado en el estado de cuenta.
  bool get esTasa => this == TipoDeuda.arbitrios;
}

/// Ícono del tributo en un círculo tintado (color al 12 %).
class IconoTributo extends StatelessWidget {
  const IconoTributo(this.tipo, {super.key, this.lado = 32});

  final TipoDeuda tipo;
  final double lado;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Container(
          width: lado,
          height: lado,
          decoration: BoxDecoration(
            color: tipo.color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(tipo.icono, size: lado * 0.55, color: tipo.color),
        ),
      );
}
