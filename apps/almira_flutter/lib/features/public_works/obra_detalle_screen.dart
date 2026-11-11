import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/utils/formato.dart';
import '../../core/widgets/componentes.dart';
import '../../core/widgets/mapa_almira.dart';
import '../../shared/services/proveedores.dart';
import 'obras_screen.dart';

class ObraDetalleScreen extends ConsumerWidget {
  const ObraDetalleScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vista = ref.watch(vistaProvider);
    final hoy = ref.watch(relojProvider)();
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Obra')),
      body: CuerpoAsync<VistaMunicipal>(
        valor: vista,
        alRecargar: ref.read(datosProvider.notifier).recargar,
        construir: (v) {
          final obra = v.obras.where((o) => o.id == id).firstOrNull;
          if (obra == null) {
            return const [
              VistaVacia(
                icono: Icons.search_off_rounded,
                titulo: 'No encontramos esta obra',
                detalle: 'Puede que ya no esté publicada.',
              ),
            ];
          }
          final actualizada = obra.actualizadaEn;
          final inicio = obra.inicio;
          final gasto = obra.montoAsignado > 0
              ? (obra.montoEjecutado / obra.montoAsignado * 100).clamp(0, 100).round()
              : null;
          return [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(obra.nombre, style: textos.headlineSmall),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                InsigniaObra(obra.estado),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: Text(obra.ubicacion, style: textos.bodyMedium)),
              ],
            ),
            espacio,
            if (obra.tieneUbicacion)
              MarcoMapa(
                child: MapaAlmira(
                  centro: LatLng(obra.latitud!, obra.longitud!),
                  zoom: ConfigMapa.zoomCalle,
                  interactivo: false,
                  marcadores: [
                    MarcadorMapa(
                      id: obra.id,
                      punto: LatLng(obra.latitud!, obra.longitud!),
                      etiqueta: obra.nombre,
                      color: colorObra(obra),
                    ),
                  ],
                  descripcion: 'Mapa con la ubicación de la obra: ${obra.ubicacion}',
                ),
              )
            else
              const Aviso('Esta obra no tiene un punto en el mapa.', icono: Icons.map_outlined),
            espacio,
            Tarjeta(child: AvanceFisico(obra)),
            espacio,
            Tarjeta(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Presupuesto', style: textos.titleSmall),
                  espacioChico,
                  FilaDato('Asignado', soles(obra.montoAsignado)),
                  FilaDato(
                    'Gastado',
                    gasto == null ? soles(obra.montoEjecutado) : '${soles(obra.montoEjecutado)} ($gasto %)',
                  ),
                  if (obra.porcentajeTributos != null)
                    FilaDato('Financiado con tributos', '${obra.porcentajeTributos!.round()} %'),
                ],
              ),
            ),
            espacio,
            Tarjeta(
              child: Column(
                children: [
                  if (inicio != null) FilaDato('Inicio', fechaLarga(inicio)),
                  if (obra.meta.trim().isNotEmpty) FilaDato('Meta', obra.meta),
                  if (actualizada != null)
                    FilaDato('Última actualización', haceDias(actualizada, hoy)),
                ],
              ),
            ),
            if (obra.hitos.isNotEmpty) ...[
              espacioGrande,
              const TituloSeccion('Hitos'),
              espacioChico,
              for (final hito in obra.hitos)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 3),
                        child: Icon(Icons.flag_outlined, size: 18, color: AppColors.primary),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text(hito, style: textos.bodyLarge)),
                    ],
                  ),
                ),
            ],
          ];
        },
      ),
    );
  }
}
