import 'package:flutter/material.dart';

/// Periodos de los filtros por fecha. «elegido» es el rango que la persona marca en el calendario.
enum PeriodoFecha { todas, esteMes, tresMeses, esteAnio, elegido }

/// Filtro por fecha de un listado: un periodo rápido o un rango del calendario. La fecha de hoy
/// llega siempre de afuera (`relojProvider`), nunca se lee aquí.
class FiltroFechas {
  const FiltroFechas({this.periodo = PeriodoFecha.todas, this.elegido});

  final PeriodoFecha periodo;
  final DateTimeRange? elegido;

  static const todas = FiltroFechas();

  bool get activo => periodo != PeriodoFecha.todas;

  FiltroFechas conPeriodo(PeriodoFecha p) => FiltroFechas(periodo: p);

  FiltroFechas conRango(DateTimeRange rango) => FiltroFechas(periodo: PeriodoFecha.elegido, elegido: rango);

  /// El rango de días que cubre el filtro (ambos extremos incluidos), o null si no filtra.
  DateTimeRange? rango(DateTime hoy) {
    final dia = DateUtils.dateOnly(hoy);
    return switch (periodo) {
      PeriodoFecha.todas => null,
      PeriodoFecha.esteMes => DateTimeRange(start: DateTime(dia.year, dia.month), end: dia),
      PeriodoFecha.tresMeses => DateTimeRange(start: DateTime(dia.year, dia.month - 2), end: dia),
      PeriodoFecha.esteAnio => DateTimeRange(start: DateTime(dia.year), end: dia),
      PeriodoFecha.elegido => elegido == null
          ? null
          : DateTimeRange(start: DateUtils.dateOnly(elegido!.start), end: DateUtils.dateOnly(elegido!.end)),
    };
  }

  /// ¿Esa fecha entra en el filtro? Sin filtro, todo entra; una fecha vacía no entra si hay filtro.
  bool contiene(DateTime? fecha, DateTime hoy) {
    final r = rango(hoy);
    if (r == null) return true;
    if (fecha == null) return false;
    final dia = DateUtils.dateOnly(fecha);
    return !dia.isBefore(r.start) && !dia.isAfter(r.end);
  }
}
