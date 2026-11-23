import 'dart:ui' show Color;

import '../../app/theme/app_colors.dart';
import '../../app/theme/iconos_almira.dart';
import '../../core/utils/formato.dart';
import '../../shared/models/modelos.dart';
import '../account/estado_cuenta_logica.dart';

// Lógica del Detalle de deuda y de la hoja de Trimestre. Todo sale de los datos de la deuda y
// de la fecha real de hoy; no hay cifras ni textos fijos.

/// La deuda está en cobranza coactiva: es del tipo coactivo o tiene expediente coactivo.
bool enCoactiva(Deuda d) => d.tipo == TipoDeuda.coactivo || (d.expCoactivo?.trim().isNotEmpty ?? false);

/// Ícono y color de la caja del tributo.
(IconoA, Color) iconoTributo(TipoDeuda tipo) => switch (tipo) {
  TipoDeuda.predial => (IconoA.predio, AppColors.primary),
  TipoDeuda.arbitrios => (IconoA.arbitrios, AppColors.lima),
  TipoDeuda.multa => (IconoA.multa, AppColors.coral),
  TipoDeuda.coactivo => (IconoA.multa, AppColors.coral),
  TipoDeuda.otros => (IconoA.cuponera, AppColors.sol),
};

/// Texto en tipo oración: «IMPUESTO PREDIAL» → «Impuesto predial». Si ya trae minúsculas, se
/// respeta (puede tener nombres propios).
String tipoOracion(String texto) {
  final t = texto.trim();
  if (t.isEmpty) return t;
  final enMayusculas = t == t.toUpperCase() && t != t.toLowerCase();
  final base = enMayusculas ? t.toLowerCase() : t;
  return base[0].toUpperCase() + base.substring(1);
}

/// Título del detalle: el concepto en tipo oración con su año («Impuesto predial 2023»).
String tituloDeuda(Deuda d) {
  final concepto = tipoOracion(d.concepto.isEmpty ? d.tipo.name : d.concepto);
  final anio = d.anioTributo;
  if (anio == 0 || concepto.contains('$anio')) return concepto;
  return '$concepto $anio';
}

const _ordinales = {1: '1.er', 2: '2.º', 3: '3.er', 4: '4.º'};

/// Bajada del detalle: periodo y código («4.º trimestre · Código 2023-TRIM.4»).
String? bajadaDeuda(Deuda d) {
  final trimestre = d.trimestre;
  final periodo = trimestre != null && _ordinales.containsKey(trimestre)
      ? '${_ordinales[trimestre]} trimestre'
      : tipoOracion(d.periodo);
  final codigo = d.nroValor?.trim();
  final partes = [if (periodo.isNotEmpty) periodo, if (codigo != null && codigo.isNotEmpty) 'Código $codigo'];
  return partes.isEmpty ? null : partes.join(' · ');
}

/// Tiempo transcurrido desde [desde] hasta [hoy]: «hoy», «hace 5 días», «hace 2 meses»,
/// «hace casi 1 año», «hace 3 años».
String haceTiempo(DateTime desde, DateTime hoy) {
  final dias = diasEntre(desde, hoy);
  if (dias <= 0) return 'hoy';
  if (dias == 1) return 'ayer';
  if (dias < 30) return 'hace $dias días';
  if (dias < 330) {
    final meses = (dias / 30).floor();
    return meses == 1 ? 'hace 1 mes' : 'hace $meses meses';
  }
  if (dias < 365) return 'hace casi 1 año';
  final anios = (dias / 365).floor();
  return anios == 1 ? 'hace 1 año' : 'hace $anios años';
}

/// Pagos aplicados a la deuda. Si está pagada y la base no trae el monto de los pagos, se toma
/// su importe: así la cuenta cuadra (importe − pagos = saldo 0).
double pagosDe(Deuda d) => d.estado == EstadoDeuda.pagada && d.pagosAplicados == 0 ? d.importe : d.pagosAplicados;

/// Título de una cuota: «Trimestre 04 · 2025». Si el periodo ya trae el año («4.ª cuota 2026»),
/// no se repite.
String tituloCuota(Deuda d) {
  final periodo = etiquetaPeriodo(d);
  final anio = d.anioTributo;
  return anio == 0 || periodo.contains('$anio') ? periodo : '$periodo · $anio';
}

/// Intereses de la deuda (moratorio más actualización).
double interesesDe(Deuda d) => d.interesMoratorio + d.interesActualizacion;

