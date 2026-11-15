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

  /// Barra superior (sin la barra de estado): también la fila de marca de la cabecera.
  static const double barraSuperior = 56;

  /// Cuánto se monta la hoja blanca sobre el color de la cabecera.
  static const double solapeHoja = 20;

  /// Parte de la pantalla que ocupa la cabecera del ingreso (40 %; 34 % en pantallas bajas).
  static const double cabeceraIngreso = 0.40;
  static const double cabeceraIngresoBaja = 0.34;

  /// Logo en la cabecera de marca.
  static const double logoCabecera = 28;

  /// Logo de la pantalla de carga: mismo tamaño que el ícono del splash nativo (112 dp), para
  /// que no salte al pasar de uno a otra.
  static const double logoCarga = 112;

  /// Círculo de un acceso rápido de Inicio.
  static const double acceso = 56;

  /// Separación entre grupos de una ficha o de una pantalla de detalle.
  static const double grupo = 24;

  /// Botón central del Asistente en la barra inferior: diámetro total con el anillo blanco,
  /// grosor del anillo y cuánto sobresale por encima de la barra.
  static const double botonCentral = 56;
  static const double anilloCentral = 4;
  static const double salienteCentral = 18;

  /// Línea corta sobre la pestaña activa de la barra inferior.
  static const double lineaActivaAncho = 24;
  static const double lineaActivaAlto = 3;
}

/// Tamaños de ícono. Un solo estilo de línea («regular»); «fill» solo en la pestaña activa.
abstract final class AppIconos {
  static const double navegacion = 24;
  static const double boton = 20;
  static const double lista = 20;
  static const double caja = 24;
  static const double insignia = 16;
  static const double vacio = 28;

  /// Ícono del botón central del Asistente.
  static const double central = 28;
}

abstract final class AppRadius {
  static const double insignia = 6;
  static const double caja = 10;
  static const double campo = 12;
  static const double boton = 12;
  static const double tarjeta = 12;

  /// Bloque Destacado, mapa, tarjeta grande y tarjeta flotante.
  static const double destacado = 16;

  /// Esquinas superiores de la hoja blanca que se monta sobre la cabecera.
  static const double hoja = 20;
  static const double dialogo = 20;
  static const double pastilla = 999;
}
