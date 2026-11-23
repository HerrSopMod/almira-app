import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/iconos.dart';
import '../../app/theme/iconos_almira.dart';
import '../../core/utils/formato.dart';
import '../../core/widgets/componentes.dart';
import '../../core/widgets/mapa_almira.dart';
import '../../core/widgets/movimiento.dart';
import '../../shared/models/modelos.dart';
import '../../shared/services/proveedores.dart';
import 'obras_screen.dart';

/// Detalle de obra (rediseño): la ilustración grande arriba con el botón de volver y el estado;
/// la tarjeta con el nombre, la dirección, el anillo de avance físico, la meta y la última
/// actualización; el presupuesto (cuánto se gastó del asignado) y la ubicación en el mapa.
class ObraDetalleScreen extends ConsumerWidget {
  const ObraDetalleScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vista = ref.watch(vistaProvider);
    final hoy = ref.watch(relojProvider)();
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      body: CuerpoAsync<VistaMunicipal>(
        valor: vista,
        alRecargar: ref.read(datosProvider.notifier).recargar,
        cabecera: (v) => _Portada(obra: v?.obras.where((o) => o.id == id).firstOrNull),
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
          final meta = obra.meta.trim();
          final gasto = obra.montoAsignado > 0
              ? (obra.montoEjecutado / obra.montoAsignado * 100).clamp(0, 100).toDouble()
              : null;
          return [
            Aparecer(
              child: Tarjeta(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(obra.nombre, style: textos.headlineSmall!.copyWith(fontSize: 22)),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: IconoAlmira(IconoA.ubicacion, tamano: 18, color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 6),
                        Expanded(child: Text(obra.ubicacion, style: textos.bodyMedium)),
                      ],
                    ),
                    espacio,
                    Row(
                      children: [
                        _AnilloAvance(obra: obra),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (meta.isNotEmpty) _DatoCorto('Meta', meta),
                              if (meta.isNotEmpty && actualizada != null) const SizedBox(height: AppSpacing.md),
                              if (actualizada != null) _DatoCorto('Última actualización', haceDias(actualizada, hoy)),
                              if (inicio != null) ...[
                                const SizedBox(height: AppSpacing.md),
                                _DatoCorto('Inicio', fechaLarga(inicio)),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            espacio,
            Aparecer(
              paso: 1,
              child: Tarjeta(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const TituloSeccion('Presupuesto'),
                    espacio,
                    if (gasto != null) ...[_BloqueGasto(porcentaje: gasto, asignado: obra.montoAsignado), espacioChico],
                    _FilaMonto(IconoA.presupuesto, AppColors.primary, 'Asignado', soles(obra.montoAsignado)),
                    const Divider(),
                    _FilaMonto(IconoA.pagar, AppColors.coral, 'Gastado', soles(obra.montoEjecutado)),
                    if (obra.porcentajeTributos != null) ...[
                      const Divider(),
                      _FilaMonto(
                        IconoA.municipalidad,
                        AppColors.lima,
                        'Financiado con tributos',
                        '${obra.porcentajeTributos!.round()}$_nbsp%',
                      ),
                    ],
                  ],
                ),
              ),
            ),
            espacio,
            Aparecer(
              paso: 2,
              child: Tarjeta(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const TituloSeccion('Ubicación'),
                    espacioChico,
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
                  ],
                ),
              ),
            ),
            if (obra.hitos.isNotEmpty) ...[
              espacio,
              Tarjeta(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const TituloSeccion('Hitos'),
                    const SizedBox(height: AppSpacing.xs),
                    for (final (i, hito) in obra.hitos.indexed) ...[
                      if (i > 0) const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        child: Row(
                          children: [
                            _iconoHito(hito),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(child: Text(hito, style: textos.bodyLarge!)),
                          ],
                        ),
                      ),
                    ],
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

/// Espacio no separable: evita que «66 %» se parta en dos líneas.
const _nbsp = ' ';

/// Portada: la ilustración de la obra a todo el ancho, con el botón de volver y el estado. La hoja
/// crema sube sobre ella.
class _Portada extends StatelessWidget {
  const _Portada({required this.obra});

  final Obra? obra;

  @override
  Widget build(BuildContext context) {
    final arriba = MediaQuery.paddingOf(context).top;
    final o = obra;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: barraSobreBlanco,
      child: SizedBox(
        height: arriba + 210,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (o != null)
              ImagenIlustracion(ilustracionDeObra(o), ajuste: BoxFit.cover)
            else
              const ColoredBox(color: AppColors.primary100),
            Positioned(
              top: arriba + AppSpacing.md,
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.caja),
                      boxShadow: AppColors.sombraCard,
                    ),
                    child: BotonCuadro(
                      semantica: 'Volver',
                      fondo: AppColors.surface,
                      alTocar: () => Navigator.maybePop(context),
                      child: const Icon(Phosphor.arrowLeft, size: 22, color: AppColors.textPrimary),
                    ),
                  ),
                  const Spacer(),
                  if (o != null) InsigniaObra(o.estado),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Anillo del avance físico: se llena hasta el porcentaje (lima si la obra concluyó).
class _AnilloAvance extends StatelessWidget {
  const _AnilloAvance({required this.obra});

  final Obra obra;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final pct = obra.avancePct.clamp(0, 100).toDouble();
    final color = obra.estado == EstadoObra.finalizada ? AppColors.lima : AppColors.primary500;
    final anillo = TweenAnimationBuilder<double>(
      tween: Tween(begin: sinMovimiento(context) ? pct : 0, end: pct),
      duration: const Duration(milliseconds: 1400),
      curve: curvaAlmira,
      builder: (context, valor, _) => CustomPaint(
        painter: _PintorAnillo(fraccion: valor / 100, color: color),
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
    final base = Paint()
      ..color = AppColors.primary50
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosor;
    canvas.drawCircle(centro, radio, base);
    final arco = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosor
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: centro, radius: radio), -math.pi / 2, 2 * math.pi * fraccion, false, arco);
  }

  @override
  bool shouldRepaint(_PintorAnillo old) => old.fraccion != fraccion || old.color != color;
}

/// Rótulo pequeño en gris y valor en 800 (meta, última actualización).
class _DatoCorto extends StatelessWidget {
  const _DatoCorto(this.rotulo, this.valor);

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(rotulo, style: textos.labelMedium!.copyWith(color: AppColors.textSecondary)),
        Text(valor, style: textos.titleMedium!.copyWith(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

/// Bloque turquesa con el porcentaje gastado del presupuesto, el asignado y una barra sol.
class _BloqueGasto extends StatelessWidget {
  const _BloqueGasto({required this.porcentaje, required this.asignado});

  final double porcentaje;
  final double asignado;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Semantics(
      label: 'Gastado del presupuesto: ${porcentaje.round()} por ciento de ${soles(asignado)}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.campo + 2)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Gastado del presupuesto', style: textos.labelMedium!.copyWith(color: AppColors.subtextoCabecera)),
            const SizedBox(height: AppSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${porcentaje.round()}$_nbsp%',
                  style: textos.headlineMedium!.copyWith(color: AppColors.onPrimary, fontFeatures: cifrasTabulares),
                ),
                const Spacer(),
                Flexible(
                  child: Text(soles(asignado), style: textos.labelMedium!.copyWith(color: AppColors.subtextoCabecera)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppRadius.pastilla),
              ),
              child: BarraCreciente(fraccion: porcentaje / 100, color: AppColors.sol),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fila del presupuesto: caja pastel con el ícono, el rótulo y el monto a la derecha.
class _FilaMonto extends StatelessWidget {
  const _FilaMonto(this.icono, this.color, this.rotulo, this.valor);

  final IconoA icono;
  final Color color;
  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          IconoColor.svg(icono, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(rotulo, style: textos.bodyLarge)),
          const SizedBox(width: AppSpacing.md),
          Text(
            valor,
            textAlign: TextAlign.end,
            style: textos.titleMedium!.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              fontFeatures: cifrasTabulares,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ícono de un hito: completado si dice 100 %, en curso en los demás casos.
Widget _iconoHito(String hito) {
  final pct = RegExp(r'(\d+)\s*%').firstMatch(hito)?.group(1);
  final completo = pct != null && int.parse(pct) >= 100;
  return completo
      ? const IconoColor(PhosphorFill.checkCircle, color: AppColors.lima, lado: 36)
      : const IconoColor(PhosphorFill.clockClockwise, color: AppColors.sol, lado: 36);
}
