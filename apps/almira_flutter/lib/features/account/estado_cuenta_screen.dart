import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/iconos.dart';
import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils/formato.dart';
import '../../core/widgets/componentes.dart';
import '../../core/widgets/filtros.dart';
import '../../core/widgets/tributo.dart';
import '../../shared/models/modelos.dart';
import '../../shared/services/proveedores.dart';
import 'estado_cuenta_logica.dart';
import 'pdf_documentos.dart';

enum _Vista { estado, historial }

/// Estado de cuenta por tributo y año, con su PDF, y el historial de pagos, en dos pestañas.
class EstadoCuentaScreen extends ConsumerStatefulWidget {
  const EstadoCuentaScreen({super.key});

  @override
  ConsumerState<EstadoCuentaScreen> createState() => _EstadoCuentaScreenState();
}

class _EstadoCuentaScreenState extends ConsumerState<EstadoCuentaScreen>
    with SingleTickerProviderStateMixin {
  _Vista _vista = _Vista.estado;
  late final TabController _pestanas = TabController(length: _Vista.values.length, vsync: this);

  @override
  void dispose() {
    _pestanas.dispose();
    super.dispose();
  }
  int? _anio;
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
      appBar: AppBar(title: const Text('Estado de cuenta')),
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
            // Dos vistas: pestañas con subrayado.
            TabBar(
              controller: _pestanas,
              // Con letra grande las etiquetas no entran a la mitad del ancho: se desplazan en vez
              // de cortarse.
              isScrollable: MediaQuery.textScalerOf(context).scale(1) > 1.15,
              tabAlignment: MediaQuery.textScalerOf(context).scale(1) > 1.15 ? TabAlignment.start : null,
              onTap: (i) => setState(() => _vista = _Vista.values[i]),
              tabs: const [Tab(text: 'Estado de cuenta'), Tab(text: 'Historial de pagos')],
            ),
            espacioGrande,
            if (_vista == _Vista.estado) ..._estado(v, hoy) else ..._historial(v),
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
      Text(
        [if (v.municipalidad != null) v.municipalidad!.nombre, 'al ${fechaLarga(hoy)}'].join(' · '),
        style: textos.bodyMedium,
      ),
      espacioChico,
      Ficha('Contribuyente', tipoTitulo(vecino.nombreCompleto)),
      Ficha('Código', vecino.codigoContribuyente ?? '-'),
      if (vecino.dni != null) Ficha('DNI o RUC', vecino.dni!),
      if (vecino.domicilioFiscal != null) Ficha('Domicilio fiscal', vecino.domicilioFiscal!),
      espacio,
      FilledButton.icon(
        onPressed: _generando ? null : () => _descargar(v, hoy),
        icon: _generando
            ? const SizedBox(
                width: AppIconos.boton,
                height: AppIconos.boton,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.onPrimary),
              )
            : const Icon(Phosphor.filePdf, size: AppIconos.boton),
        label: const Text('Descargar PDF'),
      ),
      if (estado.vacio) ...[
        espacio,
        const VistaVacia(icono: Phosphor.receipt, titulo: 'Aún no tienes tributos registrados'),
      ] else ...[
        // Impuestos y tasas son tributos distintos: se agrupan con su propio encabezado.
        for (final grupo in _gruposDeTributos(estado.tributos)) ...[
          espacioSeccion,
          TituloSeccion(grupo.titulo),
          for (final tributo in grupo.tributos) ...[
            espacio,
            Text(tributo.tipo.nombre, style: textos.titleMedium!.copyWith(fontWeight: FontWeight.w600)),
            for (final anio in tributo.anios) ...[
              espacioChico,
              _TablaAnio(anio: anio, hoy: hoy),
            ],
            espacioChico,
            const Divider(),
            FilaDato('Total acumulado', soles(tributo.acumulado.saldo), destacado: true),
            Text('Pagado ${soles(tributo.acumulado.pagos)}', style: textos.bodyMedium),
          ],
        ],
        espacioSeccion,
        _TotalGeneral(estado.general),
      ],
    ];
  }

  List<Widget> _historial(VistaMunicipal v) {
    final aniosConPago = {
      for (final p in historialDePagos(v.pagos, v.deudas))
        if (p.anio != null) p.anio!,
    }.toList()
      ..sort((a, b) => b.compareTo(a));
    final tributos = {
      for (final p in historialDePagos(v.pagos, v.deudas))
        if (p.tributo != null) p.tributo!,
    }.toList();
    final lista = historialDePagos(v.pagos, v.deudas, anio: _anio, tributo: _tributo);
    final total = lista.fold<double>(0, (s, p) => s + p.pago.monto);

    return [
      GrupoFiltros(
        titulo: 'Año',
        chips: [
          ChipFiltro(texto: 'Todos', activo: _anio == null, alTocar: () => setState(() => _anio = null)),
          for (final a in aniosConPago)
            ChipFiltro(texto: '$a', activo: _anio == a, alTocar: () => setState(() => _anio = a)),
        ],
      ),
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
        const Divider(),
        for (final (i, p) in lista.indexed) ...[
          if (i > 0) const Divider(),
          _FilaHistorial(pago: p),
        ],
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
      titulo: d?.tipo.nombre ?? 'Pago',
      monto: soles(pago.pago.monto),
      detalle: Text(
        [
          if (d != null) _periodoConAnio(d),
          if (fecha != null) fechaCorta(fecha),
          pago.pago.etiquetaMedio,
          if (pago.pago.referencia != null) pago.pago.referencia!,
        ].join(' · '),
        style: Theme.of(context).textTheme.bodyMedium,
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
  const _TablaAnio({required this.anio, required this.hoy});

  final GrupoAnio anio;
  final DateTime hoy;

  static String _f(DateTime? d) => d == null ? '' : fechaCorta(d);

  void _detalle(BuildContext context, Deuda d) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.margen, 0, AppSpacing.margen, AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${etiquetaPeriodo(d)} ${d.anioTributo}', style: Theme.of(context).textTheme.titleLarge),
              Text(d.concepto, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.md),
              Ficha('Estado', d.pendiente ? 'Pendiente' : 'Pagado'),
              Ficha('Vencimiento', _f(d.vencimiento)),
              if (d.fechaPago != null) Ficha('Fecha de pago', _f(d.fechaPago)),
              if (d.nroValor != null) Ficha('Nro. de valor', d.nroValor!),
              if (d.expCoactivo != null) Ficha('Exp. coactivo', d.expCoactivo!),
              const Divider(height: AppSpacing.xl),
              FilaDato('Insoluto', soles(d.montoInsoluto)),
              FilaDato('Gastos de emisión', soles(d.gastosEmision)),
              FilaDato('Interés de actualización', soles(d.interesActualizacion + d.interesMoratorio)),
              FilaDato('Descuento', '- ${soles(d.descuento)}'),
              FilaDato('Pagos', soles(d.pagosAplicados)),
              FilaDato('Saldo', soles(d.saldo), destacado: true),
            ],
          ),
        ),
      ),
    );
  }

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
            titulo: etiquetaPeriodo(d),
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
    final texto = !d.pendiente
        ? 'Pagado el ${_f(d.fechaPago ?? d.vencimiento)}'
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

