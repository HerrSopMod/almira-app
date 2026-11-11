import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils/formato.dart';
import '../../core/widgets/componentes.dart';
import '../../shared/models/modelos.dart';
import '../../shared/services/proveedores.dart';
import 'pagos_logica.dart';
import 'widgets_deuda.dart';

/// Pagar: obligaciones por estado y, en «Pagados», los pagos registrados.
class PagosScreen extends ConsumerStatefulWidget {
  const PagosScreen({super.key, this.filtroInicial});

  final String? filtroInicial;

  @override
  ConsumerState<PagosScreen> createState() => _PagosScreenState();
}

class _PagosScreenState extends ConsumerState<PagosScreen> {
  late FiltroDeuda _filtro = FiltroDeuda.de(widget.filtroInicial);

  @override
  void didUpdateWidget(PagosScreen anterior) {
    super.didUpdateWidget(anterior);
    if (widget.filtroInicial != null && widget.filtroInicial != anterior.filtroInicial) {
      _filtro = FiltroDeuda.de(widget.filtroInicial);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vista = ref.watch(vistaProvider);
    final esDemo = ref.watch(esDemoProvider);
    final hoy = ref.watch(relojProvider)();
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagar'),
        actions: [
          if (esDemo)
            const Padding(
              padding: EdgeInsets.only(right: AppSpacing.lg),
              child: Center(child: EtiquetaDemo(sobreTurquesa: true)),
            ),
        ],
      ),
      body: CuerpoAsync<VistaMunicipal>(
        valor: vista,
        alRecargar: ref.read(datosProvider.notifier).recargar,
        construir: (v) {
          if (v.vecino == null) {
            return [
              VistaVacia(
                icono: Icons.badge_outlined,
                titulo: 'Vincula tu código de contribuyente',
                detalle: 'Así verás tus tributos de ${v.municipalidad?.nombre ?? 'tu municipalidad'}.',
                accion: 'Vincular código',
                alTocar: () => context.push(Rutas.vincular),
              ),
            ];
          }
          final resumen = resumirDeuda(v.deudas, hoy);
          final lista = filtrarDeudas(v.deudas, _filtro, hoy);
          return [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: Text('Total pendiente', style: textos.bodyMedium)),
                Text(
                  soles(resumen.total),
                  style: textos.headlineSmall!.copyWith(fontFeatures: cifrasTabulares),
                ),
              ],
            ),
            espacio,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final filtro in FiltroDeuda.values)
                  ChoiceChip(
                    label: Text(filtro.etiqueta),
                    selected: _filtro == filtro,
                    onSelected: (_) => setState(() => _filtro = filtro),
                  ),
              ],
            ),
            espacio,
            if (lista.isEmpty)
              VistaVacia(
                icono: switch (_filtro) {
                  FiltroDeuda.pagados => Icons.receipt_long_outlined,
                  _ => Icons.check_circle_outline_rounded,
                },
                titulo: switch (_filtro) {
                  FiltroDeuda.pendientes => 'No tienes obligaciones pendientes',
                  FiltroDeuda.vencidos => 'No tienes obligaciones vencidas',
                  FiltroDeuda.pagados => 'Aún no hay pagos registrados',
                },
              )
            else
              for (final deuda in lista) ...[
                FilaDeuda(
                  deuda: deuda,
                  hoy: hoy,
                  alTocar: () => context.go(Rutas.deuda(deuda.id)),
                ),
                espacioChico,
              ],
            if (_filtro == FiltroDeuda.pagados && v.pagos.isNotEmpty) ...[
              espacio,
              TituloSeccion('Constancias'),
              espacioChico,
              Tarjeta(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                child: Column(
                  children: [
                    for (final (i, pago) in v.pagos.indexed) ...[
                      if (i > 0) const Divider(),
                      _FilaPago(
                        pago: pago,
                        deuda: v.deudas.where((d) => d.id == pago.deudaId).firstOrNull,
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (_filtro != FiltroDeuda.pagados && resumen.cantidad > 0) ...[
              espacio,
              AccionPago(municipalidad: v.municipalidad, esDemo: esDemo),
            ],
          ];
        },
      ),
    );
  }
}

class _FilaPago extends StatelessWidget {
  const _FilaPago({required this.pago, this.deuda});

  final Pago pago;
  final Deuda? deuda;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final fecha = pago.creadoEn;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(deuda?.concepto ?? 'Pago', style: textos.titleSmall),
                Text(
                  [
                    if (fecha != null) fechaCorta(fecha),
                    if (pago.referencia != null) pago.referencia!,
                    pago.estado.etiqueta,
                  ].join(' · '),
                  style: textos.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            soles(pago.monto),
            style: textos.titleSmall!.copyWith(fontFeatures: cifrasTabulares),
          ),
        ],
      ),
    );
  }
}
