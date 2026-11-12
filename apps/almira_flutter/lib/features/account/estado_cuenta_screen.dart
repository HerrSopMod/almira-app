import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

/// Estado de cuenta corriente por tributo y año, con su PDF, y el historial de pagos.
class EstadoCuentaScreen extends ConsumerStatefulWidget {
  const EstadoCuentaScreen({super.key});

  @override
  ConsumerState<EstadoCuentaScreen> createState() => _EstadoCuentaScreenState();
}

class _EstadoCuentaScreenState extends ConsumerState<EstadoCuentaScreen> {
  _Vista _vista = _Vista.estado;
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
                icono: Icons.badge_outlined,
                titulo: 'Vincula tu código de contribuyente',
                accion: 'Vincular código',
                alTocar: () => context.push(Rutas.vincular),
              ),
            ];
          }
          return [
            SegmentedButton<_Vista>(
              segments: const [
                ButtonSegment(value: _Vista.estado, label: Text('Estado de cuenta')),
                ButtonSegment(value: _Vista.historial, label: Text('Historial de pagos')),
              ],
              selected: {_vista},
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(textStyle: Theme.of(context).textTheme.labelMedium),
              onSelectionChanged: (s) => setState(() => _vista = s.first),
            ),
            espacio,
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
      Tarjeta(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(v.municipalidad?.nombre ?? '', style: textos.titleSmall!.copyWith(color: AppColors.primary)),
            const SizedBox(height: AppSpacing.xs),
            Text('ESTADO DE CUENTA CORRIENTE', style: textos.titleMedium),
            Text('Al ${fechaLarga(hoy)}', style: textos.bodyMedium),
            const Divider(height: AppSpacing.xl),
            FilaDato('Código', vecino.codigoContribuyente ?? '-'),
            if (vecino.dni != null) FilaDato('DNI/RUC', vecino.dni!),
            FilaDato('Contribuyente', vecino.nombreCompleto),
            if (vecino.domicilioFiscal != null) FilaDato('Domicilio fiscal', vecino.domicilioFiscal!),
          ],
        ),
      ),
      espacio,
      FilledButton.icon(
        onPressed: _generando ? null : () => _descargar(v, hoy),
        icon: _generando
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : const Icon(Icons.picture_as_pdf_outlined, size: 20),
        label: const Text('Descargar PDF'),
      ),
      if (estado.vacio) ...[
        espacio,
        const VistaVacia(icono: Icons.receipt_long_outlined, titulo: 'Aún no tienes tributos registrados'),
      ] else ...[
        // Impuestos y tasas son tributos distintos: se agrupan con su propio encabezado.
        for (final grupo in _gruposDeTributos(estado.tributos)) ...[
          espacioGrande,
          Semantics(
            header: true,
            child: Text(grupo.titulo, style: textos.titleLarge),
          ),
          for (final tributo in grupo.tributos) ...[
            espacio,
            Row(
              children: [
                IconoTributo(tributo.tipo, lado: 32),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    tributo.tipo.nombre,
                    style: textos.titleMedium!.copyWith(color: tributo.tipo.color),
                  ),
                ),
              ],
            ),
            espacioChico,
            for (final anio in tributo.anios) ...[
              _TablaAnio(anio: anio),
              espacioChico,
            ],
            _FilaResumen('Total acumulado', tributo.acumulado, tono: Tono.primario),
          ],
        ],
        espacioGrande,
        _FilaResumen('Total general', estado.general, tono: Tono.neutro, grande: true),
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
    final textos = Theme.of(context).textTheme;
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
        const VistaVacia(icono: Icons.receipt_long_outlined, titulo: 'No hay pagos con ese filtro')
      else ...[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(AppRadius.campo),
          ),
          child: Row(
            children: [
              Expanded(child: Text(plural(lista.length, 'pago', 'pagos'), style: textos.titleSmall)),
              Text(soles(total), style: textos.titleMedium!.copyWith(fontFeatures: cifrasTabulares)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Tarjeta(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          child: Column(
            children: [
              for (final (i, p) in lista.indexed) ...[
                if (i > 0) const Divider(),
                _FilaHistorial(pago: p),
              ],
            ],
          ),
        ),
      ],
    ];
  }
}

class _FilaHistorial extends StatelessWidget {
  const _FilaHistorial({required this.pago});

