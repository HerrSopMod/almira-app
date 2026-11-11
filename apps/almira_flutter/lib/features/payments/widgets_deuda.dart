import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';

import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils/formato.dart';
import '../../core/widgets/componentes.dart';
import '../../shared/models/modelos.dart';
import 'pagos_logica.dart';

class InsigniaDeuda extends StatelessWidget {
  const InsigniaDeuda(this.estado, {super.key});

  final EstadoDeuda estado;

  @override
  Widget build(BuildContext context) => switch (estado) {
        EstadoDeuda.vencida => Insignia(estado.etiqueta, tono: Tono.error, icono: Icons.error_outline_rounded),
        EstadoDeuda.vigente => Insignia(estado.etiqueta, tono: Tono.aviso, icono: Icons.schedule_rounded),
        EstadoDeuda.pagada => Insignia(estado.etiqueta, tono: Tono.exito, icono: Icons.check_rounded),
      };
}

/// Fila de una obligación: concepto, periodo, vencimiento, importe y estado.
class FilaDeuda extends StatelessWidget {
  const FilaDeuda({super.key, required this.deuda, required this.hoy, this.alTocar});

  final Deuda deuda;
  final DateTime hoy;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final estado = deuda.estadoAl(hoy);
    return Tarjeta(
      onTap: alTocar,
      semantica: '${deuda.concepto}, ${soles(deuda.total)}, ${estado.etiqueta}. Ver detalle',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(deuda.concepto, style: textos.titleMedium),
                if (deuda.periodo.isNotEmpty) Text(deuda.periodo, style: textos.bodyMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(vencimientoDe(deuda, hoy), style: textos.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                soles(deuda.total),
                style: textos.titleMedium!.copyWith(fontFeatures: cifrasTabulares),
              ),
              const SizedBox(height: AppSpacing.sm),
              InsigniaDeuda(estado),
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
    return FilledButton.icon(
      onPressed: () => context.push(Rutas.pagoEnLinea),
      icon: const Icon(Icons.lock_outline_rounded, size: 20),
      label: const Text('Pagar en línea'),
    );
  }
}
