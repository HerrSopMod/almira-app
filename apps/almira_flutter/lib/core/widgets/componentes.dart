import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/iconos.dart';
import '../../app/theme/iconos_almira.dart';
import '../errors/error_app.dart';
import 'movimiento.dart';

/// Duración de las microanimaciones. Con «reducir movimiento» activado en el
/// sistema, no se anima.
Duration duracionDe(BuildContext context, [int ms = 200]) =>
    MediaQuery.maybeDisableAnimationsOf(context) == true ? Duration.zero : Duration(milliseconds: ms);

/// Ícono de la marca (casa con burbuja), en SVG. Solo el dibujo, sin texto. En [blanco] va la
/// versión para la cabecera turquesa.
class LogoAlmira extends StatelessWidget {
  const LogoAlmira({super.key, this.lado = 40, this.blanco = false});

  final double lado;
  final bool blanco;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    blanco ? 'assets/marca/icono-blanco.svg' : 'assets/marca/icono.svg',
    width: lado,
    height: lado,
    semanticsLabel: 'Almira',
  );
}

/// Logo vertical del ingreso: el ícono en blanco con «Almira» debajo, escrito como texto.
class LogoVertical extends StatelessWidget {
  const LogoVertical({super.key, this.altoIcono = 96});

  final double altoIcono;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    label: 'Almira',
    child: ExcludeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LogoAlmira(lado: altoIcono, blanco: true),
          const SizedBox(height: AppSpacing.md),
          Text('Almira', style: Theme.of(context).textTheme.headlineMedium!.copyWith(color: AppColors.onPrimary)),
        ],
      ),
    ),
  );
}

/// Marca en una fila: ícono de 28 con «Almira» al lado, en Plus Jakarta Sans Bold. En [blanco] va sobre
/// turquesa. Se mantiene por compatibilidad: las pestañas raíz ya la traen en [CabeceraMarca].
class MarcaAlmira extends StatelessWidget {
  const MarcaAlmira({super.key, this.blanco = false});

  final bool blanco;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Almira',
    child: ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LogoAlmira(lado: AppSpacing.logoCabecera, blanco: blanco),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              'Almira',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge!
                  .copyWith(fontWeight: FontWeight.w700, color: blanco ? AppColors.onPrimary : AppColors.textPrimary),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Logo de Google con sus cuatro colores (rojo, azul, amarillo y verde). Es la marca tal
/// cual: no se recolorea.
class LogoGoogle extends StatelessWidget {
  const LogoGoogle({super.key, this.lado = 22});

  final double lado;

