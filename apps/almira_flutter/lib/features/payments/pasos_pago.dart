import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

/// Indicador de los tres pasos del pago: Deuda, Medio de pago y Comprobante.
class PasosPago extends StatelessWidget {
  const PasosPago({super.key, required this.actual});

  /// 0, 1 o 2.
  final int actual;

  static const _titulos = ['Deuda', 'Medio de pago', 'Comprobante'];

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Semantics(
      label: 'Paso ${actual + 1} de 3: ${_titulos[actual]}',
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < _titulos.length; i++) ...[
              if (i > 0)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 13),
                    child: Container(
                      height: 2,
                      color: i <= actual ? AppColors.primary : AppColors.border,
                    ),
                  ),
                ),
              Column(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: i <= actual ? AppColors.primary : AppColors.track,
                    child: i < actual
                        ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                        : Text(
                            '${i + 1}',
                            style: textos.labelMedium!.copyWith(
                              color: i == actual ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _titulos[i],
                    style: textos.labelSmall!.copyWith(
                      color: i <= actual ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
