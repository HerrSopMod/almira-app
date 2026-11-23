import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/iconos_almira.dart';
import '../../core/widgets/componentes.dart';

/// Una pestaña de la barra. [rama] es su posición en el router (Inicio 0, Pagar 1,
/// Reclamos 2, Obras 3, Asistente 4): las rutas no cambian, solo el orden en pantalla.
class _Destino {
  const _Destino(this.rama, this.etiqueta, this.icono);
  final int rama;
  final String etiqueta;
  final IconoA icono;
}

const _inicio = _Destino(0, 'Inicio', IconoA.inicio);
const _pagar = _Destino(1, 'Pagar', IconoA.pagar);
const _reclamos = _Destino(2, 'Reclamos', IconoA.reclamos);
const _obras = _Destino(3, 'Obras', IconoA.obras);
const _ramaAsistente = 4;

/// Marco de las cinco secciones principales, con la barra inferior.
/// Cada pestaña conserva su estado (filtro, scroll, pantalla abierta).
class ShellPrincipal extends StatelessWidget {
  const ShellPrincipal({super.key, required this.navegacion});

  final StatefulNavigationShell navegacion;

  void _ir(int rama) => navegacion.goBranch(
    rama,
    // Tocar la pestaña ya elegida vuelve a su pantalla principal.
    initialLocation: rama == navegacion.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
    // Con el teclado abierto la barra se oculta: no roba espacio ni salta.
    final conTeclado = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      body: navegacion,
      bottomNavigationBar: conTeclado ? null : BarraInferior(actual: navegacion.currentIndex, alElegir: _ir),
    );
  }
}

/// Barra inferior blanca con una línea arriba y sombra suave hacia arriba. Orden: Inicio, Pagar,
/// Asistente (botón central que sobresale), Reclamos y Obras. La pestaña activa va en turquesa
/// con una línea corta arriba.
class BarraInferior extends StatelessWidget {
  const BarraInferior({super.key, required this.actual, required this.alElegir});

  /// Rama activa del router.
  final int actual;
  final ValueChanged<int> alElegir;

  @override
  Widget build(BuildContext context) {
    final abajo = MediaQuery.paddingOf(context).bottom;
    Widget pestana(_Destino d) => Expanded(
      child: _Pestana(destino: d, activa: actual == d.rama, alTocar: () => alElegir(d.rama)),
    );
    // Las etiquetas son de una sola palabra y el ancho es fijo: el aumento de letra se limita a
    // 1.15 para que «Reclamos» no se parta.
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.15)),
      child: SizedBox(
        height: AppSpacing.salienteCentral + AppSpacing.barraInferior + abajo,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              top: AppSpacing.salienteCentral,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border)),
                  boxShadow: [BoxShadow(color: Color(0x0F12393A), blurRadius: 20, offset: Offset(0, -6))],
                ),
                child: Padding(
                  padding: EdgeInsets.only(bottom: abajo),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      pestana(_inicio),
                      pestana(_pagar),
                      Expanded(
                        child: _EtiquetaCentral(
                          activa: actual == _ramaAsistente,
                          alTocar: () => alElegir(_ramaAsistente),
                        ),
                      ),
                      pestana(_reclamos),
                      pestana(_obras),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: _BotonAsistente(activo: actual == _ramaAsistente, alTocar: () => alElegir(_ramaAsistente)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pestaña común: línea corta arriba si está activa, ícono redondeado y etiqueta de 11.
class _Pestana extends StatelessWidget {
  const _Pestana({required this.destino, required this.activa, required this.alTocar});

  final _Destino destino;
  final bool activa;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final duracion = duracionDe(context);
    final color = activa ? AppColors.primary : AppColors.textSecondary;
    final etiqueta = Theme.of(context).textTheme.labelSmall!;
    return Semantics(
      button: true,
      selected: activa,
      label: destino.etiqueta,
      excludeSemantics: true,
      child: Tooltip(
        message: destino.etiqueta,
        excludeFromSemantics: true,
        child: InkWell(
          onTap: alTocar,
          child: Column(
            children: [
              AnimatedContainer(
                duration: duracion,
                curve: Curves.easeOut,
                width: activa ? AppSpacing.lineaActivaAncho : 0,
                height: AppSpacing.lineaActivaAlto,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.pastilla),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: color),
                duration: duracion,
                builder: (_, c, _) => IconoAlmira(destino.icono, tamano: AppIconos.navegacion, color: c),
              ),
              const SizedBox(height: AppSpacing.xs),
              AnimatedDefaultTextStyle(
                duration: duracion,
                style: etiqueta.copyWith(color: color, fontWeight: activa ? FontWeight.w800 : FontWeight.w700),
                child: Text(destino.etiqueta, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lugar del Asistente en la fila: solo su etiqueta, alineada con las demás. El círculo va
/// encima, en [_BotonAsistente]. Toda la columna también abre el Asistente.
class _EtiquetaCentral extends StatelessWidget {
  const _EtiquetaCentral({required this.activa, required this.alTocar});

  final bool activa;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final etiqueta = Theme.of(context).textTheme.labelSmall!;
    return ExcludeSemantics(
      child: InkWell(
        onTap: alTocar,
        child: Column(
          children: [
            // Mismo alto que línea + ícono de las otras pestañas: las etiquetas quedan en fila.
            const SizedBox(height: AppSpacing.lineaActivaAlto + AppSpacing.sm + AppIconos.navegacion + AppSpacing.xs),
            AnimatedDefaultTextStyle(
              duration: duracionDe(context),
              style: etiqueta.copyWith(
                color: activa ? AppColors.primary : AppColors.textSecondary,
                fontWeight: activa ? FontWeight.w800 : FontWeight.w700,
              ),
              child: const Text('Asistente', maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón circular del Asistente: degradado turquesa, anillo blanco de 4 y sombra turquesa.
/// Sobresale de la barra. Activo: un poco más oscuro.
class _BotonAsistente extends StatelessWidget {
  const _BotonAsistente({required this.activo, required this.alTocar});

  final bool activo;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: activo,
    label: 'Asistente',
    excludeSemantics: true,
    child: Tooltip(
      message: 'Asistente',
      excludeFromSemantics: true,
      child: Container(
        width: AppSpacing.botonCentral,
        height: AppSpacing.botonCentral,
        padding: const EdgeInsets.all(AppSpacing.anilloCentral),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Color(0x590A6E72), blurRadius: 18, offset: Offset(0, 8))],
        ),
        child: AnimatedContainer(
          duration: duracionDe(context),
          decoration: BoxDecoration(
            gradient: activo
                ? const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark])
                : AppColors.degradadoAsistente,
            shape: BoxShape.circle,
          ),
          child: Material(
            type: MaterialType.transparency,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: alTocar,
              child: const Center(
                child: IconoAlmira(IconoA.asistente, tamano: AppIconos.central, color: AppColors.onPrimary),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
