/// Escala de 4/8 dp, radios y medidas del sistema de diseño.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;

  /// Separación entre secciones de una pantalla.
  static const double seccion = 48;

  /// Margen lateral de toda pantalla.
  static const double margen = 20;

  /// Alto mínimo de un control táctil.
  static const double toque = 48;

  /// Alto del botón y del campo.
  static const double boton = 52;

  /// Caja de ícono (cuadrado con radio [AppRadius.caja]).
  static const double caja = 40;
  static const double cajaGrande = 56;

  /// Insignia de estado: alto de la pastilla.
  static const double altoInsignia = 24;
  static const double iconoInsignia = AppIconos.insignia;

  /// Barra inferior, sin el área segura.
  static const double barraInferior = 64;
}

/// Tamaños de ícono. Un solo estilo de línea («regular»); «fill» solo en la pestaña activa.
abstract final class AppIconos {
  static const double navegacion = 24;
  static const double boton = 20;
  static const double lista = 20;
  static const double caja = 24;
  static const double insignia = 16;
  static const double vacio = 28;
}

abstract final class AppRadius {
  static const double insignia = 6;
  static const double caja = 10;
  static const double campo = 12;
  static const double boton = 12;
  static const double tarjeta = 12;

  /// Bloque Destacado, mapa y tarjeta grande.
  static const double destacado = 16;
  static const double dialogo = 20;
  static const double pastilla = 999;
}