/// Un concepto del desglose. [resta] es true para descuentos y pagos.
class ConceptoDeuda {
  const ConceptoDeuda(this.nombre, this.monto, {this.color, this.resta = false});

  final String nombre;
  final double monto;
  final Color? color;
  final bool resta;
}

/// «¿De qué se compone?»: lo que suma (importe, gastos de emisión, intereses) con su color para
/// la barra, y lo que resta (descuento, pagos). Los conceptos en 0 se omiten, salvo el importe.
List<ConceptoDeuda> conceptosDe(Deuda d) => [
  ConceptoDeuda('Importe', d.montoInsoluto, color: AppColors.primary500),
  if (d.gastosEmision > 0) ConceptoDeuda('Gastos de emisión', d.gastosEmision, color: AppColors.sol),
  if (interesesDe(d) > 0) ConceptoDeuda('Intereses', interesesDe(d), color: AppColors.coral),
  if (d.descuento > 0) ConceptoDeuda('Descuento', d.descuento, resta: true),
  if (pagosDe(d) > 0) ConceptoDeuda('Pagos', pagosDe(d), resta: true),
];

/// Situación de una cuota para la hoja de Trimestre.
enum SituacionCuota { pagadaATiempo, pagadaTarde, pagada, vencida, porVencer }

class EstadoCuota {
  const EstadoCuota(this.situacion, this.titulo, this.detalle);

  final SituacionCuota situacion;

  /// «Pagado a tiempo», «Pagado», «Vencido», «Por vencer».
  final String titulo;

  /// «8 días antes del vencimiento», «hace 2 meses, suma intereses», «vence en 19 días».
  final String? detalle;

  bool get pagada =>
      situacion == SituacionCuota.pagadaATiempo ||
      situacion == SituacionCuota.pagadaTarde ||
      situacion == SituacionCuota.pagada;
}

/// Fecha en que se pagó la cuota: la de la base o, si falta, la del pago registrado.
DateTime? fechaDePago(Deuda d, Iterable<Pago> pagos) {
  if (d.fechaPago != null) return d.fechaPago;
  final suyos =
      pagos.where((p) => p.deudaId == d.id && p.estado == EstadoPago.confirmado && p.creadoEn != null).toList()
        ..sort((a, b) => b.creadoEn!.compareTo(a.creadoEn!));
  return suyos.firstOrNull?.creadoEn;
}

String _dias(int n) => n == 1 ? '1 día' : '$n días';

/// Estado de la cuota con su explicación, comparando las fechas reales.
EstadoCuota estadoCuota(Deuda d, DateTime hoy, {DateTime? pagadoEl}) {
  final vence = d.vencimiento;
  final estado = d.estadoAl(hoy);
  if (estado == EstadoDeuda.pagada) {
    if (vence == null || pagadoEl == null) return const EstadoCuota(SituacionCuota.pagada, 'Pagado', null);
    final antes = diasEntre(pagadoEl, vence);
    if (antes > 0) {
      return EstadoCuota(SituacionCuota.pagadaATiempo, 'Pagado a tiempo', '${_dias(antes)} antes del vencimiento');
    }
    if (antes == 0) {
      return const EstadoCuota(SituacionCuota.pagadaATiempo, 'Pagado a tiempo', 'el mismo día del vencimiento');
    }
    return EstadoCuota(SituacionCuota.pagadaTarde, 'Pagado', '${_dias(-antes)} después del vencimiento');
  }
  if (estado == EstadoDeuda.vencida) {
    final intereses = interesesDe(d) > 0 ? ', suma intereses' : '';
    return EstadoCuota(
      SituacionCuota.vencida,
      'Vencido',
      vence == null ? (intereses.isEmpty ? null : 'suma intereses') : '${haceTiempo(vence, hoy)}$intereses',
    );
  }
  if (vence == null) return const EstadoCuota(SituacionCuota.porVencer, 'Por vencer', null);
  final faltan = diasEntre(hoy, vence);
  return EstadoCuota(SituacionCuota.porVencer, 'Por vencer', faltan == 0 ? 'vence hoy' : 'vence en ${_dias(faltan)}');
}

/// Pago confirmado con número de operación, para generar la constancia; null si no existe.
Pago? pagoConConstancia(Deuda d, Iterable<Pago> pagos) => pagos
    .where(
      (p) =>
          p.deudaId == d.id &&
          p.estado == EstadoPago.confirmado &&
          (p.referencia?.trim().isNotEmpty ?? false) &&
          MedioPago.values.any((m) => m.clave == p.medio),
    )
    .firstOrNull;
