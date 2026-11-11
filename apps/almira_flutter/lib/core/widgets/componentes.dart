import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../errors/error_app.dart';

/// Duración de las microanimaciones. Con «reducir movimiento» activado en el
/// sistema, no se anima.
Duration duracionDe(BuildContext context, [int ms = 200]) =>
    MediaQuery.maybeDisableAnimationsOf(context) == true
        ? Duration.zero
        : Duration(milliseconds: ms);

class LogoAlmira extends StatelessWidget {
  const LogoAlmira({super.key, this.lado = 72});

  final double lado;

  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/logo_almira.png',
        width: lado,
        height: lado,
        fit: BoxFit.contain,
        semanticLabel: 'Almira',
        filterQuality: FilterQuality.medium,
      );
}

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

/// Estado en una pastilla: siempre con texto, y con ícono cuando aclara.
/// Nunca depende solo del color.
class Insignia extends StatelessWidget {
  const Insignia(this.texto, {super.key, this.tono = Tono.neutro, this.icono});

  final String texto;
  final Tono tono;
  final IconData? icono;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: tono.fondo,
          borderRadius: BorderRadius.circular(AppRadius.pastilla),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icono != null) ...[
              Icon(icono, size: 14, color: tono.texto),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                texto,
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      color: tono.texto,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      );
}

/// Marca visible del modo demostración: los datos que se ven no son oficiales.
class EtiquetaDemo extends StatelessWidget {
  const EtiquetaDemo({super.key, this.sobreTurquesa = false});

  final bool sobreTurquesa;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Modo demostración: datos de ejemplo',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: sobreTurquesa ? Colors.white.withValues(alpha: 0.18) : AppColors.warningSoft,
            borderRadius: BorderRadius.circular(AppRadius.pastilla),
          ),
          child: ExcludeSemantics(
            child: Text(
              'Demostración',
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: sobreTurquesa ? Colors.white : AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ),
      );
}

/// Tarjeta blanca y ligera: borde tenue, sin sombra.
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

/// Ícono dentro de un círculo suave.
class CajaIcono extends StatelessWidget {
  const CajaIcono(this.icono, {super.key, this.tono = Tono.primario, this.lado = 40});

  final IconData icono;
  final Tono tono;
  final double lado;

  @override
  Widget build(BuildContext context) => Container(
        width: lado,
        height: lado,
        decoration: BoxDecoration(color: tono.fondo, shape: BoxShape.circle),
        child: Icon(icono, size: lado * 0.5, color: tono.texto),
      );
}

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
              child: Text(texto, style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
          ?accion,
        ],
      );
}

/// "Etiqueta ........ valor", con el valor a la derecha.
class FilaDato extends StatelessWidget {
  const FilaDato(this.etiqueta, this.valor, {super.key, this.destacado = false});

  final String etiqueta;
  final String valor;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(etiqueta, style: destacado ? textos.titleMedium : textos.bodyMedium),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              valor,
              textAlign: TextAlign.end,
              style: (destacado ? textos.titleMedium : textos.bodyLarge)!.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Nota breve dentro de una pantalla (información, advertencia o error).
class Aviso extends StatelessWidget {
  const Aviso(this.texto, {super.key, this.tono = Tono.neutro, this.icono, this.accion});

  final String texto;
  final Tono tono;
  final IconData? icono;
  final Widget? accion;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: tono == Tono.error,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: tono.fondo,
            borderRadius: BorderRadius.circular(AppRadius.campo),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icono ??
                    switch (tono) {
                      Tono.error => Icons.error_outline_rounded,
                      Tono.aviso => Icons.warning_amber_rounded,
                      Tono.exito => Icons.check_circle_outline_rounded,
                      _ => Icons.info_outline_rounded,
                    },
                size: 20,
                color: tono.texto,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      texto,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: tono == Tono.neutro ? AppColors.textSecondary : tono.texto,
                          ),
                    ),
                    ?accion,
                  ],
                ),
              ),
            ],
          ),
        ),
      );
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
          CajaIcono(icono, lado: 64, tono: Tono.neutro),
          const SizedBox(height: AppSpacing.lg),
          Text(titulo, style: textos.titleMedium, textAlign: TextAlign.center),
          if (detalle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(detalle!, style: textos.bodyMedium, textAlign: TextAlign.center),
          ],
          if (accion != null && alTocar != null) ...[
            const SizedBox(height: AppSpacing.lg),
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
      icono: e.sinConexion ? Icons.wifi_off_rounded : Icons.cloud_off_rounded,
      titulo: e.titulo,
      detalle: e.detalle,
      accion: alReintentar == null ? null : 'Reintentar',
      alTocar: alReintentar,
    );
  }
}

class VistaCargando extends StatelessWidget {
  const VistaCargando({super.key, this.texto = 'Cargando'});

  final String texto;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Semantics(
            label: texto,
            child: const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ),
        ),
      );
}

/// Cuerpo de una pantalla conectada a datos: carga, error con reintento o
/// contenido. Al recargar conserva lo que ya se veía, sin parpadeos.
class CuerpoAsync<T> extends StatelessWidget {
  const CuerpoAsync({
    super.key,
    required this.valor,
    required this.alRecargar,
    required this.construir,
  });

  final AsyncValue<T> valor;
  final Future<void> Function() alRecargar;
  final List<Widget> Function(T datos) construir;

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
    return RefreshIndicator(
      onRefresh: alRecargar,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.margen,
          AppSpacing.lg,
          AppSpacing.margen,
          AppSpacing.xl,
        ),
        children: [
          AnimatedSize(
            duration: duracionDe(context),
            alignment: Alignment.topCenter,
            child: valor.isLoading && datos != null
                ? const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                    child: LinearProgressIndicator(minHeight: 2),
                  )
                : const SizedBox(width: double.infinity),
          ),
          ...hijos,
        ],
      ),
    );
  }
}

/// Separación vertical estándar entre bloques.
const espacio = SizedBox(height: AppSpacing.lg);
const espacioChico = SizedBox(height: AppSpacing.sm);
const espacioGrande = SizedBox(height: AppSpacing.xl);

void mostrarMensaje(BuildContext context, String texto) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(texto)));
}
