import 'dart:math' as math;

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
import '../../app/theme/iconos_almira.dart';
import '../../core/widgets/movimiento.dart';
import '../complaints/reclamos_screen.dart';
import 'fotos_obra.dart';
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
    .where(
      (o) => switch (filtro) {
        FiltroObra.todas => true,
        FiltroObra.enEjecucion => o.estado == EstadoObra.enEjecucion,
        FiltroObra.concluidas => o.estado == EstadoObra.finalizada,
      },
    )
    .toList();

Color colorObra(Obra obra) => obra.estado == EstadoObra.finalizada ? AppColors.limaTexto : AppColors.primary;

/// Ilustración de una obra según su nombre (pistas, parque o veredas). Es la que se ve cuando la
/// obra no tiene fotos.
Ilustracion ilustracionDeObra(Obra obra) {
  final n = normalizar('${obra.nombre} ${obra.nombreCorto ?? ''}');
  if (n.contains('parque') || n.contains('plaza') || n.contains('area verde')) return Ilustracion.obraParque;
  if (n.contains('vereda') || n.contains('accesib')) return Ilustracion.obraVeredas;
  return Ilustracion.obraPistas;
}

class InsigniaObra extends StatelessWidget {
  const InsigniaObra(this.estado, {super.key, this.sobreTurquesa = false});

  final EstadoObra estado;

  /// Fondo blanco para que la píldora se lea sobre la barra turquesa.
  final bool sobreTurquesa;

  @override
  Widget build(BuildContext context) {
    final fondo = sobreTurquesa ? AppColors.surface : null;
    return estado == EstadoObra.finalizada
        ? Insignia(estado.etiqueta, tono: Tono.exito, icono: Phosphor.check, fondo: fondo)
        : Insignia(estado.etiqueta, tono: Tono.aviso, fondo: fondo);
  }
}

/// Avance físico de la obra en un anillo que se llena hasta el porcentaje, rotulado «avance
/// físico» para no confundirlo con el gasto. Solo va en obras en ejecución.
class AvanceFisico extends StatelessWidget {
  const AvanceFisico(this.obra, {super.key});

  final Obra obra;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final pct = obra.avancePct.clamp(0, 100).toDouble();
    final anillo = TweenAnimationBuilder<double>(
      tween: Tween(begin: sinMovimiento(context) ? pct : 0, end: pct),
      duration: const Duration(milliseconds: 1400),
      curve: curvaAlmira,
      builder: (context, valor, _) => CustomPaint(
        painter: _PintorAnillo(fraccion: valor / 100, color: AppColors.primary500),
        child: SizedBox.square(
          dimension: 104,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  child: Text(
                    '${valor.round()}%',
                    style: textos.headlineSmall!.copyWith(fontFeatures: cifrasTabulares),
                  ),
                ),
                Text('avance físico', style: textos.labelSmall!.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      ),
    );
    return Semantics(label: 'Avance físico ${pct.round()} por ciento', excludeSemantics: true, child: anillo);
  }
}

class _PintorAnillo extends CustomPainter {
  const _PintorAnillo({required this.fraccion, required this.color});

  final double fraccion;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const grosor = 10.0;
    final centro = size.center(Offset.zero);
    final radio = (math.min(size.width, size.height) - grosor) / 2;
    canvas.drawCircle(
      centro,
      radio,
      Paint()
        ..color = AppColors.primary50
        ..style = PaintingStyle.stroke
        ..strokeWidth = grosor,
    );
    canvas.drawArc(
      Rect.fromCircle(center: centro, radius: radio),
      -math.pi / 2,
      2 * math.pi * fraccion,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = grosor
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_PintorAnillo old) => old.fraccion != fraccion || old.color != color;
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

