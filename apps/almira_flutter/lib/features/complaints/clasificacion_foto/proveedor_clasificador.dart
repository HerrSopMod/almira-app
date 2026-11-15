import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'clasificador_foto.dart';
import 'clasificador_mlkit.dart' if (dart.library.js_interop) 'clasificador_web.dart';

/// Clasificador de fotos que usa la app. Para usar un modelo propio, cambia
/// solo esta implementación: las pantallas no se tocan.
final clasificadorFotoProvider = Provider<ClasificadorFoto>(
  (ref) => crearClasificadorFoto((cerrar) => ref.onDispose(() => cerrar())),
);
