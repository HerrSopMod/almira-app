import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/errors/error_app.dart';
import '../../core/widgets/componentes.dart';
import '../../shared/services/proveedores.dart';

final _celularValido = RegExp(r'^9\d{8}$');

/// Verificación del celular tras vincular la cuponera. Con el código de 6 dígitos
/// se guarda el celular de los avisos y sigue el consentimiento.
class VerificarCelularScreen extends ConsumerStatefulWidget {
  const VerificarCelularScreen({super.key});

  @override
  ConsumerState<VerificarCelularScreen> createState() => _VerificarCelularScreenState();
}

class _VerificarCelularScreenState extends ConsumerState<VerificarCelularScreen> {
  final _formulario = GlobalKey<FormState>();
  final _celular = TextEditingController();
  final _codigo = TextEditingController();
  bool _codigoPedido = false;
  bool _ocupado = false;
  String? _error;

  @override
  void dispose() {
    _celular.dispose();
    _codigo.dispose();
    super.dispose();
  }

  Future<void> _verificar() async {
    if (_ocupado || !_formulario.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      await ref.read(repositorioProvider).guardarCelular(_celular.text);
      if (mounted) context.go(Rutas.consentimiento);
    } catch (error) {
      if (mounted) setState(() => _error = ErrorApp.de(error).detalle);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  void _pedirCodigo() {
    if (!_formulario.currentState!.validate()) return;
    setState(() {
      _codigoPedido = true;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Verifica tu celular')),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.margen),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _formulario,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _celular,
                        keyboardType: TextInputType.phone,
                        autofillHints: const [AutofillHints.telephoneNumberNational],
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(9),
                        ],
                        onChanged: (_) {
                          if (_codigoPedido) setState(() => _codigoPedido = false);
                        },
                        decoration: const InputDecoration(labelText: 'Celular', prefixText: '+51 '),
                        validator: (v) => _celularValido.hasMatch(v ?? '')
                            ? null
                            : 'Escribe los 9 dígitos de tu celular.',
                      ),
                      if (_codigoPedido) ...[
                        espacio,
                        TextFormField(
                          controller: _codigo,
                          keyboardType: TextInputType.number,
                          autofillHints: const [AutofillHints.oneTimeCode],
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          onFieldSubmitted: (_) => _verificar(),
                          decoration: const InputDecoration(labelText: 'Código de 6 dígitos'),
                          validator: (v) =>
                              (v ?? '').length == 6 ? null : 'Escribe el código de 6 dígitos.',
                        ),
                      ],
                      if (_error != null) ...[espacio, Aviso(_error!, tono: Tono.error)],
                      espacio,
                      FilledButton(
                        onPressed: _ocupado ? null : (_codigoPedido ? _verificar : _pedirCodigo),
                        child: _ocupado
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                              )
                            : Text(_codigoPedido ? 'Verificar' : 'Recibir código'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
