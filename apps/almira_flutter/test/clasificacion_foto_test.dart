import 'dart:typed_data';

import 'package:almira_flutter/features/complaints/clasificacion_foto/clasificador_foto.dart';
import 'package:almira_flutter/features/complaints/clasificacion_foto/clasificador_web.dart';
import 'package:almira_flutter/features/complaints/clasificacion_foto/regla_foto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('decidirFoto', () {
    test('una selfie no es válida', () {
      final r = decidirFoto(const [
        EtiquetaDetectada('Selfie', 0.92),
        EtiquetaDetectada('Smile', 0.85),
      ]);
      expect(r.estado, EstadoFoto.noValida);
      expect(r.motivo, 'Esta foto no parece de la vía pública.');
    });

    test('una pista es válida', () {
      final r = decidirFoto(const [
        EtiquetaDetectada('Road', 0.81),
        EtiquetaDetectada('Asphalt', 0.66),
        EtiquetaDetectada('Sky', 0.9),
      ]);
      expect(r.estado, EstadoFoto.valida);
      expect(r.motivo, 'La foto muestra la vía pública.');
    });

    test('en una mezcla gana la etiqueta no válida con confianza suficiente', () {
      final r = decidirFoto(const [
        EtiquetaDetectada('Road', 0.9),
        EtiquetaDetectada('Dog', 0.75),
      ]);
      expect(r.estado, EstadoFoto.noValida);
    });

    test('en una mezcla, una no válida bajo 0.7 no impide que sea válida', () {
      final r = decidirFoto(const [
        EtiquetaDetectada('Road', 0.65),
        EtiquetaDetectada('Dog', 0.69),
      ]);
      expect(r.estado, EstadoFoto.valida);
    });

    test('sin etiquetas queda en revisión', () {
      final r = decidirFoto(const []);
      expect(r.estado, EstadoFoto.enRevision);
      expect(r.motivo, 'No pudimos reconocer qué muestra. Puedes enviarla igual.');
    });

    test('etiquetas válidas bajo 0.6 o desconocidas quedan en revisión', () {
      final r = decidirFoto(const [
        EtiquetaDetectada('Building', 0.59),
        EtiquetaDetectada('Sky', 0.95),
      ]);
      expect(r.estado, EstadoFoto.enRevision);
    });

    test('los umbrales son inclusivos y no distinguen mayúsculas', () {
      expect(decidirFoto(const [EtiquetaDetectada('web page', 0.7)]).estado, EstadoFoto.noValida);
      expect(decidirFoto(const [EtiquetaDetectada('VEHICLE', 0.6)]).estado, EstadoFoto.valida);
    });
  });

  test('en web la foto queda en revisión', () async {
    final r = await ClasificadorWeb().clasificar(ImagenReclamo(ruta: 'x', bytes: Uint8List(0)));
    expect(r, ResultadoFoto.enRevision);
  });
}
