import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../shared/models/modelos.dart';
import 'estado_cuenta_logica.dart';

final _monto = NumberFormat('#,##0.00', 'en_US');
final _dia = DateFormat('dd-MM-yyyy');
final _diaCorto = DateFormat('dd/MM/yy');

String _m(double valor) => _monto.format(valor);
String _f(DateTime? fecha) => fecha == null ? '' : _dia.format(fecha);

const _verde = PdfColor.fromInt(0xFF0B7F86);
const _gris = PdfColor.fromInt(0xFF5B6B6E);

pw.TextStyle _estilo({double tamano = 8, bool negrita = false, PdfColor? color}) =>
    pw.TextStyle(fontSize: tamano, fontWeight: negrita ? pw.FontWeight.bold : pw.FontWeight.normal, color: color);

/// Abre las opciones del sistema para guardar o compartir el PDF.
Future<void> compartirPdf(Uint8List bytes, String nombreArchivo) =>
    Printing.sharePdf(bytes: bytes, filename: nombreArchivo);

pw.Widget _encabezadoContribuyente(Municipalidad? municipalidad, Vecino vecino) {
  pw.Widget dato(String etiqueta, String valor) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.Row(children: [
          pw.SizedBox(width: 150, child: pw.Text(etiqueta, style: _estilo(tamano: 9))),
          pw.Expanded(child: pw.Text(valor, style: _estilo(tamano: 9, negrita: true))),
        ]),
      );
  return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
    dato('Código', vecino.codigoContribuyente ?? ''),
    dato('DNI/RUC', vecino.dni ?? ''),
    dato('Apellidos y Nombres/Razón Social', vecino.nombreCompleto),
    dato('Domicilio Fiscal', vecino.domicilioFiscal ?? ''),
  ]);
}

pw.Widget _titulo(String linea1, String linea2, Municipalidad? municipalidad, {String? derecha}) =>
    pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Expanded(
        child: pw.Text(
          (municipalidad?.nombre ?? '').toUpperCase(),
          style: _estilo(tamano: 11, negrita: true, color: _verde),
        ),
      ),
      pw.Column(children: [
        pw.Text(linea1, style: _estilo(tamano: 14, negrita: true)),
        pw.Text(linea2, style: _estilo(tamano: 14, negrita: true)),
      ]),
      pw.Expanded(
        child: pw.Align(
          alignment: pw.Alignment.topRight,
          child: pw.Text(derecha ?? '', style: _estilo(tamano: 9)),
        ),
      ),
    ]);

pw.Widget _celda(String texto, {bool derecha = false, bool negrita = false, double tamano = 7.5}) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5, horizontal: 2),
      child: pw.Text(
        texto,
        textAlign: derecha ? pw.TextAlign.right : pw.TextAlign.left,
        style: _estilo(tamano: tamano, negrita: negrita),
      ),
    );

List<pw.Widget> _filaTotales(String etiqueta, Totales t, {bool negrita = true}) => [
      _celda(etiqueta, negrita: negrita),
      _celda(''),
      _celda(''),
      _celda(_m(t.insoluto), derecha: true, negrita: negrita),
      _celda(_m(t.gastos), derecha: true, negrita: negrita),
      _celda(_m(t.interes), derecha: true, negrita: negrita),
      _celda(_m(-t.descuento), derecha: true, negrita: negrita),
      _celda(_m(t.pagos), derecha: true, negrita: negrita),
      _celda(_m(t.saldo), derecha: true, negrita: negrita),
      _celda(''),
      _celda(''),
    ];

