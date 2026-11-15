import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/iconos.dart';
import '../../app/router.dart';

import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
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

/// Fila de una obligación. Primera línea: ícono, nombre e importe a la derecha; debajo, el
/// periodo y el vencimiento, con la insignia de estado alineada a la derecha. Así el nombre
/// tiene todo el ancho y no se parte a mitad de palabra con letra grande.
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
          IconoTributo(deuda.tipo, lado: AppSpacing.caja),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(deuda.tipo.nombre, style: textos.titleMedium)),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      soles(deuda.total),
                      style: textos.titleMedium!.copyWith(fontFeatures: cifrasTabulares),
                    ),
                  ],
                ),
                if (deuda.periodo.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(deuda.periodo, style: textos.bodyMedium),
                ],
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(child: Text(vencimientoDe(deuda, hoy), style: textos.bodySmall)),
                    const SizedBox(width: AppSpacing.sm),
                    InsigniaDeuda(estado),
                  ],
                ),
              ],
            ),
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
