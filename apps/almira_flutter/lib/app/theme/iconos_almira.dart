import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Los 35 íconos propios del rediseño (`assets/iconos/*.svg`): 24×24, trazo de 1.8 redondeado.
/// El trazo es `currentColor`, así que toman el color del [IconTheme] o el que se pase.
enum IconoA {
  alerta,
  arbitrios,
  asistente,
  avance,
  ayuda,
  bache,
  calendario,
  camara,
  campana,
  candado,
  celular,
  chat,
  cuponera,
  descargar,
  enviar,
  estado,
  foto,
  historial,
  inicio,
  meta,
  multa,
  municipalidad,
  obras,
  ojo,
  pagar,
  perfil,
  poste,
  predio,
  presupuesto,
  privacidad,
  reclamos,
  sms,
  tarjeta,
  texto,
  ubicacion;

  String get ruta => 'assets/iconos/$name.svg';
}

/// Ícono de línea del rediseño. Sin [color], usa el del [IconTheme] (como `Icon`).
class IconoAlmira extends StatelessWidget {
  const IconoAlmira(this.icono, {super.key, this.tamano, this.color, this.semantica});

  final IconoA icono;
  final double? tamano;
  final Color? color;

  /// Texto para lectores de pantalla; sin él, el ícono es decorativo.
  final String? semantica;

  @override
  Widget build(BuildContext context) {
    final tema = IconTheme.of(context);
    final lado = tamano ?? tema.size ?? 24;
    final dibujo = SvgPicture.asset(
      icono.ruta,
      width: lado,
      height: lado,
      theme: SvgTheme(currentColor: color ?? tema.color ?? const Color(0xFF12393A)),
    );
    return semantica == null
        ? ExcludeSemantics(child: dibujo)
        : Semantics(
            label: semantica,
            child: ExcludeSemantics(child: dibujo),
          );
  }
}

/// Ilustraciones del rediseño (`assets/ilustraciones/*.svg`).
enum Ilustracion {
  almiBot('almi-bot'),
  barrio('hero-barrio'),
  mapa('mapa'),
  obraParque('obra-parque'),
  obraPistas('obra-pistas'),
  obraVeredas('obra-veredas'),
  pasoCelular('paso-celular'),
  pasoClave('paso-clave'),
  pasoCuponera('paso-cuponera'),
  pasoPrivacidad('paso-privacidad'),
  vacioPagos('vacio-pagos');

  const Ilustracion(this.archivo);
  final String archivo;
  String get ruta => 'assets/ilustraciones/$archivo.svg';
}

/// Una ilustración decorativa, a lo ancho disponible.
class ImagenIlustracion extends StatelessWidget {
  const ImagenIlustracion(this.ilustracion, {super.key, this.alto, this.ancho, this.ajuste = BoxFit.contain});

  final Ilustracion ilustracion;
  final double? alto;
  final double? ancho;
  final BoxFit ajuste;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SvgPicture.asset(ilustracion.ruta, height: alto, width: ancho, fit: ajuste),
  );
}
