import 'package:flutter/material.dart';

import '../../app/theme/iconos.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../utils/formato.dart';
import '../utils/rango_fechas.dart';

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
                    const Icon(Phosphor.check, size: AppIconos.insignia, color: Colors.white),
                    const SizedBox(width: 6),
                  ] else if (icono != null) ...[
                    Icon(icono, size: AppIconos.insignia, color: AppColors.textPrimary),
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

/// Filtro por fecha, fácil de usar: periodos rápidos («Este mes», «3 meses», «Este año») y un
/// botón con el calendario para elegir un rango de días. Con un rango elegido, el botón muestra
/// las fechas. [hoy] viene del reloj de la app.
class GrupoFiltroFechas extends StatelessWidget {
  const GrupoFiltroFechas({
    super.key,
    required this.filtro,
    required this.hoy,
    required this.alCambiar,
    this.titulo = 'Fechas',
  });

  final FiltroFechas filtro;
  final DateTime hoy;
  final ValueChanged<FiltroFechas> alCambiar;
  final String titulo;

  Future<void> _elegirEnCalendario(BuildContext context) async {
    final dia = DateUtils.dateOnly(hoy);
    final rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(dia.year - 5),
      lastDate: DateTime(dia.year + 1, 12, 31),
      initialDateRange: filtro.elegido,
      currentDate: dia,
      locale: const Locale('es', 'PE'),
      helpText: 'Elige las fechas',
      saveText: 'Aplicar',
      cancelText: 'Cancelar',
      confirmText: 'Aplicar',
    );
    if (rango != null) alCambiar(filtro.conRango(rango));
  }

  @override
  Widget build(BuildContext context) {
    final elegido = filtro.periodo == PeriodoFecha.elegido ? filtro.elegido : null;
    final textoCalendario = elegido == null
        ? 'Elegir fechas'
        : '${fechaCorta(elegido.start)} – ${fechaCorta(elegido.end)}';
    return GrupoFiltros(
      titulo: titulo,
      chips: [
        ChipFiltro(
          texto: 'Todas',
          activo: filtro.periodo == PeriodoFecha.todas,
          alTocar: () => alCambiar(FiltroFechas.todas),
        ),
        ChipFiltro(
          texto: textoCalendario,
          icono: Phosphor.calendarBlank,
          activo: filtro.periodo == PeriodoFecha.elegido,
          alTocar: () => _elegirEnCalendario(context),
        ),
        ChipFiltro(
          texto: 'Este mes',
          activo: filtro.periodo == PeriodoFecha.esteMes,
          alTocar: () => alCambiar(filtro.conPeriodo(PeriodoFecha.esteMes)),
        ),
        ChipFiltro(
          texto: '3 meses',
          activo: filtro.periodo == PeriodoFecha.tresMeses,
          alTocar: () => alCambiar(filtro.conPeriodo(PeriodoFecha.tresMeses)),
        ),
        ChipFiltro(
          texto: 'Este año',
          activo: filtro.periodo == PeriodoFecha.esteAnio,
          alTocar: () => alCambiar(filtro.conPeriodo(PeriodoFecha.esteAnio)),
        ),
      ],
    );
  }
}
