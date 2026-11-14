import 'clasificador_foto.dart';
import 'etiquetas_foto.dart';

/// Una etiqueta que el modelo vio en la foto y su confianza (0 a 1).
class EtiquetaDetectada {
  const EtiquetaDetectada(this.nombre, this.confianza);

  final String nombre;
  final double confianza;
}

final _validas = {for (final e in etiquetasValidas) e.toLowerCase()};
final _noValidas = {for (final e in etiquetasNoValidas) e.toLowerCase()};

/// Regla de la foto, independiente del modelo:
/// 1. Una etiqueta no válida con confianza ≥ [umbralNoValida] → no válida.
/// 2. Si no, una etiqueta válida con confianza ≥ [umbralValida] → válida.
/// 3. Si no → en revisión.
ResultadoFoto decidirFoto(Iterable<EtiquetaDetectada> etiquetas) {
  final lista = etiquetas.toList();
  bool hay(Set<String> nombres, double umbral) =>
      lista.any((e) => e.confianza >= umbral && nombres.contains(e.nombre.trim().toLowerCase()));

  if (hay(_noValidas, umbralNoValida)) return ResultadoFoto.noValida;
  if (hay(_validas, umbralValida)) return ResultadoFoto.valida;
  return ResultadoFoto.enRevision;
}
