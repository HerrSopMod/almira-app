import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_spacing.dart';
import '../../core/widgets/componentes.dart';
import '../../shared/services/proveedores.dart';
import '../auth/formulario_vincular.dart';

class VincularScreen extends ConsumerWidget {
  const VincularScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vista = ref.watch(vistaProvider);
    final textos = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Vincular cuponera')),
      body: SafeArea(
        top: false,
        child: CuerpoAsync<VistaMunicipal>(
          valor: vista,
          alRecargar: ref.read(datosProvider.notifier).recargar,
          construir: (v) {
            final municipalidad = v.municipalidad;
            if (municipalidad == null) {
              return const [
                VistaVacia(
                  icono: Icons.location_city_rounded,
                  titulo: 'Aún no hay municipalidades disponibles',
                ),
              ];
            }
            return [
              Text(municipalidad.nombre, style: textos.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Comprobamos tu número de cuponera y tu DNI.',
                style: textos.bodyMedium,
              ),
              if (v.vecino != null) ...[
                espacio,
                Aviso(
                  'Ya tienes una cuponera vinculada: ${v.vecino!.codigoContribuyente ?? v.vecino!.nombre}',
                  tono: Tono.exito,
                ),
              ],
              espacioGrande,
              FormularioVincular(
                municipalidadId: municipalidad.id,
                alVincular: () => context.pop(),
              ),
            ];
          },
        ),
      ),
    );
  }
}
