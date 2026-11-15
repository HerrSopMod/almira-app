import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme/iconos.dart';
import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/utils/formato.dart';
import '../../core/widgets/componentes.dart';
import '../../core/widgets/filtros.dart';
import '../../core/widgets/mapa_almira.dart';
import '../../shared/models/modelos.dart';
import '../../shared/services/proveedores.dart';
import '../../app/theme/app_theme.dart';
import '../complaints/piezas_lista.dart';
import '../complaints/reclamos_logica.dart';

enum FiltroObra {
  todas('Todas'),
  enEjecucion('En ejecución'),
  concluidas('Concluidas');

  const FiltroObra(this.etiqueta);
  final String etiqueta;
}

/// Obras que pasan el filtro. El mapa y la lista usan esta misma lista.
List<Obra> filtrarObras(List<Obra> obras, FiltroObra filtro) => obras
    .where((o) => switch (filtro) {
          FiltroObra.todas => true,
          FiltroObra.enEjecucion => o.estado == EstadoObra.enEjecucion,
          FiltroObra.concluidas => o.estado == EstadoObra.finalizada,
        })
    .toList();

Color colorObra(Obra obra) =>
    obra.estado == EstadoObra.finalizada ? AppColors.success : AppColors.primary;

class InsigniaObra extends StatelessWidget {
  const InsigniaObra(this.estado, {super.key});

  final EstadoObra estado;

  @override
  Widget build(BuildContext context) => estado == EstadoObra.finalizada
      ? Insignia(estado.etiqueta, tono: Tono.exito, icono: Phosphor.check)
      : Insignia(estado.etiqueta, tono: Tono.primario);
}

/// Avance físico de la obra, rotulado para no confundirlo con el gasto.
class AvanceFisico extends StatelessWidget {
  const AvanceFisico(this.obra, {super.key});

  final Obra obra;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final pct = obra.avancePct.clamp(0, 100).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Avance físico', style: textos.bodyMedium!)),
            Text('${pct.round()} %', style: textos.titleMedium!.copyWith(fontFeatures: cifrasTabulares)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pastilla),
          child: LinearProgressIndicator(
            value: pct / 100,
            minHeight: 6,
            color: colorObra(obra),
            semanticsLabel: 'Avance físico ${pct.round()} por ciento',
          ),
        ),
      ],
    );
  }
}

class ObrasScreen extends ConsumerStatefulWidget {
  const ObrasScreen({super.key});

  @override
  ConsumerState<ObrasScreen> createState() => _ObrasScreenState();
}

class _ObrasScreenState extends ConsumerState<ObrasScreen> {
  final _mapa = MapController();
  final _claves = <String, GlobalKey>{};
  FiltroObra _filtro = FiltroObra.todas;
  String? _seleccionada;
  bool _mapaVisible = true;

  @override
  void dispose() {
    _mapa.dispose();
    super.dispose();
  }

  void _alTocarMarcador(String id) {
    setState(() => _seleccionada = id);
    final contexto = _claves[id]?.currentContext;
    if (contexto != null) {
      Scrollable.ensureVisible(contexto, duration: duracionDe(context, 250), alignment: 0.1);
    }
  }

