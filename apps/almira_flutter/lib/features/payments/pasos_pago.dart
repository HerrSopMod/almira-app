import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

/// Indicador de los tres pasos del pago: Deuda, Medio de pago y Comprobante.
class PasosPago extends StatelessWidget {
  const PasosPago({super.key, required this.actual});

  /// 0, 1 o 2.
  final int actual;

  @override
  Widget build(BuildContext context) =>
      IndicadorPasos(titulos: const ['Deuda', 'Medio de pago', 'Comprobante'], actual: actual);
}

/// Indicador de pasos con círculos numerados, línea de avance y el nombre de cada paso.
class IndicadorPasos extends StatelessWidget {
  const IndicadorPasos({super.key, required this.titulos, required this.actual});

  final List<String> titulos;

  /// Paso en curso, desde 0.
  final int actual;

  List<String> get _titulos => titulos;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Semantics(
      label: 'Paso ${actual + 1} de ${_titulos.length}: ${_titulos[actual]}',
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
