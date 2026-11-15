import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/iconos.dart';
import '../../app/router.dart';

import '../../app/theme/app_spacing.dart';
import '../../core/utils/formato.dart';
import '../../core/widgets/componentes.dart';
import '../../core/widgets/tributo.dart';
import '../../shared/models/modelos.dart';
import 'pagos_logica.dart';

class InsigniaDeuda extends StatelessWidget {
  const InsigniaDeuda(this.estado, {super.key});

  final EstadoDeuda estado;

  @override
  Widget build(BuildContext context) => switch (estado) {
        EstadoDeuda.vencida => Insignia(estado.etiqueta, tono: Tono.error, icono: Phosphor.warningCircle),
        EstadoDeuda.vigente => Insignia(estado.etiqueta, tono: Tono.aviso, icono: Phosphor.clock),
        EstadoDeuda.pagada => Insignia(estado.etiqueta, tono: Tono.exito, icono: Phosphor.check),
      };
}

/// Fila de una obligación, como una fila de lista: nombre del tributo en 15/500, periodo y
/// vencimiento en gris de 13 debajo, monto a la derecha y flecha. El vencimiento es una línea de
/// texto («Vence el 30 de noviembre»); solo si ya venció va en rojo. La insignia queda para los
/// estados reales: Vencida y Pagada.
class FilaDeuda extends StatelessWidget {
  const FilaDeuda({super.key, required this.deuda, required this.hoy, this.alTocar});

  final Deuda deuda;
  final DateTime hoy;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final estado = deuda.estadoAl(hoy);
    final vencida = estado == EstadoDeuda.vencida;
    return FilaLista(
      titulo: deuda.tipo.nombre,
      monto: soles(deuda.total),
      alTocar: alTocar,
      semantica: '${deuda.concepto}, ${soles(deuda.total)}, ${estado.etiqueta}. Ver detalle',
      detalle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (deuda.periodo.isNotEmpty) Text(deuda.periodo, style: textos.bodyMedium),
          if (estado == EstadoDeuda.pagada) ...[
            const SizedBox(height: AppSpacing.xs),
            InsigniaDeuda(estado),
          ] else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextoPlazo(vencimientoDe(deuda, hoy), vencido: vencida),
                if (vencida) InsigniaDeuda(estado),
              ],
            ),
        ],
      ),
    );
  }
}

/// Acción de pago: abre el pago en línea. En modo demostración no hay pago.
class AccionPago extends StatelessWidget {
  const AccionPago({super.key, required this.municipalidad, required this.esDemo});

  final Municipalidad? municipalidad;
  final bool esDemo;

  @override
  Widget build(BuildContext context) {
    if (esDemo) {
      return const Aviso(
        'Demostración: el pago no está disponible con datos de ejemplo.',
        tono: Tono.aviso,
      );
    }
    return FilledButton(
      onPressed: () => context.push(Rutas.pagoEnLinea),
      child: const Text('Pagar en línea'),
    );
  }
}
