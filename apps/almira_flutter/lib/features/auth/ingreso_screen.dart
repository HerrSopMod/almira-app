import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../core/errors/error_app.dart';
import '../../core/widgets/app_confirm_dialog.dart';
import '../../core/widgets/componentes.dart';
import '../../shared/services/proveedores.dart';

const _claveMinima = 8;
const _altoCampo = 52.0;

/// Ingreso. Arriba, un encabezado claro con el logo, el nombre y una frase; abajo, un panel
/// turquesa con esquinas superiores redondeadas que ocupa el resto de la pantalla, con los
/// campos en píldora blanca, «Ingresar» y Google. Todo del mismo ancho. En modo demostración no
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
      if (mounted)
        mostrarMensaje(
          context,
          'Si el correo está registrado, te enviamos un enlace.',
        );
    } catch (error) {
      if (mounted) mostrarMensaje(context, ErrorApp.de(error).detalle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esDemo = ref.watch(esDemoProvider);
    // Con el teclado abierto se oculta el encabezado para que los campos y «Ingresar» se vean.
    final tecladoAbierto = MediaQuery.viewInsetsOf(context).bottom > 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: barraSobreBlanco,
      child: Scaffold(
        backgroundColor: AppColors.surfaceSubtle,
        resizeToAvoidBottomInset: true,
        body: LayoutBuilder(
          builder: (context, restricciones) => SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: restricciones.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // La zona clara toma el espacio que sobra y centra el encabezado.
                    Expanded(
                      child: tecladoAbierto
                          ? SizedBox(height: MediaQuery.paddingOf(context).top)
                          : const _ZonaClara(),
                    ),
                    _Panel(
                      child: Form(
                        key: _formulario,
                        autovalidateMode: _intentado
                            ? AutovalidateMode.onUserInteraction
                            : AutovalidateMode.disabled,
                        child: esDemo ? _demo() : _conCuenta(),
                      ),
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

  Widget _demo() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Center(child: EtiquetaDemo(sobreTurquesa: true)),
      const SizedBox(height: AppSpacing.md),
      Text(
        'Esta versión muestra datos de ejemplo. No necesitas una cuenta.',
        style: Theme.of(context).textTheme.bodyMedium!
            .copyWith(color: Colors.white),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppSpacing.xl),
      _BotonBlanco(
        texto: 'Entrar a la demostración',
        alTocar: _ocupado
            ? null
            : () => _ejecutar(
                () => ref.read(servicioAuthProvider).ingresarDemo(),
              ),
      ),
      if (_error != null) ...[
        const SizedBox(height: AppSpacing.lg),
        _Error(_error!),
      ],
    ],
  );

  Widget _conCuenta() {
    final textos = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Inicia sesión',
          style: textos.titleLarge!.copyWith(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        _CampoPildora(
          controller: _usuario,
          etiqueta: 'Correo o código',
          icono: Icons.person_outline_rounded,
          teclado: TextInputType.emailAddress,
          autofill: const [AutofillHints.username],
          accion: TextInputAction.next,
          validator: (v) => (v ?? '').trim().length >= 4
              ? null
              : 'Escribe tu correo o tu código de contribuyente.',
        ),
        const SizedBox(height: AppSpacing.lg),
        _CampoPildora(
          controller: _clave,
          etiqueta: 'Clave web',
          icono: Icons.lock_outline_rounded,
          oculto: !_verClave,
          autofill: const [AutofillHints.password],
          accion: TextInputAction.done,
          alEnviar: _ingresar,
          sufijo: IconButton(
            tooltip: _verClave ? 'Ocultar clave' : 'Mostrar clave',
            icon: Icon(
              _verClave
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
            ),
            onPressed: () => setState(() => _verClave = !_verClave),
          ),
          validator: (v) => (v ?? '').length >= _claveMinima
              ? null
              : 'Usa al menos $_claveMinima caracteres.',
        ),
        Center(
          child: TextButton(
            onPressed: _ocupado ? null : _olvidoClave,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              minimumSize: const Size(48, 44),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              tapTargetSize: MaterialTapTargetSize.padded,
            ),
            child: Text(
              '¿Olvidaste tu clave?',
              style: textos.labelMedium!.copyWith(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
        if (_error != null) ...[
          _Error(_error!),
          const SizedBox(height: AppSpacing.md),
        ],
        _BotonBlanco(
          texto: 'Ingresar',
          cargando: _ocupado,
          alTocar: _ocupado ? null : _ingresar,
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: Divider(color: Colors.white.withValues(alpha: 0.4)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                'o',
                style: textos.bodySmall!.copyWith(color: Colors.white),
              ),
            ),
            Expanded(
              child: Divider(color: Colors.white.withValues(alpha: 0.4)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _BotonBlanco(
          texto: 'Continuar con Google',
          icono: const LogoGoogle(lado: 20),
          conBorde: true,
          alTocar: _ocupado
              ? null
              : () => _ejecutar(
                  () => ref.read(servicioAuthProvider).ingresarConGoogle(),
                ),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextButton(
          onPressed: _ocupado ? null : () => context.push(Rutas.registro),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
          ),
          child: Text.rich(
            TextSpan(
              style: textos.bodyMedium!.copyWith(
                decoration: TextDecoration.none,
              ),
              children: [
                TextSpan(
                  text: '¿Primera vez? ',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const TextSpan(
                  text: 'Regístrate con tu cuponera',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
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

/// Zona clara: ocupa el espacio que sobra sobre el panel, con detalles suaves, y centra en él el
/// logo, el nombre y la frase.
class _ZonaClara extends StatelessWidget {
  const _ZonaClara();

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    // En pantallas bajas el encabezado se compacta para que quepan los campos.
    final bajo = MediaQuery.sizeOf(context).height < 700;
    final logo = bajo ? 72.0 : 88.0;
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            right: -60,
            top: -40,
            child: _Mancha(130, AppColors.mentaSuave),
          ),
          Positioned(
            left: -50,
            bottom: -30,
            child: _Mancha(90, AppColors.coralSuave),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xl + AppSpacing.sm,
              MediaQuery.paddingOf(context).top + AppSpacing.md,
              AppSpacing.xl + AppSpacing.sm,
              AppSpacing.md,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: logo,
                    height: logo,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.noche.withValues(alpha: 0.12),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(child: LogoAlmira(lado: logo * 0.68)),
                  ),
                  SizedBox(height: bajo ? AppSpacing.md : AppSpacing.lg),
                  Semantics(
                    header: true,
                    child: Text(
                      'Almira',
                      style: textos.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Tus pagos, reclamos y obras municipales en un solo lugar.',
                    style: textos.bodyMedium,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Mancha extends StatelessWidget {
  const _Mancha(this.lado, this.color);

  final double lado;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: lado,
    height: lado,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

/// Panel turquesa con esquinas superiores de 32, del alto de su contenido y anclado abajo.
class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: const BoxDecoration(
      color: AppColors.primary,
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.panel),
      ),
    ),
    padding: EdgeInsets.fromLTRB(
      AppSpacing.xl,
      AppSpacing.xl + AppSpacing.xs,
      AppSpacing.xl,
      MediaQuery.paddingOf(context).bottom + AppSpacing.md,
    ),
    child: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: child,
      ),
    ),
  );
}

/// Campo en píldora blanca de 52 de alto, con ícono a la izquierda y, si hace falta, un
/// botón a la derecha. El error sale debajo, en blanco sobre el turquesa.
class _CampoPildora extends StatelessWidget {
  const _CampoPildora({
    required this.controller,
    required this.etiqueta,
    required this.icono,
    required this.validator,
    this.teclado,
    this.autofill,
    this.accion,
    this.oculto = false,
    this.sufijo,
    this.alEnviar,
  });

  final TextEditingController controller;
  final String etiqueta;
  final IconData icono;
  final String? Function(String?) validator;
  final TextInputType? teclado;
  final Iterable<String>? autofill;
  final TextInputAction? accion;
  final bool oculto;
  final Widget? sufijo;
  final VoidCallback? alEnviar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    OutlineInputBorder borde([
      Color color = Colors.transparent,
      double ancho = 0,
    ]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(_altoCampo / 2),
      borderSide: BorderSide(color: color, width: ancho),
    );
    return TextFormField(
      controller: controller,
      obscureText: oculto,
      keyboardType: teclado,
      autofillHints: autofill,
      autocorrect: false,
      enableSuggestions: !oculto,
      textInputAction: accion,
      onFieldSubmitted: alEnviar == null ? null : (_) => alEnviar!(),
      style: textos.bodyLarge,
      validator: validator,
      decoration: InputDecoration(
        hintText: etiqueta,
        hintStyle: textos.bodyLarge!.copyWith(color: AppColors.textSecondary),
        filled: true,
        fillColor: Colors.white,
        isDense: false,
        constraints: const BoxConstraints(minHeight: _altoCampo),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        prefixIcon: Icon(icono, size: 22),
        prefixIconColor: AppColors.primary,
        suffixIcon: sufijo,
        suffixIconColor: AppColors.textSecondary,
        border: borde(),
        enabledBorder: borde(),
        focusedBorder: borde(AppColors.foco, 1.5),
        errorBorder: borde(AppColors.coral, 2),
        focusedErrorBorder: borde(AppColors.coral, 1.5),
        errorStyle: textos.bodySmall!.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        errorMaxLines: 2,
      ),
    );
  }
}

/// Botón blanco con texto turquesa, de 52 de alto y todo el ancho.
class _BotonBlanco extends StatelessWidget {
  const _BotonBlanco({
    required this.texto,
    required this.alTocar,
    this.icono,
    this.conBorde = false,
    this.cargando = false,
  });

  final String texto;
  final VoidCallback? alTocar;
  final Widget? icono;
  final bool conBorde;
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return SizedBox(
      height: _altoCampo,
      child: FilledButton(
        onPressed: alTocar,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: conBorde
              ? AppColors.textPrimary
              : AppColors.primaryDark,
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.7),
          minimumSize: const Size.fromHeight(_altoCampo),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        ),
        child: cargando
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icono != null) ...[
                    icono!,
                    const SizedBox(width: AppSpacing.md),
                  ],
                  Flexible(
                    child: Text(
                      texto,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textos.labelLarge!.copyWith(
                        color: conBorde
                            ? AppColors.textPrimary
                            : AppColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Error general sobre el panel: tarjeta clara, legible sobre el turquesa.
class _Error extends StatelessWidget {
  const _Error(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorSoft,
        borderRadius: BorderRadius.circular(AppRadius.campo),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 20,
            color: AppColors.error,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              texto,
              style: Theme.of(context).textTheme.bodySmall!
                  .copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    ),
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
      if (_formulario.currentState!.validate())
        Navigator.pop(context, _correo.text.trim());
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
          prefixIcon: Icon(Icons.mail_outline_rounded),
        ),
        validator: (v) =>
            RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch((v ?? '').trim())
            ? null
            : 'Escribe un correo válido.',
      ),
    ),
  );
}