  void _verEnMapa(Obra obra) {
    setState(() {
      _seleccionada = obra.id;
      _mapaVisible = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        _mapa.move(LatLng(obra.latitud!, obra.longitud!), ConfigMapa.zoomCalle);
      } catch (_) {
        // El mapa no está en pantalla (por ejemplo, no cargó): la tarjeta
        // queda resaltada y no pasa nada más.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vista = ref.watch(vistaProvider);
    final esDemo = ref.watch(esDemoProvider);
    final v = vista.valueOrNull;
    final textos = Theme.of(context).textTheme;

    final filtradas = v == null ? const <Obra>[] : filtrarObras(v.obras, _filtro);
    final ubicadas = filtradas.where((o) => o.tieneUbicacion).toList();
    final base = v == null ? null : centroDe(v);
    final hayMapa = v != null && v.obras.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Obras'),
        actions: [
          if (esDemo) const Center(child: EtiquetaDemo()),
          if (hayMapa)
            IconButton(
              tooltip: _mapaVisible ? 'Ver solo la lista' : 'Ver el mapa',
              icon: Icon(_mapaVisible ? Phosphor.listBullets : Phosphor.mapTrifold),
              onPressed: () => setState(() => _mapaVisible = !_mapaVisible),
            ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: Column(
        children: [
          if (hayMapa)
            AnimatedSize(
              duration: duracionDe(context, 220),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: _mapaVisible
                  ? SizedBox(
                      height: (MediaQuery.sizeOf(context).height * 0.3).clamp(180, 280).toDouble(),
                      width: double.infinity,
                      child: MapaAlmira(
                        // Al cambiar el filtro, el mapa vuelve a encuadrar sus marcadores.
                        key: ValueKey(_filtro),
                        controlador: _mapa,
                        centro: base!.centro,
                        zoom: base.zoom,
                        encuadrarMarcadores: true,
                        seleccionado: _seleccionada,
                        alTocarMarcador: _alTocarMarcador,
                        marcadores: [
                          for (final o in ubicadas)
                            MarcadorMapa(
                              id: o.id,
                              punto: LatLng(o.latitud!, o.longitud!),
                              etiqueta: '${o.nombre}, ${o.estado.etiqueta}',
                              color: colorObra(o),
                            ),
                        ],
                        descripcion: 'Mapa con ${plural(ubicadas.length, 'obra', 'obras')}',
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          Expanded(
            child: CuerpoAsync<VistaMunicipal>(
              valor: vista,
              alRecargar: ref.read(datosProvider.notifier).recargar,
              construir: (v) {
                if (v.obras.isEmpty) {
                  return const [
                    VistaVacia(
                      icono: Phosphor.barricade,
                      titulo: 'Aún no hay obras publicadas',
                      detalle: 'Tu municipalidad todavía no publicó obras en Almira.',
                    ),
                  ];
                }
                return [
                  GrupoFiltros(
                    chips: [
                      for (final filtro in FiltroObra.values)
                        ChipFiltro(
                          texto: filtro.etiqueta,
                          activo: _filtro == filtro,
                          alTocar: () => setState(() {
                            _filtro = filtro;
                            _seleccionada = null;
                          }),
                        ),
                    ],
                  ),
                  espacio,
                  Text(plural(filtradas.length, 'obra', 'obras'), style: textos.bodyMedium!),
                  if (filtradas.isEmpty)
                    const VistaVacia(
                      icono: Phosphor.funnelSimpleX,
                      titulo: 'No hay obras con este filtro',
                    )
                  else
                    ListaFilas(
                      filas: [
                        for (final obra in filtradas)
                          _FilaObra(
                            key: _claves.putIfAbsent(obra.id, GlobalKey.new),
                            obra: obra,
                            seleccionada: obra.id == _seleccionada,
                            alVerEnMapa: obra.tieneUbicacion ? () => _verEnMapa(obra) : null,
                          ),
                      ],
                    ),
                ];
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila de obra: nombre, ubicación en gris, avance a la derecha y flecha. Debajo, su estado y
/// el enlace al mapa. La obra elegida en el mapa se marca con fondo gris claro.
class _FilaObra extends StatelessWidget {
  const _FilaObra({
    super.key,
    required this.obra,
    required this.seleccionada,
    this.alVerEnMapa,
  });

  final Obra obra;
  final bool seleccionada;
  final VoidCallback? alVerEnMapa;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final pct = obra.avancePct.clamp(0, 100).round();
    return AnimatedContainer(
      duration: duracionDe(context),
      color: seleccionada ? AppColors.surfaceSubtle : AppColors.surface,
      child: FilaLista(
        titulo: obra.nombre,
        monto: '$pct$_nbsp%',
        alTocar: () => context.go(Rutas.obra(obra.id)),
        semantica: 'Obra ${obra.nombre}, ${obra.estado.etiqueta}, avance físico $pct por ciento. Ver detalle',
        detalle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DetalleFila(obra.ubicacion),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
          spacing: AppSpacing.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            InsigniaObra(obra.estado),
            if (alVerEnMapa != null)
              TextButton(
                onPressed: alVerEnMapa,
                style: TextButton.styleFrom(
                  minimumSize: const Size(AppSpacing.toque, AppSpacing.toque),
                  padding: EdgeInsets.zero,
                  textStyle: textos.bodyMedium!.copyWith(fontWeight: FontWeight.w600),
                ),
                child: const Text('Ver en el mapa'),
              )
            else
              Text('Sin ubicación en el mapa', style: textos.bodyMedium!),
          ],
        ),
          ],
        ),
      ),
    );
  }
}

/// Espacio no separable: evita que «66 %» se parta en dos líneas.
const _nbsp = ' ';