/// Estado de cuenta corriente: mismas columnas y agrupación que el de la municipalidad.
Future<Uint8List> pdfEstadoCuenta({
  required Municipalidad? municipalidad,
  required Vecino vecino,
  required EstadoCuenta estado,
  required DateTime hoy,
}) async {
  final doc = pw.Document(title: 'Estado de cuenta corriente', author: 'Almira');
  const anchos = <int, pw.TableColumnWidth>{
    0: pw.FlexColumnWidth(1.7),
    1: pw.FlexColumnWidth(0.7),
    2: pw.FlexColumnWidth(2.6),
    3: pw.FlexColumnWidth(1.2),
    4: pw.FlexColumnWidth(1),
    5: pw.FlexColumnWidth(1),
    6: pw.FlexColumnWidth(1),
    7: pw.FlexColumnWidth(1.2),
    8: pw.FlexColumnWidth(1.2),
    9: pw.FlexColumnWidth(1.6),
    10: pw.FlexColumnWidth(1.6),
  };
  const columnas = [
    'Periodo', 'Est', 'F.Ven. / F.Pag', 'Insoluto', 'G.E.', 'Int/Act', 'Dscto.', 'Pagos', 'Saldo',
    'Nro. Valor', 'Exp. Coac.',
  ];
  const derechas = {3, 4, 5, 6, 7, 8};

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(28),
      header: (contexto) => pw.Column(children: [
        _titulo('ESTADO DE CUENTA CORRIENTE', 'AL ${_diaCorto.format(hoy)}', municipalidad,
            derecha: 'Página ${contexto.pageNumber} de ${contexto.pagesCount}'),
        pw.SizedBox(height: 8),
        _encabezadoContribuyente(municipalidad, vecino),
        pw.Divider(thickness: 0.6),
      ]),
      build: (contexto) => [
        pw.Table(
          columnWidths: anchos,
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 0.6))),
              children: [
                for (final (i, c) in columnas.indexed) _celda(c, negrita: true, derecha: derechas.contains(i)),
              ],
            ),
          ],
        ),
        for (final tributo in estado.tributos) ...[
          pw.SizedBox(height: 8),
          pw.Text(tributo.titulo, style: _estilo(tamano: 9, negrita: true)),
          for (final anio in tributo.anios) ...[
            pw.SizedBox(height: 4),
            pw.Text('Año: ${anio.anio}', style: _estilo(tamano: 8.5, negrita: true)),
            pw.Table(
              columnWidths: anchos,
              children: [
                for (final d in anio.filas)
                  pw.TableRow(children: [
                    _celda(etiquetaPeriodo(d)),
                    _celda(estadoCorto(d)),
                    _celda(d.pendiente ? _f(d.vencimiento) : '${_f(d.vencimiento)} / ${_f(d.fechaPago)}'),
                    _celda(_m(d.montoInsoluto), derecha: true),
                    _celda(_m(d.gastosEmision), derecha: true),
                    _celda(_m(d.interesActualizacion + d.interesMoratorio), derecha: true),
                    _celda(_m(-d.descuento), derecha: true),
                    _celda(_m(d.pagosAplicados), derecha: true),
                    _celda(_m(d.saldo), derecha: true),
                    _celda(d.nroValor ?? ''),
                    _celda(d.expCoactivo ?? ''),
                  ]),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(width: 0.4))),
                  children: _filaTotales('Total del ${anio.anio}', anio.subtotal),
                ),
              ],
            ),
          ],
          pw.Table(
            columnWidths: anchos,
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(width: 0.8))),
                children: _filaTotales('Total Acumulado', tributo.acumulado),
              ),
            ],
          ),
        ],
        pw.SizedBox(height: 14),
        pw.Container(
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.9)),
          child: pw.Table(
            columnWidths: anchos,
            children: [pw.TableRow(children: _filaTotales('Total General', estado.general))],
          ),
        ),
      ],
    ),
  );
  return doc.save();
}

/// Hoja de Resumen (HR): lo emitido por tributo en el ejercicio, con los predios del contribuyente.
Future<Uint8List> pdfHojaResumen({
  required Municipalidad? municipalidad,
  required Vecino vecino,
  required List<Predio> predios,
  required List<Deuda> deudas,
  required int anio,
}) async {
  final doc = pw.Document(title: 'Hoja de Resumen $anio', author: 'Almira');
  final delAnio = deudas.where((d) => d.anioTributo == anio).toList();
  final filas = <List<String>>[];
  var general = const Totales();
  for (final tipo in [TipoDeuda.predial, TipoDeuda.arbitrios]) {
    final t = Totales.sumar(delAnio.where((d) => d.tipo == tipo));
    general = general + t;
    filas.add([
      tipo == TipoDeuda.predial ? 'Impuesto predial' : 'Arbitrios municipales',
      _m(t.insoluto), _m(t.gastos), _m(t.interes), _m(t.insoluto + t.gastos + t.interes - t.descuento),
      _m(t.saldo),
    ]);
  }
  filas.add([
    'Total del ejercicio', _m(general.insoluto), _m(general.gastos), _m(general.interes),
    _m(general.insoluto + general.gastos + general.interes - general.descuento), _m(general.saldo),
  ]);

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        _titulo('HOJA DE RESUMEN', 'HR $anio', municipalidad),
        pw.SizedBox(height: 14),
        _encabezadoContribuyente(municipalidad, vecino),
        pw.SizedBox(height: 14),
        pw.Text('Resumen del ejercicio $anio', style: _estilo(tamano: 10, negrita: true)),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headers: ['Tributo', 'Insoluto', 'G.E.', 'Int/Act', 'Total emitido', 'Saldo'],
          data: filas,
          headerStyle: _estilo(tamano: 8.5, negrita: true),
          cellStyle: _estilo(tamano: 8.5),
          cellAlignments: {
            for (var i = 1; i < 6; i++) i: pw.Alignment.centerRight,
          },
          headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFE7F2F3)),
        ),
        pw.SizedBox(height: 16),
        pw.Text('Predios', style: _estilo(tamano: 10, negrita: true)),
        pw.SizedBox(height: 6),
        for (final p in predios)
          pw.Text('${p.codigo}  ·  ${p.direccion}', style: _estilo(tamano: 9)),
        if (predios.isEmpty) pw.Text('Sin predios registrados.', style: _estilo(tamano: 9, color: _gris)),
        pw.Spacer(),
        pw.Text('Emitido el ${_dia.format(DateTime.now())}', style: _estilo(tamano: 8, color: _gris)),
      ]),
    ),
  );
  return doc.save();
}

