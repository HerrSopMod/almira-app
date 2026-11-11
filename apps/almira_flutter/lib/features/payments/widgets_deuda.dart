import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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

/// Acción de pago. Almira no procesa pagos: lleva al portal oficial de la
/// municipalidad cuando existe, y lo dice. En modo demostración no hay pago.
class AccionPago extends StatelessWidget {
  const AccionPago({super.key, required this.municipalidad, required this.esDemo});

  final Municipalidad? municipalidad;
  final bool esDemo;

  Future<void> _abrir(BuildContext context, String url) async {
    final abierto = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)
        .catchError((_) => false);
    if (!abierto && context.mounted) {
      mostrarMensaje(context, 'No se pudo abrir el portal de pago.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (esDemo) {
      return const Aviso(
        'Demostración: el pago no está disponible con datos de ejemplo.',
        tono: Tono.aviso,
      );
    }
    final url = municipalidad?.urlPago;
    if (url == null || url.isEmpty) {
      return const Aviso('Tu municipalidad aún no tiene un portal de pago enlazado en Almira.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: () => _abrir(context, url),
          icon: const Icon(Icons.open_in_new_rounded, size: 20),
          label: const Text('Pagar en el portal municipal'),
        ),
        espacioChico,
        Text(
          'El pago se hace en el portal de tu municipalidad. Puede tardar en verse aquí.',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
