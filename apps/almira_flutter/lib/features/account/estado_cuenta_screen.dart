import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/iconos.dart';
import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils/formato.dart';
import '../../core/utils/rango_fechas.dart';
import '../../core/widgets/componentes.dart';
import '../../core/widgets/movimiento.dart';
import '../../app/theme/iconos_almira.dart';
import '../../core/widgets/filtros.dart';
import '../../core/widgets/tributo.dart';
import '../../shared/models/modelos.dart';
import '../../shared/services/proveedores.dart';
import 'estado_cuenta_logica.dart';
import '../payments/detalle_deuda_logica.dart';
import 'hoja_trimestre.dart';
import 'pdf_documentos.dart';

enum _Vista { estado, historial }

/// Estado de cuenta por tributo y año, con su PDF, y el historial de pagos, en dos pestañas.
class EstadoCuentaScreen extends ConsumerStatefulWidget {
  const EstadoCuentaScreen({super.key});

  @override
  ConsumerState<EstadoCuentaScreen> createState() => _EstadoCuentaScreenState();
}

class _EstadoCuentaScreenState extends ConsumerState<EstadoCuentaScreen> with SingleTickerProviderStateMixin {
  _Vista _vista = _Vista.estado;
  late final TabController _pestanas = TabController(length: _Vista.values.length, vsync: this);

  @override
  void dispose() {
    _pestanas.dispose();
    super.dispose();
  }

  FiltroFechas _fechas = FiltroFechas.todas;
  TipoDeuda? _tributo;
  bool _generando = false;

