import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

import 'clasificador_foto.dart';
import 'etiquetas_foto.dart';
import 'regla_foto.dart';

/// Clasificador con el modelo base de etiquetado de ML Kit. Corre en el
/// teléfono (Android e iOS) y la imagen no sale del dispositivo.
/// No registra la foto ni las etiquetas.
class ClasificadorMlKit implements ClasificadorFoto {
  ClasificadorMlKit({this.diagnostico = diagnosticoFotoActivo});

  /// Adjunta al resultado los datos del modo diagnóstico.
  final bool diagnostico;

  ImageLabeler? _etiquetador;

  static const _tiempoMaximo = Duration(seconds: 10);

  bool get _soportado =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<ResultadoFoto> clasificar(ImagenReclamo imagen) async {
    if (!_soportado) {
      return _conDiagnostico(ResultadoFoto.enRevision, error: 'Plataforma sin soporte: ${defaultTargetPlatform.name}');
    }
    try {
      final etiquetador =
          _etiquetador ??= ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: umbralModelo));
      final etiquetas =
          await etiquetador.processImage(InputImage.fromFilePath(imagen.ruta)).timeout(_tiempoMaximo);
      final detectadas = [for (final e in etiquetas) EtiquetaDetectada(e.label, e.confidence)];
      return _conDiagnostico(decidirFoto(detectadas), etiquetas: detectadas);
    } catch (error) {
      return _conDiagnostico(ResultadoFoto.enRevision, error: describirError(error));
    }
  }

  ResultadoFoto _conDiagnostico(
    ResultadoFoto resultado, {
    List<EtiquetaDetectada> etiquetas = const [],
    String? error,
  }) =>
      diagnostico
          ? resultado.conDiagnostico(DiagnosticoFoto(
              implementacion: 'mlkit',
              etiquetas: mejoresEtiquetas(etiquetas),
              error: error,
              umbralModelo: umbralModelo,
            ))
          : resultado;

  Future<void> cerrar() async {
    try {
      await _etiquetador?.close();
    } catch (_) {
      // Nada que hacer: el etiquetador ya no se usará.
    }
    _etiquetador = null;
  }
}

/// Tipo y mensaje de una excepción, para el modo diagnóstico.
String describirError(Object error) => switch (error) {
      PlatformException(:final code, :final message) => 'PlatformException [$code]: ${message ?? ''}',
      _ => '${error.runtimeType}: $error',
    };

ClasificadorFoto crearClasificadorFoto(void Function(Future<void> Function()) alCerrar) {
  final clasificador = ClasificadorMlKit();
  alCerrar(clasificador.cerrar);
  return clasificador;
}
