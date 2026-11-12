import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

/// Chip de filtro. Activo: relleno turquesa, texto blanco y un check pequeño. Inactivo: blanco,
/// borde gris visible (3:1) y texto oscuro. Mínimo 44 de alto para tocarlo bien.
class ChipFiltro extends StatelessWidget {
  const ChipFiltro({
    super.key,
    required this.texto,
    required this.activo,
    required this.alTocar,
    this.icono,
  });

  final String texto;
  final bool activo;
  final VoidCallback alTocar;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme.labelLarge!.copyWith(
          fontSize: 14,
          color: activo ? Colors.white : AppColors.textPrimary,
        );
    return Semantics(
      button: true,
      selected: activo,
      label: texto,
      excludeSemantics: true,
      child: Material(
        color: activo ? AppColors.primary : AppColors.surface,
        shape: StadiumBorder(
          side: BorderSide(color: activo ? AppColors.primary : AppColors.bordeControl),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: alTocar,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (activo) ...[
                    const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                  ] else if (icono != null) ...[
                    Icon(icono, size: 16, color: AppColors.textPrimary),
                    const SizedBox(width: 6),
                  ],
                  Text(texto, style: estilo, maxLines: 1),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Grupo de filtros: un título pequeño y los chips en una sola fila con scroll horizontal.
class GrupoFiltros extends StatelessWidget {
  const GrupoFiltros({super.key, this.titulo, required this.chips});

  final String? titulo;
  final List<Widget> chips;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (titulo != null)
            Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.xs),
            child: Semantics(
              header: true,
              child: Text(titulo!, style: Theme.of(context).textTheme.labelMedium),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: chips.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (_, i) => chips[i],
            ),
          ),
        ],
      );
}
