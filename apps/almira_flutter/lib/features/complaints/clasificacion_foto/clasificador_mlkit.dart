import 'package:flutter/foundation.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

import 'clasificador_foto.dart';
import 'etiquetas_foto.dart';
import 'regla_foto.dart';

/// Clasificador con el modelo base de etiquetado de ML Kit. Corre en el
/// teléfono (Android e iOS) y la imagen no sale del dispositivo.
/// No registra la foto ni las etiquetas.
class ClasificadorMlKit implements ClasificadorFoto {
  ImageLabeler? _etiquetador;

  static const _tiempoMaximo = Duration(seconds: 10);

  bool get _soportado =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<ResultadoFoto> clasificar(ImagenReclamo imagen) async {
    if (!_soportado) return ResultadoFoto.enRevision;
    try {
      final etiquetador =
          _etiquetador ??= ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: umbralModelo));
      final etiquetas =
          await etiquetador.processImage(InputImage.fromFilePath(imagen.ruta)).timeout(_tiempoMaximo);
      return decidirFoto([for (final e in etiquetas) EtiquetaDetectada(e.label, e.confidence)]);
    } catch (_) {
      return ResultadoFoto.enRevision;
    }
  }

  Future<void> cerrar() async {
    try {
      await _etiquetador?.close();
    } catch (_) {
      // Nada que hacer: el etiquetador ya no se usará.
    }
    _etiquetador = null;
  }
}

ClasificadorFoto crearClasificadorFoto(void Function(Future<void> Function()) alCerrar) {
  final clasificador = ClasificadorMlKit();
  alCerrar(clasificador.cerrar);
  return clasificador;
}
