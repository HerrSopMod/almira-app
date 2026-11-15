import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/iconos.dart';
import '../../core/errors/error_app.dart';
import '../../core/widgets/app_confirm_dialog.dart';
import '../../core/widgets/componentes.dart';
import '../../shared/services/proveedores.dart';

const _claveMinima = 8;

/// Ingreso sobre fondo blanco: el logo vertical arriba, los campos del tema, «Ingresar» como
/// única acción primaria, Google como secundaria y el registro como enlace. En modo
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
  bool _intentado = false;
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
    setState(() => _intentado = true);
    if (!_formulario.currentState!.validate()) return;
    final auth = ref.read(servicioAuthProvider);
    final usuario = _usuario.text.trim();
    _ejecutar(
      () => usuario.contains('@')
          ? auth.ingresarConCorreo(usuario, _clave.text)
          : auth.ingresarConCodigo(usuario, _clave.text),
    );
  }

  Future<void> _olvidoClave() async {
    final correo = await showDialog<String>(
      context: context,
      builder: (_) => const _DialogoOlvido(),
    );
    if (correo == null || !mounted) return;
    try {
      await ref.read(servicioAuthProvider).enviarEnlaceClave(correo);
      if (mounted) {
        mostrarMensaje(context, 'Si el correo está registrado, te enviamos un enlace.');
      }
    } catch (error) {
      if (mounted) mostrarMensaje(context, ErrorApp.de(error).detalle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esDemo = ref.watch(esDemoProvider);
    // Con el teclado abierto el logo se achica para que los campos e «Ingresar» se vean.
    final tecladoAbierto = MediaQuery.viewInsetsOf(context).bottom > 0;
    final bajo = MediaQuery.sizeOf(context).height < 700;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: barraSobreBlanco,
      child: Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margen),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Con el teclado abierto el logo se oculta para que los campos e «Ingresar»
                    // queden a la vista.
                    if (tecladoAbierto)
                      const SizedBox(height: AppSpacing.lg)
                    else ...[
                      SizedBox(height: bajo ? AppSpacing.xl : AppSpacing.seccion + AppSpacing.lg),
                      const Center(child: LogoVertical()),
                      SizedBox(height: bajo ? AppSpacing.xl : AppSpacing.xxxl),
                    ],
                    Form(
                      key: _formulario,
                      autovalidateMode:
                          _intentado ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
                      child: esDemo ? _demo() : _conCuenta(),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _demo() => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: EtiquetaDemo()),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Esta versión muestra datos de ejemplo. No necesitas una cuenta.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          _Boton(
            texto: 'Entrar a la demostración',
            cargando: _ocupado,
            alTocar: _ocupado ? null : () => _ejecutar(() => ref.read(servicioAuthProvider).ingresarDemo()),
          ),
          if (_error != null) ...[const SizedBox(height: AppSpacing.lg), Aviso(_error!, tono: Tono.error)],
        ],
      );

  Widget _conCuenta() {
    final textos = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _usuario,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.username],
          autocorrect: false,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Correo o código de contribuyente',
            prefixIcon: Icon(Phosphor.user, size: AppIconos.lista),
          ),
          validator: (v) =>
              (v ?? '').trim().length >= 4 ? null : 'Escribe tu correo o tu código de contribuyente.',
        ),
        const SizedBox(height: AppSpacing.lg),
        TextFormField(
          controller: _clave,
          obscureText: !_verClave,
          enableSuggestions: false,
          autocorrect: false,
          autofillHints: const [AutofillHints.password],
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _ingresar(),
          decoration: InputDecoration(
            labelText: 'Clave web',
            prefixIcon: const Icon(Phosphor.lock, size: AppIconos.lista),
            suffixIcon: IconButton(
              tooltip: _verClave ? 'Ocultar clave' : 'Mostrar clave',
              icon: Icon(_verClave ? Phosphor.eyeSlash : Phosphor.eye, size: AppIconos.lista),
              onPressed: () => setState(() => _verClave = !_verClave),
            ),
          ),
          validator: (v) => (v ?? '').length >= _claveMinima ? null : 'Usa al menos $_claveMinima caracteres.',
        ),
        const SizedBox(height: AppSpacing.xs),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _ocupado ? null : _olvidoClave,
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm)),
            child: const Text('¿Olvidaste tu clave?'),
          ),
        ),
        if (_error != null) ...[Aviso(_error!, tono: Tono.error), const SizedBox(height: AppSpacing.lg)],
        const SizedBox(height: AppSpacing.sm),
        _Boton(texto: 'Ingresar', cargando: _ocupado, alTocar: _ocupado ? null : _ingresar),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text('o', style: textos.bodySmall),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        OutlinedButton.icon(
          onPressed: _ocupado ? null : () => _ejecutar(() => ref.read(servicioAuthProvider).ingresarConGoogle()),
          // Botón de Google: blanco, borde gris de 1 px y texto oscuro, como pide la guía.
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.border),
          ),
          icon: const LogoGoogle(lado: 20),
          label: const Text('Continuar con Google'),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextButton(
          onPressed: _ocupado ? null : () => context.push(Rutas.registro),
          style: TextButton.styleFrom(minimumSize: const Size.fromHeight(AppSpacing.toque)),
          child: Text.rich(
            TextSpan(
              style: textos.bodyMedium,
              children: const [
                TextSpan(text: '¿Primera vez? '),
                TextSpan(
                  text: 'Regístrate con tu cuponera',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

/// Botón primario del ingreso: muestra el avance mientras se espera al servicio.
class _Boton extends StatelessWidget {
  const _Boton({required this.texto, required this.alTocar, this.cargando = false});

  final String texto;
  final VoidCallback? alTocar;
  final bool cargando;

  @override
  Widget build(BuildContext context) => FilledButton(
        onPressed: alTocar,
        child: cargando
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : Text(texto),
      );
}

/// Pide el correo para enviar el enlace de recuperación.
class _DialogoOlvido extends StatefulWidget {
  const _DialogoOlvido();

  @override
  State<_DialogoOlvido> createState() => _DialogoOlvidoState();
}

class _DialogoOlvidoState extends State<_DialogoOlvido> {
  final _formulario = GlobalKey<FormState>();
  final _correo = TextEditingController();

  @override
  void dispose() {
    _correo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppConfirmDialog(
        titulo: 'Recupera tu clave',
        textoConfirmar: 'Enviar enlace',
        alConfirmar: () {
          if (_formulario.currentState!.validate()) {
            Navigator.pop(context, _correo.text.trim());
          }
        },
        alCancelar: () => Navigator.pop(context),
        contenido: Form(
          key: _formulario,
          child: TextFormField(
            controller: _correo,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Correo',
              prefixIcon: Icon(Phosphor.envelope, size: AppIconos.lista),
            ),
            validator: (v) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch((v ?? '').trim())
                ? null
                : 'Escribe un correo válido.',
          ),
        ),
      );
}
