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
        for (final tributo in estado.tributos) ...[
          espacioGrande,
          TituloSeccion(tributo.titulo),
          espacioChico,
          for (final anio in tributo.anios) ...[
            _TablaAnio(anio: anio),
            espacioChico,
          ],
          _FilaResumen('Total acumulado', tributo.acumulado, tono: Tono.primario),
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
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          ChoiceChip(
            label: const Text('Todos los años'),
            selected: _anio == null,
            onSelected: (_) => setState(() => _anio = null),
          ),
          for (final a in aniosConPago)
            ChoiceChip(label: Text('$a'), selected: _anio == a, onSelected: (_) => setState(() => _anio = a)),
        ],
      ),
      espacioChico,
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          ChoiceChip(
            label: const Text('Todos los tributos'),
            selected: _tributo == null,
            onSelected: (_) => setState(() => _tributo = null),
          ),
          for (final t in tributos)
            ChoiceChip(
              label: Text(t.etiqueta),
              selected: _tributo == t,
              onSelected: (_) => setState(() => _tributo = t),
            ),
        ],
      ),
      espacio,
      if (lista.isEmpty)
        const VistaVacia(icono: Icons.receipt_long_outlined, titulo: 'No hay pagos con ese filtro')
      else ...[
        Row(
          children: [
            Expanded(child: Text(plural(lista.length, 'pago', 'pagos'), style: textos.bodyMedium)),
            Text(soles(total), style: textos.titleMedium!.copyWith(fontFeatures: cifrasTabulares)),
          ],
        ),
        espacioChico,
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d?.concepto ?? 'Pago', style: textos.titleSmall),
                if (d != null) Text(etiquetaPeriodo(d) + ' ' + d.anioTributo.toString(), style: textos.bodyMedium),
                Text(
                  [
                    if (fecha != null) fechaCorta(fecha),
                    pago.pago.etiquetaMedio,
                    if (pago.pago.referencia != null) pago.pago.referencia!,
                  ].join(' · '),
                  style: textos.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            soles(pago.pago.monto),
            style: textos.titleSmall!.copyWith(fontFeatures: cifrasTabulares),
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

/// Un año de un tributo: tabla con las mismas columnas del estado de cuenta, que se
/// desplaza hacia los lados en pantallas angostas.
class _TablaAnio extends StatelessWidget {
  const _TablaAnio({required this.anio});

  final GrupoAnio anio;

  static const _anchos = <double>[104, 44, 156, 78, 62, 66, 62, 78, 78, 118, 108];
  static const _titulos = [
    'Periodo', 'Est', 'F.Ven. / F.Pag', 'Insoluto', 'G.E.', 'Int/Act', 'Dscto.', 'Pagos', 'Saldo',
    'Nro. Valor', 'Exp. Coac.',
  ];
  static const _derecha = {3, 4, 5, 6, 7, 8};

  Widget _celda(int i, String texto, {bool negrita = false, Color? color}) => SizedBox(
        width: _anchos[i],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
          child: Text(
            texto,
            textAlign: _derecha.contains(i) ? TextAlign.right : TextAlign.left,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: negrita ? FontWeight.w600 : FontWeight.w400,
              color: color ?? AppColors.textPrimary,
              fontFeatures: cifrasTabulares,
            ),
          ),
        ),
      );

  Widget _fila(List<String> celdas, {bool negrita = false, Color? fondo, Color? color}) => Container(
        color: fondo,
        child: Row(children: [for (final (i, c) in celdas.indexed) _celda(i, c, negrita: negrita, color: color)]),
      );

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final t = anio.subtotal;
    String f(DateTime? d) => d == null ? '' : fechaCorta(d);
    return Tarjeta(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text('Año ${anio.anio}', style: textos.titleSmall),
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Column(
              children: [
                _fila(_titulos, negrita: true, fondo: AppColors.surfaceSubtle, color: AppColors.textSecondary),
                for (final d in anio.filas)
                  _fila([
                    etiquetaPeriodo(d),
                    estadoCorto(d),
                    d.pendiente ? f(d.vencimiento) : '${f(d.vencimiento)} / ${f(d.fechaPago)}',
                    soles(d.montoInsoluto).substring(3),
                    soles(d.gastosEmision).substring(3),
                    soles(d.interesActualizacion + d.interesMoratorio).substring(3),
                    soles(-d.descuento).replaceFirst('S/ ', ''),
                    soles(d.pagosAplicados).substring(3),
                    soles(d.saldo).substring(3),
                    d.nroValor ?? '',
                    d.expCoactivo ?? '',
                  ], color: d.pendiente ? AppColors.error : null),
                _fila([
                  'Total ${anio.anio}',
                  '',
                  '',
                  soles(t.insoluto).substring(3),
                  soles(t.gastos).substring(3),
                  soles(t.interes).substring(3),
                  soles(-t.descuento).replaceFirst('S/ ', ''),
                  soles(t.pagos).substring(3),
                  soles(t.saldo).substring(3),
                  '',
                  '',
                ], negrita: true, fondo: AppColors.primarySoft),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
