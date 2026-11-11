import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/utils/formato.dart';
import '../../core/utils/plazos.dart';
import '../../core/widgets/componentes.dart';
import '../../shared/models/modelos.dart';
import '../../shared/services/proveedores.dart';
import 'reclamos_logica.dart';

/// Insignia del reclamo: «Resuelto» o la situación de su plazo.
class InsigniaReclamo extends StatelessWidget {
  const InsigniaReclamo({super.key, required this.reclamo, required this.hoy});

  final Reclamo reclamo;
  final DateTime hoy;

  @override
  Widget build(BuildContext context) {
    if (reclamo.resuelto) {
      return const Insignia('Resuelto', tono: Tono.exito, icono: Icons.check_rounded);
    }
    final plazo = plazoDe(reclamo, hoy)!;
    return switch (plazo.estado) {
      EstadoPlazo.dentro => Insignia(plazo.etiqueta, tono: Tono.primario, icono: Icons.schedule_rounded),
      EstadoPlazo.porVencer ||
      EstadoPlazo.venceHoy =>
        Insignia(plazo.etiqueta, tono: Tono.aviso, icono: Icons.schedule_rounded),
      EstadoPlazo.vencido =>
        Insignia(plazo.etiqueta, tono: Tono.error, icono: Icons.error_outline_rounded),
      EstadoPlazo.porConfirmar =>
        Insignia(plazo.etiqueta, icono: Icons.help_outline_rounded),
    };
  }
}

class ReclamosScreen extends ConsumerWidget {
  const ReclamosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vista = ref.watch(vistaProvider);
    final hoy = ref.watch(relojProvider)();
    final esDemo = ref.watch(esDemoProvider);
    final puedeReclamar = vista.valueOrNull?.vecino != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reclamos'),
        actions: [
          if (esDemo)
            const Padding(
              padding: EdgeInsets.only(right: AppSpacing.lg),
              child: Center(child: EtiquetaDemo(sobreTurquesa: true)),
            ),
        ],
      ),
      floatingActionButton: puedeReclamar
          ? FloatingActionButton.extended(
              onPressed: () => context.push(Rutas.nuevoReclamo),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nuevo reclamo'),
              elevation: 2,
            )
          : null,
      body: CuerpoAsync<VistaMunicipal>(
        valor: vista,
        alRecargar: ref.read(datosProvider.notifier).recargar,
        construir: (v) {
          if (v.vecino == null) {
            return [
              VistaVacia(
                icono: Icons.badge_outlined,
                titulo: 'Vincula tu código de contribuyente',
                detalle: 'Lo necesitas para enviar reclamos a tu municipalidad.',
                accion: 'Vincular código',
                alTocar: () => context.push(Rutas.vincular),
              ),
            ];
          }
          if (v.reclamos.isEmpty) {
            return const [
              VistaVacia(
                icono: Icons.campaign_outlined,
                titulo: 'Aún no tienes reclamos',
                detalle: 'Reporta un problema con una foto y su ubicación.',
              ),
            ];
          }
          return [
            for (final reclamo in v.reclamos) ...[
              _TarjetaReclamo(reclamo: reclamo, hoy: hoy),
              espacioChico,
            ],
            // Deja libre el espacio del botón flotante.
            const SizedBox(height: 72),
          ];
        },
      ),
    );
  }
}

class _TarjetaReclamo extends StatelessWidget {
  const _TarjetaReclamo({required this.reclamo, required this.hoy});

  final Reclamo reclamo;
  final DateTime hoy;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final creado = reclamo.creadoEn;
    return Tarjeta(
      onTap: () => context.go(Rutas.reclamo(reclamo.id)),
      semantica: 'Reclamo ${reclamo.codigo}, ${reclamo.titulo}. Ver seguimiento',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(reclamo.titulo, style: textos.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(
            [reclamo.codigo, reclamo.tipo.etiqueta, if (creado != null) fechaCorta(creado)].join(' · '),
            style: textos.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          InsigniaReclamo(reclamo: reclamo, hoy: hoy),
        ],
      ),
    );
  }
}
