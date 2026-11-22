import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/iconos.dart';
import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../core/errors/error_app.dart';
import '../../core/utils/formato.dart';
import '../../core/widgets/componentes.dart';
import '../../core/widgets/marcas_pago.dart';
import '../../shared/models/modelos.dart';
import '../../shared/services/proveedores.dart';
import '../account/estado_cuenta_logica.dart';
import '../account/pdf_documentos.dart';
import 'pasos_pago.dart';
import 'payment_gateway.dart';
import 'validadores_pago.dart';

/// Medios con los que se paga en la app.
const _medios = [MedioPago.tarjeta, MedioPago.yape, MedioPago.plin];

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
      : switch (_medio) {
          MedioPago.plin => DatosPlin(celular: _celular.text, codigoAprobacion: _aprobacion.text),
          _ => DatosYape(celular: _celular.text, codigoAprobacion: _aprobacion.text),
        };

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
      bottomNavigationBar: elegidas.isEmpty
          ? null
          : Container(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.margen,
                AppSpacing.md,
                AppSpacing.margen,
                MediaQuery.paddingOf(context).bottom + AppSpacing.md,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: Text('Total a pagar', style: textos.bodyMedium)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(soles(total), style: textos.headlineSmall),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: _ocupado || total <= 0 ? null : () => _pagar(elegidas),
                    child: _ocupado
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : Text('Pagar ${soles(total)}'),
                  ),
                ],
              ),
            ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.margen, AppSpacing.xl, AppSpacing.margen, AppSpacing.xl),
          children: [
            const PasosPago(actual: 1),
            espacioGrande,
            if (elegidas.isEmpty)
              const VistaVacia(icono: Phosphor.receipt, titulo: 'No hay periodos por pagar')
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
                            _LineaResumen(concepto: d.concepto, periodo: d.periodo, monto: d.saldo),
                          const Divider(height: AppSpacing.xl),
                          FilaDato('Total a pagar', soles(total), destacado: true),
                        ],
                      ),
                    ),
                    espacioSeccion,
                    const TituloSeccion('Medio de pago'),
                    espacio,
                    for (final m in _medios) ...[
                      _TarjetaMedio(
                        medio: m,
                        elegido: _medio == m,
                        alElegir: _ocupado
                            ? null
                            : () => setState(() {
                                  _medio = m;
                                  _error = null;
                                }),
                      ),
                      espacioChico,
                    ],
                    espacio,
                    if (_medio == MedioPago.tarjeta) ..._camposTarjeta(hoy) else ..._camposBilletera(_medio.etiqueta),
                    if (_error != null) ...[espacio, Aviso(_error!, tono: Tono.error)],
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
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Número de tarjeta',
            prefixIcon: const Icon(Phosphor.creditCard),
            // Al escribir, aparece la marca de la tarjeta.
            suffixIcon: switch (marcaDeTarjeta(_numero.text)) {
              null => null,
              final marca => Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: LogoMarca(marca, alto: 24),
              ),
            },
            suffixIconConstraints: const BoxConstraints(minHeight: 24, minWidth: 24),
          ),
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
                decoration: const InputDecoration(labelText: 'Vencimiento', hintText: 'MM/AA', prefixIcon: Icon(Phosphor.calendarBlank)),
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
                decoration: const InputDecoration(labelText: 'CVV', prefixIcon: Icon(Phosphor.password)),
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
          decoration: const InputDecoration(labelText: 'Titular de la tarjeta', prefixIcon: Icon(Phosphor.user)),
          validator: validarTitular,
        ),
      ];

  List<Widget> _camposBilletera(String nombre) => [
        TextFormField(
          controller: _celular,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
          decoration: InputDecoration(labelText: 'Celular de $nombre', prefixText: '+51 ', prefixIcon: Icon(Phosphor.deviceMobile)),
          validator: validarCelularYape,
        ),
        espacio,
        TextFormField(
          controller: _aprobacion,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
          decoration: InputDecoration(
            labelText: 'Código de aprobación',
            prefixIcon: Icon(Phosphor.sealCheck),
            helperText: 'Lo ves en tu app $nombre.',
          ),
          validator: validarCodigoAprobacion,
        ),
      ];
}