  final PagoRealizado pago;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final d = pago.deuda;
    final fecha = pago.pago.creadoEn;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (d != null) ...[IconoTributo(d.tipo, lado: 36), const SizedBox(width: AppSpacing.md)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d?.tipo.nombre ?? 'Pago',
                  style: textos.titleSmall!.copyWith(fontSize: 15),
                ),
                if (d != null)
                  Text(
                    _periodoConAnio(d),
                    style: textos.bodySmall!.copyWith(fontSize: 13),
                  ),
                Text(
                  [
                    if (fecha != null) fechaCorta(fecha),
                    pago.pago.etiquetaMedio,
                    if (pago.pago.referencia != null) pago.pago.referencia!,
                  ].join(' · '),
                  style: textos.bodySmall!.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            soles(pago.pago.monto),
            textAlign: TextAlign.right,
            style: textos.titleSmall!.copyWith(fontSize: 15, fontFeatures: cifrasTabulares),
          ),
        ],
      ),
    );
  }
}

class _FilaResumen extends StatelessWidget {
  const _FilaResumen(this.etiqueta, this.totales, {this.tono = Tono.neutro, this.grande = false});

  final String etiqueta;
  final Totales totales;
  final Tono tono;
  final bool grande;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Tarjeta(
      color: tono.fondo,
      conBorde: false,
      child: Column(
        children: [
          FilaDato(etiqueta, soles(totales.saldo), destacado: true),
          if (grande) ...[
            FilaDato('Insoluto', soles(totales.insoluto)),
            FilaDato('Gastos de emisión', soles(totales.gastos)),
            FilaDato('Intereses', soles(totales.interes)),
            FilaDato('Descuentos', '- ${soles(totales.descuento)}'),
            FilaDato('Pagos', soles(totales.pagos)),
          ] else
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Pagado ${soles(totales.pagos)}', style: textos.bodySmall),
            ),
        ],
      ),
    );
  }
}

/// Un año de un tributo, en tarjetas que caben en el ancho del teléfono (sin desplazarse hacia
/// los lados): cada periodo muestra su estado, sus fechas y su saldo, y al tocarlo se abre el
/// detalle con todas las columnas del estado de cuenta.
class _TablaAnio extends StatelessWidget {
  const _TablaAnio({required this.anio});

  final GrupoAnio anio;

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
              FilaDato('Estado', d.pendiente ? 'Pendiente' : 'Pagado'),
              FilaDato('Vencimiento', _f(d.vencimiento)),
              if (d.fechaPago != null) FilaDato('Fecha de pago', _f(d.fechaPago)),
              const Divider(height: AppSpacing.xl),
              FilaDato('Insoluto', soles(d.montoInsoluto)),
              FilaDato('Gastos de emisión', soles(d.gastosEmision)),
              FilaDato('Interés de actualización', soles(d.interesActualizacion + d.interesMoratorio)),
              FilaDato('Descuento', '- ${soles(d.descuento)}'),
              FilaDato('Pagos', soles(d.pagosAplicados)),
              FilaDato('Saldo', soles(d.saldo), destacado: true),
              if (d.nroValor != null) ...[
                const Divider(height: AppSpacing.xl),
                FilaDato('Nro. de valor', d.nroValor!),
              ],
              if (d.expCoactivo != null) FilaDato('Exp. coactivo', d.expCoactivo!),
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
    TextStyle cifra(TextStyle base) => base.copyWith(fontFeatures: cifrasTabulares);

    return Tarjeta(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
            child: Row(
              children: [
                Expanded(child: Text('Año ${anio.anio}', style: textos.titleSmall)),
                Text('Saldo', style: textos.bodySmall),
              ],
            ),
          ),
          const Divider(),
          for (final d in anio.filas) ...[
            InkWell(
              onTap: () => _detalle(context, d),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            etiquetaPeriodo(d),
                            style: textos.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            d.pendiente
                                ? 'Pendiente · vence ${_f(d.vencimiento)}'
                                : 'Pagado · ${_f(d.fechaPago ?? d.vencimiento)}',
                            style: textos.bodySmall!.copyWith(
                              color: d.pendiente ? AppColors.error : AppColors.textSecondary,
                            ),
                            maxLines: 2,
                          ),
                          if (d.nroValor != null)
                            Text('Valor ${d.nroValor}', style: textos.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      soles(d.saldo),
                      textAlign: TextAlign.right,
                      style: cifra(textos.titleSmall!),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            const Divider(),
          ],
          Container(
            color: AppColors.primarySoft,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Total ${anio.anio}', style: textos.titleSmall)),
                    Text(soles(t.saldo), style: cifra(textos.titleSmall!)),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(child: Text('Insoluto ${soles(t.insoluto)}', style: textos.bodySmall)),
                    Text('Pagos ${soles(t.pagos)}', style: cifra(textos.bodySmall!)),
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
