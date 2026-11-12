import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
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
            Semantics(
              header: true,
              child: Text(
                obra.nombre,
                style: textos.headlineSmall!.copyWith(fontSize: 21, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(alignment: Alignment.centerLeft, child: InsigniaObra(obra.estado)),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(Icons.place_outlined, size: 18, color: AppColors.textSecondary),
                ),
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
                  _FilaObra(Icons.account_balance_wallet_outlined, 'Asignado', soles(obra.montoAsignado)),
                  _FilaObra(
                    Icons.payments_outlined,
                    'Gastado',
                    soles(obra.montoEjecutado),
                    avance: gasto == null ? null : gasto / 100,
                    nota: gasto == null ? null : '$gasto${_nbsp}% del presupuesto',
                  ),
                  if (obra.porcentajeTributos != null)
                    _FilaObra(
                      Icons.account_balance_outlined,
                      'Financiado con tributos',
                      '${obra.porcentajeTributos!.round()}$_nbsp%',
                    ),
                ],
              ),
            ),
            espacio,
            Tarjeta(
              child: Column(
                children: [
                  if (inicio != null) _FilaObra(Icons.event_outlined, 'Inicio', fechaLarga(inicio)),
                  if (obra.meta.trim().isNotEmpty) _FilaObra(Icons.flag_outlined, 'Meta', obra.meta, largo: true),
                  if (actualizada != null)
                    _FilaObra(Icons.update_rounded, 'Última actualización', haceDias(actualizada, hoy)),
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
                        child: Icon(Icons.flag_outlined, size: 20, color: AppColors.textPrimary),
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

/// Espacio no separable: evita que «66 %» se parta en dos líneas.
const _nbsp = ' ';

/// Fila de una tarjeta de la obra: ícono oscuro a la izquierda, etiqueta y valor alineado a la
/// derecha en una sola línea. Con [avance] y [nota] muestra debajo una mini barra y su texto.
/// Con [largo] el valor va bajo la etiqueta, para textos que no caben en una línea.
class _FilaObra extends StatelessWidget {
  const _FilaObra(this.icono, this.etiqueta, this.valor, {this.avance, this.nota, this.largo = false});

  final IconData icono;
  final String etiqueta;
  final String valor;
  final double? avance;
  final String? nota;
  final bool largo;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final cifras = textos.titleSmall!.copyWith(fontFeatures: cifrasTabulares);
    final Widget cuerpo;
    if (largo) {
      cuerpo = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiqueta, style: textos.bodyMedium),
          const SizedBox(height: 2),
          Text(valor, style: textos.bodyLarge),
        ],
      );
    } else {
      // La etiqueta ocupa lo que necesita (hasta el 55 % del ancho) y el valor se alinea a la
      // derecha en el resto, de modo que todos los valores quedan en la misma columna.
      cuerpo = LayoutBuilder(
        builder: (context, caja) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: caja.maxWidth * 0.55),
              child: Text(etiqueta, style: textos.bodyMedium),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(valor, style: cifras, maxLines: 1, softWrap: false),
                  ),
                  if (nota != null) ...[
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(nota!, style: textos.bodySmall, maxLines: 1, softWrap: false),
                    ),
                  ],
                  if (avance != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    SizedBox(
                      width: 104,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.pastilla),
                        child: LinearProgressIndicator(
                          value: avance!.clamp(0, 1),
                          minHeight: 4,
                          color: AppColors.textPrimary,
                          semanticsLabel: 'Presupuesto gastado',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icono, size: 20, color: AppColors.textPrimary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: cuerpo),
        ],
      ),
    );
  }
}
