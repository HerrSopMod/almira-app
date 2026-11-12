import 'dart:io';

import 'package:almira_flutter/shared/models/modelos.dart';
import 'package:flutter_test/flutter_test.dart';

/// El código de contribuyente (público para su dueño) y el número de cuponera (privado) son
/// dos datos distintos. El cliente nunca debe pedir ni mostrar la cuponera.
void main() {
  test('el modelo del vecino no tiene el número de cuponera, aunque la fila lo traiga', () {
    final v = Vecino.deFila({
      'id': 'v',
      'municipalidad_id': 'm',
      'nombre': 'Carmen Huamaní',
      'codigo_contribuyente': 'PUL-0002',
      'numero_cuponera': '6204891735',
    });
    expect(v.codigoContribuyente, 'PUL-0002');
    expect(v.toString(), isNot(contains('6204891735')));
    expect(v.nombreCompleto, isNot(contains('6204891735')));
  });

  test('el repositorio nunca pide numero_cuponera ni usa select * en vecinos', () {
    final fuente = File('lib/shared/services/repositorio_supabase.dart').readAsStringSync();
    final columnas = RegExp(r"_columnasVecino =\s*([^;]+);").firstMatch(fuente)!.group(1)!;
    expect(columnas, contains('codigo_contribuyente'));
    expect(columnas, isNot(contains('numero_cuponera')));
    expect(fuente, contains("columnas: _columnasVecino"));
  });

  test('ninguna pantalla muestra el número de cuponera', () {
    final archivos = Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
    for (final archivo in archivos) {
      final texto = archivo.readAsStringSync();
      expect(texto.contains('numero_cuponera') && !archivo.path.contains('repositorio_supabase'), isFalse,
          reason: '${archivo.path} lee numero_cuponera');
    }
  });

  test('la migración oculta la cuponera y documenta los dos códigos', () {
    final sql = File('../../supabase/migrations/20261111000004_ocultar_cuponera.sql').readAsStringSync();
    expect(sql, contains('comment on column public.vecinos.codigo_contribuyente'));
    expect(sql, contains('comment on column public.vecinos.numero_cuponera'));
    expect(sql, contains('revoke select on public.vecinos from authenticated'));
    final concesion = RegExp(r'grant select \(([^)]+)\)', dotAll: true).firstMatch(sql)!.group(1)!;
    expect(concesion, contains('codigo_contribuyente'));
    expect(concesion, isNot(contains('numero_cuponera')));
  });

  test('el SQL de reinicio solo toca a los cinco contribuyentes', () {
    final sql = File('../../supabase/reset_and_seed.sql').readAsStringSync();
    for (final codigo in ['LIN-0001', 'PUL-0002', 'LAV-0003', 'MIR-0004', 'CER-0005']) {
      expect(sql, contains(codigo));
    }
    expect(sql, isNot(contains('0048217'))); // Rosa no se reinicia.
    expect(sql, contains('begin;'));
    expect(sql, contains('commit;'));
    // Todo delete sobre auth.users lleva su condición.
    expect(RegExp(r'delete from auth\.users u\s+where').hasMatch(sql), isTrue);
  });
}
