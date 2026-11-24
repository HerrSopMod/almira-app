import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/iconos.dart';
import '../../app/theme/iconos_almira.dart';
import '../../core/widgets/componentes.dart';
import '../../core/widgets/mapa_almira.dart';
import '../../shared/models/modelos.dart';
import 'obras_screen.dart';

/// Zoom del mapa de una obra: lo bastante cerca para leer los nombres de las calles.
const zoomObra = ConfigMapa.zoomCalle + 1;

/// Abre la ubicación de la obra en Google Maps (o la app de mapas del teléfono).
Future<void> abrirEnMapas(BuildContext context, Obra obra) async {
  final destino = Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query': '${obra.latitud},${obra.longitud}',
  });
  final abierto = await launchUrl(destino, mode: LaunchMode.externalApplication).catchError((_) => false);
  if (!abierto && context.mounted) mostrarMensaje(context, 'No se pudo abrir el mapa.');
}

MarcadorMapa _marcador(Obra obra) => MarcadorMapa(
  id: obra.id,
  punto: LatLng(obra.latitud!, obra.longitud!),
  etiqueta: obra.nombre,
  color: colorObra(obra),
);

/// Ubicación en el detalle de la obra: la dirección, un mapa cercano (al tocarlo se abre el mapa
/// completo para moverse entre las calles) y «Cómo llegar».
class UbicacionObra extends StatelessWidget {
  const UbicacionObra({super.key, required this.obra});

  final Obra obra;

  void _abrirMapa(BuildContext context) => Navigator.of(
    context,
    rootNavigator: true,
  ).push(MaterialPageRoute<void>(builder: (_) => MapaObraScreen(obra: obra)));

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final direccion = obra.ubicacion.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (direccion.isNotEmpty) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: IconoAlmira(IconoA.ubicacion, tamano: 20, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(direccion, style: textos.titleMedium)),
            ],
          ),
          espacioChico,
        ],
        if (!obra.tieneUbicacion)
          Text('Sin punto en el mapa.', style: textos.bodyMedium!)
        else ...[
          MarcoMapa(
            child: Stack(
              children: [
                // El mapa siempre lleva su atribución (la dibuja MapaAlmira).
                MapaAlmira(
                  centro: LatLng(obra.latitud!, obra.longitud!),
                  zoom: zoomObra,
                  interactivo: false,
                  marcadores: [_marcador(obra)],
                  descripcion: 'Mapa con la ubicación de la obra: $direccion',
                ),
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _abrirMapa(context),
                      child: Semantics(button: true, label: 'Ver el mapa completo'),
                    ),
                  ),
                ),
                Positioned(
                  left: AppSpacing.sm,
                  top: AppSpacing.sm,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.pastilla),
                        boxShadow: AppColors.sombraCard,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Phosphor.mapTrifold, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Toca para ver las calles',
                            style: textos.labelMedium!.copyWith(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          espacioChico,
          OutlinedButton.icon(
            onPressed: () => abrirEnMapas(context, obra),
            icon: const IconoAlmira(IconoA.ubicacion, tamano: 20, color: AppColors.primary),
            label: const Text('Cómo llegar'),
          ),
        ],
      ],
    );
  }
}

/// Mapa completo de una obra: se mueve y se acerca para ver entre qué calles está. Abajo, el
/// nombre, la dirección y «Cómo llegar».
class MapaObraScreen extends StatefulWidget {
  const MapaObraScreen({super.key, required this.obra});

  final Obra obra;

  @override
  State<MapaObraScreen> createState() => _MapaObraScreenState();
}

class _MapaObraScreenState extends State<MapaObraScreen> {
  final _mapa = MapController();

  @override
  void dispose() {
    _mapa.dispose();
    super.dispose();
  }

  LatLng get _punto => LatLng(widget.obra.latitud!, widget.obra.longitud!);

  void _zoom(double cambio) {
    final camara = _mapa.camera;
    _mapa.move(camara.center, (camara.zoom + cambio).clamp(5, ConfigMapa.zoomMaximo).toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final obra = widget.obra;
    return Scaffold(
      appBar: const BarraAlmira(titulo: 'Ubicación'),
      body: Stack(
        children: [
          Positioned.fill(
            child: MapaAlmira(
              controlador: _mapa,
              centro: _punto,
              zoom: zoomObra,
              marcadores: [_marcador(obra)],
              descripcion: 'Mapa de la obra ${obra.nombre}: ${obra.ubicacion}',
            ),
          ),
          // Acercar, alejar y volver a la obra, para quien usa el mouse o prefiere botones.
          Positioned(
            right: AppSpacing.margen,
            top: AppSpacing.lg,
            child: Column(
              children: [
                _BotonMapa(icono: Icons.add_rounded, semantica: 'Acercar', alTocar: () => _zoom(1)),
                const SizedBox(height: AppSpacing.sm),
                _BotonMapa(icono: Icons.remove_rounded, semantica: 'Alejar', alTocar: () => _zoom(-1)),
                const SizedBox(height: AppSpacing.sm),
                _BotonMapa(
                  icono: Phosphor.crosshair,
                  semantica: 'Volver a la obra',
                  alTocar: () => _mapa.move(_punto, zoomObra),
                ),
              ],
            ),
          ),
          Positioned(
            left: AppSpacing.margen,
            right: AppSpacing.margen,
            bottom: AppSpacing.margen + MediaQuery.paddingOf(context).bottom + 24,
            child: Tarjeta(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(obra.nombre, style: textos.titleMedium!.copyWith(fontWeight: FontWeight.w800)),
                  if (obra.ubicacion.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const IconoAlmira(IconoA.ubicacion, tamano: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(child: Text(obra.ubicacion.trim(), style: textos.bodyMedium)),
                      ],
                    ),
                  ],
                  espacio,
                  FilledButton.icon(
                    onPressed: () => abrirEnMapas(context, obra),
                    icon: const IconoAlmira(IconoA.ubicacion, tamano: 20, color: AppColors.onPrimary),
                    label: const Text('Cómo llegar'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BotonMapa extends StatelessWidget {
  const _BotonMapa({required this.icono, required this.semantica, required this.alTocar});

  final IconData icono;
  final String semantica;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.caja), boxShadow: AppColors.sombraCard),
    child: BotonCuadro(
      semantica: semantica,
      fondo: AppColors.surface,
      alTocar: alTocar,
      child: Icon(icono, color: AppColors.textPrimary),
    ),
  );
}