    // Pestaña raíz sin CuerpoAsync arriba: cabecera turquesa y, en la hoja blanca, el mapa (con
    // su atribución) y la lista.
    return Scaffold(
      body: Column(
        children: [
          CabeceraMarca(
            titulo: 'Obras',
            esDemo: esDemo,
            acciones: [
              if (hayMapa)
                IconButton(
                  tooltip: _mapaVisible ? 'Ver solo la lista' : 'Ver el mapa',
                  icon: Icon(_mapaVisible ? Phosphor.listBullets : Phosphor.mapTrifold),
                  onPressed: () => setState(() => _mapaVisible = !_mapaVisible),
                ),
            ],
          ),
          Expanded(
            child: HojaBlanca(
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.hoja)),
                child: Column(
                  children: [
                    if (hayMapa)
                      AnimatedSize(
                        duration: duracionDe(context, 220),
                        curve: Curves.easeOut,
                        alignment: Alignment.topCenter,
                        child: _mapaVisible
                            ? Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.margen,
                                  AppSpacing.lg,
                                  AppSpacing.margen,
                                  0,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(AppRadius.tarjeta),
                                  child: SizedBox(
                                    height: (MediaQuery.sizeOf(context).height * 0.26).clamp(160, 240).toDouble(),
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
                                  ),
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
                                ilustracion: Ilustracion.obraPistas,
                                titulo: 'Aún no hay obras publicadas',
                                detalle: 'Tu municipalidad todavía no publicó obras en Almira.',
                              ),
                            ];
                          }
                          final enEjecucion = v.obras.where((o) => o.estado == EstadoObra.enEjecucion).length;
                          final concluidas = v.obras.length - enEjecucion;
                          return [
                            Aparecer(
                              child: IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: Contador(
                                        numero: v.obras.length,
                                        texto: v.obras.length == 1 ? 'Obra' : 'Obras',
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Contador(numero: enEjecucion, texto: 'En ejecución', tono: Tono.aviso),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Contador(
                                        numero: concluidas,
                                        texto: concluidas == 1 ? 'Concluida' : 'Concluidas',
                                        tono: Tono.exito,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            espacio,
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
                              const VistaVacia(icono: Phosphor.funnelSimpleX, titulo: 'No hay obras con este filtro')
                            else
                              for (final (i, obra) in filtradas.indexed) ...[
                                const SizedBox(height: AppSpacing.md),
                                Aparecer(
                                  paso: 2 + i,
                                  child: _TarjetaObra(
                                    key: _claves.putIfAbsent(obra.id, GlobalKey.new),
                                    obra: obra,
                                    seleccionada: obra.id == _seleccionada,
                                    alVerEnMapa: obra.tieneUbicacion ? () => _verEnMapa(obra) : null,
                                  ),
                                ),
                              ],
                          ];
                        },
                      ),
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

/// Obra como tarjeta: la ilustración arriba con su estado, el nombre y la dirección, el avance
/// con su barra y el enlace al mapa. La obra elegida en el mapa se marca con borde turquesa.
class _TarjetaObra extends StatelessWidget {
  const _TarjetaObra({super.key, required this.obra, required this.seleccionada, this.alVerEnMapa});

  final Obra obra;
  final bool seleccionada;
  final VoidCallback? alVerEnMapa;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final pct = obra.avancePct.clamp(0, 100).round();
    final concluida = obra.estado == EstadoObra.finalizada;
    return AnimatedContainer(
      duration: duracionDe(context),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.tarjeta + 2),
        border: Border.all(color: seleccionada ? AppColors.primary : Colors.transparent, width: 2),
      ),
      child: Tarjeta(
        padding: EdgeInsets.zero,
        onTap: () => context.go(Rutas.obra(obra.id)),
        semantica: concluida
            ? 'Obra ${obra.nombre}, ${obra.estado.etiqueta}. Ver detalle'
            : 'Obra ${obra.nombre}, ${obra.estado.etiqueta}, avance físico $pct por ciento. Ver detalle',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 112,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ImagenObra(obra: obra),
                  Positioned(top: AppSpacing.md, left: AppSpacing.md, child: InsigniaObra(obra.estado)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              obra.nombre,
                              style: textos.titleMedium!.copyWith(fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                            Text(obra.ubicacion, style: textos.bodyMedium),
                          ],
                        ),
                      ),
                      if (!concluida) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '$pct$_nbsp%',
                          style: textos.titleLarge!.copyWith(fontSize: 20, fontFeatures: cifrasTabulares),
                        ),
                      ],
                    ],
                  ),
                  // Una obra concluida no necesita barra de avance.
                  if (!concluida) const SizedBox(height: AppSpacing.sm),
                  if (!concluida)
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primary50,
                        borderRadius: BorderRadius.circular(AppRadius.pastilla),
                      ),
                      child: BarraCreciente(
                        fraccion: pct / 100,
                        color: concluida ? AppColors.limaTexto.withValues(alpha: 0.75) : AppColors.primary500,
                      ),
                    ),
                  if (alVerEnMapa != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: alVerEnMapa,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(AppSpacing.toque, AppSpacing.toque),
                          padding: EdgeInsets.zero,
                          textStyle: textos.titleSmall,
                        ),
                        icon: const IconoAlmira(IconoA.ubicacion, tamano: 18, color: AppColors.primary),
                        label: const Text('Ver en el mapa'),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text('Sin ubicación en el mapa', style: textos.bodySmall),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Espacio no separable: evita que «66 %» se parta en dos líneas.
const _nbsp = ' ';
