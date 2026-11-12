import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

/// Configuración del mapa. Es OpenStreetMap, sin clave: sirve para una
/// demostración y uso ligero. Una app con mucho tráfico necesita un proveedor
/// de teselas con contrato (ver README, «Mapa»).
abstract final class ConfigMapa {
  static const teselas = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const agente = 'com.almira.almira_flutter';
  static final derechos = Uri.parse('https://www.openstreetmap.org/copyright');
  static const centroLima = LatLng(-12.0464, -77.0428);
  static const zoomCiudad = 12.0;
  static const zoomCalle = 16.0;
  static const zoomMaximo = 18.0;

  /// Teselas fallidas seguidas a partir de las que se avisa del error.
  static const fallasParaError = 3;
}

class MarcadorMapa {
  const MarcadorMapa({
    required this.id,
    required this.punto,
    required this.etiqueta,
    this.color = AppColors.primary,
    this.icono = Icons.location_on_rounded,
  });

  final String id;
  final LatLng punto;

  /// Nombre para lectores de pantalla.
  final String etiqueta;
  final Color color;
  final IconData icono;
}

/// Mapa único de la app: lo usan Obras, Nuevo reclamo y Seguimiento.
///
/// - Muestra siempre la atribución de OpenStreetMap.
/// - Si las teselas no cargan, cambia a «No se pudo cargar el mapa» con
///   «Reintentar»; nunca deja un rectángulo en blanco.
/// - Con [alMoverCentro], dibuja un pin fijo al centro: el vecino mueve el
///   mapa para ubicarlo.
class MapaAlmira extends StatefulWidget {
  const MapaAlmira({
    super.key,
    required this.centro,
    this.zoom = ConfigMapa.zoomCalle,
    this.marcadores = const [],
    this.seleccionado,
    this.alTocarMarcador,
    this.alMoverCentro,
    this.interactivo = true,
    this.controlador,
    this.descripcion = 'Mapa',
    this.encuadrarMarcadores = false,
  });

  final LatLng centro;
  final double zoom;
  final List<MarcadorMapa> marcadores;
  final String? seleccionado;
  final ValueChanged<String>? alTocarMarcador;
  final ValueChanged<LatLng>? alMoverCentro;
  final bool interactivo;
  final MapController? controlador;

  /// Alternativa textual del mapa (dirección o resumen).
  final String descripcion;

  /// Ajusta el encuadre inicial para que entren todos los marcadores.
  final bool encuadrarMarcadores;

  @override
  State<MapaAlmira> createState() => _MapaAlmiraState();
}

class _MapaAlmiraState extends State<MapaAlmira> {
  int _fallas = 0;
  int _intento = 0;

  bool get _conError => _fallas >= ConfigMapa.fallasParaError;

