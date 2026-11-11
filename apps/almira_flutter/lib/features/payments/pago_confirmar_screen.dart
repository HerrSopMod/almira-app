import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../core/errors/error_app.dart';
import '../../core/utils/formato.dart';
import '../../core/widgets/componentes.dart';
import '../../shared/models/modelos.dart';
import '../../shared/services/proveedores.dart';
import '../account/estado_cuenta_logica.dart';
import '../account/pdf_documentos.dart';
import 'pasos_pago.dart';
import 'payment_gateway.dart';
import 'validadores_pago.dart';

/// Medios con los que se paga en la app.
const _medios = [MedioPago.tarjeta, MedioPago.yape];

/// Pasos 2 y 3 del pago: medio de pago (tarjeta o Yape) y comprobante. El servidor
/// confirma el pago con el importe de la base; los datos de la tarjeta o de Yape solo
/// se comprueban en el teléfono y no se guardan.
class PagoConfirmarScreen extends ConsumerStatefulWidget {
  const PagoConfirmarScreen({super.key, required this.deudaIds});

  final List<String> deudaIds;

  @override
  ConsumerState<PagoConfirmarScreen> createState() => _PagoConfirmarScreenState();
}

class _PagoConfirmarScreenState extends ConsumerState<PagoConfirmarScreen> {
  final _formulario = GlobalKey<FormState>();
  final _numero = TextEditingController();
  final _vencimiento = TextEditingController();
  final _cvv = TextEditingController();
  final _titular = TextEditingController();
  final _celular = TextEditingController();
  final _aprobacion = TextEditingController();

  MedioPago _medio = MedioPago.tarjeta;
  bool _ocupado = false;
  String? _error;

  // Se llena al pagar, para el comprobante (las deudas ya figurarán como pagadas).
  ResultadoCobro? _resultado;
  List<LineaComprobante> _lineas = const [];
  MedioPago _medioPagado = MedioPago.tarjeta;

  List<TextEditingController> get _controles =>
      [_numero, _vencimiento, _cvv, _titular, _celular, _aprobacion];

  @override
  void dispose() {
    // Lo escrito se borra antes de soltar los controles.
    for (final c in _controles) {
      c.clear();
      c.dispose();
    }
    super.dispose();
  }

  DatosPago _datos() => _medio == MedioPago.tarjeta
      ? DatosTarjeta(
          numero: _numero.text,
          vencimiento: _vencimiento.text,
          cvv: _cvv.text,
          titular: _titular.text.trim(),
        )
      : DatosYape(celular: _celular.text, codigoAprobacion: _aprobacion.text);

