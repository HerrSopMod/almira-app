import 'formato.dart';

/// Situación del plazo de atención de un reclamo.
enum EstadoPlazo { dentro, porVencer, venceHoy, vencido, porConfirmar }

/// Días hábiles restantes desde los que el plazo se muestra como "por vencer".
const diasPorVencer = 2;

class Plazo {
  const Plazo({required this.estado, this.restantes, this.total, this.limite});

  const Plazo.porConfirmar() : this(estado: EstadoPlazo.porConfirmar);

  final EstadoPlazo estado;

  /// Días hábiles que quedan después de hoy. Nunca supera [total].
  final int? restantes;

  /// Días hábiles del plazo completo.
  final int? total;

  /// Último día del plazo.
  final DateTime? limite;

  /// Texto corto para la insignia.
  String get etiqueta => switch (estado) {
        EstadoPlazo.dentro || EstadoPlazo.porVencer => restantes == 1
            ? 'Queda 1 día hábil'
            : 'Quedan $restantes días hábiles',
        EstadoPlazo.venceHoy => 'Vence hoy',
        EstadoPlazo.vencido => 'Plazo vencido',
        EstadoPlazo.porConfirmar => 'Plazo por confirmar',
      };

  /// Parte del plazo ya transcurrida, de 0 a 1. Null si no se conoce.
  double? get transcurrido {
    final t = total, r = restantes;
    if (t == null || r == null || t <= 0) return null;
    return ((t - r) / t).clamp(0, 1).toDouble();
  }
}

bool esHabil(DateTime dia) =>
    dia.weekday != DateTime.saturday && dia.weekday != DateTime.sunday;

/// Último día de un plazo en días hábiles (lunes a viernes, sin feriados).
/// El día de creación cuenta como el primero si es hábil.
DateTime fechaLimite(DateTime creadoEn, int plazoDias) {
  var dia = soloDia(creadoEn);
  var contados = esHabil(dia) ? 1 : 0;
  while (contados < plazoDias) {
    dia = dia.add(const Duration(days: 1));
    if (esHabil(dia)) contados++;
  }
  return dia;
}

/// Días hábiles después de [desde] y hasta [hasta], incluido.
int habilesEntre(DateTime desde, DateTime hasta) {
  var cuenta = 0;
  var dia = soloDia(desde).add(const Duration(days: 1));
  final fin = soloDia(hasta);
  while (!dia.isAfter(fin)) {
    if (esHabil(dia)) cuenta++;
    dia = dia.add(const Duration(days: 1));
  }
  return cuenta;
}

/// Plazo de un reclamo abierto, calculado con la fecha real de [hoy].
///
/// Devuelve null si el reclamo ya está resuelto. Si faltan datos o son
/// incoherentes (sin plazo, creado en el futuro, o quedarían más días que el
/// plazo total), devuelve "Plazo por confirmar" en vez de un número
/// contradictorio como "Quedan 16 de 10 días".
Plazo? calcularPlazo({
  required DateTime? creadoEn,
  required int? plazoDias,
  required bool resuelto,
  required DateTime hoy,
}) {
  if (resuelto) return null;
  if (creadoEn == null || plazoDias == null || plazoDias <= 0) {
    return const Plazo.porConfirmar();
  }
  final creado = soloDia(creadoEn);
  final dia = soloDia(hoy);
  if (creado.isAfter(dia)) return const Plazo.porConfirmar();

  final limite = fechaLimite(creado, plazoDias);
  if (dia.isAfter(limite)) {
    return Plazo(estado: EstadoPlazo.vencido, restantes: 0, total: plazoDias, limite: limite);
  }
  if (dia == limite) {
    return Plazo(estado: EstadoPlazo.venceHoy, restantes: 0, total: plazoDias, limite: limite);
  }
  final restantes = habilesEntre(dia, limite);
  if (restantes > plazoDias) return const Plazo.porConfirmar();
  return Plazo(
    estado: restantes <= diasPorVencer ? EstadoPlazo.porVencer : EstadoPlazo.dentro,
    restantes: restantes,
    total: plazoDias,
    limite: limite,
  );
}
