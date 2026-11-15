import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/iconos.dart';
import '../../app/router.dart';
import '../../core/widgets/componentes.dart';
import '../../shared/models/modelos.dart';
import '../../shared/services/proveedores.dart';
import 'piezas_lista.dart';
import 'reclamos_logica.dart';

/// Insignia del reclamo: solo su estado real (En atención, Derivado, Resuelto).
/// El plazo va aparte, como una línea de texto.
class InsigniaReclamo extends StatelessWidget {
  const InsigniaReclamo({super.key, required this.reclamo});

  final Reclamo reclamo;

  @override
  Widget build(BuildContext context) => reclamo.resuelto
      ? const Insignia('Resuelto', tono: Tono.exito, icono: Phosphor.check)
      : Insignia(reclamo.estado.etiqueta, tono: Tono.primario);
}

class ReclamosScreen extends ConsumerWidget {
  const ReclamosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vista = ref.watch(vistaProvider);
    final hoy = ref.watch(relojProvider)();
    final esDemo = ref.watch(esDemoProvider);

    return Scaffold(
      body: CuerpoAsync<VistaMunicipal>(
        valor: vista,
        alRecargar: ref.read(datosProvider.notifier).recargar,
        cabecera: (_) => CabeceraMarca(titulo: 'Reclamos', esDemo: esDemo),
        construir: (v) {
          if (v.vecino == null) {
            return [
              VistaVacia(
                icono: Phosphor.identificationBadge,
                titulo: 'Vincula tu código de contribuyente',
                detalle: 'Lo necesitas para enviar reclamos.',
                accion: 'Vincular código',
                alTocar: () => context.push(Rutas.vincular),
              ),
            ];
          }
          if (v.reclamos.isEmpty) {
            return [
              VistaVacia(
                icono: Phosphor.megaphone,
                titulo: 'Aún no tienes reclamos',
                detalle: 'Reporta un problema con una foto y su ubicación.',
                accion: 'Nuevo reclamo',
                alTocar: () => context.push(Rutas.nuevoReclamo),
              ),
            ];
          }
          return [
            // Única acción primaria de la pantalla, arriba de la lista.
            FilledButton(
              onPressed: () => context.push(Rutas.nuevoReclamo),
              child: const Text('Nuevo reclamo'),
            ),
            espacioGrande,
            ListaFilas(
              filas: [for (final reclamo in v.reclamos) _FilaReclamo(reclamo: reclamo, hoy: hoy)],
            ),
          ];
        },
      ),
    );
  }
}

class _FilaReclamo extends StatelessWidget {
  const _FilaReclamo({required this.reclamo, required this.hoy});

  final Reclamo reclamo;
  final DateTime hoy;

  @override
  Widget build(BuildContext context) {
    final plazo = plazoDe(reclamo, hoy);
    final detalle = plazo == null ? '${reclamo.codigo} · ${reclamo.tipo.etiqueta}' : textoPlazo(plazo);
    return FilaLista(
      titulo: reclamo.titulo,
      detalle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          plazo == null ? DetalleFila(detalle) : PlazoReclamo(plazo),
          espacioChico,
          InsigniaReclamo(reclamo: reclamo),
        ],
      ),
      alTocar: () => context.go(Rutas.reclamo(reclamo.id)),
      semantica: '${reclamo.titulo}. ${reclamo.resuelto ? 'Resuelto' : reclamo.estado.etiqueta}. $detalle. '
          'Ver seguimiento',
    );
  }
}
