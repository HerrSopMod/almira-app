import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/utils/formato.dart';
import '../../core/widgets/componentes.dart';
import '../../core/widgets/mapa_almira.dart';
import '../../shared/models/modelos.dart';
import '../../shared/services/proveedores.dart';
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
      ? Insignia(estado.etiqueta, tono: Tono.exito, icono: Icons.check_rounded)
      : Insignia(estado.etiqueta, tono: Tono.primario, icono: Icons.construction_rounded);
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
            Expanded(child: Text('Avance físico', style: textos.bodySmall)),
            Text('${pct.round()} %', style: textos.labelMedium),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pastilla),
          child: LinearProgressIndicator(
            value: pct / 100,
            minHeight: 6,
            color: colorObra(obra),
            semanticsLabel: 'Avance físico',
            semanticsValue: '${pct.round()} por ciento',
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
    final hoy = ref.watch(relojProvider)();
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
          if (esDemo) const Center(child: EtiquetaDemo(sobreTurquesa: true)),
          if (hayMapa)
            IconButton(
              tooltip: _mapaVisible ? 'Ver solo la lista' : 'Ver el mapa',
              icon: Icon(_mapaVisible ? Icons.view_list_rounded : Icons.map_rounded),
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
                      icono: Icons.construction_rounded,
                      titulo: 'Aún no hay obras publicadas',
                      detalle: 'Tu municipalidad todavía no publicó obras en Almira.',
                    ),
                  ];
                }
                return [
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final filtro in FiltroObra.values)
                        ChoiceChip(
                          label: Text(filtro.etiqueta),
                          selected: _filtro == filtro,
                          onSelected: (_) => setState(() {
                            _filtro = filtro;
                            _seleccionada = null;
                          }),
                        ),
                    ],
                  ),
                  espacioChico,
                  Text(plural(filtradas.length, 'obra', 'obras'), style: textos.bodySmall),
                  espacioChico,
                  if (filtradas.isEmpty)
                    const VistaVacia(
                      icono: Icons.filter_alt_off_outlined,
                      titulo: 'No hay obras con este filtro',
                    )
                  else
                    for (final obra in filtradas) ...[
                      _TarjetaObra(
                        key: _claves.putIfAbsent(obra.id, GlobalKey.new),
                        obra: obra,
                        hoy: hoy,
                        seleccionada: obra.id == _seleccionada,
                        alVerEnMapa: obra.tieneUbicacion ? () => _verEnMapa(obra) : null,
                      ),
                      espacioChico,
                    ],
                ];
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaObra extends StatelessWidget {
  const _TarjetaObra({
    super.key,
    required this.obra,
    required this.hoy,
    required this.seleccionada,
    this.alVerEnMapa,
  });

  final Obra obra;
  final DateTime hoy;
  final bool seleccionada;
  final VoidCallback? alVerEnMapa;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return AnimatedContainer(
      duration: duracionDe(context),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.tarjeta),
        border: Border.all(
          color: seleccionada ? AppColors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: Tarjeta(
        onTap: () => context.go(Rutas.obra(obra.id)),
        semantica: 'Obra ${obra.nombre}, ${obra.estado.etiqueta}. Ver detalle',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(obra.nombre, style: textos.titleMedium)),
                const SizedBox(width: AppSpacing.sm),
                InsigniaObra(obra.estado),
              ],
            ),
            const SizedBox(height: 2),
            Text(obra.ubicacion, style: textos.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            AvanceFisico(obra),
            if (alVerEnMapa != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: alVerEnMapa,
                  icon: const Icon(Icons.place_outlined, size: 18),
                  label: const Text('Ver en el mapa'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    textStyle: textos.labelMedium,
                  ),
                ),
              )
            else ...[
              espacioChico,
              Text('Sin ubicación en el mapa', style: textos.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
