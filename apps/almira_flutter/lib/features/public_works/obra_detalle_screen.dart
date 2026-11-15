import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme/app_spacing.dart';
import '../../app/theme/iconos.dart';
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
                icono: Phosphor.magnifyingGlass,
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
            Semantics(
              header: true,
              child: Text(obra.nombre, style: textos.titleLarge!),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(obra.ubicacion, style: textos.bodyMedium!),
            espacioChico,
            Align(alignment: Alignment.centerLeft, child: InsigniaObra(obra.estado)),
            espacio,
            // El mapa siempre lleva su atribución (la dibuja MapaAlmira).
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
              Text('Sin punto en el mapa.', style: textos.bodyMedium!),
            espacioGrande,
            AvanceFisico(obra),
            espacioGrande,
            const TituloSeccion('Presupuesto'),
            const SizedBox(height: AppSpacing.xs),
            FilaDato('Asignado', soles(obra.montoAsignado)),
            FilaDato('Gastado', soles(obra.montoEjecutado)),
            if (gasto != null) FilaDato('Gastado del presupuesto', '$gasto$_nbsp%'),
            if (obra.porcentajeTributos != null)
              FilaDato('Financiado con tributos', '${obra.porcentajeTributos!.round()}$_nbsp%'),
            espacioGrande,
            if (inicio != null) Ficha('Inicio', fechaLarga(inicio)),
            if (obra.meta.trim().isNotEmpty) Ficha('Meta', obra.meta.trim()),
            if (actualizada != null) Ficha('Última actualización', haceDias(actualizada, hoy)),
            if (obra.hitos.isNotEmpty) ...[
              espacioGrande,
              const TituloSeccion('Hitos'),
              const SizedBox(height: AppSpacing.xs),
              for (final (i, hito) in obra.hitos.indexed) ...[
                if (i > 0) const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Text(hito, style: textos.bodyLarge!),
                ),
              ],
            ],
          ];
        },
      ),
    );
  }
}

/// Espacio no separable: evita que «66 %» se parta en dos líneas.
const _nbsp = ' ';
