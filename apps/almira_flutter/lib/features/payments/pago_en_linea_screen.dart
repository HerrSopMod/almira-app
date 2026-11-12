import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils/formato.dart';
import '../../core/widgets/componentes.dart';
import '../../shared/models/modelos.dart';
import '../../shared/services/proveedores.dart';
import '../account/estado_cuenta_logica.dart';
import 'pasos_pago.dart';

const _pestanas = [TipoDeuda.predial, TipoDeuda.arbitrios, TipoDeuda.coactivo, TipoDeuda.otros];

/// Pagos en línea: pestañas por tributo, «Beneficio al vencimiento» o «Deuda
/// general», periodos con casilla, importe total y «Siguiente».
class PagoEnLineaScreen extends ConsumerStatefulWidget {
  const PagoEnLineaScreen({super.key});

  @override
  ConsumerState<PagoEnLineaScreen> createState() => _PagoEnLineaScreenState();
}

class _PagoEnLineaScreenState extends ConsumerState<PagoEnLineaScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _pestanasControl = TabController(length: _pestanas.length, vsync: this)
    ..addListener(() => setState(() {}));
  bool _beneficio = true;
  final Set<String> _elegidas = {};

  @override
  void dispose() {
    _pestanasControl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vista = ref.watch(vistaProvider);
    final hoy = ref.watch(relojProvider)();
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagos en línea'),
        bottom: TabBar(
          controller: _pestanasControl,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          labelStyle: textos.titleSmall,
          unselectedLabelStyle: textos.titleSmall!.copyWith(fontWeight: FontWeight.w500),
          labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          dividerColor: Colors.transparent,
          tabs: [for (final t in _pestanas) Tab(text: t.etiqueta)],
        ),
      ),
      body: SafeArea(
        top: false,
        child: CuerpoAsyncSinLista<VistaMunicipal>(
          valor: vista,
          alRecargar: ref.read(datosProvider.notifier).recargar,
          construir: (v) {
            if (v.vecino == null) {
              return VistaVacia(
                icono: Icons.badge_outlined,
                titulo: 'Vincula tu código de contribuyente',
                accion: 'Vincular código',
                alTocar: () => context.push(Rutas.vincular),
              );
            }
            final tributo = _pestanas[_pestanasControl.index];
            final lista = deudasParaPagar(v.deudas, tributo, beneficio: _beneficio, hoy: hoy);
            final elegidasTotal = v.deudas.where((d) => _elegidas.contains(d.id) && d.pendiente).toList();
            final total = sumarSaldos(elegidasTotal);
            final todasMarcadas = lista.isNotEmpty && lista.every((d) => _elegidas.contains(d.id));

            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(AppSpacing.margen, AppSpacing.lg, AppSpacing.margen, 0),
                  child: PasosPago(actual: 0),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.margen, AppSpacing.md, AppSpacing.margen, 0),
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('Beneficio al vencimiento')),
                      ButtonSegment(value: false, label: Text('Deuda general')),
                    ],
                    selected: {_beneficio},
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(textStyle: textos.labelMedium),
                    onSelectionChanged: (s) => setState(() => _beneficio = s.first),
                  ),
                ),
                Expanded(
                  child: lista.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.all(AppSpacing.margen),
                          children: [
                            VistaVacia(
                              icono: Icons.check_circle_outline_rounded,
                              titulo: _beneficio
                                  ? 'No tienes pagos del año en curso'
                                  : 'No tienes deuda en ${tributo.etiqueta.toLowerCase()}',
                            ),
                          ],
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(
                              AppSpacing.margen, AppSpacing.md, AppSpacing.margen, AppSpacing.lg),
                          children: [
                            CheckboxListTile(
                              value: todasMarcadas,
                              onChanged: (marcar) => setState(() {
                                for (final d in lista) {
                                  marcar == true ? _elegidas.add(d.id) : _elegidas.remove(d.id);
                                }
                              }),
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Seleccionar todo'),
                            ),
                            for (final d in lista) ...[
                              _FilaPeriodo(
                                deuda: d,
                                hoy: hoy,
                                marcada: _elegidas.contains(d.id),
                                alCambiar: (marcar) => setState(
                                  () => marcar ? _elegidas.add(d.id) : _elegidas.remove(d.id),
                                ),
                              ),
                              espacioChico,
                            ],
                          ],
                        ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.margen, AppSpacing.md, AppSpacing.margen, AppSpacing.lg),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text('Importe total', style: textos.bodyLarge)),
                          Text(
                            soles(total),
                            style: textos.titleLarge!.copyWith(fontFeatures: cifrasTabulares),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: elegidasTotal.isEmpty
                              ? null
                              : () => context.push(
                                    Rutas.confirmarPago,
                                    extra: elegidasTotal.map((d) => d.id).toList(),
                                  ),
                          child: const Text('Siguiente'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FilaPeriodo extends StatelessWidget {
  const _FilaPeriodo({
    required this.deuda,
    required this.hoy,
    required this.marcada,
    required this.alCambiar,
  });

  final Deuda deuda;
  final DateTime hoy;
  final bool marcada;
  final ValueChanged<bool> alCambiar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final vencida = deuda.estadoAl(hoy) == EstadoDeuda.vencida;
    return Tarjeta(
      onTap: () => alCambiar(!marcada),
      padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
      semantica: '${deuda.concepto} ${deuda.periodo}, ${soles(deuda.saldo)}',
      child: Row(
        children: [
          Checkbox(value: marcada, onChanged: (m) => alCambiar(m ?? false)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(deuda.periodo.isEmpty ? deuda.concepto : deuda.periodo, style: textos.titleSmall),
                Text(deuda.concepto, style: textos.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                if (vencida) const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Insignia('Vencida', tono: Tono.error, icono: Icons.error_outline_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(soles(deuda.saldo), style: textos.titleSmall!.copyWith(fontFeatures: cifrasTabulares)),
        ],
      ),
    );
  }
}

/// Como `CuerpoAsync`, pero el contenido ocupa toda la pantalla (no es una lista que se desplaza).
class CuerpoAsyncSinLista<T> extends StatelessWidget {
  const CuerpoAsyncSinLista({
    super.key,
    required this.valor,
    required this.alRecargar,
    required this.construir,
  });

  final AsyncValue<T> valor;
  final Future<void> Function() alRecargar;
  final Widget Function(T datos) construir;

  @override
  Widget build(BuildContext context) {
    final datos = valor.valueOrNull;
    if (valor.hasError && !valor.isLoading) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.margen),
        children: [VistaError(valor.error!, alReintentar: alRecargar)],
      );
    }
    if (datos == null) return const VistaCargando();
    return construir(datos);
  }
}
