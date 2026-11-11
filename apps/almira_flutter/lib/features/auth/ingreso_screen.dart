import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../core/errors/error_app.dart';
import '../../core/widgets/componentes.dart';
import '../../shared/services/proveedores.dart';

const _claveMinima = 8;
final _correoValido = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
final _celularValido = RegExp(r'^9\d{8}$');

enum _Metodo { correo, celular }

/// Ingreso. Con el servicio conectado: Google, correo o celular con código.
/// En modo demostración no hay cuentas: un solo botón, dicho con claridad.
class IngresoScreen extends ConsumerStatefulWidget {
  const IngresoScreen({super.key});

  @override
  ConsumerState<IngresoScreen> createState() => _IngresoScreenState();
}

class _IngresoScreenState extends ConsumerState<IngresoScreen> {
  final _formulario = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  final _celular = TextEditingController();
  final _codigo = TextEditingController();

  _Metodo _metodo = _Metodo.correo;
  bool _registro = false;
  bool _verClave = false;
  bool _codigoEnviado = false;
  bool _ocupado = false;
  String? _error;
  String? _nota;

  @override
  void dispose() {
    _correo.dispose();
    _clave.dispose();
    _celular.dispose();
    _codigo.dispose();
    super.dispose();
  }

  Future<void> _ejecutar(Future<String?> Function() accion) async {
    if (_ocupado) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _ocupado = true;
      _error = null;
      _nota = null;
    });
    try {
      final nota = await accion();
      if (mounted) setState(() => _nota = nota);
    } catch (error) {
      if (mounted) setState(() => _error = ErrorApp.de(error).detalle);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  void _enviarCorreo() {
    if (!_formulario.currentState!.validate()) return;
    final auth = ref.read(servicioAuthProvider);
    _ejecutar(() async {
      if (!_registro) {
        await auth.ingresarConCorreo(_correo.text, _clave.text);
        return null;
      }
      final conSesion = await auth.crearCuenta(_correo.text, _clave.text);
      return conSesion ? null : 'Te enviamos un correo. Confírmalo y vuelve a ingresar.';
    });
  }

  void _enviarCelular() {
    if (!_formulario.currentState!.validate()) return;
    final auth = ref.read(servicioAuthProvider);
    _ejecutar(() async {
      if (_codigoEnviado) {
        await auth.verificarCodigoSms(_celular.text, _codigo.text);
        return null;
      }
      await auth.enviarCodigoSms(_celular.text);
      if (mounted) setState(() => _codigoEnviado = true);
      return 'Te enviamos un código por SMS.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final esDemo = ref.watch(esDemoProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: barraSobreBlanco,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.margen,
                vertical: AppSpacing.xl,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _formulario,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: LogoAlmira(lado: 96)),
                      espacioChico,
                      Semantics(
                        header: true,
                        child: Text(
                          'Almira',
                          style: textos.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Tus pagos, reclamos y obras municipales en un solo lugar.',
                        style: textos.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      if (esDemo) ..._demo() else ..._conCuenta(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _demo() => [
        const Center(child: EtiquetaDemo()),
        espacioChico,
        Text(
          'Esta versión muestra datos de ejemplo. No necesitas una cuenta.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        espacioGrande,
        FilledButton(
          onPressed: _ocupado
              ? null
              : () => _ejecutar(() async {
                    await ref.read(servicioAuthProvider).ingresarDemo();
                    return null;
                  }),
          child: const Text('Entrar a la demostración'),
        ),
        if (_error != null) ...[espacio, Aviso(_error!, tono: Tono.error)],
      ];

  List<Widget> _conCuenta() => [
        OutlinedButton.icon(
          onPressed: _ocupado
              ? null
              : () => _ejecutar(() async {
                    await ref.read(servicioAuthProvider).ingresarConGoogle();
                    return null;
                  }),
          icon: const _LogoGoogle(),
          label: const Text('Continuar con Google'),
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.textPrimary),
        ),
        espacio,
        SegmentedButton<_Metodo>(
          segments: const [
            ButtonSegment(value: _Metodo.correo, label: Text('Correo')),
            ButtonSegment(value: _Metodo.celular, label: Text('Celular')),
          ],
          selected: {_metodo},
          showSelectedIcon: false,
          onSelectionChanged: _ocupado
              ? null
              : (elegido) => setState(() {
                    _metodo = elegido.first;
                    _error = null;
                    _nota = null;
                  }),
        ),
        espacio,
        if (_metodo == _Metodo.correo) ..._campoCorreo() else ..._campoCelular(),
        if (_error != null) ...[espacio, Aviso(_error!, tono: Tono.error)],
        if (_nota != null) ...[espacio, Aviso(_nota!, tono: Tono.primario)],
        espacio,
        FilledButton(
          onPressed: _ocupado
              ? null
              : (_metodo == _Metodo.correo ? _enviarCorreo : _enviarCelular),
          child: _ocupado
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : Text(switch ((_metodo, _registro, _codigoEnviado)) {
                  (_Metodo.correo, true, _) => 'Crear cuenta',
                  (_Metodo.correo, false, _) => 'Ingresar',
                  (_Metodo.celular, _, true) => 'Verificar código',
                  (_Metodo.celular, _, false) => 'Recibir código por SMS',
                }),
        ),
        if (_metodo == _Metodo.correo)
          TextButton(
            onPressed: _ocupado
                ? null
                : () => setState(() {
                      _registro = !_registro;
                      _error = null;
                      _nota = null;
                    }),
            child: Text(_registro ? 'Ya tengo cuenta' : 'Crear una cuenta'),
          ),
      ];

  List<Widget> _campoCorreo() => [
        TextFormField(
          controller: _correo,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          autocorrect: false,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'Correo'),
          validator: (valor) =>
              _correoValido.hasMatch((valor ?? '').trim()) ? null : 'Escribe un correo válido.',
        ),
        espacio,
        TextFormField(
          controller: _clave,
          obscureText: !_verClave,
          autofillHints: [_registro ? AutofillHints.newPassword : AutofillHints.password],
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _enviarCorreo(),
          decoration: InputDecoration(
            labelText: 'Contraseña',
            helperText: _registro ? 'Mínimo $_claveMinima caracteres.' : null,
            suffixIcon: IconButton(
              tooltip: _verClave ? 'Ocultar contraseña' : 'Mostrar contraseña',
              icon: Icon(_verClave ? Icons.visibility_off_rounded : Icons.visibility_rounded),
              onPressed: () => setState(() => _verClave = !_verClave),
            ),
          ),
          validator: (valor) => (valor ?? '').length >= _claveMinima
              ? null
              : 'Usa al menos $_claveMinima caracteres.',
        ),
      ];

  List<Widget> _campoCelular() => [
        TextFormField(
          controller: _celular,
          keyboardType: TextInputType.phone,
          autofillHints: const [AutofillHints.telephoneNumberNational],
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(9),
          ],
          onChanged: (_) {
            if (_codigoEnviado) setState(() => _codigoEnviado = false);
          },
          decoration: const InputDecoration(labelText: 'Celular', prefixText: '+51 '),
          validator: (valor) => _celularValido.hasMatch(valor ?? '')
              ? null
              : 'Escribe los 9 dígitos de tu celular.',
        ),
        if (_codigoEnviado) ...[
          espacio,
          TextFormField(
            controller: _codigo,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: const InputDecoration(labelText: 'Código de 6 dígitos'),
            validator: (valor) =>
                (valor ?? '').length == 6 ? null : 'Escribe el código de 6 dígitos.',
          ),
        ],
      ];
}

/// "G" de Google, sin depender de un archivo de imagen.
class _LogoGoogle extends StatelessWidget {
  const _LogoGoogle();

  @override
  Widget build(BuildContext context) => const ExcludeSemantics(
        child: Text(
          'G',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF4285F4),
          ),
        ),
      );
}
