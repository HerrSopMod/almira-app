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

/// Ingreso: cabecera turquesa alta con el logo blanco al centro y el formulario en una hoja
/// blanca que sube sobre ella. «Ingresar» es la única acción primaria, Google la secundaria y el
/// registro un enlace. En modo
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
    final tecladoAbierto = MediaQuery.viewInsetsOf(context).bottom > 0;
    final arriba = MediaQuery.paddingOf(context).top;
    final abajo = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: barraSobreBlanco,
      child: Scaffold(
        backgroundColor: AppColors.surfaceSubtle,
        resizeToAvoidBottomInset: true,
        body: LayoutBuilder(
          builder: (context, caja) {
            final alto = caja.maxHeight;
            final bajo = MediaQuery.sizeOf(context).height < 700;
            // Parte superior clara con círculos turquesa suaves, el logo en un círculo blanco, el
            // nombre y una frase (40 % de la pantalla, 34 % si es baja). Con el teclado abierto se
            // reduce a la barra de estado para que los campos e «Ingresar» queden a la vista.
            final cabecera = tecladoAbierto
                ? arriba + AppSpacing.lg
                : alto * (bajo ? AppSpacing.cabeceraIngresoBaja : AppSpacing.cabeceraIngreso);
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: cabecera,
                    child: tecladoAbierto ? null : _ZonaClara(arriba: arriba, bajo: bajo),
                  ),
                  // Hoja blanca que sube sobre la cabecera y llega hasta el borde inferior.
                  ConstrainedBox(
                    constraints: BoxConstraints(minHeight: (alto - cabecera).clamp(0, double.infinity)),
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.hoja)),
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.margen,
                          AppSpacing.xl,
                          AppSpacing.margen,
                          AppSpacing.xl + abajo,
                        ),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 440),
                            child: Form(
                              key: _formulario,
                              autovalidateMode: _intentado
                                  ? AutovalidateMode.onUserInteraction
                                  : AutovalidateMode.disabled,
                              child: esDemo ? _demo() : _conCuenta(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
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
            prefixIcon: Icon(Phosphor.user),
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
            prefixIcon: const Icon(Phosphor.lock),
            suffixIcon: IconButton(
              tooltip: _verClave ? 'Ocultar clave' : 'Mostrar clave',
              icon: Icon(_verClave ? Phosphor.eyeSlash : Phosphor.eye),
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
              prefixIcon: Icon(Phosphor.envelope),
            ),
            validator: (v) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch((v ?? '').trim())
                ? null
                : 'Escribe un correo válido.',
          ),
        ),
      );
}

/// Parte superior del ingreso: fondo claro con círculos turquesa suaves, el logo en un círculo
/// blanco con sombra tenue, el nombre y una frase. Ocupa el espacio que deja el formulario.
class _ZonaClara extends StatelessWidget {
  const _ZonaClara({required this.arriba, required this.bajo});

  final double arriba;
  final bool bajo;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final logo = bajo ? AppSpacing.logoIngresoBajo : AppSpacing.logoIngreso;
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(right: -60, top: -40, child: _Circulo(150, AppColors.primarySoft)),
          Positioned(left: -50, bottom: 24, child: _Circulo(96, AppColors.primary.withValues(alpha: 0.10))),
          Positioned(right: 36, bottom: 56, child: _Circulo(16, AppColors.primary.withValues(alpha: 0.22))),
          Positioned(left: 44, top: arriba + 28, child: _Circulo(10, AppColors.primary.withValues(alpha: 0.28))),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              arriba + AppSpacing.md,
              AppSpacing.xxl,
              AppSpacing.solapeHoja + AppSpacing.md,
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Semantics(
                  header: true,
                  label: 'Almira',
                  child: ExcludeSemantics(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: logo,
                          height: logo,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.textPrimary.withValues(alpha: 0.10),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(child: LogoAlmira(lado: logo * 0.62)),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text('Almira', style: textos.headlineMedium),
                        const SizedBox(height: AppSpacing.xs),
                        SizedBox(
                          width: 280,
                          child: Text(
                            'Tus pagos, reclamos y obras municipales en un solo lugar.',
                            style: textos.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Circulo extends StatelessWidget {
  const _Circulo(this.lado, this.color);

  final double lado;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Container(width: lado, height: lado, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}
