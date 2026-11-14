import 'dart:typed_data';

/// Resultado de mirar la foto de un reclamo en el teléfono. Es una sugerencia
/// para el vecino: nunca bloquea el envío.
enum EstadoFoto { valida, noValida, enRevision }

class ResultadoFoto {
  const ResultadoFoto(this.estado, this.motivo);

  final EstadoFoto estado;

  /// Explicación corta para el vecino, en español de Perú y de «tú».
  final String motivo;

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