  Future<void> _pagar(List<Deuda> elegidas) async {
    if (_ocupado || !_formulario.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _ocupado = true;
      _error = null;
    });
    // Se guarda qué se paga antes de que los datos se refresquen.
    final lineas = [
      for (final d in elegidas)
        LineaComprobante(concepto: d.concepto, periodo: d.periodo, monto: d.saldo),
    ];
    try {
      final resultado = await ref.read(paymentGatewayProvider).cobrar(
            SolicitudCobro(deudaIds: widget.deudaIds, datos: _datos()),
          );
      // Ya no hacen falta: se borran los datos del medio de pago.
      for (final c in _controles) {
        c.clear();
      }
      await ref.read(datosProvider.notifier).recargar();
      if (mounted) {
        setState(() {
          _resultado = resultado;
          _lineas = lineas;
          _medioPagado = _medio;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = ErrorApp.de(error).detalle);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vista = ref.watch(vistaProvider);
    final hoy = ref.watch(relojProvider)();
    final textos = Theme.of(context).textTheme;
    final v = vista.valueOrNull;

    if (_resultado != null) {
      return _Comprobante(
        resultado: _resultado!,
        lineas: _lineas,
        medio: _medioPagado,
        municipalidad: v?.municipalidad,
        vecino: v?.vecino,
      );
    }

    final elegidas = [
      for (final d in v?.deudas ?? const <Deuda>[])
        if (widget.deudaIds.contains(d.id) && d.pendiente) d,
    ];
    final total = sumarSaldos(elegidas);

    return Scaffold(
      appBar: AppBar(title: const Text('Pagos en línea')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.margen),
          children: [
            const PasosPago(actual: 1),
            espacio,
            if (elegidas.isEmpty)
              const VistaVacia(icono: Icons.receipt_long_outlined, titulo: 'No hay periodos por pagar')
            else
              Form(
                key: _formulario,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Tarjeta(
                      child: Column(
                        children: [
                          for (final d in elegidas)
                            FilaDato(
                              d.periodo.isEmpty ? d.concepto : '${d.concepto} · ${d.periodo}',
                              soles(d.saldo),
                            ),
                          const Divider(height: AppSpacing.xl),
                          FilaDato('Total a pagar', soles(total), destacado: true),
                        ],
                      ),
                    ),
                    espacioGrande,
                    TituloSeccion('Medio de pago'),
                    espacioChico,
                    SegmentedButton<MedioPago>(
                      segments: [
                        for (final m in _medios)
                          ButtonSegment(
                            value: m,
                            icon: Icon(m == MedioPago.tarjeta ? Icons.credit_card_rounded : Icons.smartphone_rounded),
                            label: Text(m == MedioPago.tarjeta ? 'Tarjeta' : 'Yape'),
                          ),
                      ],
                      selected: {_medio},
                      showSelectedIcon: false,
                      onSelectionChanged: _ocupado
                          ? null
                          : (s) => setState(() {
                                _medio = s.first;
                                _error = null;
                              }),
                    ),
                    espacio,
                    if (_medio == MedioPago.tarjeta) ..._camposTarjeta(hoy) else ..._camposYape(),
                    if (_error != null) ...[espacio, Aviso(_error!, tono: Tono.error)],
                    espacioGrande,
                    FilledButton.icon(
                      onPressed: _ocupado || total <= 0 ? null : () => _pagar(elegidas),
                      icon: _ocupado
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : const Icon(Icons.lock_outline_rounded, size: 20),
                      label: Text('Pagar ${soles(total)}'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Tus avisos de estas deudas se detienen al confirmar.',
                      style: textos.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _camposTarjeta(DateTime hoy) => [
        TextFormField(
          controller: _numero,
          keyboardType: TextInputType.number,
          autofillHints: const [AutofillHints.creditCardNumber],
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(19), _GruposDe4()],
          decoration: const InputDecoration(labelText: 'Número de tarjeta'),
          validator: validarNumeroTarjeta,
        ),
        espacio,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _vencimiento,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.creditCardExpirationDate],
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4), _MesAnio()],
                decoration: const InputDecoration(labelText: 'Vencimiento', hintText: 'MM/AA'),
                validator: (v) => validarVencimiento(v, hoy),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: TextFormField(
                controller: _cvv,
                keyboardType: TextInputType.number,
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                autofillHints: const [AutofillHints.creditCardSecurityCode],
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                decoration: const InputDecoration(labelText: 'CVV'),
                validator: validarCvv,
              ),
            ),
          ],
        ),
        espacio,
        TextFormField(
          controller: _titular,
          textCapitalization: TextCapitalization.characters,
          autofillHints: const [AutofillHints.creditCardName],
          decoration: const InputDecoration(labelText: 'Titular de la tarjeta'),
          validator: validarTitular,
        ),
      ];

  List<Widget> _camposYape() => [
        TextFormField(
          controller: _celular,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
          decoration: const InputDecoration(labelText: 'Celular de Yape', prefixText: '+51 '),
          validator: validarCelularYape,
        ),
        espacio,
        TextFormField(
          controller: _aprobacion,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
          decoration: const InputDecoration(
            labelText: 'Código de aprobación',
            helperText: 'Lo ves en tu app Yape.',
          ),
          validator: validarCodigoAprobacion,
        ),
      ];
}

/// Agrupa los dígitos de la tarjeta de a cuatro.
class _GruposDe4 extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue anterior, TextEditingValue nuevo) {
    final d = nuevo.text.replaceAll(RegExp(r'\D'), '');
    final texto = [for (var i = 0; i < d.length; i += 4) d.substring(i, i + 4 > d.length ? d.length : i + 4)].join(' ');
    return TextEditingValue(text: texto, selection: TextSelection.collapsed(offset: texto.length));
  }
}