  static const _svg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
<path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
<path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
<path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
<path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
</svg>''';

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SvgPicture.string(_svg, width: lado, height: lado),
  );
}

// ---------------------------------------------------------------------------------------
// Cabecera de marca y hoja blanca
//
// CÓMO USARLAS
//
// 1. Pestaña raíz con datos (Inicio, Pagar, Reclamos, Obras): Scaffold sin AppBar y
//    CuerpoAsync con `cabecera`. La cabecera turquesa va arriba, detrás de la barra de
//    estado, y el contenido dentro de una HojaBlanca que se monta sobre ella:
//
//      Scaffold(
//        body: CuerpoAsync<VistaMunicipal>(
//          valor: vista,
//          alRecargar: ref.read(datosProvider.notifier).recargar,
//          cabecera: (v) => CabeceraMarca(
//            titulo: 'Reclamos',
//            esDemo: esDemo,
//            acciones: [IconButton(tooltip: 'Avisos', icon: Icon(Phosphor.bell), onPressed: …)],
//          ),
//          construir: (v) => [ … ],   // lo de siempre: va dentro de la hoja blanca
//        ),
//      )
//
//    Opcional: `flotante: (v) => …` deja una tarjeta a caballo entre el turquesa y la hoja
//    (solo Inicio la usa). `hijo:` en CabeceraMarca pone contenido blanco bajo el título.
//
// 2. Pestaña raíz sin CuerpoAsync (por ejemplo, el chat o una pantalla con mapa): pon
//    CabeceraMarca arriba y el resto en HojaBlanca, en una Column:
//
//      Column(children: [
//        CabeceraMarca(titulo: 'Asistente'),
//        Expanded(child: HojaBlanca(padding: EdgeInsets.zero, child: …)),
//      ])
//
// 3. Pantalla de detalle (deuda, reclamo, obra, pago): un AppBar normal. El tema ya la pinta
//    turquesa compacta con la flecha y el título en blanco; no hace falta nada más:
//
//      Scaffold(appBar: AppBar(title: const Text('Seguimiento')), body: …)
//
// Dentro de la cabecera todo se dibuja en blanco (SobreTurquesa): no pongas colores a mano.
// ---------------------------------------------------------------------------------------

/// Bloque superior turquesa de las pestañas raíz. Empieza detrás de la barra de estado; lleva el
/// título de la pantalla a la izquierda y las acciones a la derecha (sin logo: ya se sabe en qué
/// app estás). Sin [titulo], solo quedan las acciones. [hijo] va debajo, también en blanco (el
/// saludo de Inicio). Debajo de la cabecera siempre va una [HojaBlanca].
class CabeceraMarca extends StatelessWidget {
  const CabeceraMarca({
    super.key,
    this.titulo,
    this.acciones = const [],
    this.hijo,
    this.esDemo = false,
    this.rellenoInferior = AppSpacing.solapeHoja,
    this.decorado = false,
  });

  final String? titulo;
  final List<Widget> acciones;
  final Widget? hijo;
  final bool esDemo;

  /// Círculos extra (sol y uno oscuro abajo), solo en el encabezado alto de Inicio.
  final bool decorado;

  /// Espacio turquesa bajo el contenido: la hoja blanca se monta sobre él.
  final double rellenoInferior;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final arriba = MediaQuery.paddingOf(context).top;
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.degradadoCabecera),
      child: CustomPaint(
        painter: _CirculosCabecera(decorado: decorado),
        child: Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.margen, arriba, AppSpacing.sm, rellenoInferior),
          child: SobreTurquesa(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sin título ni acciones (Inicio), el contenido de [hijo] ocupa la barra.
                if (titulo != null || acciones.isNotEmpty || esDemo)
                  SizedBox(
                    height: AppSpacing.barraSuperior,
                    child: Row(
                      children: [
                        Expanded(
                          child: titulo == null
                              ? const SizedBox.shrink()
                              : Semantics(
                                  header: true,
                                  child: Text(
                                    titulo!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textos.headlineSmall!.copyWith(color: AppColors.onPrimary),
                                  ),
                                ),
                        ),
                        // Con letra muy grande la etiqueta no entra junto al título.
                        if (esDemo && MediaQuery.textScalerOf(context).scale(1) <= 1.15) ...[
                          const EtiquetaDemo(sobreTurquesa: true),
                          const SizedBox(width: AppSpacing.xs),
                        ],
                        ...acciones,
                      ],
                    ),
                  ),
                if (hijo != null)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.md),
                    child: hijo,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Encabezado de las pantallas de detalle (rediseño): degradado turquesa, botón cuadrado de volver
/// (o de cerrar, en las que se abren como diálogo), título de 24 en 800 y, al pie, el arranque de
/// la hoja crema con esquinas de 26. Va en `Scaffold.appBar`, con el fondo crema del tema.
class BarraAlmira extends StatelessWidget implements PreferredSizeWidget {
  const BarraAlmira({
    super.key,
    required this.titulo,
    this.acciones = const [],
    this.esDemo = false,
    this.cerrar,
    this.alVolver,
    this.conVolver = true,
  });

  final String titulo;
  final List<Widget> acciones;
  final bool esDemo;

  /// Muestra una X en vez de la flecha. Sin valor, la X sale si la pantalla se abrió como diálogo.
  final bool? cerrar;

  /// Qué hace el botón de volver; por defecto, cerrar la pantalla.
  final VoidCallback? alVolver;

  /// false oculta el botón de volver aunque se pueda volver.
  final bool conVolver;

  static const double _fila = 64;

  @override
  Size get preferredSize => const Size.fromHeight(_fila + AppSpacing.sm + AppRadius.hoja);

  @override
  Widget build(BuildContext context) {
    final arriba = MediaQuery.paddingOf(context).top;
    final ruta = ModalRoute.of(context);
    final puedeVolver = conVolver && (alVolver != null || (ruta?.impliesAppBarDismissal ?? false));
    final esCerrar = cerrar ?? (ruta is PageRoute && ruta.fullscreenDialog);
    final textos = Theme.of(context).textTheme;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: barraSobreTurquesa,
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.degradadoCabecera),
        child: CustomPaint(
          painter: const _CirculosCabecera(decorado: false),
          child: SobreTurquesa(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: arriba),
                SizedBox(
                  height: _fila,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: puedeVolver ? AppSpacing.lg : AppSpacing.margen,
                      right: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        if (puedeVolver) ...[
                          BotonCuadro(
                            semantica: esCerrar ? 'Cerrar' : 'Volver',
                            alTocar: alVolver ?? () => Navigator.maybePop(context),
                            child: Icon(esCerrar ? Icons.close_rounded : Phosphor.arrowLeft, size: 22),
                          ),
                          const SizedBox(width: AppSpacing.md),
                        ],
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(
                              titulo,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textos.headlineSmall!.copyWith(color: AppColors.onPrimary),
                            ),
                          ),
                        ),
                        if (esDemo && MediaQuery.textScalerOf(context).scale(1) <= 1.15) ...[
                          const EtiquetaDemo(sobreTurquesa: true),
                          const SizedBox(width: AppSpacing.xs),
                        ],
                        ...acciones,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  height: AppRadius.hoja,
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.hoja)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón cuadrado de 44 con radio de 14, blanco translúcido sobre el degradado.
class BotonCuadro extends StatelessWidget {
  const BotonCuadro({super.key, required this.semantica, required this.alTocar, required this.child, this.fondo});

  final String semantica;
  final VoidCallback alTocar;
  final Widget child;
  final Color? fondo;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: semantica,
    excludeSemantics: true,
    child: Tooltip(
      message: semantica,
      excludeFromSemantics: true,
      child: Presionable(
        child: Material(
          color: fondo ?? Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(AppRadius.caja),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: alTocar,
            child: SizedBox.square(
              dimension: AppSpacing.caja,
              child: Center(child: child),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Círculos suaves del encabezado: uno turquesa claro arriba a la derecha y, en Inicio, uno sol
/// y otro oscuro abajo a la izquierda. Se anclan a la esquina, sea cual sea el alto.
class _CirculosCabecera extends CustomPainter {
  const _CirculosCabecera({required this.decorado});

  final bool decorado;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    final w = size.width;
    canvas.drawCircle(Offset(w - 30, 18), 62, Paint()..color = AppColors.primary500.withValues(alpha: 0.55));
    if (!decorado) return;
    canvas.drawCircle(Offset(w - 58, 104), 16, Paint()..color = AppColors.sol.withValues(alpha: 0.9));
    canvas.drawCircle(const Offset(30, 150), 46, Paint()..color = AppColors.primaryDark.withValues(alpha: 0.55));
  }

  @override
  bool shouldRepaint(_CirculosCabecera old) => old.decorado != decorado;
}

/// Pone [abajo] montado sobre los últimos [solape] px de [arriba]: la hoja crema (o la tarjeta
/// del saldo) sube sobre el encabezado sin dejar un hueco al final.
class Solape extends MultiChildRenderObjectWidget {
  Solape({super.key, required this.solape, required Widget arriba, required Widget abajo})
    : super(children: [arriba, abajo]);

  final double solape;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderSolape(solape);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) =>
      (renderObject as _RenderSolape).solape = solape;
}

class _DatosSolape extends ContainerBoxParentData<RenderBox> {}

class _RenderSolape extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, _DatosSolape>, RenderBoxContainerDefaultsMixin<RenderBox, _DatosSolape> {
  _RenderSolape(this._solape);

  double _solape;
  set solape(double v) {
    if (v == _solape) return;
    _solape = v;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _DatosSolape) child.parentData = _DatosSolape();
  }

  @override
  void performLayout() {
    final arriba = firstChild!;
    final abajo = childAfter(arriba)!;
    final ancho = BoxConstraints.tightFor(width: constraints.maxWidth);
    arriba.layout(ancho, parentUsesSize: true);
    abajo.layout(ancho, parentUsesSize: true);
    final inicio = math.max(0.0, arriba.size.height - _solape);
    (arriba.parentData! as _DatosSolape).offset = Offset.zero;
    (abajo.parentData! as _DatosSolape).offset = Offset(0, inicio);
    size = constraints.constrain(Size(constraints.maxWidth, math.max(arriba.size.height, inicio + abajo.size.height)));
  }

  @override
  void paint(PaintingContext context, Offset offset) => defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

/// Todo lo que va dentro de la cabecera turquesa se dibuja en blanco: texto, íconos y botones.
class SobreTurquesa extends StatelessWidget {
  const SobreTurquesa({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => IconTheme(
    data: const IconThemeData(color: AppColors.onPrimary, size: AppIconos.navegacion),
    child: IconButtonTheme(
      data: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size(AppSpacing.toque, AppSpacing.toque),
        ),
      ),
      child: TextButtonTheme(
        data: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: AppColors.onPrimary)),
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: AppColors.onPrimary),
          child: child,
        ),
      ),
    ),
  );
}

/// Hoja crema con las esquinas superiores de 26, que se monta sobre el encabezado. Dentro de
/// [CuerpoAsync] sube sobre el degradado con [Solape]; sola (en una `Column` debajo de
/// [CabeceraMarca]), pinta detrás de sus esquinas la franja final del degradado.
/// Con [flotante], la tarjeta va arriba sobre el degradado y la hoja no tiene esquinas.
class HojaBlanca extends StatelessWidget {
  const HojaBlanca({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(AppSpacing.margen, AppSpacing.xl, AppSpacing.margen, AppSpacing.xxl),
    this.flotante,
    this.sobreCabecera = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Widget? flotante;

  /// true cuando va sola debajo de [CabeceraMarca]: pinta la franja del degradado detrás de las
  /// esquinas. Con [Solape] no hace falta (el degradado real queda detrás).
  final bool sobreCabecera;

  static const _forma = BorderRadius.vertical(top: Radius.circular(AppRadius.hoja));

  /// Colores del borde inferior del degradado del encabezado, de izquierda a derecha.
  static const _franja = LinearGradient(
    colors: [Color(0xFF0E8986), AppColors.primary, AppColors.primaryDark, AppColors.primaryDark],
    stops: [0, 0.42, 0.8, 1],
  );

  @override
  Widget build(BuildContext context) {
    final flot = flotante;
    if (flot != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margen),
            child: Aparecer(child: TarjetaFlotante(child: flot)),
          ),
          Padding(padding: padding, child: child),
        ],
      );
    }
    final hoja = Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: AppColors.background, borderRadius: _forma),
      padding: padding,
      child: child,
    );
    if (!sobreCabecera) return hoja;
    return Stack(
      children: [
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: AppRadius.hoja,
          child: DecoratedBox(decoration: BoxDecoration(gradient: _franja)),
        ),
        hoja,
      ],
    );
  }
}

/// Tarjeta blanca de radio 22 con sombra suave. Flota sobre el encabezado (saldo de Inicio).
class TarjetaFlotante extends StatelessWidget {
  const TarjetaFlotante({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.margen),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.tarjeta),
      boxShadow: AppColors.sombraCard,
    ),
    child: child,
  );
}

// ---------------------------------------------------------------------------------------
// Insignias, tarjetas y fichas
// ---------------------------------------------------------------------------------------

/// Tonos de estado: turquesa (primario), coral (acento: en curso), lima (éxito), sol (aviso) y
/// rojo (error). Cada uno con su fondo pastel y su texto oscuro (AA).
enum Tono { neutro, primario, acento, exito, aviso, error }

extension ColoresTono on Tono {
  Color get fondo => switch (this) {
    Tono.neutro => AppColors.primary50,
    Tono.primario => AppColors.primary100,
    Tono.acento => AppColors.coral100,
    Tono.exito => AppColors.lima100,
    Tono.aviso => AppColors.sol100,
    Tono.error => AppColors.errorSoft,
  };

  Color get texto => switch (this) {
    Tono.neutro => AppColors.textSecondary,
    Tono.primario => AppColors.primary,
    Tono.acento => AppColors.coralTexto,
    Tono.exito => AppColors.limaTexto,
    Tono.aviso => AppColors.solTexto,
    Tono.error => AppColors.error,
  };
}

/// Estado real en una insignia de 24 («En atención», «Resuelto», «Vencida», «Pagada»). Siempre
/// con texto, y con ícono cuando aclara. Los plazos y fechas no van en insignia: van en texto.
class Insignia extends StatelessWidget {
  const Insignia(this.texto, {super.key, this.tono = Tono.neutro, this.icono, this.fondo});

  final String texto;
  final Tono tono;
  final IconData? icono;

  /// Reemplaza el fondo suave del tono (por ejemplo, blanco sobre la cabecera turquesa).
  final Color? fondo;

  /// Píldora de 26 que crece si el texto del teléfono es más grande: fondo pastel del tono y
  /// texto en su color oscuro. Sin ícono, lleva un punto del mismo color.
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: AppSpacing.altoInsignia),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(color: fondo ?? tono.fondo, borderRadius: BorderRadius.circular(AppRadius.pastilla)),
    // En un espacio muy angosto (letra al doble junto a un monto), el contenido se achica un poco
    // en vez de desbordarse. Con espacio, se ve a su tamaño normal.
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[
            Icon(icono, size: AppIconos.insignia - 2, color: tono.texto),
            const SizedBox(width: 6),
          ] else if (tono != Tono.neutro) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: tono.texto, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(texto, maxLines: 1, style: Theme.of(context).textTheme.labelMedium!.copyWith(color: tono.texto)),
        ],
      ),
    ),
  );
}

/// Marca visible del modo demostración: los datos que se ven no son oficiales. Sobre la
/// cabecera turquesa ([sobreTurquesa]) va en blanco con el texto ámbar, para que se lea (AA).
class EtiquetaDemo extends StatelessWidget {
  const EtiquetaDemo({super.key, this.sobreTurquesa = false});

  final bool sobreTurquesa;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Modo demostración: datos de ejemplo',
    child: ExcludeSemantics(
      child: sobreTurquesa ? const _DemoSobreTurquesa() : const Insignia('Demostración', tono: Tono.aviso),
    ),
  );
}

/// «● Demostración» sobre el degradado: píldora blanca translúcida con un punto sol.
class _DemoSobreTurquesa extends StatelessWidget {
  const _DemoSobreTurquesa();

  @override
  Widget build(BuildContext context) => Container(
    height: AppSpacing.altoInsignia + 4,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(AppRadius.pastilla),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(color: AppColors.sol, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text('Demostración', style: Theme.of(context).textTheme.labelMedium!.copyWith(color: AppColors.onPrimary)),
      ],
    ),
  );
}

/// Línea de plazo o vencimiento, en texto de 13: «Vence el 30 de noviembre», «Respuesta hasta
/// el 27 de noviembre». Solo cuando ya venció va en rojo de estado.
class TextoPlazo extends StatelessWidget {
  const TextoPlazo(this.texto, {super.key, this.vencido = false});

  final String texto;
  final bool vencido;

  @override
  Widget build(BuildContext context) => Text(
    texto,
    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
      color: vencido ? AppColors.error : AppColors.textSecondary,
      fontWeight: vencido ? FontWeight.w500 : FontWeight.w400,
    ),
  );
}

/// Tarjeta blanca de radio 22 con sombra suave sobre el fondo crema. Para agrupar; nunca una
/// tarjeta dentro de otra. Con [conBorde] en false va plana (sin sombra).
class Tarjeta extends StatelessWidget {
  const Tarjeta({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.color = AppColors.surface,
    this.conBorde = true,
    this.semantica,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color color;
  final bool conBorde;
  final String? semantica;

  @override
  Widget build(BuildContext context) {
    final radio = BorderRadius.circular(AppRadius.tarjeta);
    final material = Material(
      color: color,
      borderRadius: radio,
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? Padding(padding: padding, child: child)
          : Semantics(
              button: true,
              label: semantica,
              child: InkWell(
                onTap: onTap,
                child: Padding(padding: padding, child: child),
              ),
            ),
    );
    final caja = DecoratedBox(
      decoration: BoxDecoration(borderRadius: radio, boxShadow: conBorde ? AppColors.sombraCard : null),
      child: material,
    );
    return onTap == null ? caja : Presionable(child: caja);
  }
}

/// Bloque Destacado: fondo turquesa claro, radio de 16 y relleno de 20. Máximo uno por
/// pantalla, para lo más importante de esa pantalla.
class Destacado extends StatelessWidget {
  const Destacado({super.key, required this.child, this.padding = const EdgeInsets.all(AppSpacing.margen)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(AppRadius.destacado)),
    child: child,
  );
}

/// Caja de ícono del rediseño (IconTile): ícono de línea en tinta, sin manchas de color, sobre
/// un fondo pastel redondeado (turquesa, sol, coral o lima según [color]). Radio de 14 en 44,
/// 16 en 48-52 y 20 en 58. [circulo] se conserva por compatibilidad y ya no cambia la forma.
class IconoColor extends StatelessWidget {
  const IconoColor(
    IconData this.icono, {
    super.key,
    this.color = AppColors.primary,
    this.lado = AppSpacing.caja,
    this.circulo = false,
  }) : svg = null;

  /// Con uno de los íconos propios del rediseño.
  const IconoColor.svg(IconoA this.svg, {super.key, this.color = AppColors.primary, this.lado = AppSpacing.caja})
    : icono = null,
      circulo = false;

  final IconData? icono;
  final IconoA? svg;
  final Color color;
  final double lado;
  final bool circulo;

  @override
  Widget build(BuildContext context) {
    final radio = lado >= 58 ? AppRadius.cajaGrande : (lado >= 48 ? AppRadius.cajaMediana : AppRadius.caja);
    final tamano = lado >= 58 ? 26.0 : (lado >= 48 ? 24.0 : 22.0);
    return ExcludeSemantics(
      child: Container(
        width: lado,
        height: lado,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: AppColors.fondoPastel(color), borderRadius: BorderRadius.circular(radio)),
        child: svg != null
            ? IconoAlmira(svg!, tamano: tamano, color: AppColors.textPrimary)
            : Icon(icono, size: tamano, color: AppColors.textPrimary),
      ),
    );
  }
}

/// Ícono en tinta dentro de una caja pastel del tono (turquesa muy claro si es neutro).
class CajaIcono extends StatelessWidget {
  const CajaIcono(this.icono, {super.key, this.tono = Tono.primario, this.lado = AppSpacing.caja});

  final IconData icono;
  final Tono tono;
  final double lado;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: lado,
      height: lado,
      decoration: BoxDecoration(
        color: tono == Tono.neutro ? AppColors.primary50 : tono.fondo,
        borderRadius: BorderRadius.circular(lado >= 48 ? AppRadius.cajaMediana : AppRadius.caja),
      ),
      child: Icon(
        icono,
        size: lado >= AppSpacing.cajaGrande ? AppIconos.vacio : AppIconos.caja - 2,
        color: tono == Tono.error ? AppColors.error : AppColors.textPrimary,
      ),
    );
  }
}

/// Acceso rápido de Inicio: círculo turquesa claro con el ícono turquesa y una etiqueta de
/// hasta dos líneas, centrada. Toda la columna es táctil.
class Acceso extends StatelessWidget {
  const Acceso({
    super.key,
    required this.icono,
    required this.texto,
    required this.alTocar,
    this.color = AppColors.primary,
    this.svg,
  });

  final IconData icono;

  /// Ícono propio del rediseño; si está, reemplaza a [icono].
  final IconoA? svg;
  final Color color;
  final String texto;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme.labelMedium!.copyWith(height: 1.25);
    return Semantics(
      button: true,
      label: texto,
      child: ExcludeSemantics(
        child: Presionable(
          child: InkWell(
            onTap: alTocar,
            borderRadius: BorderRadius.circular(AppRadius.campo),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (svg != null)
                    IconoColor.svg(svg!, color: color, lado: AppSpacing.acceso)
                  else
                    IconoColor(icono, color: color, lado: AppSpacing.acceso),
                  const SizedBox(height: AppSpacing.sm),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                    // Una sola palabra («Cuponera») se achica antes que partirse a la mitad; varias
                    // palabras van en hasta dos líneas.
                    child: texto.contains(' ')
                        ? Text(
                            texto,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: estilo,
                          )
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(texto, maxLines: 1, style: estilo),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Título de sección (20) con una acción opcional a la derecha.
class TituloSeccion extends StatelessWidget {
  const TituloSeccion(this.texto, {super.key, this.accion});

  final String texto;
  final Widget? accion;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Semantics(header: true, child: Text(texto, style: Theme.of(context).textTheme.titleLarge)),
      ),
      ?accion,
    ],
  );
}

/// Rótulo de grupo en gris y tipo oración («Cuenta y predio»).
class RotuloSeccion extends StatelessWidget {
  const RotuloSeccion(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) => Semantics(header: true, child: Text(texto, style: estiloRotulo(context)));
}

/// Rótulo de un grupo de filas del rediseño («CUENTA Y PREDIO»): 12 en 800, gris, en
/// mayúsculas con algo de aire. Lectores de pantalla lo leen en tipo oración.
class RotuloGrupo extends StatelessWidget {
  const RotuloGrupo(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    label: texto,
    excludeSemantics: true,
    child: Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
      child: Text(
        texto.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium!
            .copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w800, letterSpacing: 0.7),
      ),
    ),
  );
}

/// Grupo de filas dentro de una tarjeta blanca, con una línea fina entre ellas.
class GrupoTarjeta extends StatelessWidget {
  const GrupoTarjeta({super.key, required this.filas, this.padding});

  final List<Widget> filas;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Tarjeta(
    padding: padding ?? const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, fila) in filas.indexed) ...[if (i > 0) const Divider(), fila],
      ],
    ),
  );
}

/// Ficha de un dato: rótulo pequeño en gris arriba y el valor debajo, a todo el ancho. Para
/// textos (fechas, direcciones, nombres), no para montos: esos van en [FilaDato].
class Ficha extends StatelessWidget {
  const Ficha(this.rotulo, this.valor, {super.key});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rotulo, style: estiloRotulo(context)),
          const SizedBox(height: 2),
          Text(valor, style: textos.bodyLarge),
        ],
      ),
    );
  }
}

/// "Etiqueta ........ monto": solo para montos, que van a la derecha en 500 y cifras tabulares.
/// [destacado] es la fila Total: etiqueta de 15 y monto de 20 en negrita.
class FilaDato extends StatelessWidget {
  const FilaDato(this.etiqueta, this.valor, {super.key, this.destacado = false});

  final String etiqueta;
  final String valor;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              etiqueta,
              style: destacado ? textos.bodyLarge!.copyWith(fontWeight: FontWeight.w500) : textos.bodyMedium,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // El monto va pegado al borde derecho, alineado con los de las demás filas.
          Flexible(
            child: Align(
              alignment: Alignment.topRight,
              child: Text(
                valor,
                textAlign: TextAlign.end,
                style: (destacado ? textos.titleLarge : textos.bodyLarge)!.copyWith(
                  fontWeight: destacado ? FontWeight.w700 : FontWeight.w500,
                  fontFeatures: cifrasTabulares,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila de lista: nombre a la izquierda en 15/500, línea secundaria en gris de 13, el monto
/// a la derecha y la flecha. Mínimo 56 de alto. Entre filas va un [Divider].
class FilaLista extends StatelessWidget {
  const FilaLista({
    super.key,
    required this.titulo,
    this.detalle,
    this.monto,
    this.inicio,
    this.final_,
    this.alTocar,
    this.semantica,
    this.padding = const EdgeInsets.symmetric(vertical: AppSpacing.md),
  });

  final String titulo;

  /// Línea secundaria, o varias líneas si se pasa un widget en [detalle].
  final Widget? detalle;
  final String? monto;
  final Widget? inicio;

  /// Reemplaza la flecha.
  final Widget? final_;
  final VoidCallback? alTocar;
  final String? semantica;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final fila = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSpacing.cajaGrande),
      child: Padding(
        padding: padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (inicio != null) ...[inicio!, const SizedBox(width: AppSpacing.md)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(titulo, style: textos.titleMedium),
                  if (detalle != null) ...[const SizedBox(height: 2), detalle!],
                ],
              ),
            ),
            if (monto != null) ...[
              const SizedBox(width: AppSpacing.md),
              Text(
                monto!,
                textAlign: TextAlign.end,
                style: textos.titleMedium!.copyWith(fontFeatures: cifrasTabulares),
              ),
            ],
            if (alTocar != null || final_ != null) ...[
              const SizedBox(width: AppSpacing.sm),
              final_ ?? const Icon(Phosphor.caretRight, size: AppIconos.lista, color: AppColors.textSecondary),
            ],
          ],
        ),
      ),
    );
    if (alTocar == null) return fila;
    return Semantics(
      button: true,
      label: semantica,
      child: InkWell(onTap: alTocar, child: fila),
    );
  }
}

/// Fila táctil con ícono, título, detalle opcional y flecha. Mínimo 56 de alto. Para agrupar
/// varias, van separadas con [Divider].
class FilaAccion extends StatelessWidget {
  const FilaAccion({super.key, required this.titulo, required this.alTocar, this.icono, this.detalle, this.final_});

  final String titulo;
  final VoidCallback? alTocar;
  final IconData? icono;
  final String? detalle;

  /// Reemplaza la flecha (por ejemplo, una insignia).
  final Widget? final_;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return InkWell(
      onTap: alTocar,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.cajaGrande),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            children: [
              if (icono != null) ...[IconoColor(icono!), const SizedBox(width: AppSpacing.md)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(titulo, style: textos.titleMedium),
                    if (detalle != null) Text(detalle!, style: textos.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              final_ ?? const Icon(Phosphor.caretRight, size: AppIconos.lista, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nota breve dentro de una pantalla. En tono neutro va sin fondo: ícono de 20 y texto
/// gris. Error, aviso y éxito llevan su fondo suave.
class Aviso extends StatelessWidget {
  const Aviso(this.texto, {super.key, this.tono = Tono.neutro, this.icono, this.accion});

  final String texto;
  final Tono tono;
  final IconData? icono;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final neutro = tono == Tono.neutro;
    return Semantics(
      liveRegion: tono == Tono.error,
      child: Container(
        padding: neutro ? EdgeInsets.zero : const EdgeInsets.all(AppSpacing.md),
        decoration: neutro
            ? null
            : BoxDecoration(color: tono.fondo, borderRadius: BorderRadius.circular(AppRadius.campo)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icono ??
                  switch (tono) {
                    Tono.error => Phosphor.warningCircle,
                    Tono.aviso => Phosphor.warning,
                    Tono.exito => Phosphor.checkCircle,
                    _ => Phosphor.info,
                  },
              size: AppIconos.lista,
              color: tono.texto,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    texto,
                    style: Theme.of(context).textTheme.bodyLarge!
                        .copyWith(color: neutro ? AppColors.textSecondary : tono.texto),
                  ),
                  if (accion != null) ...[const SizedBox(height: AppSpacing.sm), accion!],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estado vacío: qué pasa y, si corresponde, qué hacer después.
class VistaVacia extends StatelessWidget {
  const VistaVacia({
    super.key,
    required this.icono,
    required this.titulo,
    this.detalle,
    this.accion,
    this.alTocar,
    this.ilustracion,
  });

  final IconData icono;

  /// Ilustración del rediseño en lugar de la caja con el ícono.
  final Ilustracion? ilustracion;
  final String titulo;
  final String? detalle;
  final String? accion;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl, horizontal: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ilustracion != null)
            Rebote(child: ImagenIlustracion(ilustracion!, alto: 140))
          else
            CajaIcono(icono, lado: AppSpacing.cajaGrande, tono: Tono.neutro),
          const SizedBox(height: AppSpacing.lg),
          Text(titulo, style: textos.titleLarge, textAlign: TextAlign.center),
          if (detalle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(detalle!, style: textos.bodyMedium, textAlign: TextAlign.center),
          ],
          if (accion != null && alTocar != null) ...[
            const SizedBox(height: AppSpacing.xl),
            FilledButton(onPressed: alTocar, child: Text(accion!)),
          ],
        ],
      ),
    );
  }
}

/// Error recuperable: distingue la falta de internet de un fallo del servicio.
class VistaError extends StatelessWidget {
  const VistaError(this.error, {super.key, this.alReintentar});

  final Object error;
  final VoidCallback? alReintentar;

  @override
  Widget build(BuildContext context) {
    final e = ErrorApp.de(error);
    return VistaVacia(
      icono: e.sinConexion ? Phosphor.wifiSlash : Phosphor.cloudSlash,
      titulo: e.titulo,
      detalle: e.detalle,
      accion: alReintentar == null ? null : 'Reintentar',
      alTocar: alReintentar,
    );
  }
}

/// Carga con esqueletos: bloques grises que laten suavemente con la forma de lo que va a
/// aparecer. Con «reducir movimiento» quedan quietos.
class VistaCargando extends StatefulWidget {
  const VistaCargando({super.key, this.texto = 'Cargando'});

  final String texto;

  @override
  State<VistaCargando> createState() => _VistaCargandoState();
}

class _VistaCargandoState extends State<VistaCargando> with SingleTickerProviderStateMixin {
  late final AnimationController _pulso = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _pulso.dispose();
    super.dispose();
  }

  Widget _bloque(double alto, {double? ancho, double radio = AppRadius.campo}) => Container(
    width: ancho,
    height: alto,
    decoration: BoxDecoration(color: AppColors.track, borderRadius: BorderRadius.circular(radio)),
  );

  @override
  Widget build(BuildContext context) {
    final quieto = MediaQuery.maybeDisableAnimationsOf(context) == true;
    return Semantics(
      label: widget.texto,
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _pulso,
          builder: (context, hijo) => Opacity(opacity: quieto ? 0.7 : 0.45 + 0.4 * _pulso.value, child: hijo),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bloque(132, radio: AppRadius.destacado),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(child: _bloque(64, radio: AppRadius.tarjeta)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: _bloque(64, radio: AppRadius.tarjeta)),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              _bloque(16, ancho: 120),
              const SizedBox(height: AppSpacing.md),
              _bloque(76, radio: AppRadius.tarjeta),
              const SizedBox(height: AppSpacing.sm),
              _bloque(76, radio: AppRadius.tarjeta),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cuerpo de una pantalla conectada a datos: carga, error con reintento o
/// contenido. Al recargar conserva lo que ya se veía, sin parpadeos.
///
/// Con [cabecera], la pantalla es una pestaña raíz: la cabecera turquesa va primero y el
/// contenido dentro de una [HojaBlanca], todo en un mismo desplazamiento. [flotante] es la
/// tarjeta que queda a caballo entre la cabecera y la hoja (solo cuando hay datos).
class CuerpoAsync<T> extends StatelessWidget {
  const CuerpoAsync({
    super.key,
    required this.valor,
    required this.alRecargar,
    required this.construir,
    this.cabecera,
    this.flotante,
  });

  final AsyncValue<T> valor;
  final Future<void> Function() alRecargar;
  final List<Widget> Function(T datos) construir;
  final Widget Function(T? datos)? cabecera;
  final Widget? Function(T datos)? flotante;

  @override
  Widget build(BuildContext context) {
    final datos = valor.valueOrNull;
    final List<Widget> hijos;
    if (valor.hasError && !valor.isLoading) {
      // No se muestra un "S/ 0.00" ni una lista vacía como si fuera un dato.
      hijos = [VistaError(valor.error!, alReintentar: alRecargar)];
    } else if (datos == null) {
      hijos = const [VistaCargando()];
    } else {
      hijos = construir(datos);
    }
    final progreso = AnimatedSize(
      duration: duracionDe(context),
      alignment: Alignment.topCenter,
      child: valor.isLoading && datos != null
          ? const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: LinearProgressIndicator(minHeight: 2),
            )
          : const SizedBox(width: double.infinity),
    );
    final encabezado = cabecera;
    final lista = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: encabezado == null
          ? const EdgeInsets.fromLTRB(AppSpacing.margen, AppSpacing.xl, AppSpacing.margen, AppSpacing.xxl)
          : EdgeInsets.zero,
      children: encabezado == null
          ? [progreso, ...hijos]
          : [
              Builder(
                builder: (context) {
                  final flot = datos == null ? null : flotante?.call(datos);
                  return Solape(
                    solape: flot == null ? AppSpacing.solapeHoja : AppSpacing.solapeInicio,
                    arriba: encabezado(datos),
                    abajo: HojaBlanca(
                      sobreCabecera: false,
                      flotante: flot,
                      padding: flot == null
                          ? const EdgeInsets.fromLTRB(
                              AppSpacing.margen,
                              AppSpacing.xl,
                              AppSpacing.margen,
                              AppSpacing.xxl,
                            )
                          : const EdgeInsets.fromLTRB(
                              AppSpacing.margen,
                              AppSpacing.margen,
                              AppSpacing.margen,
                              AppSpacing.xxl,
                            ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [progreso, ...hijos]),
                    ),
                  );
                },
              ),
            ],
    );
    return RefreshIndicator(
      onRefresh: alRecargar,
      color: AppColors.primary,
      // El fondo crema sigue hasta el final aunque el contenido sea corto.
      child: ColoredBox(color: AppColors.background, child: lista),
    );
  }
}

/// Campo con su rótulo encima (14, peso 700), como en el rediseño: el campo lleva solo el
/// ejemplo dentro. El rótulo también es la etiqueta del campo para lectores de pantalla.
class CampoConRotulo extends StatelessWidget {
  const CampoConRotulo({super.key, required this.rotulo, required this.campo});

  final String rotulo;
  final Widget campo;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      ExcludeSemantics(child: Text(rotulo, style: Theme.of(context).textTheme.titleSmall!.copyWith(fontSize: 14))),
      const SizedBox(height: AppSpacing.sm),
      Semantics(label: rotulo, child: campo),
    ],
  );
}

/// Monto grande del rediseño: «S/» a la mitad del tamaño, la parte entera grande y los decimales
/// al 55 %, en 800 con tracking negativo. Ejemplo: `S/` `120` `.50`.
class Monto extends StatelessWidget {
  const Monto(this.valor, {super.key, this.tamano = 44, this.color = AppColors.textPrimary});

  final double valor;
  final double tamano;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final centimos = (valor * 100).round();
    final entero = centimos ~/ 100;
    final decimales = (centimos % 100).toString().padLeft(2, '0');
    final miles = entero.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
    final base = TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontWeight: FontWeight.w800,
      color: color,
      height: 1,
      letterSpacing: -0.03 * tamano,
      fontFeatures: cifrasTabulares,
    );
    return Semantics(
      label: 'S/ $miles.$decimales',
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'S/ ',
              style: base.copyWith(fontSize: tamano * 0.5, letterSpacing: 0),
            ),
            TextSpan(
              text: miles,
              style: base.copyWith(fontSize: tamano),
            ),
            TextSpan(
              text: '.$decimales',
              style: base.copyWith(fontSize: tamano * 0.55),
            ),
          ],
        ),
        maxLines: 1,
      ),
    );
  }
}

/// Separación vertical estándar entre bloques.
const espacio = SizedBox(height: AppSpacing.lg);
const espacioChico = SizedBox(height: AppSpacing.sm);
const espacioGrande = SizedBox(height: AppSpacing.xl);
const espacioSeccion = SizedBox(height: AppSpacing.xxxl);

void mostrarMensaje(BuildContext context, String texto) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(texto)));
}
