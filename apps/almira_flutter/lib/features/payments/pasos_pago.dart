import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/iconos.dart';

/// Indicador de los tres pasos del pago: Deuda, Medio de pago y Comprobante.
class PasosPago extends StatelessWidget {
  const PasosPago({super.key, required this.actual});

  /// 0, 1 o 2.
  final int actual;

  @override
  Widget build(BuildContext context) =>
      IndicadorPasos(titulos: const ['Deuda', 'Medio de pago', 'Comprobante'], actual: actual);
}

/// A partir de esta escala de letra los nombres no entran en tres columnas sin partirse: se
/// muestra solo el paso en curso.
const _escalaCompacta = 1.2;

/// Indicador de pasos: círculos numerados unidos por una línea, con el nombre de cada paso
/// debajo en columnas del mismo ancho. Con letra muy grande se reduce a una línea.
class IndicadorPasos extends StatelessWidget {
  const IndicadorPasos({super.key, required this.titulos, required this.actual});

  final List<String> titulos;

  /// Paso en curso, desde 0.
  final int actual;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final compacto = MediaQuery.textScalerOf(context).scale(1) > _escalaCompacta;
    final etiqueta = 'Paso ${actual + 1} de ${titulos.length}: ${titulos[actual]}';

    if (compacto) {
      return Semantics(
        label: etiqueta,
        child: ExcludeSemantics(
          child: Row(
            children: [
              _Circulo(numero: actual + 1, estado: _EstadoPaso.actual),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Paso ${actual + 1} de ${titulos.length} · ${titulos[actual]}',
                  style: textos.titleSmall,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Semantics(
      label: etiqueta,
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < titulos.length; i++)
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: i == 0
                              ? const SizedBox.shrink()
                              : _Linea(hecha: i <= actual),
                        ),
                        _Circulo(
                          numero: i + 1,
                          estado: i < actual
                              ? _EstadoPaso.hecho
                              : i == actual
                                  ? _EstadoPaso.actual
                                  : _EstadoPaso.pendiente,
                        ),
                        Expanded(
                          child: i == titulos.length - 1
                              ? const SizedBox.shrink()
                              : _Linea(hecha: i < actual),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                      child: Text(
                        titulos[i],
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textos.labelMedium!.copyWith(
                          color: i <= actual ? AppColors.textPrimary : AppColors.textSecondary,
                          fontWeight: i == actual ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum _EstadoPaso { hecho, actual, pendiente }

class _Circulo extends StatelessWidget {
  const _Circulo({required this.numero, required this.estado});

  final int numero;
  final _EstadoPaso estado;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: estado == _EstadoPaso.pendiente ? AppColors.surface : AppColors.primary,
        border: Border.all(
          color: estado == _EstadoPaso.pendiente ? AppColors.border : AppColors.primary,
          width: 1.5,
        ),
      ),
      child: estado == _EstadoPaso.hecho
          ? const Icon(Phosphor.check, size: AppIconos.insignia, color: Colors.white)
          : Text(
              '$numero',
              style: textos.labelMedium!.copyWith(
                color: estado == _EstadoPaso.actual ? Colors.white : AppColors.textSecondary,
              ),
            ),
    );
  }
}

class _Linea extends StatelessWidget {
  const _Linea({required this.hecha});

  final bool hecha;

  @override
  Widget build(BuildContext context) =>
      Container(height: 2, color: hecha ? AppColors.primary : AppColors.border);
}
