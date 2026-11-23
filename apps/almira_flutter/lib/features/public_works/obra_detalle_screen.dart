import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
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
      appBar: BarraAlmira(titulo: 'Obra'),
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Phosphor.mapPin, size: AppIconos.insignia + 2, color: AppColors.acentoRosa),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: Text(obra.ubicacion, style: textos.bodyMedium!)),
              ],
            ),
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
            espacioChico,
            Tarjeta(
              child: Column(
                children: [
                  _FilaIcono(PhosphorFill.wallet, AppColors.acentoAzul, 'Asignado', soles(obra.montoAsignado), aLaDerecha: true),
                  _FilaIcono(PhosphorFill.receipt, AppColors.acentoAmbar, 'Gastado', soles(obra.montoEjecutado), aLaDerecha: true),
                  if (gasto != null)
                    _FilaIcono(PhosphorFill.listChecks, AppColors.acentoVioleta, 'Gastado del presupuesto', '$gasto$_nbsp%', aLaDerecha: true),
                  if (obra.porcentajeTributos != null)
                    _FilaIcono(
                      PhosphorFill.bank,
                      AppColors.acentoVerde,
                      'Financiado con tributos',
                      '${obra.porcentajeTributos!.round()}$_nbsp%',
                      aLaDerecha: true,
                    ),
                ],
              ),
            ),
            if (inicio != null || obra.meta.trim().isNotEmpty || actualizada != null) ...[
              espacioGrande,
              Tarjeta(
                child: Column(
                  children: [
                    if (inicio != null) _FilaIcono(PhosphorFill.calendarBlank, AppColors.acentoAzul, 'Inicio', fechaLarga(inicio)),
                    if (obra.meta.trim().isNotEmpty) _FilaIcono(PhosphorFill.flag, AppColors.acentoRosa, 'Meta', obra.meta.trim()),
                    if (actualizada != null)
                      _FilaIcono(PhosphorFill.arrowClockwise, AppColors.acentoVerde, 'Última actualización', haceDias(actualizada, hoy)),
                  ],
                ),
              ),
            ],
            if (obra.hitos.isNotEmpty) ...[
              espacioGrande,
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
          ];
        },
      ),
    );
  }
}

/// Espacio no separable: evita que «66 %» se parta en dos líneas.
const _nbsp = ' ';

/// Ícono de un hito: completado si dice 100 %, en curso en los demás casos.
Widget _iconoHito(String hito) {
  final pct = RegExp(r'(\d+)\s*%').firstMatch(hito)?.group(1);
  final completo = pct != null && int.parse(pct) >= 100;
  return completo
      ? const IconoColor(PhosphorFill.checkCircle, color: AppColors.acentoVerde, lado: 36)
      : const IconoColor(PhosphorFill.clockClockwise, color: AppColors.acentoAmbar, lado: 36);
}

/// Dato con ícono de color: rótulo y valor. Los montos y porcentajes van a la derecha
/// ([aLaDerecha]); los demás, con el rótulo arriba y el valor debajo.
class _FilaIcono extends StatelessWidget {
  const _FilaIcono(this.icono, this.color, this.rotulo, this.valor, {this.aLaDerecha = false});

  final IconData icono;
  final Color color;
  final String rotulo;
  final String valor;
  final bool aLaDerecha;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          IconoColor(icono, color: color, lado: 36),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: aLaDerecha
                ? Text(rotulo, style: textos.bodyMedium)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rotulo, style: estiloRotulo(context)),
                      const SizedBox(height: 2),
                      Text(valor, style: textos.bodyLarge),
                    ],
                  ),
          ),
          if (aLaDerecha) ...[
            const SizedBox(width: AppSpacing.md),
            Text(
              valor,
              textAlign: TextAlign.end,
              style: textos.bodyLarge!.copyWith(fontWeight: FontWeight.w500, fontFeatures: cifrasTabulares),
            ),
          ],
        ],
      ),
    );
  }
}
