import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/iconos.dart';
import '../errors/error_app.dart';

/// Duración de las microanimaciones. Con «reducir movimiento» activado en el
/// sistema, no se anima.
Duration duracionDe(BuildContext context, [int ms = 200]) =>
    MediaQuery.maybeDisableAnimationsOf(context) == true
        ? Duration.zero
        : Duration(milliseconds: ms);

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
              Text(
                'Almira',
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(color: AppColors.onPrimary),
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
// ---------------------------------------------------------------------------------------

/// Bloque superior turquesa de las pestañas raíz. Empieza detrás de la barra de estado; lleva
/// el logo en blanco y el título a la izquierda y las acciones a la derecha. [hijo] va debajo,
/// también en blanco (el saludo de Inicio, el total de Pagar). Debajo de la cabecera siempre
/// va una [HojaBlanca].
class CabeceraMarca extends StatelessWidget {
  const CabeceraMarca({
    super.key,
    required this.titulo,
    this.acciones = const [],
    this.hijo,
    this.esDemo = false,
    this.rellenoInferior = AppSpacing.solapeHoja + AppSpacing.lg,
  });

  final String titulo;
  final List<Widget> acciones;
  final Widget? hijo;
  final bool esDemo;

  /// Espacio turquesa bajo el contenido: la hoja blanca se monta sobre él.
  final double rellenoInferior;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final arriba = MediaQuery.paddingOf(context).top;
    return ColoredBox(
      color: AppColors.primary,
      child: Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.margen, arriba, AppSpacing.sm, rellenoInferior),
        child: SobreTurquesa(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: AppSpacing.barraSuperior,
                child: Row(
                  children: [
                    const LogoAlmira(lado: AppSpacing.logoCabecera, blanco: true),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          titulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textos.titleLarge!.copyWith(color: AppColors.onPrimary),
                        ),
                      ),
                    ),
                    // Con letra muy grande la etiqueta no entra junto al título.
                    if (esDemo && MediaQuery.textScalerOf(context).scale(1) <= 1.15) ...[
                      const EtiquetaDemo(),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    ...acciones,
                  ],
                ),
              ),
              if (hijo != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm, right: AppSpacing.md),
                  child: hijo,
                ),
            ],
          ),
        ),
      ),
    );
  }
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
            data: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.onPrimary),
            ),
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: AppColors.onPrimary),
              child: child,
            ),
          ),
        ),
      );
}

/// Hoja blanca con las esquinas superiores redondeadas, que se monta sobre el color de la
/// cabecera. Con [flotante], esa tarjeta queda a caballo entre el color y la hoja, con una
/// sombra muy suave: la hoja empieza a la mitad de su altura.
class HojaBlanca extends StatelessWidget {
  const HojaBlanca({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.margen,
      AppSpacing.xl,
      AppSpacing.margen,
      AppSpacing.xxl,
    ),
    this.flotante,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Widget? flotante;

  static const _forma = BorderRadius.vertical(top: Radius.circular(AppRadius.hoja));

  @override
  Widget build(BuildContext context) {
    if (flotante == null) {
      return Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(color: AppColors.surface, borderRadius: _forma),
        padding: padding,
        child: child,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            // Fondo de la unión: turquesa en la mitad de arriba, hoja blanca desde la mitad.
            const Positioned.fill(
              child: Column(
                children: [
                  Expanded(child: ColoredBox(color: AppColors.primary)),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: _forma),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margen),
              child: TarjetaFlotante(child: flotante!),
            ),
          ],
        ),
        Container(width: double.infinity, color: AppColors.surface, padding: padding, child: child),
      ],
    );
  }
}

/// Tarjeta blanca de radio 16 con la única sombra de la app, muy suave. Flota sobre la unión
/// entre la cabecera y la hoja.
class TarjetaFlotante extends StatelessWidget {
  const TarjetaFlotante({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.margen),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.destacado),
          boxShadow: const [
            BoxShadow(color: AppColors.sombraTarjeta, blurRadius: 16, offset: Offset(0, 6)),
          ],
        ),
        child: child,
      );
}

// ---------------------------------------------------------------------------------------
// Insignias, tarjetas y fichas
// ---------------------------------------------------------------------------------------

enum Tono { neutro, primario, exito, aviso, error }

extension ColoresTono on Tono {
  Color get fondo => switch (this) {
        Tono.neutro => AppColors.surfaceSubtle,
        Tono.primario => AppColors.primarySoft,
        Tono.exito => AppColors.successSoft,
        Tono.aviso => AppColors.warningSoft,
        Tono.error => AppColors.errorSoft,
      };

  Color get texto => switch (this) {
        Tono.neutro => AppColors.textSecondary,
        Tono.primario => AppColors.primaryDark,
        Tono.exito => AppColors.success,
        Tono.aviso => AppColors.warning,
        Tono.error => AppColors.error,
      };
}

/// Estado real en una insignia de 24 («En atención», «Resuelto», «Vencida», «Pagada»). Siempre
/// con texto, y con ícono cuando aclara. Los plazos y fechas no van en insignia: van en texto.
class Insignia extends StatelessWidget {
  const Insignia(this.texto, {super.key, this.tono = Tono.neutro, this.icono});

