import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/iconos.dart';
import '../../core/utils/formato.dart';
import '../../core/widgets/componentes.dart';
import '../../shared/models/modelos.dart';
import '../../shared/services/proveedores.dart';
import 'widgets_deuda.dart';

/// Detalle de una obligación: el monto primero, grande y con aire; debajo el concepto y el
/// periodo; luego una fila con el plazo y la insignia de estado; el desglose; y una sola
/// acción, pagar.
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
            const SizedBox(height: AppSpacing.xs),
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
            if (deuda.periodo.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(deuda.periodo, style: textos.bodyMedium),
            ],
            espacioGrande,
            _FilaPlazo(estado: estado, vencimiento: vencimiento, hoy: hoy),
            espacioGrande,
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
              espacioSeccion,
              AccionPago(municipalidad: v.municipalidad, esDemo: esDemo),
            ],
          ];
        },
      ),
    );
  }
}

/// «Vence en 15 días», «Vence hoy» o «Venció hace 3 días», con un reloj a la izquierda y la
/// insignia de estado a la derecha. La fecha exacta va en la tarjeta de abajo.
class _FilaPlazo extends StatelessWidget {
  const _FilaPlazo({required this.estado, required this.vencimiento, required this.hoy});

  final EstadoDeuda estado;
  final DateTime? vencimiento;
  final DateTime hoy;

  String get _texto {
    final v = vencimiento;
    if (estado == EstadoDeuda.pagada) return 'Pagada';
    if (v == null) return 'Sin fecha de vencimiento';
    final dias = diasEntre(hoy, v);
    if (dias == 0) return 'Vence hoy';
    if (dias > 0) return 'Vence en ${plural(dias, 'día', 'días')}';
    return 'Venció hace ${plural(-dias, 'día', 'días')}';
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(
          estado == EstadoDeuda.pagada ? Phosphor.checkCircle : Phosphor.clock,
          size: AppIconos.lista,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(_texto, style: textos.bodyLarge!.copyWith(fontWeight: FontWeight.w500))),
        const SizedBox(width: AppSpacing.sm),
        InsigniaDeuda(estado),
      ],
    );
  }
}
