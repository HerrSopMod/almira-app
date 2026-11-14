import 'clasificador_foto.dart';

/// En web no se ejecuta el modelo: toda foto queda en revisión.
class ClasificadorWeb implements ClasificadorFoto {
  @override
  Future<ResultadoFoto> clasificar(ImagenReclamo imagen) async => ResultadoFoto.enRevision;
}

ClasificadorFoto crearClasificadorFoto(void Function(Future<void> Function()) alCerrar) => ClasificadorWeb();
