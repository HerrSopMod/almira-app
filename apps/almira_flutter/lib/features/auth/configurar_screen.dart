import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/iconos.dart';
import '../../app/theme/iconos_almira.dart';
import '../../core/widgets/componentes.dart';
import '../../shared/models/modelos.dart';
import '../../shared/services/proveedores.dart';
import 'formulario_vincular.dart';
import 'pasos_registro.dart';

/// Paso 1 de 4 del primer ingreso con Google: la cuenta todavía no es de un contribuyente. Elige
/// la municipalidad y vincula su número de cuponera con su DNI; el servidor valida los dos y, ante
/// cualquier fallo, responde lo mismo. Sin vínculo no se sigue.
class ConfigurarScreen extends ConsumerWidget {
  const ConfigurarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vista = ref.watch(vistaProvider);
    final sesion = ref.watch(sesionProvider);
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      appBar: BarraPasos(
        paso: 1,
        nombre: 'Cuponera',
        conVolver: false,
        accion: TextButton(
          onPressed: () => ref.read(sesionProvider.notifier).cerrarSesion(),
          child: const Text('Salir'),
        ),
      ),
      body: SafeArea(
        top: false,
        child: CuerpoAsync<VistaMunicipal>(
          valor: vista,
          alRecargar: ref.read(datosProvider.notifier).recargar,
          construir: (v) {
            if (v.municipalidades.isEmpty) {
              return [
                const VistaVacia(
                  icono: Phosphor.buildings,
                  titulo: 'Aún no hay municipalidades disponibles',
                  detalle: 'Vuelve a intentarlo más tarde.',
                ),
              ];
            }
            final elegida = sesion.municipalidadElegida ?? v.municipalidad?.id;
            final vinculada = v.vecino != null;
            final rotulo = textos.titleSmall!.copyWith(fontSize: 14);
            return [
              const CabeceraPaso(
                ilustracion: Ilustracion.pasoCuponera,
                fondo: AppColors.primary50,
                titulo: 'Vincula tu cuponera',
                detalle: 'Así vemos tus tributos y pagos de tu casa.',
              ),
              Semantics(header: true, child: Text('Tu municipalidad', style: rotulo)),
              espacioChico,
              for (final Municipalidad m in v.municipalidades) ...[
                TarjetaOpcion(
                  titulo: m.nombre,
                  detalle: m.zona,
                  elegida: m.id == elegida,
                  alElegir: () => ref.read(sesionProvider.notifier).elegirMunicipalidad(m.id),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              const SizedBox(height: AppSpacing.sm),
              Semantics(header: true, child: Text('Tu número de cuponera', style: rotulo)),
              espacioChico,
              if (vinculada) ...[
                _CuponeraVinculada(codigo: v.vecino!.codigoContribuyente ?? v.vecino!.nombre),
                const SizedBox(height: AppSpacing.sm),
                Text('Es un dato privado: confirma que eres contribuyente.', style: textos.bodySmall),
                espacio,
                Aviso('Cuponera vinculada: ${v.vecino!.codigoContribuyente ?? v.vecino!.nombre}', tono: Tono.exito),
              ] else if (elegida != null)
                FormularioVincular(municipalidadId: elegida),
              espacioGrande,
              BotonPaso(
                texto: 'Continuar',
                alTocar: vinculada && elegida != null
                    ? () {
                        ref.read(sesionProvider.notifier).elegirMunicipalidad(elegida);
                        context.push(Rutas.crearClave);
                      }
                    : null,
              ),
            ];
          },
        ),
      ),
    );
  }
}

/// El número de cuponera ya vinculado, como un campo lleno con el check.
class _CuponeraVinculada extends StatelessWidget {
  const _CuponeraVinculada({required this.codigo});

  final String codigo;

  @override
  Widget build(BuildContext context) => Container(
    height: AppSpacing.campo,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.campo),
      border: Border.all(color: AppColors.limaTexto, width: 1.5),
    ),
    child: Row(
      children: [
        const IconoAlmira(IconoA.cuponera, tamano: 22, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(codigo, style: Theme.of(context).textTheme.titleMedium)),
        const Icon(Icons.check_rounded, color: AppColors.limaTexto),
      ],
    ),
  );
}
