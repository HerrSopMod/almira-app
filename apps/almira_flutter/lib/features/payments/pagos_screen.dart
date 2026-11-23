import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/iconos.dart';
import '../../app/theme/iconos_almira.dart';
import '../../app/router.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils/formato.dart';
import '../../core/utils/rango_fechas.dart';
import '../../core/widgets/componentes.dart';
import '../../core/widgets/filtros.dart';
import '../../core/widgets/movimiento.dart';
import '../../core/widgets/tributo.dart';
import '../account/estado_cuenta_logica.dart';
import '../../shared/models/modelos.dart';
import '../../shared/services/proveedores.dart';
import 'pagos_logica.dart';
import 'widgets_deuda.dart';

/// Pagar (rediseño): selector Pendientes / Vencidos / Pagados, filtro por fechas y las
/// obligaciones con casilla. La barra de abajo suma lo elegido (en el teléfono) y «Pagar» abre la
/// confirmación de siempre; el servidor toma los montos de la base. En «Pagados», los pagos
/// registrados. Al final, los documentos.
class PagosScreen extends ConsumerStatefulWidget {
  const PagosScreen({super.key, this.filtroInicial});

  final String? filtroInicial;

  @override
  ConsumerState<PagosScreen> createState() => _PagosScreenState();
}

class _PagosScreenState extends ConsumerState<PagosScreen> {
  late FiltroDeuda _filtro = FiltroDeuda.de(widget.filtroInicial);
  FiltroFechas _fechas = FiltroFechas.todas;

  /// Obligaciones que el vecino quitó de la selección (por defecto, todas van marcadas).
  final Set<String> _desmarcadas = {};

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
    final v = vista.valueOrNull;
    final seleccionables = v == null || v.vecino == null || _filtro == FiltroDeuda.pagados
        ? const <Deuda>[]
        : _lista(v, hoy);
    final elegidas = seleccionables.where((d) => d.pendiente && !_desmarcadas.contains(d.id)).toList();
    return Scaffold(
      bottomNavigationBar: seleccionables.isEmpty
          ? null
          : _BarraSeleccion(
              cantidad: elegidas.length,
              total: sumarSaldos(elegidas),
              // En demostración no hay pago: se muestra el total, pero no se paga.
              alPagar: esDemo || elegidas.isEmpty
                  ? null
                  : () => context.push(Rutas.confirmarPago, extra: elegidas.map((d) => d.id).toList()),
            ),
      body: CuerpoAsync<VistaMunicipal>(
        valor: vista,
        alRecargar: ref.read(datosProvider.notifier).recargar,
        cabecera: (v) => CabeceraMarca(titulo: 'Pagar', esDemo: esDemo),
        construir: (v) {
          if (v.vecino == null) {
            return [
              VistaVacia(
                icono: Phosphor.identificationBadge,
                ilustracion: Ilustracion.pasoCuponera,
                titulo: 'Vincula tu código de contribuyente',
                detalle: 'Así verás tus tributos de ${v.municipalidad?.nombre ?? 'tu municipalidad'}.',
                accion: 'Vincular código',
                alTocar: () => context.push(Rutas.vincular),
              ),
            ];
          }
          final lista = _lista(v, hoy);
          final pagados = _filtro == FiltroDeuda.pagados;
          return [
            Aparecer(
              child: Segmentado<FiltroDeuda>(
                oscuro: true,
                opciones: [for (final f in FiltroDeuda.values) (f, f.etiqueta)],
                actual: _filtro,
                alElegir: (f) => setState(() => _filtro = f),
              ),
            ),
            espacio,
            GrupoFiltroFechas(filtro: _fechas, hoy: hoy, alCambiar: (f) => setState(() => _fechas = f)),
            espacio,
            if (lista.isEmpty)
              VistaVacia(
                icono: pagados ? Phosphor.receipt : Phosphor.checkCircle,
                ilustracion: pagados ? null : Ilustracion.vacioPagos,
                titulo: switch (_filtro) {
                  FiltroDeuda.pendientes => '¡Estás al día!',
                  FiltroDeuda.vencidos => 'No tienes obligaciones vencidas',
                  FiltroDeuda.pagados => 'Aún no hay pagos registrados',
                },
                detalle: _filtro == FiltroDeuda.pendientes ? 'No tienes obligaciones pendientes.' : null,
              )
            else
              Aparecer(
                paso: 2,
                child: GrupoTarjeta(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.xs, AppSpacing.lg, AppSpacing.xs),
                  filas: [
                    for (final deuda in lista)
                      _FilaObligacion(
                        deuda: deuda,
                        hoy: hoy,
                        marcada: !pagados && !_desmarcadas.contains(deuda.id),
                        alMarcar: pagados || !deuda.pendiente
                            ? null
                            : (m) => setState(() => m ? _desmarcadas.remove(deuda.id) : _desmarcadas.add(deuda.id)),
                        alTocar: () => context.go(Rutas.deuda(deuda.id)),
                        conEstado: !pagados,
                      ),
                  ],
                ),
              ),
            if (pagados && v.pagos.isNotEmpty) ...[
              espacioGrande,
              const TituloSeccion('Constancias'),
              espacio,
              GrupoTarjeta(
                filas: [
                  for (final pago in v.pagos)
                    _FilaPago(pago: pago, deuda: v.deudas.where((d) => d.id == pago.deudaId).firstOrNull),
                ],
              ),
            ],
            if (!pagados && esDemo && lista.isNotEmpty) ...[
              espacio,
              const Aviso('En la demostración el pago no está disponible: usamos datos de ejemplo.', tono: Tono.aviso),
            ],
            espacioGrande,
            const TituloSeccion('Documentos'),
            espacio,
            GrupoTarjeta(
              filas: [
                FilaAccion(
                  icono: Phosphor.receipt,
                  titulo: 'Estado de cuenta',
                  detalle: 'Al ${fechaLarga(hoy)}',
                  alTocar: () => context.push(Rutas.estadoCuenta),
                ),
                FilaAccion(
                  icono: Phosphor.fileText,
                  titulo: 'Cuponera',
                  detalle: 'Resumen de tus tributos del año',
                  alTocar: () => context.push(Rutas.cuponera),
                ),
              ],
            ),
          ];
        },
      ),
    );
  }

  /// Obligaciones del estado y las fechas elegidas. El filtro por fechas mira el vencimiento (o el
  /// día de pago, en «Pagados»).
  List<Deuda> _lista(VistaMunicipal v, DateTime hoy) => [
    for (final d in filtrarDeudas(v.deudas, _filtro, hoy))
      if (_fechas.contiene(_filtro == FiltroDeuda.pagados ? (d.fechaPago ?? d.vencimiento) : d.vencimiento, hoy)) d,
  ];
}

