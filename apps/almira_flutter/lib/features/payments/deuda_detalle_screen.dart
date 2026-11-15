import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_spacing.dart';
import '../../app/theme/iconos.dart';
import '../../core/utils/formato.dart';
import '../../core/widgets/componentes.dart';
import '../../shared/models/modelos.dart';
import '../../shared/services/proveedores.dart';
import 'pagos_logica.dart';
import 'widgets_deuda.dart';

/// Detalle de una obligación: el monto primero, grande; debajo el concepto, el periodo y una
/// línea con el vencimiento (en rojo solo si ya venció); el desglose con líneas finas; las fichas
/// de fecha y predio; y una sola acción, pagar.
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
                icono: Phosphor.magnifyingGlass,
                titulo: 'No encontramos esta obligación',
                detalle: 'Puede que ya no esté registrada en tu municipalidad.',
              ),
            ];
          }
          final estado = deuda.estadoAl(hoy);
          final vencimiento = deuda.vencimiento;
          final predio = v.predios.where((p) => p.id == deuda.predioId).firstOrNull;
          return [
            Text(deuda.pendiente ? 'Saldo' : 'Total pagado', style: textos.bodyMedium),
            // El monto se achica antes que partirse en dos líneas.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Semantics(
                header: true,
                child: Text(soles(deuda.total), style: textos.displayMedium),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(deuda.concepto, style: textos.titleLarge),
            if (deuda.periodo.isNotEmpty) Text(deuda.periodo, style: textos.bodyMedium),
            const SizedBox(height: AppSpacing.sm),
            // Estado real en insignia solo si venció o ya está pagada; el plazo, en texto.
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (estado != EstadoDeuda.pagada)
                  TextoPlazo(vencimientoDe(deuda, hoy), vencido: estado == EstadoDeuda.vencida),
                if (estado != EstadoDeuda.vigente) InsigniaDeuda(estado),
              ],
            ),
            espacioGrande,
            const Divider(),
            FilaDato('Importe', soles(deuda.montoInsoluto)),
            if (deuda.gastosEmision > 0) FilaDato('Gastos de emisión', soles(deuda.gastosEmision)),
            if (deuda.interesMoratorio + deuda.interesActualizacion > 0)
              FilaDato('Intereses', soles(deuda.interesMoratorio + deuda.interesActualizacion)),
            if (deuda.descuento > 0) FilaDato('Descuento', '- ${soles(deuda.descuento)}'),
            const Divider(),
            FilaDato(deuda.pendiente ? 'Saldo' : 'Total pagado', soles(deuda.total), destacado: true),
            espacioGrande,
            Ficha('Fecha límite', vencimiento == null ? 'Sin fecha registrada' : fechaLarga(vencimiento)),
            if (predio != null) Ficha('Predio', predio.direccion),
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
