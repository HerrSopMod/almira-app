import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_spacing.dart';
import '../../core/utils/formato.dart';
import '../../core/widgets/componentes.dart';
import '../../shared/services/proveedores.dart';
import 'widgets_deuda.dart';

class DeudaDetalleScreen extends ConsumerWidget {
  const DeudaDetalleScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vista = ref.watch(vistaProvider);
    final esDemo = ref.watch(esDemoProvider);
    final hoy = ref.watch(relojProvider)();
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle')),
      body: CuerpoAsync<VistaMunicipal>(
        valor: vista,
        alRecargar: ref.read(datosProvider.notifier).recargar,
        construir: (v) {
          final deuda = v.deudas.where((d) => d.id == id).firstOrNull;
          if (deuda == null) {
            return const [
              VistaVacia(
                icono: Icons.search_off_rounded,
                titulo: 'No encontramos esta obligación',
                detalle: 'Puede que ya no esté registrada en tu municipalidad.',
              ),
            ];
          }
          final estado = deuda.estadoAl(hoy);
          final vencimiento = deuda.vencimiento;
          final predio = v.predios.where((p) => p.id == deuda.predioId).firstOrNull;
          return [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(deuda.concepto, style: textos.headlineSmall),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                InsigniaDeuda(estado),
              ],
            ),
            if (deuda.periodo.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(deuda.periodo, style: textos.bodyMedium),
            ],
            espacio,
            Tarjeta(
              child: Column(
                children: [
                  FilaDato('Importe', soles(deuda.montoInsoluto)),
                  if (deuda.gastosEmision > 0) FilaDato('Gastos de emisión', soles(deuda.gastosEmision)),
                  if (deuda.interesMoratorio + deuda.interesActualizacion > 0)
                    FilaDato('Intereses', soles(deuda.interesMoratorio + deuda.interesActualizacion)),
                  if (deuda.descuento > 0) FilaDato('Descuento', '- ${soles(deuda.descuento)}'),
                  const Divider(height: AppSpacing.xl),
                  FilaDato(deuda.pendiente ? 'Saldo' : 'Total pagado', soles(deuda.total), destacado: true),
                ],
              ),
            ),
            espacio,
            Tarjeta(
              child: Column(
                children: [
                  FilaDato(
                    'Fecha límite',
                    vencimiento == null ? 'Sin fecha registrada' : fechaLarga(vencimiento),
                  ),
                  if (predio != null) FilaDato('Predio', predio.direccion),
                ],
              ),
            ),
            if (deuda.pendiente) ...[
              espacioGrande,
              AccionPago(municipalidad: v.municipalidad, esDemo: esDemo),
            ],
          ];
        },
      ),
    );
  }
}