/// Barra fija de abajo: cuántas van elegidas, el total y «Pagar».
class _BarraSeleccion extends StatelessWidget {
  const _BarraSeleccion({required this.cantidad, required this.total, required this.alPagar});

  final int cantidad;
  final double total;
  final VoidCallback? alPagar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.margen, AppSpacing.md, AppSpacing.margen, AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(plural(cantidad, 'seleccionada', 'seleccionadas'), style: textos.labelMedium),
                  FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Monto(total, tamano: 26)),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.boton),
                boxShadow: alPagar == null ? null : AppColors.sombraPrimaria,
              ),
              child: FilledButton(
                onPressed: alPagar,
                style: FilledButton.styleFrom(minimumSize: const Size(0, AppSpacing.boton)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [Text('Pagar'), SizedBox(width: 6), Icon(Icons.chevron_right_rounded, size: 20)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Obligación con casilla: caja pastel del tributo, nombre, periodo y estado, y el monto.
class _FilaObligacion extends StatelessWidget {
  const _FilaObligacion({
    required this.deuda,
    required this.hoy,
    required this.marcada,
    required this.alMarcar,
    required this.alTocar,
    this.conEstado = true,
  });

  final Deuda deuda;
  final DateTime hoy;
  final bool marcada;
  final ValueChanged<bool>? alMarcar;
  final VoidCallback alTocar;

  /// En «Pagados» todas están pagadas: la insignia repetiría la pestaña.
  final bool conEstado;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final estado = deuda.estadoAl(hoy);
    final (icono, color) = switch (deuda.tipo) {
      TipoDeuda.multa || TipoDeuda.coactivo => (IconoA.multa, AppColors.coral),
      TipoDeuda.arbitrios => (IconoA.arbitrios, AppColors.lima),
      TipoDeuda.predial => (IconoA.predio, AppColors.sol),
      _ => (IconoA.cuponera, AppColors.primary),
    };
    final insignia = switch (estado) {
      EstadoDeuda.vencida => Insignia(estado.etiqueta, tono: Tono.error, icono: Phosphor.warningCircle),
      EstadoDeuda.pagada => Insignia(estado.etiqueta, tono: Tono.exito, icono: Phosphor.check),
      EstadoDeuda.vigente => Insignia(
        deuda.vencimiento == null ? estado.etiqueta : 'Vence el ${diaYMes(deuda.vencimiento!)}',
        tono: Tono.aviso,
      ),
    };
    final monto = Text(
      soles(deuda.total),
      style: textos.titleMedium!.copyWith(fontSize: 16, fontWeight: FontWeight.w800),
    );
    // Con letra muy grande, el monto baja debajo del texto en vez de apretarlo.
    final grande = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return Semantics(
      button: true,
      label: '${deuda.tipo.nombre}, ${soles(deuda.total)}, ${estado.etiqueta}. Ver detalle',
      child: InkWell(
        onTap: alTocar,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            children: [
              if (alMarcar != null)
                CasillaAlmira(marcada: marcada, alCambiar: alMarcar, semantica: 'Pagar ${deuda.tipo.nombre}')
              else
                const SizedBox(width: AppSpacing.md),
              IconoColor.svg(icono, color: color),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(deuda.tipo.nombre, style: textos.titleMedium!.copyWith(fontWeight: FontWeight.w800)),
                    Text(periodoConAnio(deuda), style: textos.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (conEstado) ...[const SizedBox(height: 6), insignia],
                    if (grande) ...[const SizedBox(height: 6), monto],
                  ],
                ),
              ),
              if (!grande) ...[const SizedBox(width: AppSpacing.sm), monto],
            ],
          ),
        ),
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
    final fecha = pago.creadoEn;
    return FilaLista(
      titulo: deuda?.concepto ?? 'Pago',
      monto: soles(pago.monto),
      detalle: Text(
        [
          if (fecha != null) fechaCorta(fecha),
          if (pago.referencia != null) pago.referencia!,
          pago.estado.etiqueta,
        ].join(' · '),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
