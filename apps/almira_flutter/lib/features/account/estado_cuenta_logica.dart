import '../../shared/models/modelos.dart';

/// Sumas de un grupo de periodos, con las mismas columnas del estado de cuenta.
class Totales {
  const Totales({
    this.insoluto = 0,
    this.gastos = 0,
    this.interes = 0,
    this.descuento = 0,
    this.pagos = 0,
    this.saldo = 0,
  });

  final double insoluto;
  final double gastos;
  final double interes;
  final double descuento;
  final double pagos;
  final double saldo;

  Totales operator +(Totales otro) => Totales(
        insoluto: insoluto + otro.insoluto,
        gastos: gastos + otro.gastos,
        interes: interes + otro.interes,
        descuento: descuento + otro.descuento,
        pagos: pagos + otro.pagos,
        saldo: saldo + otro.saldo,
      );

  static Totales de(Deuda d) => Totales(
        insoluto: d.montoInsoluto,
        gastos: d.gastosEmision,
        interes: d.interesActualizacion + d.interesMoratorio,
        descuento: d.descuento,
        pagos: d.pagosAplicados,
        saldo: d.saldo,
      );

  static Totales sumar(Iterable<Deuda> deudas) =>
      deudas.fold(const Totales(), (suma, d) => suma + de(d));
}

/// Los periodos de un tributo en un año, con su subtotal.
class GrupoAnio {
  const GrupoAnio(this.anio, this.filas, this.subtotal);

  final int anio;
  final List<Deuda> filas;
  final Totales subtotal;
}

/// Todo un tributo (Predial, Arbitrios…), agrupado por año.
class GrupoTributo {
  const GrupoTributo(this.tipo, this.anios, this.acumulado);

  final TipoDeuda tipo;
  final List<GrupoAnio> anios;
  final Totales acumulado;

  String get titulo => switch (tipo) {
        TipoDeuda.predial => 'IMPUESTO PREDIAL',
        TipoDeuda.arbitrios => 'ARBITRIOS MUNICIPALES',
        TipoDeuda.coactivo => 'COBRANZA COACTIVA',
        TipoDeuda.multa => 'MULTAS',
        TipoDeuda.otros => 'OTROS',
      };
}

class EstadoCuenta {
  const EstadoCuenta(this.tributos, this.general);

  final List<GrupoTributo> tributos;
  final Totales general;

  bool get vacio => tributos.isEmpty;
}

const _ordenTributos = [
  TipoDeuda.predial,
  TipoDeuda.arbitrios,
  TipoDeuda.coactivo,
  TipoDeuda.multa,
  TipoDeuda.otros,
];

int _porPeriodo(Deuda a, Deuda b) {
  final porAnio = a.anioTributo.compareTo(b.anioTributo);
  if (porAnio != 0) return porAnio;
  final porTrimestre = (a.trimestre ?? 0).compareTo(b.trimestre ?? 0);
  if (porTrimestre != 0) return porTrimestre;
  final va = a.vencimiento, vb = b.vencimiento;
  return va == null || vb == null ? 0 : va.compareTo(vb);
}

/// Agrupa las deudas por tributo y por año, con subtotal por año, total
/// acumulado por tributo y total general.
EstadoCuenta construirEstadoCuenta(Iterable<Deuda> deudas) {
  final tributos = <GrupoTributo>[];
  for (final tipo in _ordenTributos) {
    final delTipo = deudas.where((d) => d.tipo == tipo).toList()..sort(_porPeriodo);
    if (delTipo.isEmpty) continue;
    final anios = <GrupoAnio>[];
    for (final anio in {for (final d in delTipo) d.anioTributo}) {
      final filas = delTipo.where((d) => d.anioTributo == anio).toList();
      anios.add(GrupoAnio(anio, filas, Totales.sumar(filas)));
    }
    tributos.add(GrupoTributo(tipo, anios, Totales.sumar(delTipo)));
  }
  return EstadoCuenta(tributos, Totales.sumar(deudas));
}

/// Periodo como se lee en el estado de cuenta: "Trimestre 02" o el texto de la base.
String etiquetaPeriodo(Deuda d) => d.trimestre != null
    ? 'Trimestre ${d.trimestre!.toString().padLeft(2, '0')}'
    : (d.periodo.isEmpty ? d.concepto : d.periodo);

/// "Pag" si ya se pagó y "Pen" si está pendiente.
String estadoCorto(Deuda d) => d.pendiente ? 'Pen' : 'Pag';

/// Un pago del historial, con el tributo y el año de la deuda que cubrió.
class PagoRealizado {
  const PagoRealizado(this.pago, this.deuda);

  final Pago pago;
  final Deuda? deuda;

  int? get anio => deuda?.anioTributo;
  TipoDeuda? get tributo => deuda?.tipo;
}

/// Pagos confirmados, del más reciente al más antiguo, con filtros opcionales.
List<PagoRealizado> historialDePagos(
  List<Pago> pagos,
  List<Deuda> deudas, {
  int? anio,
  TipoDeuda? tributo,
}) {
  final porId = {for (final d in deudas) d.id: d};
  final lista = [
    for (final p in pagos)
      if (p.estado == EstadoPago.confirmado) PagoRealizado(p, porId[p.deudaId]),
  ].where((p) => (anio == null || p.anio == anio) && (tributo == null || p.tributo == tributo)).toList();
  lista.sort((a, b) {
    final fa = a.pago.creadoEn, fb = b.pago.creadoEn;
    if (fa == null || fb == null) return fa == null ? 1 : -1;
    return fb.compareTo(fa);
  });
  return lista;
}

/// Periodos pendientes que se pueden pagar en línea, por tributo. «Beneficio al
/// vencimiento» ofrece solo los del año en curso; «Deuda general», todos.
List<Deuda> deudasParaPagar(
  List<Deuda> deudas,
  TipoDeuda tributo, {
  required bool beneficio,
  required DateTime hoy,
}) {
  final lista = deudas
      .where((d) => d.pendiente && d.saldo > 0 && _coincideTributo(d.tipo, tributo))
      .where((d) => !beneficio || d.anioTributo == hoy.year)
      .toList()
    ..sort(_porPeriodo);
  return lista;
}

/// La pestaña «Otros» reúne las multas y cualquier otro tributo.
bool _coincideTributo(TipoDeuda real, TipoDeuda pestana) =>
    pestana == TipoDeuda.otros ? (real == TipoDeuda.otros || real == TipoDeuda.multa) : real == pestana;

double sumarSaldos(Iterable<Deuda> deudas) => deudas.fold(0, (s, d) => s + d.saldo);
