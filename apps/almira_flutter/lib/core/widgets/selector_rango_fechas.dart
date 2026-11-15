import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/iconos.dart';
import '../utils/formato.dart';

/// Abre el selector de rango en una hoja inferior y devuelve el rango elegido (o null si se cierra).
/// Un solo mes a la vez, con flechas: se ve completo sin desplazarse.
Future<DateTimeRange?> elegirRangoFechas(
  BuildContext context, {
  required DateTime hoy,
  required DateTime primera,
  required DateTime ultima,
  DateTimeRange? inicial,
}) => showModalBottomSheet<DateTimeRange>(
  context: context,
  useSafeArea: true,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => SelectorRangoFechas(hoy: hoy, primera: primera, ultima: ultima, inicial: inicial),
);

/// Calendario compacto de un mes para elegir desde qué día hasta qué día. Se toca el primer día y
/// luego el último; tocar otra vez empieza de nuevo. «Aplicar» devuelve el rango.
class SelectorRangoFechas extends StatefulWidget {
  const SelectorRangoFechas({
    super.key,
    required this.hoy,
    required this.primera,
    required this.ultima,
    this.inicial,
  });

  final DateTime hoy;
  final DateTime primera;
  final DateTime ultima;
  final DateTimeRange? inicial;

  @override
  State<SelectorRangoFechas> createState() => _SelectorRangoFechasState();
}

class _SelectorRangoFechasState extends State<SelectorRangoFechas> {
  late DateTime _mes;
  DateTime? _inicio;
  DateTime? _fin;

  DateTime get _hoy => DateUtils.dateOnly(widget.hoy);

  @override
  void initState() {
    super.initState();
    _inicio = widget.inicial == null ? null : DateUtils.dateOnly(widget.inicial!.start);
    _fin = widget.inicial == null ? null : DateUtils.dateOnly(widget.inicial!.end);
    final referencia = _inicio ?? _hoy;
    _mes = DateTime(referencia.year, referencia.month);
  }

  bool _dentro(DateTime dia) => !dia.isBefore(DateUtils.dateOnly(widget.primera)) && !dia.isAfter(DateUtils.dateOnly(widget.ultima));

  bool get _hayAnterior => _dentro(DateTime(_mes.year, _mes.month, 0));
  bool get _haySiguiente => _dentro(DateTime(_mes.year, _mes.month + 1));

  void _tocar(DateTime dia) {
    setState(() {
      if (_inicio == null || _fin != null) {
        _inicio = dia;
        _fin = null;
      } else if (dia.isBefore(_inicio!)) {
        _inicio = dia;
      } else {
        _fin = dia;
      }
    });
  }

  String get _resumen {
    if (_inicio == null) return 'Toca el primer día';
    if (_fin == null) return '${fechaCorta(_inicio!)} · toca el último día';
    return '${fechaCorta(_inicio!)} – ${fechaCorta(_fin!)}';
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final l10n = MaterialLocalizations.of(context);
    final primerDiaSemana = l10n.firstDayOfWeekIndex;
    final diasDelMes = DateUtils.getDaysInMonth(_mes.year, _mes.month);
    // Casillas vacías antes del día 1, según el día en que empieza la semana.
    final vacias = (_mes.weekday % 7 - primerDiaSemana + 7) % 7;
    final filas = ((vacias + diasDelMes) / 7).ceil();

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(AppSpacing.margen, 0, AppSpacing.margen, AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text('Elige las fechas', style: textos.titleLarge)),
          const SizedBox(height: AppSpacing.xs),
          Text(_resumen, style: textos.bodyMedium!.copyWith(color: _inicio == null ? AppColors.textSecondary : AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              IconButton(
                tooltip: 'Mes anterior',
                icon: const Icon(Phosphor.arrowLeft),
                onPressed: _hayAnterior ? () => setState(() => _mes = DateTime(_mes.year, _mes.month - 1)) : null,
              ),
              Expanded(
                child: Text(
                  _mayuscula(l10n.formatMonthYear(_mes)),
                  textAlign: TextAlign.center,
                  style: textos.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Mes siguiente',
                icon: const RotatedBox(quarterTurns: 2, child: Icon(Phosphor.arrowLeft)),
                onPressed: _haySiguiente ? () => setState(() => _mes = DateTime(_mes.year, _mes.month + 1)) : null,
              ),
            ],
          ),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Center(
                    child: Text(
                      l10n.narrowWeekdays[(primerDiaSemana + i) % 7],
                      style: textos.labelMedium,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          for (var f = 0; f < filas; f++)
            Row(
              children: [
                for (var c = 0; c < 7; c++)
                  Expanded(child: _celda(context, f * 7 + c - vacias + 1, diasDelMes, l10n)),
              ],
            ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: _inicio == null
                ? null
                : () => Navigator.pop(context, DateTimeRange(start: _inicio!, end: _fin ?? _inicio!)),
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  Widget _celda(BuildContext context, int numero, int diasDelMes, MaterialLocalizations l10n) {
    if (numero < 1 || numero > diasDelMes) return const SizedBox(height: 44);
    final dia = DateTime(_mes.year, _mes.month, numero);
    final habilitado = _dentro(dia);
    final esInicio = _inicio != null && DateUtils.isSameDay(dia, _inicio);
    final esFin = _fin != null && DateUtils.isSameDay(dia, _fin);
    final enRango = _inicio != null && _fin != null && !dia.isBefore(_inicio!) && !dia.isAfter(_fin!);
    final extremo = esInicio || esFin;
    final esHoy = DateUtils.isSameDay(dia, _hoy);
    final textos = Theme.of(context).textTheme;

    final color = extremo
        ? AppColors.onPrimary
        : !habilitado
            ? AppColors.textSecondary.withValues(alpha: 0.4)
            : AppColors.textPrimary;

    return Semantics(
      button: true,
      selected: extremo,
      enabled: habilitado,
      label: l10n.formatFullDate(dia),
      excludeSemantics: true,
      child: InkWell(
        onTap: habilitado ? () => _tocar(dia) : null,
        child: SizedBox(
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Franja del rango: toda la casilla, y solo la mitad en los extremos.
              if (enRango)
                Positioned.fill(
                  top: 4,
                  bottom: 4,
                  left: esInicio && !esFin ? 22 : 0,
                  right: esFin && !esInicio ? 22 : 0,
                  child: ColoredBox(color: extremo && _inicio == _fin ? Colors.transparent : AppColors.primarySoft),
                ),
              if (extremo || esHoy)
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: extremo ? AppColors.primary : null,
                    border: !extremo && esHoy ? Border.all(color: AppColors.primary, width: 1.5) : null,
                  ),
                ),
              Text(
                '$numero',
                style: textos.bodyLarge!.copyWith(
                  color: color,
                  fontWeight: extremo ? FontWeight.w600 : FontWeight.w400,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _mayuscula(String texto) => texto.isEmpty ? texto : texto[0].toUpperCase() + texto.substring(1);
