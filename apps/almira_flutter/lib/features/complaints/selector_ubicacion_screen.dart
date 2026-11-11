import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/utils/ubicacion.dart';
import '../../core/widgets/componentes.dart';
import '../../core/widgets/mapa_almira.dart';

/// Selector de ubicación del reclamo: el vecino mueve el mapa bajo un pin
/// fijo y confirma. El GPS es opcional; sin permiso, se ubica a mano.
/// Devuelve el punto elegido con `Navigator.pop`.
class SelectorUbicacionScreen extends StatefulWidget {
  const SelectorUbicacionScreen({super.key, required this.centro, required this.zoom, this.inicial});

  final LatLng centro;
  final double zoom;
  final LatLng? inicial;

  @override
  State<SelectorUbicacionScreen> createState() => _SelectorUbicacionScreenState();
}

class _SelectorUbicacionScreenState extends State<SelectorUbicacionScreen> {
  final _controlador = MapController();
  late LatLng _punto = widget.inicial ?? widget.centro;
  bool _buscando = false;
  ResultadoUbicacion? _falla;

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  Future<void> _usarMiUbicacion() async {
    setState(() {
      _buscando = true;
      _falla = null;
    });
    final resultado = await ubicacionActual();
    if (!mounted) return;
    final punto = resultado.punto;
    if (punto != null) {
      _controlador.move(punto, ConfigMapa.zoomCalle + 1);
      setState(() => _punto = punto);
    }
    setState(() {
      _buscando = false;
      _falla = punto == null ? resultado : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Ubica el problema')),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                MapaAlmira(
                  controlador: _controlador,
                  centro: widget.inicial ?? widget.centro,
                  zoom: widget.inicial != null ? ConfigMapa.zoomCalle + 1 : widget.zoom,
                  alMoverCentro: (centro) => _punto = centro,
                  descripcion: 'Mapa para ubicar el problema. Mueve el mapa bajo el pin.',
                ),
                Positioned(
                  right: AppSpacing.lg,
                  bottom: AppSpacing.xxl,
                  child: FloatingActionButton(
                    heroTag: 'mi-ubicacion',
                    tooltip: 'Usar mi ubicación',
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.primary,
                    elevation: 2,
                    onPressed: _buscando ? null : _usarMiUbicacion,
                    child: _buscando
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Icon(Icons.my_location_rounded),
                  ),
                ),
              ],
            ),
          ),
          DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.margen,
                  AppSpacing.lg,
                  AppSpacing.margen,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_falla != null) ...[
                      Aviso(
                        _falla!.mensaje,
                        tono: Tono.aviso,
                        accion: _falla!.ofrecerAjustes
                            ? TextButton(
                                onPressed: abrirAjustesDeUbicacion,
                                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                                child: const Text('Abrir ajustes'),
                              )
                            : null,
                      ),
                      espacioChico,
                    ] else ...[
                      Text(
                        'Mueve el mapa hasta que el pin marque el lugar.',
                        style: textos.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      espacio,
                    ],
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(_punto),
                      child: const Text('Confirmar ubicación'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
