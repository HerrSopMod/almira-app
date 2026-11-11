import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/widgets/componentes.dart';
import '../../shared/models/modelos.dart';
import '../../shared/services/proveedores.dart';
import 'formulario_vincular.dart';

/// Primer ingreso: municipalidad y código de contribuyente.
/// El código es opcional aquí; sin él se pueden ver las obras, y se vincula
/// después desde Mi perfil.
class ConfigurarScreen extends ConsumerWidget {
  const ConfigurarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vista = ref.watch(vistaProvider);
    final sesion = ref.watch(sesionProvider);
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configura tu cuenta'),
        actions: [
          TextButton(
            onPressed: () => ref.read(sesionProvider.notifier).cerrarSesion(),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('Salir'),
          ),
        ],
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
                  icono: Icons.location_city_rounded,
                  titulo: 'Aún no hay municipalidades disponibles',
                  detalle: 'Vuelve a intentarlo más tarde.',
                ),
              ];
            }
            final elegida = sesion.municipalidadElegida ?? v.municipalidad?.id;
            return [
              TituloSeccion('Tu municipalidad'),
              espacioChico,
              Tarjeta(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: RadioGroup<String>(
                  groupValue: elegida,
                  onChanged: (id) {
                    if (id != null) ref.read(sesionProvider.notifier).elegirMunicipalidad(id);
                  },
                  child: Column(
                    children: [
                      for (final Municipalidad m in v.municipalidades)
                        RadioListTile<String>(
                          value: m.id,
                          title: Text(m.nombre),
                          subtitle: m.zona.isEmpty ? null : Text(m.zona),
                        ),
                    ],
                  ),
                ),
              ),
              espacioGrande,
              TituloSeccion('Tu código de contribuyente'),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Con él verás tus tributos y podrás reclamar. Puedes vincularlo después.',
                style: textos.bodyMedium,
              ),
              espacio,
              if (v.vecino != null)
                Aviso(
                  'Código vinculado: ${v.vecino!.codigoContribuyente ?? v.vecino!.nombre}',
                  tono: Tono.exito,
                )
              else if (elegida != null)
                FormularioVincular(municipalidadId: elegida),
              espacioGrande,
              FilledButton(
                onPressed: elegida == null
                    ? null
                    : () {
                        ref.read(sesionProvider.notifier).elegirMunicipalidad(elegida);
                        context.push(Rutas.consentimiento);
                      },
                child: const Text('Continuar'),
              ),
            ];
          },
        ),
      ),
    );
  }
}
