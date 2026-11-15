import 'clasificador_foto.dart';

/// En web no se ejecuta el modelo: toda foto queda en revisión.
class ClasificadorWeb implements ClasificadorFoto {
  ClasificadorWeb({this.diagnostico = diagnosticoFotoActivo});

  /// Adjunta al resultado los datos del modo diagnóstico.
  final bool diagnostico;

  @override
  Future<ResultadoFoto> clasificar(ImagenReclamo imagen) async => diagnostico
      ? ResultadoFoto.enRevision.conDiagnostico(const DiagnosticoFoto(implementacion: 'web'))
      : ResultadoFoto.enRevision;
}

ClasificadorFoto crearClasificadorFoto(void Function(Future<void> Function()) alCerrar) => ClasificadorWeb();
