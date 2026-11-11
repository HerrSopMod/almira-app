import '../../core/utils/formato.dart';
import '../../shared/models/modelos.dart';

/// Resumen de lo pendiente. Todo sale de las deudas: no hay cifras fijas.
class ResumenDeuda {
  const ResumenDeuda({
    required this.total,
    required this.cantidad,
    required this.cantidadVencidas,
    required this.montoVencido,
    required this.cantidadPorVencer,
    required this.montoPorVencer,
    this.proximoVencimiento,
  });

  /// Suma de todas las obligaciones pendientes (insoluto más intereses).
  final double total;
  final int cantidad;
  final int cantidadVencidas;
  final double montoVencido;
  final int cantidadPorVencer;
  final double montoPorVencer;

  /// Vencimiento más cercano desde hoy (incluido), o null si no hay.
  final DateTime? proximoVencimiento;

  bool get alDia => cantidad == 0;
}

ResumenDeuda resumirDeuda(List<Deuda> deudas, DateTime hoy) {
  final pendientes = deudas.where((d) => d.pendiente).toList();
  final vencidas = pendientes.where((d) => d.estadoAl(hoy) == EstadoDeuda.vencida).toList();
  final porVencer = pendientes.where((d) => d.estadoAl(hoy) != EstadoDeuda.vencida).toList();
  double sumar(List<Deuda> lista) => lista.fold(0, (suma, d) => suma + d.total);

  final futuros = porVencer.map((d) => d.vencimiento).whereType<DateTime>().toList()..sort();
  return ResumenDeuda(
    total: sumar(pendientes),
    cantidad: pendientes.length,
    cantidadVencidas: vencidas.length,
    montoVencido: sumar(vencidas),
    cantidadPorVencer: porVencer.length,
    montoPorVencer: sumar(porVencer),
    proximoVencimiento: futuros.firstOrNull,
  );
}

enum FiltroDeuda {
  pendientes('Pendientes'),
  vencidos('Vencidos'),
  pagados('Pagados');

  const FiltroDeuda(this.etiqueta);
  final String etiqueta;

  static FiltroDeuda de(String? valor) =>
      values.firstWhere((f) => f.name == valor, orElse: () => FiltroDeuda.pendientes);
}

/// Deudas del filtro, de la que vence antes a la que vence después.
List<Deuda> filtrarDeudas(List<Deuda> deudas, FiltroDeuda filtro, DateTime hoy) {
  final lista = deudas.where((d) {
    final estado = d.estadoAl(hoy);
    return switch (filtro) {
      FiltroDeuda.pendientes => d.pendiente,
      FiltroDeuda.vencidos => estado == EstadoDeuda.vencida,
      FiltroDeuda.pagados => estado == EstadoDeuda.pagada,
    };
  }).toList();
  lista.sort((a, b) {
    final va = a.vencimiento, vb = b.vencimiento;
    if (va == null || vb == null) return va == null ? 1 : -1;
    return filtro == FiltroDeuda.pagados ? vb.compareTo(va) : va.compareTo(vb);
  });
  return lista;
}

/// "Vence el 30 de noviembre" o "Sin fecha de vencimiento".
String vencimientoDe(Deuda deuda, DateTime hoy) {
  final v = deuda.vencimiento;
  if (v == null) return 'Sin fecha de vencimiento';
  if (deuda.estado == EstadoDeuda.pagada) return 'Venció el ${diaYMes(v)}';
  return textoVencimiento(v, hoy);
}