/// Escribe el vencimiento como MM/AA.
class _MesAnio extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue anterior, TextEditingValue nuevo) {
    final d = nuevo.text.replaceAll(RegExp(r'\D'), '');
    final texto = d.length <= 2 ? d : '${d.substring(0, 2)}/${d.substring(2)}';
    return TextEditingValue(text: texto, selection: TextSelection.collapsed(offset: texto.length));
  }
}

/// Paso 3: comprobante con el número de operación y su PDF.
class _Comprobante extends ConsumerStatefulWidget {
  const _Comprobante({
    required this.resultado,
    required this.lineas,
    required this.medio,
    required this.municipalidad,
    required this.vecino,
  });

  final ResultadoCobro resultado;
  final List<LineaComprobante> lineas;
  final MedioPago medio;
  final Municipalidad? municipalidad;
  final Vecino? vecino;

  @override
  ConsumerState<_Comprobante> createState() => _ComprobanteState();
}

class _ComprobanteState extends ConsumerState<_Comprobante> {
  bool _generando = false;

  Future<void> _descargar() async {
    if (_generando) return;
    setState(() => _generando = true);
    try {
      final bytes = await pdfComprobante(
        municipalidad: widget.municipalidad,
        vecino: widget.vecino,
        operacion: widget.resultado.operacion,
        fecha: widget.resultado.fecha,
        medio: widget.medio,
        lineas: widget.lineas,
      );
      await compartirPdf(bytes, 'comprobante-${widget.resultado.operacion}.pdf');
    } catch (_) {
      if (mounted) mostrarMensaje(context, 'No pudimos generar el comprobante. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final total = widget.lineas.fold<double>(0, (s, l) => s + l.monto);
    return Scaffold(
      appBar: AppBar(title: const Text('Pagos en línea'), automaticallyImplyLeading: false),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.margen),
          children: [
            const PasosPago(actual: 2),
            espacioGrande,
            const Center(child: CajaIcono(Icons.check_rounded, tono: Tono.exito, lado: 72)),
            espacio,
            Text('¡Pago realizado!', style: textos.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
            Text(
              soles(total),
              style: textos.displaySmall!.copyWith(fontFeatures: cifrasTabulares),
              textAlign: TextAlign.center,
            ),
            espacio,
            Tarjeta(
              child: Column(
                children: [
                  FilaDato('Operación', widget.resultado.operacion),
                  FilaDato('Fecha', fechaLarga(widget.resultado.fecha)),
                  FilaDato('Medio de pago', widget.medio.etiqueta),
                  const Divider(height: AppSpacing.xl),
                  for (final l in widget.lineas)
                    FilaDato(l.periodo.isEmpty ? l.concepto : '${l.concepto} · ${l.periodo}', soles(l.monto)),
                ],
              ),
            ),
            espacioGrande,
            FilledButton.icon(
              onPressed: _generando ? null : _descargar,
              icon: _generando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined, size: 20),
              label: const Text('Descargar comprobante'),
            ),
            espacioChico,
            OutlinedButton(
              onPressed: () => context.go(Rutas.estadoCuenta),
              child: const Text('Ver estado de cuenta'),
            ),
            espacioChico,
            TextButton(onPressed: () => context.go(Rutas.inicio), child: const Text('Volver al inicio')),
          ],
        ),
      ),
    );
  }
}