/// Hoja de Liquidación (HLP si el tributo es predial, HLA si es arbitrios) de un predio.
Future<Uint8List> pdfLiquidacion({
  required Municipalidad? municipalidad,
  required Vecino vecino,
  required Predio predio,
  required List<Deuda> deudas,
  required TipoDeuda tributo,
  required int anio,
}) async {
  final esPredial = tributo == TipoDeuda.predial;
  final sigla = esPredial ? 'HLP' : 'HLA';
  final nombre = esPredial ? 'HOJA DE LIQUIDACIÓN PREDIAL' : 'HOJA DE LIQUIDACIÓN DE ARBITRIOS';
  final doc = pw.Document(title: '$sigla $anio', author: 'Almira');
  // Las deudas del vecino que corresponden a este predio (o, si no traen predio, al único).
  final filas = deudas
      .where((d) => d.tipo == tributo && d.anioTributo == anio && (d.predioId == null || d.predioId == predio.id))
      .toList()
    ..sort((a, b) => (a.trimestre ?? 0).compareTo(b.trimestre ?? 0));
  final t = Totales.sumar(filas);

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        _titulo(nombre, '$sigla $anio', municipalidad),
        pw.SizedBox(height: 14),
        _encabezadoContribuyente(municipalidad, vecino),
        pw.SizedBox(height: 8),
        pw.Text('Predio: ${predio.codigo}  ·  ${predio.direccion}', style: _estilo(tamano: 9, negrita: true)),
        pw.SizedBox(height: 14),
        pw.TableHelper.fromTextArray(
          headers: ['Periodo', 'Vencimiento', 'Insoluto', 'G.E.', 'Int/Act', 'Total', 'Estado'],
          data: [
            for (final d in filas)
              [
                etiquetaPeriodo(d),
                _f(d.vencimiento),
                _m(d.montoInsoluto),
                _m(d.gastosEmision),
                _m(d.interesActualizacion + d.interesMoratorio),
                _m(d.importe),
                d.pendiente ? 'Pendiente' : 'Pagado',
              ],
            ['Total $anio', '', _m(t.insoluto), _m(t.gastos), _m(t.interes), _m(t.insoluto + t.gastos + t.interes - t.descuento), ''],
          ],
          headerStyle: _estilo(tamano: 8.5, negrita: true),
          cellStyle: _estilo(tamano: 8.5),
          cellAlignments: {
            for (var i = 2; i < 6; i++) i: pw.Alignment.centerRight,
          },
          headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFE7F2F3)),
        ),
        if (filas.isEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 10),
            child: pw.Text('No hay periodos emitidos para $anio.', style: _estilo(tamano: 9, color: _gris)),
          ),
        pw.Spacer(),
        pw.Text('Emitido el ${_dia.format(DateTime.now())}', style: _estilo(tamano: 8, color: _gris)),
      ]),
    ),
  );
  return doc.save();
}

/// Una línea del comprobante: lo que se pagó.
class LineaComprobante {
  const LineaComprobante({required this.concepto, required this.periodo, required this.monto});

  final String concepto;
  final String periodo;
  final double monto;
}

/// Comprobante de pago con su número de operación. No lleva datos de la tarjeta ni de Yape.
Future<Uint8List> pdfComprobante({
  required Municipalidad? municipalidad,
  required Vecino? vecino,
  required String operacion,
  required DateTime fecha,
  required MedioPago medio,
  required List<LineaComprobante> lineas,
}) async {
  final doc = pw.Document(title: 'Comprobante $operacion', author: 'Almira');
  final total = lineas.fold<double>(0, (s, l) => s + l.monto);
  final fechaHora = DateFormat('dd-MM-yyyy HH:mm').format(fecha);

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        _titulo('COMPROBANTE DE PAGO', operacion, municipalidad),
        pw.SizedBox(height: 16),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.6, color: _verde)),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('Número de operación: $operacion', style: _estilo(tamano: 11, negrita: true)),
            pw.SizedBox(height: 3),
            pw.Text('Fecha: $fechaHora', style: _estilo(tamano: 9)),
            pw.Text('Medio de pago: ${medio.etiqueta}', style: _estilo(tamano: 9)),
          ]),
        ),
        pw.SizedBox(height: 14),
        if (vecino != null) _encabezadoContribuyente(municipalidad, vecino),
        pw.SizedBox(height: 14),
        pw.TableHelper.fromTextArray(
          headers: ['Concepto', 'Periodo', 'Importe'],
          data: [for (final l in lineas) [l.concepto, l.periodo, _m(l.monto)]],
          headerStyle: _estilo(tamano: 9, negrita: true),
          cellStyle: _estilo(tamano: 9),
          cellAlignments: {2: pw.Alignment.centerRight},
          headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFE7F2F3)),
        ),
        pw.SizedBox(height: 8),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Total pagado: S/ ${_m(total)}', style: _estilo(tamano: 12, negrita: true)),
        ),
        pw.Spacer(),
        pw.Text(
          'Conserva este comprobante. Tu estado de cuenta se actualizó con este pago.',
          style: _estilo(tamano: 8, color: _gris),
        ),
      ]),
    ),
  );
  return doc.save();
}
