import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../core/errors/error_app.dart';
import '../../core/widgets/componentes.dart';
import '../../shared/services/proveedores.dart';

const _claveMinima = 8;

/// Ingreso con correo o con el número de cuponera, y la clave web. Quien no
/// tiene cuenta se registra con su cuponera (`RegistroScreen`). En modo
/// demostración no hay cuentas: un solo botón, dicho con claridad.
class IngresoScreen extends ConsumerStatefulWidget {
  const IngresoScreen({super.key});

  @override
  ConsumerState<IngresoScreen> createState() => _IngresoScreenState();
}

class _IngresoScreenState extends ConsumerState<IngresoScreen> {
  final _formulario = GlobalKey<FormState>();
  final _usuario = TextEditingController();
  final _clave = TextEditingController();

  bool _verClave = false;
  bool _ocupado = false;
  String? _error;

  @override
  void dispose() {
    _usuario.dispose();
    _clave.dispose();
    super.dispose();
  }

  Future<void> _ejecutar(Future<void> Function() accion) async {
    if (_ocupado) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      await accion();
    } catch (error) {
      if (mounted) setState(() => _error = ErrorApp.de(error).detalle);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  void _ingresar() {
    if (!_formulario.currentState!.validate()) return;
    final auth = ref.read(servicioAuthProvider);
    final usuario = _usuario.text.trim();
    _ejecutar(() => usuario.contains('@')
        ? auth.ingresarConCorreo(usuario, _clave.text)
        : auth.ingresarConCuponera(usuario, _clave.text));
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
              : () => _ejecutar(() => ref.read(servicioAuthProvider).ingresarDemo()),
          child: const Text('Entrar a la demostración'),
        ),
        if (_error != null) ...[espacio, Aviso(_error!, tono: Tono.error)],
      ];

  List<Widget> _conCuenta() => [
        OutlinedButton.icon(
          onPressed: _ocupado ? null : () => _ejecutar(() => ref.read(servicioAuthProvider).ingresarConGoogle()),
          icon: const _LogoGoogle(),
          label: const Text('Continuar con Google'),
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.textPrimary),
        ),
        espacio,
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text('o con tu clave web', style: Theme.of(context).textTheme.bodySmall),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        espacio,
        TextFormField(
          controller: _usuario,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.username],
          autocorrect: false,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'Correo o número de cuponera'),
          validator: (valor) =>
              (valor ?? '').trim().length >= 4 ? null : 'Escribe tu correo o tu número de cuponera.',
        ),
        espacio,
        TextFormField(
          controller: _clave,
          obscureText: !_verClave,
          autofillHints: const [AutofillHints.password],
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _ingresar(),
          decoration: InputDecoration(
            labelText: 'Clave web',
            suffixIcon: IconButton(
              tooltip: _verClave ? 'Ocultar clave' : 'Mostrar clave',
              icon: Icon(_verClave ? Icons.visibility_off_rounded : Icons.visibility_rounded),
              onPressed: () => setState(() => _verClave = !_verClave),
            ),
          ),
          validator: (valor) =>
              (valor ?? '').length >= _claveMinima ? null : 'Usa al menos $_claveMinima caracteres.',
        ),
        if (_error != null) ...[espacio, Aviso(_error!, tono: Tono.error)],
        espacio,
        FilledButton(
          onPressed: _ocupado ? null : _ingresar,
          child: _ocupado
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : const Text('Ingresar'),
        ),
        TextButton(
          onPressed: _ocupado ? null : () => context.push(Rutas.registro),
          child: const Text('Crear cuenta con correo'),
        ),
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
