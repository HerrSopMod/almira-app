import 'package:intl/intl.dart';

const _meses = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

// En Perú el decimal es punto y el millar, coma (el formato «es_PE» de intl usa coma decimal).
final _monto = NumberFormat('#,##0.00', 'en_US');

/// "S/ 1,234.50": soles con dos decimales, como se escribe en Perú.
String soles(num monto) => 'S/ ${_monto.format(monto)}';

/// Lee una fecha de la base. Las que traen hora y zona (timestamptz) pasan a
/// la hora del teléfono; las que son solo día ("2026-11-30") se quedan en ese día.
DateTime? leerFecha(String? iso) {
  if (iso == null || iso.trim().isEmpty) return null;
  final fecha = DateTime.tryParse(iso.trim());
  if (fecha == null) return null;
  return fecha.isUtc ? fecha.toLocal() : fecha;
}

/// "30 de noviembre de 2026".
String fechaLarga(DateTime f) => '${f.day} de ${_meses[f.month - 1]} de ${f.year}';

/// "30 de noviembre".
String diaYMes(DateTime f) => '${f.day} de ${_meses[f.month - 1]}';

/// "30 nov 2026".
String fechaCorta(DateTime f) => '${f.day} ${_meses[f.month - 1].substring(0, 3)} ${f.year}';

/// "9:05 a. m.".
String hora(DateTime f) {
  final h = f.hour % 12 == 0 ? 12 : f.hour % 12;
  final m = f.minute.toString().padLeft(2, '0');
  return '$h:$m ${f.hour < 12 ? 'a. m.' : 'p. m.'}';
}

/// Día sin hora, en UTC, para contar días sin que afecte el cambio de hora.
DateTime soloDia(DateTime f) => DateTime.utc(f.year, f.month, f.day);

/// Días de calendario desde [desde] hasta [hasta] (negativo si ya pasó).
int diasEntre(DateTime desde, DateTime hasta) =>
    soloDia(hasta).difference(soloDia(desde)).inDays;

/// "Vence el 30 de noviembre", "Vence hoy" o "Venció el 15 de octubre".
String textoVencimiento(DateTime vencimiento, DateTime hoy) {
  final dias = diasEntre(hoy, vencimiento);
  if (dias == 0) return 'Vence hoy';
  final mismoAnio = vencimiento.year == hoy.year;
  final fecha = mismoAnio ? diaYMes(vencimiento) : fechaLarga(vencimiento);
  return dias < 0 ? 'Venció el $fecha' : 'Vence el $fecha';
}

/// "hoy", "ayer", "hace 6 días".
String haceDias(DateTime fecha, DateTime hoy) {
  final dias = diasEntre(fecha, hoy);
  if (dias <= 0) return 'hoy';
  if (dias == 1) return 'ayer';
  return 'hace $dias días';
}

/// "Rosa Quispe Huamán" -> "RQ".
String iniciales(String nombre) {
  final palabras = nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (palabras.isEmpty) return '';
  final apellido = palabras.length >= 3
      ? palabras[palabras.length - 2]
      : (palabras.length == 2 ? palabras[1] : '');
  return '${palabras.first[0]}${apellido.isEmpty ? '' : apellido[0]}'.toUpperCase();
}

/// "Rosa Quispe Huamán" -> "Rosa".
String primerNombre(String nombre) => nombre.trim().split(RegExp(r'\s+')).first;

/// "1 obligación", "2 obligaciones".
String plural(int cantidad, String singular, String plural) =>
    '$cantidad ${cantidad == 1 ? singular : plural}';

/// Minúsculas y sin tildes, para comparar textos escritos por el vecino.
String normalizar(String texto) {
  const con = 'áéíóúüñ';
  const sin = 'aeiouun';
  final salida = StringBuffer();
  for (final letra in texto.toLowerCase().split('')) {
    final i = con.indexOf(letra);
    salida.write(i >= 0 ? sin[i] : letra);
  }
  return salida.toString();
}