/// Una obligación del resumen: concepto y, debajo, el periodo; el monto a la derecha.
class _LineaResumen extends StatelessWidget {
  const _LineaResumen({required this.concepto, required this.periodo, required this.monto});

  final String concepto;
  final String periodo;
  final double monto;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(concepto, style: textos.bodyLarge!.copyWith(fontWeight: FontWeight.w500)),
                if (periodo.isNotEmpty) Text(periodo, style: textos.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            soles(monto),
            style: textos.bodyLarge!.copyWith(fontWeight: FontWeight.w500, fontFeatures: cifrasTabulares),
          ),
        ],
      ),
    );
  }
}

/// Medio de pago como tarjeta con borde: caja de ícono neutra a la izquierda, nombre y
/// detalle; el elegido lleva borde turquesa de 1.5 y un check a la derecha.
class _TarjetaMedio extends StatelessWidget {
  const _TarjetaMedio({required this.medio, required this.elegido, required this.alElegir});

  final MedioPago medio;
  final bool elegido;
  final VoidCallback? alElegir;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final (nombre, detalle) = switch (medio) {
      MedioPago.tarjeta => ('Tarjeta', 'Débito o crédito'),
      _ => (medio.etiqueta, 'Con tu celular y el código de aprobación'),
    };
    final inicio = switch (medio) {
      MedioPago.tarjeta => const IconoColor(PhosphorFill.creditCard, color: AppColors.acentoAzul, lado: 44),
      MedioPago.plin => const LogoMarca(MarcaPago.plin, alto: 36),
      _ => const LogoMarca(MarcaPago.yape, alto: 36),
    };
    return Semantics(
      button: true,
      selected: elegido,
      label: '$nombre, $detalle',
      excludeSemantics: true,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.tarjeta),
          side: BorderSide(
            color: elegido ? AppColors.primary : AppColors.border,
            width: elegido ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: alElegir,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                SizedBox(width: 52, child: Center(child: inicio)),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nombre, style: textos.titleMedium),
                      Text(detalle, style: textos.bodyMedium),
                      if (medio == MedioPago.tarjeta) ...const [
                        SizedBox(height: AppSpacing.sm),
                        FilaMarcasTarjeta(),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Container(
                  width: AppIconos.navegacion,
                  height: AppIconos.navegacion,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: elegido ? AppColors.primary : AppColors.surface,
                    border: Border.all(color: elegido ? AppColors.primary : AppColors.bordeControl, width: 1.5),
                  ),
                  child: elegido
                      ? const Icon(Phosphor.check, size: AppIconos.insignia, color: Colors.white)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
      // Sin flecha (el pago ya se hizo): el título conserva el margen de siempre.
      appBar: AppBar(
        title: const Text('Pagos en línea'),
        automaticallyImplyLeading: false,
        titleSpacing: AppSpacing.margen,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.margen),
          children: [
            const PasosPago(actual: 2),
            espacioSeccion,
            const Center(child: CajaIcono(Phosphor.check, tono: Tono.exito, lado: AppSpacing.cajaGrande)),
            espacio,
            Text('Pago realizado', style: textos.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
            Text(soles(total), style: textos.displayMedium, textAlign: TextAlign.center),
            espacioGrande,
            Tarjeta(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Ficha('Operación', widget.resultado.operacion),
                  Ficha('Fecha', fechaLarga(widget.resultado.fecha)),
                  Ficha('Medio de pago', widget.medio.etiqueta),
                  const Divider(height: AppSpacing.xl),
                  for (final l in widget.lineas)
                    _LineaResumen(concepto: l.concepto, periodo: l.periodo, monto: l.monto),
                ],
              ),
            ),
            espacioSeccion,
            FilledButton.icon(
              onPressed: _generando ? null : _descargar,
              icon: _generando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Icon(Phosphor.filePdf, size: AppIconos.boton),
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
