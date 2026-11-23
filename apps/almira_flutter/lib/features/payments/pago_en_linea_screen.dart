import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/iconos.dart';
import '../../app/theme/iconos_almira.dart';
import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
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

class _PagoEnLineaScreenState extends ConsumerState<PagoEnLineaScreen> with SingleTickerProviderStateMixin {
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
      appBar: BarraAlmira(titulo: 'Pagos en línea'),
      body: SafeArea(
        top: false,
        child: CuerpoAsyncSinLista<VistaMunicipal>(
          valor: vista,
          alRecargar: ref.read(datosProvider.notifier).recargar,
          construir: (v) {
            if (v.vecino == null) {
              return VistaVacia(
                icono: Phosphor.identificationBadge,
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
                // Pestañas por tributo, sobre blanco y con subrayado.
                TabBar(
                  controller: _pestanasControl,
                  // Se desplaza si con letra grande no entran: ninguna etiqueta se corta.
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  tabs: [for (final t in _pestanas) Tab(text: t.etiqueta)],
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(AppSpacing.margen, AppSpacing.xl, AppSpacing.margen, 0),
                  child: PasosPago(actual: 0),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.margen, AppSpacing.xl, AppSpacing.margen, 0),
                  child: Segmentado<bool>(
                    opciones: const [(true, 'Beneficio al vencimiento'), (false, 'Deuda general')],
                    actual: _beneficio,
                    alElegir: (b) => setState(() => _beneficio = b),
                  ),
                ),
                Expanded(
                  child: lista.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.all(AppSpacing.margen),
                          children: [
                            VistaVacia(
                              icono: Phosphor.checkCircle,
                              ilustracion: Ilustracion.vacioPagos,
                              titulo: '¡Estás al día!',
                              detalle: _beneficio
                                  ? 'No tienes pagos del año en curso en ${tributo.etiqueta}.'
                                  : 'No tienes deuda en ${tributo.etiqueta.toLowerCase()}.',
                            ),
                            Center(
                              child: FilledButton.icon(
                                onPressed: () => context.push(Rutas.estadoCuenta),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary100,
                                  foregroundColor: AppColors.primary,
                                  minimumSize: const Size(0, 44),
                                  shape: const StadiumBorder(),
                                ),
                                icon: const IconoAlmira(IconoA.historial, tamano: 18, color: AppColors.primary),
                                label: const Text('Ver historial de pagos'),
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.margen,
                            AppSpacing.md,
                            AppSpacing.margen,
                            AppSpacing.lg,
                          ),
                          children: [
                            GrupoTarjeta(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.xs,
                                AppSpacing.xs,
                                AppSpacing.lg,
                                AppSpacing.xs,
                              ),
                              filas: [
                                InkWell(
                                  onTap: () => setState(() {
                                    for (final d in lista) {
                                      todasMarcadas ? _elegidas.remove(d.id) : _elegidas.add(d.id);
                                    }
                                  }),
                                  child: Row(
                                    children: [
                                      CasillaAlmira(
                                        marcada: todasMarcadas,
                                        semantica: 'Seleccionar todo',
                                        alCambiar: (marcar) => setState(() {
                                          for (final d in lista) {
                                            marcar ? _elegidas.add(d.id) : _elegidas.remove(d.id);
                                          }
                                        }),
                                      ),
                                      Text('Seleccionar todo', style: textos.titleMedium),
                                    ],
                                  ),
                                ),
                                for (final d in lista)
                                  _FilaPeriodo(
                                    deuda: d,
                                    hoy: hoy,
                                    marcada: _elegidas.contains(d.id),
                                    alCambiar: (marcar) =>
                                        setState(() => marcar ? _elegidas.add(d.id) : _elegidas.remove(d.id)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.margen,
                    AppSpacing.md,
                    AppSpacing.margen,
                    AppSpacing.lg,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Importe total', style: textos.labelMedium),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Monto(total, tamano: 26),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      SizedBox(
                        child: FilledButton(
                          onPressed: elegidasTotal.isEmpty
                              ? null
                              : () => context.push(Rutas.confirmarPago, extra: elegidasTotal.map((d) => d.id).toList()),
                          style: FilledButton.styleFrom(minimumSize: const Size(132, AppSpacing.boton)),
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

/// Periodo a pagar: casilla, periodo en 15/500 con el concepto en gris debajo, y el saldo a la
/// derecha. Si ya venció, la insignia «Vencida» (estado real).
class _FilaPeriodo extends StatelessWidget {
  const _FilaPeriodo({required this.deuda, required this.hoy, required this.marcada, required this.alCambiar});

  final Deuda deuda;
  final DateTime hoy;
  final bool marcada;
  final ValueChanged<bool> alCambiar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final vencida = deuda.estadoAl(hoy) == EstadoDeuda.vencida;
    return FilaLista(
      titulo: deuda.periodo.isEmpty ? deuda.concepto : deuda.periodo,
      monto: soles(deuda.saldo),
      alTocar: () => alCambiar(!marcada),
      final_: const SizedBox.shrink(),
      semantica: '${deuda.concepto} ${deuda.periodo}, ${soles(deuda.saldo)}',
      inicio: CasillaAlmira(marcada: marcada, alCambiar: alCambiar, semantica: deuda.periodo),
      detalle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(deuda.concepto, style: textos.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
          if (vencida)
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.xs),
              child: Insignia('Vencida', tono: Tono.error, icono: Phosphor.warningCircle),
            ),
        ],
      ),
    );
  }
}

/// Como `CuerpoAsync`, pero el contenido ocupa toda la pantalla (no es una lista que se desplaza).
class CuerpoAsyncSinLista<T> extends StatelessWidget {
  const CuerpoAsyncSinLista({super.key, required this.valor, required this.alRecargar, required this.construir});

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
