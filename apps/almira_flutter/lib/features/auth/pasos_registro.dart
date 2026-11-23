import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/iconos.dart';
import '../../app/theme/iconos_almira.dart';
import '../../core/widgets/componentes.dart';
import '../../core/widgets/movimiento.dart';

// Piezas del registro en 4 pasos (rediseño): Cuponera, Clave web, Celular y Privacidad.

const _totalPasos = 4;

/// Barra clara del registro: botón de volver blanco, «Paso N de 4» con el nombre del paso a la
/// derecha y cuatro segmentos de avance.
class BarraPasos extends StatelessWidget implements PreferredSizeWidget {
  const BarraPasos({
    super.key,
    required this.paso,
    required this.nombre,
    this.alVolver,
    this.conVolver = true,
    this.accion,
  });

  /// De 1 a 4.
  final int paso;
  final String nombre;
  final VoidCallback? alVolver;
  final bool conVolver;

  /// Acción a la derecha (por ejemplo, «Salir»).
  final Widget? accion;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final ruta = ModalRoute.of(context);
    final puedeVolver = conVolver && (alVolver != null || (ruta?.impliesAppBarDismissal ?? false));
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: barraSobreBlanco,
      child: ColoredBox(
        color: AppColors.background,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.margen, AppSpacing.md, AppSpacing.margen, AppSpacing.sm),
            child: Row(
              children: [
                if (puedeVolver) ...[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.caja),
                      boxShadow: AppColors.sombraCard,
                    ),
                    child: BotonCuadro(
                      semantica: 'Volver',
                      fondo: AppColors.surface,
                      alTocar: alVolver ?? () => Navigator.maybePop(context),
                      child: const Icon(Phosphor.arrowLeft, size: 22, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                ],
                Expanded(
                  child: Semantics(
                    label: 'Paso $paso de $_totalPasos: $nombre',
                    excludeSemantics: true,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                'Paso $paso de $_totalPasos',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textos.titleSmall!.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Flexible(
                              child: Text(
                                nombre,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textos.titleSmall!.copyWith(color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            for (var i = 1; i <= _totalPasos; i++) ...[
                              if (i > 1) const SizedBox(width: 6),
                              Expanded(
                                child: AnimatedContainer(
                                  duration: duracionDe(context, 400),
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: i <= paso ? AppColors.primary : const Color(0xFFE5DFD4),
                                    borderRadius: BorderRadius.circular(AppRadius.pastilla),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (accion != null) ...[const SizedBox(width: AppSpacing.sm), accion!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Arriba de cada paso: la ilustración en una caja pastel de radio 26, el título de 28 y una
/// línea que explica para qué sirve el paso.
class CabeceraPaso extends StatelessWidget {
  const CabeceraPaso({super.key, required this.ilustracion, required this.fondo, required this.titulo, this.detalle});

  final Ilustracion ilustracion;
  final Color fondo;
  final String titulo;
  final String? detalle;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    // En pantallas bajas la ilustración se achica: el formulario manda.
    final bajo = MediaQuery.sizeOf(context).height < 700;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Rebote(
          child: Container(
            height: bajo ? 112 : 140,
            decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(AppRadius.hoja)),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Flotar(child: ImagenIlustracion(ilustracion)),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Aparecer(
          paso: 1,
          child: Semantics(
            header: true,
            child: Text(titulo, style: textos.headlineMedium!.copyWith(letterSpacing: -0.56)),
          ),
        ),
        if (detalle != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Aparecer(
            paso: 2,
            child: Text(detalle!, style: textos.bodyLarge!.copyWith(color: AppColors.textSecondary)),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

/// Opción elegible como tarjeta (municipalidad): caja con el ícono, nombre y zona; elegida, con
/// borde turquesa, fondo turquesa muy claro y un círculo con el check.
class TarjetaOpcion extends StatelessWidget {
  const TarjetaOpcion({
    super.key,
    required this.titulo,
    required this.elegida,
    required this.alElegir,
    this.detalle,
    this.icono = IconoA.municipalidad,
  });

  final String titulo;
  final String? detalle;
  final bool elegida;
  final VoidCallback? alElegir;
  final IconoA icono;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final duracion = duracionDe(context);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: elegida,
      button: true,
      label: [titulo, ?detalle].join(', '),
      excludeSemantics: true,
      child: Presionable(
        child: AnimatedContainer(
          duration: duracion,
          decoration: BoxDecoration(
            color: elegida ? AppColors.primary50 : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.tarjeta - 4),
            border: Border.all(color: elegida ? AppColors.primary : AppColors.border, width: elegida ? 2 : 1.5),
            boxShadow: elegida ? null : AppColors.sombraCard,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.tarjeta - 4),
              onTap: alElegir,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    IconoColor.svg(icono, color: elegida ? AppColors.primary : AppColors.background),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(titulo, style: textos.titleMedium!.copyWith(fontWeight: FontWeight.w800)),
                          if (detalle != null && detalle!.isNotEmpty) Text(detalle!, style: textos.bodyMedium),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AnimatedContainer(
                      duration: duracion,
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: elegida ? AppColors.primary : Colors.transparent,
                        border: elegida ? null : Border.all(color: AppColors.bordeControl, width: 1.5),
                      ),
                      child: elegida ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fuerza de la clave, calculada en el teléfono solo como ayuda: cuatro segmentos y una palabra.
/// La regla que vale es la del servidor (mínimo 8 caracteres).
class MedidorClave extends StatelessWidget {
  const MedidorClave({super.key, required this.clave, required this.minimo});

  final String clave;
  final int minimo;

  @override
  Widget build(BuildContext context) {
    if (clave.isEmpty) return const SizedBox.shrink();
    var puntos = 0;
    if (clave.length >= minimo) puntos++;
    if (clave.length >= 12) puntos++;
    if (RegExp('[A-Za-z]').hasMatch(clave) && RegExp(r'\d').hasMatch(clave)) puntos++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(clave) || RegExp('[A-Z]').hasMatch(clave)) puntos++;
    if (clave.length < minimo) puntos = 1;
    final (texto, color) = switch (puntos) {
      <= 1 => ('Clave débil', AppColors.coral),
      2 => ('Clave aceptable', AppColors.sol),
      _ => ('Clave segura', AppColors.lima),
    };
    final colorTexto = switch (puntos) {
      <= 1 => AppColors.coralTexto,
      2 => AppColors.solTexto,
      _ => AppColors.limaTexto,
    };
    return Semantics(
      label: texto,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (var i = 0; i < 4; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: AnimatedContainer(
                      duration: duracionDe(context, 300),
                      height: 6,
                      decoration: BoxDecoration(
                        color: i < puntos ? color : const Color(0xFFE5DFD4),
                        borderRadius: BorderRadius.circular(AppRadius.pastilla),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(texto, style: Theme.of(context).textTheme.labelMedium!.copyWith(color: colorTexto)),
          ],
        ),
      ),
    );
  }
}

/// Reglas de la clave con su check: verde cuando se cumplen.
class ReglasClave extends StatelessWidget {
  const ReglasClave({super.key, required this.reglas});

  final List<(String, bool)> reglas;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (texto, ok) in reglas)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Semantics(
              label: '$texto: ${ok ? 'cumplido' : 'pendiente'}',
              excludeSemantics: true,
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: duracionDe(context),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: ok ? AppColors.lima100 : AppColors.primary50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: ok ? AppColors.limaTexto : AppColors.bordeControl,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      texto,
                      style: textos.labelMedium!.copyWith(color: ok ? AppColors.limaTexto : AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Código de 6 dígitos en seis casillas. Debajo hay un solo campo de texto (invisible) que recibe
/// lo que se escribe, para que funcionen el pegado y el autocompletado del SMS.
class CampoCodigo extends StatefulWidget {
  const CampoCodigo({super.key, required this.controller, this.alCompletar, this.validator});

  final TextEditingController controller;
  final VoidCallback? alCompletar;
  final FormFieldValidator<String>? validator;

  @override
  State<CampoCodigo> createState() => _CampoCodigoState();
}

class _CampoCodigoState extends State<CampoCodigo> {
  final _foco = FocusNode();

  @override
  void initState() {
    super.initState();
    _foco.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _foco.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return FormField<String>(
      validator: (_) => widget.validator?.call(widget.controller.text),
      builder: (estado) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: widget.controller,
                builder: (context, valor, _) {
                  final texto = valor.text;
                  return Row(
                    children: [
                      for (var i = 0; i < 6; i++) ...[
                        if (i > 0) const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AspectRatio(
                            aspectRatio: 0.92,
                            child: AnimatedContainer(
                              duration: duracionDe(context, 150),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(AppRadius.campo - 2),
                                border: Border.all(
                                  color: estado.hasError
                                      ? AppColors.error
                                      : (_foco.hasFocus && i == texto.length.clamp(0, 5)
                                            ? AppColors.primary
                                            : (i < texto.length ? AppColors.primary500 : AppColors.bordeCampo)),
                                  width: _foco.hasFocus && i == texto.length.clamp(0, 5) ? 2 : 1.5,
                                ),
                              ),
                              child: Text(
                                i < texto.length ? texto[i] : '',
                                style: textos.headlineSmall!.copyWith(fontFeatures: cifrasTabulares),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
              Positioned.fill(
                child: Opacity(
                  opacity: 0,
                  child: TextFormField(
                    controller: widget.controller,
                    focusNode: _foco,
                    keyboardType: TextInputType.number,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                    showCursor: false,
                    enableInteractiveSelection: false,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                    onChanged: (v) {
                      estado.didChange(v);
                      if (v.length == 6) widget.alCompletar?.call();
                    },
                  ),
                ),
              ),
            ],
          ),
          if (estado.hasError)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm, left: AppSpacing.xs),
              child: Text(estado.errorText!, style: textos.bodySmall!.copyWith(color: AppColors.error)),
            ),
        ],
      ),
    );
  }
}

/// «+51» en una pastilla turquesa clara, al inicio del campo del celular.
class PrefijoPeru extends StatelessWidget {
  const PrefijoPeru({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 10, right: 10),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: AppColors.primary50, borderRadius: BorderRadius.circular(10)),
      child: Text(
        '+51',
        style: Theme.of(context).textTheme.titleMedium!.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800),
      ),
    ),
  );
}

/// Botón principal de un paso: ocupa el ancho, con sombra turquesa y una ruedita mientras espera.
class BotonPaso extends StatelessWidget {
  const BotonPaso({super.key, required this.texto, required this.alTocar, this.ocupado = false});

  final String texto;
  final VoidCallback? alTocar;
  final bool ocupado;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppRadius.boton),
      boxShadow: alTocar == null || ocupado ? null : AppColors.sombraPrimaria,
    ),
    child: FilledButton(
      onPressed: ocupado ? null : alTocar,
      child: ocupado
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
            )
          : Text(texto),
    ),
  );
}
