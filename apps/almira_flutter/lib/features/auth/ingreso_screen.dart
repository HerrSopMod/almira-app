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

/// Ingreso: cabecera con degradado turquesa y la marca, y debajo una tarjeta con Google
/// como método principal y, como alternativa, el correo o el número de cuponera con la
/// clave web. Quien no tiene cuenta se registra con su cuponera. En modo demostración no
/// hay cuentas: un solo botón, dicho con claridad.
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
    final esDemo = ref.watch(esDemoProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: barraSobreTurquesa,
      child: Scaffold(
        backgroundColor: AppColors.surfaceSubtle,
        body: SingleChildScrollView(
          child: Column(
            children: [
              const _Cabecera(),
              Transform.translate(
                offset: const Offset(0, -32),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margen),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.noche.withValues(alpha: 0.10),
                            blurRadius: 28,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formulario,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Ingresa a tu cuenta',
                              style: Theme.of(context).textTheme.titleLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            if (esDemo) ..._demo() else ..._conCuenta(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.paddingOf(context).bottom + AppSpacing.md),
            ],
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
          onPressed: _ocupado
              ? null
              : () => _ejecutar(() => ref.read(servicioAuthProvider).ingresarConGoogle()),
          icon: const LogoGoogle(),
          label: const Text('Continuar con Google'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFDADCE0)),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
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
        const SizedBox(height: AppSpacing.xl),
        TextFormField(
          controller: _usuario,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.username],
          autocorrect: false,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Correo o número de cuponera',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
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
            prefixIcon: const Icon(Icons.lock_outline_rounded),
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
        const SizedBox(height: AppSpacing.xl),
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
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: _ocupado ? null : () => context.push(Rutas.registro),
          style: TextButton.styleFrom(foregroundColor: AppColors.primaryDark),
          child: const Text('Crear cuenta con correo'),
        ),
      ];
}

/// Cabecera con degradado turquesa y formas suaves, con un toque de coral y menta.
class _Cabecera extends StatelessWidget {
  const _Cabecera();

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.margen,
        MediaQuery.paddingOf(context).top + AppSpacing.xxl,
        AppSpacing.margen,
        AppSpacing.xxl + 40,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.noche, AppColors.primaryDark, AppColors.menta],
          stops: [0, 0.55, 1],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      child: ClipRect(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: -70,
              top: -60,
              child: _Circulo(lado: 170, color: AppColors.coral.withValues(alpha: 0.30)),
            ),
            Positioned(
              left: -60,
              bottom: -90,
              child: _Circulo(lado: 160, color: Colors.white.withValues(alpha: 0.10)),
            ),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(child: LogoAlmira(lado: 66)),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Semantics(
                    header: true,
                    child: Text(
                      'Almira',
                      style: textos.headlineMedium!.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Tus pagos, reclamos y obras municipales en un solo lugar.',
                    style: textos.bodyMedium!.copyWith(color: Colors.white.withValues(alpha: 0.92)),
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
}

class _Circulo extends StatelessWidget {
  const _Circulo({required this.lado, required this.color});

  final double lado;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: lado,
        height: lado,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