class _GrupoDeTributos {
  const _GrupoDeTributos(this.titulo, this.tributos);

  final String titulo;
  final List<GrupoTributo> tributos;
}

/// Impuestos (predial), tasas (arbitrios) y, si los hay, otros cobros (multas, coactivo…).
List<_GrupoDeTributos> _gruposDeTributos(List<GrupoTributo> tributos) {
  final impuestos = [for (final t in tributos) if (t.tipo == TipoDeuda.predial) t];
  final tasas = [for (final t in tributos) if (t.tipo.esTasa) t];
  final otros = [for (final t in tributos) if (t.tipo != TipoDeuda.predial && !t.tipo.esTasa) t];
  return [
    if (impuestos.isNotEmpty) _GrupoDeTributos('Impuestos', impuestos),
    if (tasas.isNotEmpty) _GrupoDeTributos('Tasas (arbitrios)', tasas),
    if (otros.isNotEmpty) _GrupoDeTributos('Otros cobros', otros),
  ];
}

/// «Trimestre 02 2026»; si el periodo ya trae el año («4.ª cuota 2026»), no se repite.
String _periodoConAnio(Deuda d) {
  final periodo = etiquetaPeriodo(d);
  return periodo.contains('${d.anioTributo}') ? periodo : '$periodo ${d.anioTributo}';
}