  void _anotarFalla() {
    if (!mounted || _conError) return;
    // El aviso llega mientras se pinta: se anota al terminar el cuadro.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _fallas++);
    });
  }

  void _reintentar() => setState(() {
        _fallas = 0;
        _intento++;
      });

  @override
  Widget build(BuildContext context) {
    if (_conError) return _ErrorMapa(alReintentar: _reintentar);

    final puntos = widget.marcadores.map((m) => m.punto).toList();
    final encuadre = widget.encuadrarMarcadores && puntos.length > 1
        ? CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(puntos),
            padding: const EdgeInsets.all(48),
            maxZoom: 17,
          )
        : null;

    return Semantics(
      label: widget.descripcion,
      image: true,
      child: Stack(
        children: [
          FlutterMap(
            mapController: widget.controlador,
            options: MapOptions(
              initialCenter: puntos.length == 1 && widget.encuadrarMarcadores
                  ? puntos.first
                  : widget.centro,
              initialZoom: widget.zoom,
              initialCameraFit: encuadre,
              minZoom: 5,
              maxZoom: ConfigMapa.zoomMaximo,
              backgroundColor: AppColors.surfaceSubtle,
              interactionOptions: InteractionOptions(
                flags: widget.interactivo
                    ? InteractiveFlag.all & ~InteractiveFlag.rotate
                    : InteractiveFlag.none,
              ),
              onPositionChanged: widget.alMoverCentro == null
                  ? null
                  : (camara, _) => widget.alMoverCentro!(camara.center),
            ),
            children: [
              TileLayer(
                key: ValueKey(_intento),
                urlTemplate: ConfigMapa.teselas,
                userAgentPackageName: ConfigMapa.agente,
                maxNativeZoom: 19,
                errorTileCallback: (_, _, _) => _anotarFalla(),
              ),
              if (widget.marcadores.isNotEmpty)
                MarkerLayer(
                  markers: [
                    for (final m in widget.marcadores)
                      Marker(
                        point: m.punto,
                        width: 48,
                        height: 48,
                        alignment: Alignment.topCenter,
                        child: _Pin(
                          marcador: m,
                          seleccionado: m.id == widget.seleccionado,
                          alTocar: widget.alTocarMarcador == null
                              ? null
                              : () => widget.alTocarMarcador!(m.id),
                        ),
                      ),
                  ],
                ),
            ],
          ),
          if (widget.alMoverCentro != null)
            const IgnorePointer(
              child: Center(
                child: Padding(
                  // La punta del pin marca el centro exacto.
                  padding: EdgeInsets.only(bottom: 44),
                  child: Icon(
                    Icons.location_on_rounded,
                    size: 48,
                    color: AppColors.primary,
                    shadows: [Shadow(color: Color(0x4D0F2A2E), blurRadius: 6, offset: Offset(0, 2))],
                  ),
                ),
              ),
            ),
          const Positioned(right: 6, bottom: 6, child: _Atribucion()),
        ],
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin({required this.marcador, required this.seleccionado, this.alTocar});

  final MarcadorMapa marcador;
  final bool seleccionado;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final pin = AnimatedScale(
      scale: seleccionado ? 1.2 : 1,
      alignment: Alignment.bottomCenter,
      duration: MediaQuery.maybeDisableAnimationsOf(context) == true
          ? Duration.zero
          : const Duration(milliseconds: 180),
      child: Icon(
        marcador.icono,
        size: 40,
        color: marcador.color,
        shadows: const [Shadow(color: Color(0x590F2A2E), blurRadius: 4, offset: Offset(0, 1))],
      ),
    );
    if (alTocar == null) return Semantics(label: marcador.etiqueta, child: pin);
    return Semantics(
      button: true,
      selected: seleccionado,
      label: marcador.etiqueta,
      child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: alTocar, child: pin),
    );
  }
}

/// Atribución de OpenStreetMap: siempre visible, lleva a la página de derechos.
class _Atribucion extends StatelessWidget {
  const _Atribucion();

  @override
  Widget build(BuildContext context) => Semantics(
        link: true,
        label: 'Mapa de OpenStreetMap. Ver derechos',
        child: GestureDetector(
          onTap: () => launchUrl(ConfigMapa.derechos, mode: LaunchMode.externalApplication),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const ExcludeSemantics(
              child: Text(
                '© OpenStreetMap',
                style: TextStyle(fontSize: 11, color: AppColors.textPrimary, fontFamily: 'Inter'),
              ),
            ),
          ),
        ),
      );
}

class _ErrorMapa extends StatelessWidget {
  const _ErrorMapa({required this.alReintentar});

  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.surfaceSubtle,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map_outlined, color: AppColors.textSecondary, size: 32),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'No se pudo cargar el mapa',
                style: Theme.of(context).textTheme.titleSmall,
                textAlign: TextAlign.center,
              ),
              OutlinedButton.icon(
                onPressed: alReintentar,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Reintentar'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
              ),
            ],
          ),
        ),
      );
}

/// Marco redondeado para un mapa dentro de una pantalla.
class MarcoMapa extends StatelessWidget {
  const MarcoMapa({super.key, required this.child, this.alto = 180});

  final Widget child;
  final double alto;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.tarjeta),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.tarjeta),
            border: Border.all(color: AppColors.border),
          ),
          child: SizedBox(height: alto, width: double.infinity, child: child),
        ),
      );
}
