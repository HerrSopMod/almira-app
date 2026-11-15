import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/iconos.dart';
import '../../app/router.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils/formato.dart';
import '../../core/utils/rango_fechas.dart';
import '../../core/widgets/componentes.dart';
import '../../core/widgets/filtros.dart';
import '../../shared/models/modelos.dart';
import '../../shared/services/proveedores.dart';
import 'pagos_logica.dart';
import 'widgets_deuda.dart';

/// Pagar: cabecera turquesa con el total pendiente; debajo, en la hoja blanca, las obligaciones
/// por estado y, en «Pagados», los pagos registrados.
class PagosScreen extends ConsumerStatefulWidget {
  const PagosScreen({super.key, this.filtroInicial});

  final String? filtroInicial;

  @override
  ConsumerState<PagosScreen> createState() => _PagosScreenState();
}

class _PagosScreenState extends ConsumerState<PagosScreen> {
  late FiltroDeuda _filtro = FiltroDeuda.de(widget.filtroInicial);
  FiltroFechas _fechas = FiltroFechas.todas;

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
    return Scaffold(
      body: CuerpoAsync<VistaMunicipal>(
        valor: vista,
        alRecargar: ref.read(datosProvider.notifier).recargar,
        // Cabecera baja: solo el título. El total pendiente va en la hoja, en un bloque.
        cabecera: (v) => CabeceraMarca(titulo: 'Pagar', esDemo: esDemo),
        construir: (v) {
          if (v.vecino == null) {
            return [
              VistaVacia(
                icono: Phosphor.identificationBadge,
                titulo: 'Vincula tu código de contribuyente',
                detalle: 'Así verás tus tributos de ${v.municipalidad?.nombre ?? 'tu municipalidad'}.',
                accion: 'Vincular código',
                alTocar: () => context.push(Rutas.vincular),
              ),
            ];
          }
          final resumen = resumirDeuda(v.deudas, hoy);
          // El filtro por fechas mira el vencimiento (o el día de pago, en «Pagados»).
          final lista = [
            for (final d in filtrarDeudas(v.deudas, _filtro, hoy))
              if (_fechas.contiene(
                _filtro == FiltroDeuda.pagados ? (d.fechaPago ?? d.vencimiento) : d.vencimiento,
                hoy,
              ))
                d,
          ];
          return [
            _TotalPendiente(total: resumen.total),
            espacio,
            GrupoFiltros(
              titulo: 'Estado',
              chips: [
                for (final filtro in FiltroDeuda.values)
                  ChipFiltro(
                    texto: filtro.etiqueta,
                    activo: _filtro == filtro,
                    alTocar: () => setState(() => _filtro = filtro),
                  ),
              ],
            ),
            espacio,
            GrupoFiltroFechas(
              filtro: _fechas,
              hoy: hoy,
              alCambiar: (f) => setState(() => _fechas = f),
            ),
            espacio,
            if (lista.isEmpty)
              VistaVacia(
                icono: switch (_filtro) {
                  FiltroDeuda.pagados => Phosphor.receipt,
                  _ => Phosphor.checkCircle,
                },
                titulo: switch (_filtro) {
                  FiltroDeuda.pendientes => 'No tienes obligaciones pendientes',
                  FiltroDeuda.vencidos => 'No tienes obligaciones vencidas',
                  FiltroDeuda.pagados => 'Aún no hay pagos registrados',
                },
              )
            else
              for (final (i, deuda) in lista.indexed) ...[
                if (i > 0) const Divider(),
                FilaDeuda(
                  deuda: deuda,
                  hoy: hoy,
                  alTocar: () => context.go(Rutas.deuda(deuda.id)),
                ),
              ],
            if (_filtro == FiltroDeuda.pagados && v.pagos.isNotEmpty) ...[
              espacioGrande,
              const TituloSeccion('Constancias'),
              espacioChico,
              for (final (i, pago) in v.pagos.indexed) ...[
                if (i > 0) const Divider(),
                _FilaPago(
                  pago: pago,
                  deuda: v.deudas.where((d) => d.id == pago.deudaId).firstOrNull,
                ),
              ],
            ],
            if (_filtro != FiltroDeuda.pagados && resumen.cantidad > 0) ...[
              espacioGrande,
              AccionPago(municipalidad: v.municipalidad, esDemo: esDemo),
            ],
            espacioGrande,
            const TituloSeccion('Documentos'),
            espacioChico,
            FilaAccion(
              icono: Phosphor.receipt,
              titulo: 'Estado de cuenta',
              alTocar: () => context.push(Rutas.estadoCuenta),
            ),
            const Divider(),
            FilaAccion(
              icono: Phosphor.fileText,
              titulo: 'Cuponera',
              alTocar: () => context.push(Rutas.cuponera),
            ),
          ];
        },
      ),
    );
  }
}

/// «Total pendiente» y el monto, en el único bloque Destacado de la pantalla.
class _TotalPendiente extends StatelessWidget {
  const _TotalPendiente({required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Destacado(
      child: Row(
        children: [
          Expanded(child: Text('Total pendiente', style: textos.bodyLarge)),
          // El monto se achica antes que partirse en dos líneas.
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(soles(total), style: textos.headlineSmall!.copyWith(fontFeatures: cifrasTabulares)),
            ),
          ),
        ],
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