  final String texto;
  final Tono tono;
  final IconData? icono;

  /// Crece si el texto del teléfono es más grande. Fondo del color de estado al 12 % y
  /// texto e ícono en su tono oscuro.
  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: AppSpacing.altoInsignia),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
        decoration: BoxDecoration(
          color: tono == Tono.neutro
              ? AppColors.surfaceSubtle
              : tono.texto.withValues(alpha: AppColors.alfaFondoInsignia),
          borderRadius: BorderRadius.circular(AppRadius.insignia),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icono != null) ...[
              Icon(icono, size: AppIconos.insignia, color: tono.texto),
              const SizedBox(width: AppSpacing.xs),
            ],
            Flexible(
              child: Text(
                texto,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium!.copyWith(color: tono.texto),
              ),
            ),
          ],
        ),
      );
}

/// Marca visible del modo demostración: los datos que se ven no son oficiales.
class EtiquetaDemo extends StatelessWidget {
  const EtiquetaDemo({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Modo demostración: datos de ejemplo',
        child: ExcludeSemantics(child: const Insignia('Demostración', tono: Tono.aviso)),
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

/// Tarjeta blanca y ligera: borde de 1 px, radio de 12, sin sombra. Para agrupar; nunca una
/// tarjeta dentro de otra.
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
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.tarjeta),
      side: conBorde ? const BorderSide(color: AppColors.border) : BorderSide.none,
    );
    return Material(
      color: color,
      shape: forma,
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
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(AppRadius.destacado),
        ),
        child: child,
      );
}

/// Ícono dentro de un cuadrado de 40 con radio de 10. Neutro y primario van sobre gris claro
/// con el ícono turquesa; los tonos de estado, sobre su fondo suave.
class CajaIcono extends StatelessWidget {
  const CajaIcono(this.icono, {super.key, this.tono = Tono.primario, this.lado = AppSpacing.caja});

  final IconData icono;
  final Tono tono;
  final double lado;

  @override
  Widget build(BuildContext context) {
    final sobreGris = tono == Tono.primario || tono == Tono.neutro;
    return Container(
      width: lado,
      height: lado,
      decoration: BoxDecoration(
        color: sobreGris ? AppColors.surfaceSubtle : tono.fondo,
        borderRadius: BorderRadius.circular(AppRadius.caja),
      ),
      child: Icon(
        icono,
        size: lado >= AppSpacing.cajaGrande ? AppIconos.vacio : AppIconos.caja,
        color: tono == Tono.primario ? AppColors.primary : tono.texto,
      ),
    );
  }
}

/// Acceso rápido de Inicio: círculo turquesa claro con el ícono turquesa y una etiqueta de
/// hasta dos líneas, centrada. Toda la columna es táctil.
class Acceso extends StatelessWidget {
  const Acceso({super.key, required this.icono, required this.texto, required this.alTocar});

  final IconData icono;
  final String texto;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: texto,
        child: ExcludeSemantics(
          child: InkWell(
            onTap: alTocar,
            borderRadius: BorderRadius.circular(AppRadius.campo),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: AppSpacing.acceso,
                    height: AppSpacing.acceso,
                    decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
                    child: Icon(icono, size: AppIconos.caja, color: AppColors.primary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    texto,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
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
            child: Semantics(
              header: true,
              child: Text(texto, style: Theme.of(context).textTheme.titleLarge),
            ),
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
  Widget build(BuildContext context) => Semantics(
        header: true,
        child: Text(texto, style: estiloRotulo(context)),
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
          Flexible(
            child: Text(
              valor,
              textAlign: TextAlign.end,
              style: (destacado ? textos.titleLarge : textos.bodyLarge)!.copyWith(
                fontWeight: destacado ? FontWeight.w700 : FontWeight.w500,
                fontFeatures: cifrasTabulares,
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
  const FilaAccion({
    super.key,
    required this.titulo,
    required this.alTocar,
    this.icono,
    this.detalle,
    this.final_,
  });

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
              if (icono != null) ...[
                Icon(icono, size: AppIconos.caja, color: AppColors.primary),
                const SizedBox(width: AppSpacing.md),
              ],
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
              final_ ??
                  const Icon(Phosphor.caretRight, size: AppIconos.lista, color: AppColors.textSecondary),
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
            : BoxDecoration(
                color: tono.fondo,
                borderRadius: BorderRadius.circular(AppRadius.campo),
              ),
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
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: neutro ? AppColors.textSecondary : tono.texto,
                        ),
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
  });

  final IconData icono;
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
          CajaIcono(icono, lado: AppSpacing.cajaGrande, tono: Tono.neutro),
          const SizedBox(height: AppSpacing.lg),
          Text(titulo, style: textos.titleMedium!.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.center),
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
  late final AnimationController _pulso =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);

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
              encabezado(datos),
              HojaBlanca(
                flotante: datos == null ? null : flotante?.call(datos),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [progreso, ...hijos],
                ),
              ),
            ],
    );
    return RefreshIndicator(
      onRefresh: alRecargar,
      color: AppColors.primary,
      // La hoja blanca sigue hasta el final aunque el contenido sea corto.
      child: encabezado == null ? lista : ColoredBox(color: AppColors.surface, child: lista),
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
