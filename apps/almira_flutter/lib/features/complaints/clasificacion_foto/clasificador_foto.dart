import 'dart:typed_data';

/// Resultado de mirar la foto de un reclamo en el teléfono. Es una sugerencia
/// para el vecino: nunca bloquea el envío.
enum EstadoFoto { valida, noValida, enRevision }

/// Modo diagnóstico: solo con `--dart-define=DIAGNOSTICO_FOTO=true`. Muestra en
/// pantalla lo que devolvió el modelo; nunca escribe en logs.
const diagnosticoFotoActivo = bool.fromEnvironment('DIAGNOSTICO_FOTO');

/// Datos del modo diagnóstico: qué implementación clasificó, las etiquetas con
/// mayor confianza y, si falló, el tipo y el mensaje de la excepción.
class DiagnosticoFoto {
  const DiagnosticoFoto({
    required this.implementacion,
    this.etiquetas = const [],
    this.error,
    this.umbralModelo,
  });

  /// `mlkit` o `web`.
  final String implementacion;

  /// Hasta cinco etiquetas, de mayor a menor confianza.
  final List<(String, double)> etiquetas;

  /// Tipo y mensaje de la excepción, si la hubo.
  final String? error;

  /// Confianza mínima pedida al modelo, si aplica.
  final double? umbralModelo;
}

class ResultadoFoto {
  const ResultadoFoto(this.estado, this.motivo, {this.diagnostico});

  final EstadoFoto estado;

  /// Explicación corta para el vecino, en español de Perú y de «tú».
  final String motivo;

  /// Solo en modo diagnóstico. No cuenta para la igualdad.
  final DiagnosticoFoto? diagnostico;

  ResultadoFoto conDiagnostico(DiagnosticoFoto diagnostico) =>
      ResultadoFoto(estado, motivo, diagnostico: diagnostico);

  static const valida = ResultadoFoto(EstadoFoto.valida, 'La foto muestra la vía pública.');
  static const noValida = ResultadoFoto(EstadoFoto.noValida, 'Esta foto no parece de la vía pública.');
  static const enRevision = ResultadoFoto(
    EstadoFoto.enRevision,
    'No pudimos reconocer qué muestra. Puedes enviarla igual.',
  );

  @override
  bool operator ==(Object other) => other is ResultadoFoto && other.estado == estado && other.motivo == motivo;

  @override
  int get hashCode => Object.hash(estado, motivo);
}

/// La foto tal como la eligió el vecino: la ruta del archivo y sus bytes.
class ImagenReclamo {
  const ImagenReclamo({required this.ruta, required this.bytes});

  final String ruta;
  final Uint8List bytes;
}

/// Clasifica la foto en el teléfono, sin enviarla a ningún servidor.
///
/// Las pantallas solo conocen esta interfaz: para cambiar el modelo base por
/// uno propio basta con otra implementación en `clasificadorFotoProvider`.
/// Una implementación nunca lanza errores: ante cualquier falla devuelve
/// [ResultadoFoto.enRevision].
abstract interface class ClasificadorFoto {
  Future<ResultadoFoto> clasificar(ImagenReclamo imagen);
}