  Future<void> _descargar(VistaMunicipal v, DateTime hoy) async {
    final vecino = v.vecino;
    if (vecino == null || _generando) return;
    setState(() => _generando = true);
    try {
      final bytes = await pdfEstadoCuenta(
        municipalidad: v.municipalidad,
        vecino: vecino,
        estado: construirEstadoCuenta(v.deudas),
        hoy: hoy,
      );
      await compartirPdf(bytes, 'estado-de-cuenta-${vecino.codigoContribuyente ?? 'almira'}.pdf');
    } catch (_) {
      if (mounted) mostrarMensaje(context, 'No pudimos generar el PDF. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vista = ref.watch(vistaProvider);
    final hoy = ref.watch(relojProvider)();

    return Scaffold(
      appBar: BarraAlmira(titulo: 'Estado de cuenta'),
      body: CuerpoAsync<VistaMunicipal>(
        valor: vista,
        alRecargar: ref.read(datosProvider.notifier).recargar,
        construir: (v) {
          if (v.vecino == null) {
            return [
              VistaVacia(
                icono: Phosphor.identificationBadge,
                titulo: 'Vincula tu código de contribuyente',
                accion: 'Vincular código',
                alTocar: () => context.push(Rutas.vincular),
              ),
            ];
          }
          return [
            // Dos vistas, en un selector segmentado.
            Segmentado<_Vista>(
              opciones: const [(_Vista.estado, 'Estado de cuenta'), (_Vista.historial, 'Historial de pagos')],
              actual: _vista,
              alElegir: (vista) => setState(() {
                _vista = vista;
                _pestanas.index = vista.index;
              }),
            ),
            espacioGrande,
            if (_vista == _Vista.estado) ..._estado(v, hoy) else ..._historial(v, hoy),
          ];
        },
      ),
    );
  }

  List<Widget> _estado(VistaMunicipal v, DateTime hoy) {
    final vecino = v.vecino!;
    final estado = construirEstadoCuenta(v.deudas);
    final textos = Theme.of(context).textTheme;
    return [
      Aparecer(
        child: Tarjeta(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const IconoColor.svg(IconoA.perfil, color: AppColors.sol, lado: 48),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tipoTitulo(vecino.nombreCompleto),
                          style: textos.titleMedium!.copyWith(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          ['Código ${vecino.codigoContribuyente ?? '-'}', ?v.municipalidad?.nombre].join(' · '),
                          style: textos.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                [if (v.municipalidad != null) v.municipalidad!.nombre, 'al ${fechaLarga(hoy)}'].join(' · '),
                style: textos.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: _generando ? null : () => _descargar(v, hoy),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary100,
                  foregroundColor: AppColors.primary,
                ),
                icon: _generando
                    ? const SizedBox(
                        width: AppIconos.boton,
                        height: AppIconos.boton,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const IconoAlmira(IconoA.descargar, tamano: AppIconos.boton, color: AppColors.primary),
                label: const Text('Descargar PDF'),
              ),
            ],
          ),
        ),
      ),
      if (!estado.vacio) ...[
        espacio,
        Aparecer(
          paso: 1,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _Cifra(
                    rotulo: 'Saldo total',
                    monto: estado.general.saldo,
                    detalle: 'Insoluto ${soles(estado.general.insoluto)}',
                    fondo: AppColors.primary,
                    texto: AppColors.onPrimary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _Cifra(
                    rotulo: 'Pagado',
                    monto: estado.general.pagos,
                    detalle: 'Total acumulado',
                    fondo: AppColors.lima100,
                    texto: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      if (estado.vacio) ...[
        espacio,
        const VistaVacia(icono: Phosphor.receipt, titulo: 'Aún no tienes tributos registrados'),
      ] else ...[
        // Impuestos y tasas son tributos distintos: se agrupan con su propio encabezado.
        for (final grupo in _gruposDeTributos(estado.tributos)) ...[
          espacio,
          Tarjeta(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TituloSeccion(grupo.titulo),
                for (final tributo in grupo.tributos) ...[
                  espacio,
                  Row(
                    children: [
                      IconoTributo(tributo.tipo, lado: AppSpacing.caja),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          tributo.tipo.nombre,
                          style: textos.titleMedium!.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  for (final anio in tributo.anios) ...[
                    espacio,
                    _TablaAnio(anio: anio, hoy: hoy, vista: v, esDemo: ref.watch(esDemoProvider)),
                  ],
                  espacioChico,
                  const Divider(),
                  FilaDato('Total acumulado', soles(tributo.acumulado.saldo), destacado: true),
                  Text('Pagado ${soles(tributo.acumulado.pagos)}', style: textos.bodyMedium),
                ],
              ],
            ),
          ),
        ],
        espacio,
        _TotalGeneral(estado.general),
      ],
    ];
  }

  List<Widget> _historial(VistaMunicipal v, DateTime hoy) {
    final tributos = {
      for (final p in historialDePagos(v.pagos, v.deudas))
        if (p.tributo != null) p.tributo!,
    }.toList();
    final lista = [
      for (final p in historialDePagos(v.pagos, v.deudas, tributo: _tributo))
        if (_fechas.contiene(p.pago.creadoEn, hoy)) p,
    ];
    final total = lista.fold<double>(0, (s, p) => s + p.pago.monto);

    return [
      // El calendario sustituye a los chips de año: periodos rápidos o un rango de días.
      GrupoFiltroFechas(filtro: _fechas, hoy: hoy, alCambiar: (f) => setState(() => _fechas = f)),
      espacio,
      GrupoFiltros(
        titulo: 'Tributo',
        chips: [
          ChipFiltro(texto: 'Todos', activo: _tributo == null, alTocar: () => setState(() => _tributo = null)),
          for (final t in tributos)
            ChipFiltro(
              texto: t.nombreCorto,
              icono: t.icono,
              activo: _tributo == t,
              alTocar: () => setState(() => _tributo = t),
            ),
        ],
      ),
      espacio,
      if (lista.isEmpty)
        const VistaVacia(icono: Phosphor.receipt, titulo: 'No hay pagos con ese filtro')
      else ...[
        FilaDato(plural(lista.length, 'pago', 'pagos'), soles(total), destacado: true),
        espacioChico,
        GrupoTarjeta(filas: [for (final p in lista) _FilaHistorial(pago: p)]),
      ],
    ];
  }
}

class _FilaHistorial extends StatelessWidget {
  const _FilaHistorial({required this.pago});

  final PagoRealizado pago;

  @override
  Widget build(BuildContext context) {
    final d = pago.deuda;
    final fecha = pago.pago.creadoEn;
    return FilaLista(
      inicio: d == null ? null : IconoTributo(d.tipo, lado: AppSpacing.caja),
      titulo: d?.tipo.nombre ?? 'Pago',
      monto: soles(pago.pago.monto),
      detalle: Text(
        [
          if (d != null) periodoConAnio(d),
          if (fecha != null) fechaCorta(fecha),
          pago.pago.etiquetaMedio,
          if (pago.pago.referencia != null) pago.pago.referencia!,
        ].join(' · '),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

/// Cifra grande en una tarjeta de color: rótulo, monto y una línea de detalle.
class _Cifra extends StatelessWidget {
  const _Cifra({
    required this.rotulo,
    required this.monto,
    required this.detalle,
    required this.fondo,
    required this.texto,
  });

  final String rotulo;
  final double monto;
  final String detalle;
  final Color fondo;
  final Color texto;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(AppRadius.tarjeta)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rotulo, style: textos.labelMedium!.copyWith(color: texto.withValues(alpha: 0.85))),
          const SizedBox(height: AppSpacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Rebote(child: Monto(monto, tamano: 30, color: texto)),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(detalle, style: textos.bodySmall!.copyWith(color: texto.withValues(alpha: 0.85))),
        ],
      ),
    );
  }
}

/// Total general: el único bloque Destacado de la pantalla, con el saldo y su desglose.
class _TotalGeneral extends StatelessWidget {
  const _TotalGeneral(this.totales);

  final Totales totales;

  @override
  Widget build(BuildContext context) => Destacado(
    child: Column(
      children: [
        FilaDato('Total general', soles(totales.saldo), destacado: true),
        FilaDato('Insoluto', soles(totales.insoluto)),
        FilaDato('Gastos de emisión', soles(totales.gastos)),
        FilaDato('Intereses', soles(totales.interes)),
        FilaDato('Descuentos', '- ${soles(totales.descuento)}'),
        FilaDato('Pagos', soles(totales.pagos)),
      ],
    ),
  );
}

/// Un año de un tributo, sin cajas: el año como rótulo, una fila por periodo (nombre, fecha en
/// gris y saldo a la derecha) y el total del año. Al tocar un periodo se abre el detalle con
/// todas las columnas del estado de cuenta.
class _TablaAnio extends StatelessWidget {
  const _TablaAnio({required this.anio, required this.hoy, required this.vista, required this.esDemo});

  final GrupoAnio anio;
  final DateTime hoy;
  final VistaMunicipal vista;
  final bool esDemo;

  static String _f(DateTime? d) => d == null ? '' : fechaCorta(d);

  void _detalle(BuildContext context, Deuda d) => mostrarHojaTrimestre(
    context,
    deuda: d,
    hoy: hoy,
    pagos: vista.pagos,
    municipalidad: vista.municipalidad,
    vecino: vista.vecino,
    esDemo: esDemo,
  );

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final t = anio.subtotal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Año ${anio.anio}', style: estiloRotulo(context)),
        for (final d in anio.filas) ...[
          FilaLista(
            inicio: _IndicadorCuota(deuda: d, hoy: hoy),
            titulo: tituloCuota(d),
            monto: soles(d.saldo),
            alTocar: () => _detalle(context, d),
            semantica: '${etiquetaPeriodo(d)} ${anio.anio}, saldo ${soles(d.saldo)}. Ver detalle',
            detalle: _lineaPeriodo(context, d),
          ),
          const Divider(),
        ],
        FilaDato('Total ${anio.anio}', soles(t.saldo)),
        Text('Insoluto ${soles(t.insoluto)} · Pagos ${soles(t.pagos)}', style: textos.bodyMedium),
      ],
    );
  }

  /// «Vence el 30 nov 2026», «Venció el 15 oct 2026» (en rojo) o «Pagado el 28 oct 2026».
  Widget _lineaPeriodo(BuildContext context, Deuda d) {
    final vencida = d.estadoAl(hoy) == EstadoDeuda.vencida;
    final pagado = fechaDePago(d, vista.pagos);
    final texto = !d.pendiente
        ? (pagado == null ? 'Pagado' : 'Pagado el ${_f(pagado)}')
        : (vencida ? 'Venció el ${_f(d.vencimiento)}' : 'Vence el ${_f(d.vencimiento)}');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextoPlazo(texto, vencido: vencida),
        if (d.nroValor != null)
          Text(
            'Valor ${d.nroValor}',
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}

/// Indicador de 40 de una cuota: check lima si está pagada, alerta roja si venció y calendario sol
/// si está por vencer.
class _IndicadorCuota extends StatelessWidget {
  const _IndicadorCuota({required this.deuda, required this.hoy});

  final Deuda deuda;
  final DateTime hoy;

  @override
  Widget build(BuildContext context) => switch (deuda.estadoAl(hoy)) {
    EstadoDeuda.pagada => const IconoColor(
      Icons.check_rounded,
      color: AppColors.lima,
      lado: 40,
      colorIcono: AppColors.limaTexto,
    ),
    EstadoDeuda.vencida => const IconoColor.svg(
      IconoA.alerta,
      color: AppColors.error,
      lado: 40,
      colorIcono: AppColors.error,
    ),
    EstadoDeuda.vigente => const IconoColor.svg(
      IconoA.calendario,
      color: AppColors.sol,
      lado: 40,
      colorIcono: AppColors.solTexto,
    ),
  };
}

class _GrupoDeTributos {
  const _GrupoDeTributos(this.titulo, this.tributos);

  final String titulo;
  final List<GrupoTributo> tributos;
}

/// Impuestos (predial), tasas (arbitrios) y, si los hay, otros cobros (multas, coactivo…).
List<_GrupoDeTributos> _gruposDeTributos(List<GrupoTributo> tributos) {
  final impuestos = [
    for (final t in tributos)
      if (t.tipo == TipoDeuda.predial) t,
  ];
  final tasas = [
    for (final t in tributos)
      if (t.tipo.esTasa) t,
  ];
  final otros = [
    for (final t in tributos)
      if (t.tipo != TipoDeuda.predial && !t.tipo.esTasa) t,
  ];
  return [
    if (impuestos.isNotEmpty) _GrupoDeTributos('Impuestos', impuestos),
    if (tasas.isNotEmpty) _GrupoDeTributos('Tasas (arbitrios)', tasas),
    if (otros.isNotEmpty) _GrupoDeTributos('Otros cobros', otros),
  ];
}
