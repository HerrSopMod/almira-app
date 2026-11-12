import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

/// Diálogo de la app: título y mensaje centrados, y dos botones del mismo ancho (48 de alto).
/// «Cancelar» va con borde y texto turquesa; la acción principal va rellena, en turquesa o, si
/// [destructivo], en el rojo de error. Úsalo en toda confirmación.
class AppConfirmDialog extends StatelessWidget {
  const AppConfirmDialog({
    super.key,
    required this.titulo,
    required this.textoConfirmar,
    this.mensaje,
    this.contenido,
    this.textoCancelar = 'Cancelar',
    this.destructivo = false,
    this.alConfirmar,
    this.alCancelar,
  });

  final String titulo;
  final String? mensaje;

  /// Cuerpo extra bajo el mensaje (por ejemplo un formulario).
  final Widget? contenido;
  final String textoConfirmar;
  final String textoCancelar;
  final bool destructivo;

  /// Por omisión cierra el diálogo con `true`.
  final VoidCallback? alConfirmar;

  /// Por omisión cierra el diálogo con `false`.
  final VoidCallback? alCancelar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final colorAccion = destructivo ? AppColors.error : AppColors.primary;
    return Dialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xl,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  titulo,
                  style: textos.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              if (mensaje != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  mensaje!,
                  style: textos.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
              if (contenido != null) ...[
                const SizedBox(height: AppSpacing.lg),
                contenido!,
              ],
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          alCancelar ?? () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        side: const BorderSide(
                          color: AppColors.primary,
                          width: 1.2,
                        ),
                        foregroundColor: AppColors.primary,
                      ),
                      child: Text(
                        textoCancelar,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed:
                          alConfirmar ?? () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        backgroundColor: colorAccion,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        textoConfirmar,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Muestra una confirmación y devuelve `true` si la persona acepta.
Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String textoConfirmar,
  String? mensaje,
  bool destructivo = false,
}) async {
  final respuesta = await showDialog<bool>(
    context: context,
    builder: (_) => AppConfirmDialog(
      titulo: titulo,
      mensaje: mensaje,
      textoConfirmar: textoConfirmar,
      destructivo: destructivo,
    ),
  );
  return respuesta == true;
}
