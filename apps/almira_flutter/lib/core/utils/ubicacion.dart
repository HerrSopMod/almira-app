import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

enum FallaUbicacion { gpsApagado, permisoDenegado, permisoBloqueado, sinSenal }

class ResultadoUbicacion {
  const ResultadoUbicacion.punto(LatLng this.punto) : falla = null;
  const ResultadoUbicacion.falla(FallaUbicacion this.falla) : punto = null;

  final LatLng? punto;
  final FallaUbicacion? falla;

  /// Explicación para el vecino. Siempre deja la alternativa manual.
  String get mensaje => switch (falla) {
        FallaUbicacion.gpsApagado =>
          'La ubicación del teléfono está apagada. Puedes marcar el lugar a mano en el mapa.',
        FallaUbicacion.permisoDenegado =>
          'Sin permiso de ubicación. Puedes marcar el lugar a mano en el mapa.',
        FallaUbicacion.permisoBloqueado =>
          'El permiso de ubicación está bloqueado. Actívalo en Ajustes o marca el lugar a mano en el mapa.',
        FallaUbicacion.sinSenal =>
          'No pudimos obtener tu ubicación. Marca el lugar a mano en el mapa.',
        null => '',
      };

  /// Solo si el permiso quedó bloqueado tiene sentido ofrecer los ajustes.
  bool get ofrecerAjustes => falla == FallaUbicacion.permisoBloqueado;
}

/// Lee la ubicación actual. Pide el permiso recién aquí, cuando el vecino
/// toca «Usar mi ubicación»; nunca al abrir la app.
Future<ResultadoUbicacion> ubicacionActual() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const ResultadoUbicacion.falla(FallaUbicacion.gpsApagado);
    }
    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    if (permiso == LocationPermission.deniedForever) {
      return const ResultadoUbicacion.falla(FallaUbicacion.permisoBloqueado);
    }
    if (permiso == LocationPermission.denied) {
      return const ResultadoUbicacion.falla(FallaUbicacion.permisoDenegado);
    }
    final posicion = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return ResultadoUbicacion.punto(LatLng(posicion.latitude, posicion.longitude));
  } catch (_) {
    return const ResultadoUbicacion.falla(FallaUbicacion.sinSenal);
  }
}

Future<void> abrirAjustesDeUbicacion() => Geolocator.openAppSettings();
