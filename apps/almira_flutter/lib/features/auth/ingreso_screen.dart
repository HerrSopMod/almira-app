import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/iconos.dart';
import '../../core/errors/error_app.dart';
import '../../core/widgets/app_confirm_dialog.dart';
import '../../core/widgets/componentes.dart';
import '../../core/widgets/movimiento.dart';
import '../../shared/services/proveedores.dart';

const _claveMinima = 8;

/// Ingreso (rediseño): arriba, un degradado turquesa muy claro con la casita que flota, «Almira»
/// y una frase; debajo, sobre el fondo crema, los campos con su rótulo encima. «Ingresar» es la
/// única acción primaria, Google la secundaria y el registro un enlace. En modo demostración no
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
    final correo = await showDialog<String>(context: context, builder: (_) => const _DialogoOlvido());
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
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: true,
        body: LayoutBuilder(
          builder: (context, caja) {
            final alto = caja.maxHeight;
            final bajo = MediaQuery.sizeOf(context).height < 700;
            // Zona clara de arriba (39 % de la pantalla, 34 % si es baja). Con el teclado abierto
            // se reduce a la barra de estado para que los campos e «Ingresar» queden a la vista.
            final cabecera = tecladoAbierto
                ? arriba + AppSpacing.lg
                : alto * (bajo ? AppSpacing.cabeceraIngresoBaja : AppSpacing.cabeceraIngreso);
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: alto),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: cabecera,
                        child: tecladoAbierto ? null : _ZonaClara(arriba: arriba, bajo: bajo),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(24, AppSpacing.md, 24, 26 + abajo),
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
                    ],
                  ),
                ),
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
      const Aparecer(paso: 4, child: Center(child: EtiquetaDemo())),
      const SizedBox(height: AppSpacing.md),
      Aparecer(
        paso: 5,
        child: Text(
          'Esta versión muestra datos de ejemplo. No necesitas una cuenta.',
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
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
        Aparecer(
          paso: 4,
          child: CampoConRotulo(
            rotulo: 'Correo o código de contribuyente',
            campo: TextFormField(
              controller: _usuario,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.username],
              autocorrect: false,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'ejemplo@correo.com o 0048217',
                prefixIcon: Icon(Phosphor.user, size: 22),
              ),
              validator: (v) => (v ?? '').trim().length >= 4 ? null : 'Escribe tu correo o tu código de contribuyente.',
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Aparecer(
          paso: 5,
          child: CampoConRotulo(
            rotulo: 'Clave web',
            campo: TextFormField(
              controller: _clave,
              obscureText: !_verClave,
              enableSuggestions: false,
              autocorrect: false,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _ingresar(),
              decoration: InputDecoration(
                hintText: 'Tu clave',
                prefixIcon: const Icon(Phosphor.lock, size: 22),
                suffixIcon: IconButton(
                  tooltip: _verClave ? 'Ocultar clave' : 'Mostrar clave',
                  icon: Icon(_verClave ? Phosphor.eyeSlash : Phosphor.eye, size: 22),
                  onPressed: () => setState(() => _verClave = !_verClave),
                ),
              ),
              validator: (v) => (v ?? '').length >= _claveMinima ? null : 'Usa al menos $_claveMinima caracteres.',
            ),
          ),
        ),
        Aparecer(
          paso: 5,
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _ocupado ? null : _olvidoClave,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                textStyle: textos.titleMedium,
              ),
              child: const Text('¿Olvidaste tu clave?'),
            ),
          ),
        ),
        if (_error != null) ...[Aviso(_error!, tono: Tono.error), const SizedBox(height: AppSpacing.lg)],
        const SizedBox(height: AppSpacing.xs),
        Aparecer(
          paso: 6,
          child: _Boton(texto: 'Ingresar', cargando: _ocupado, alTocar: _ocupado ? null : _ingresar),
        ),
        const SizedBox(height: AppSpacing.lg),
        Aparecer(
          paso: 6,
          child: Row(
            children: [
              const Expanded(child: Divider(color: Color(0xFFDCE5E3))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text('o', style: textos.titleSmall!.copyWith(color: AppColors.textSecondary)),
              ),
              const Expanded(child: Divider(color: Color(0xFFDCE5E3))),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Aparecer(
          paso: 7,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.boton),
              boxShadow: AppColors.sombraCard,
            ),
            child: OutlinedButton.icon(
              onPressed: _ocupado ? null : () => _ejecutar(() => ref.read(servicioAuthProvider).ingresarConGoogle()),
              // Botón de Google: blanco, borde gris y texto tinta, con el logo en sus colores.
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.textPrimary),
              icon: const LogoGoogle(lado: 22),
              label: const Text('Continuar con Google'),
            ),
          ),
        ),
        const Spacer(),
        const SizedBox(height: AppSpacing.lg),
        Aparecer(
          paso: 8,
          child: TextButton(
            onPressed: _ocupado ? null : () => context.push(Rutas.registro),
            style: TextButton.styleFrom(minimumSize: const Size.fromHeight(AppSpacing.toque)),
            child: Text.rich(
              TextSpan(
                style: textos.bodyLarge!.copyWith(color: AppColors.textSecondary),
                children: const [
                  TextSpan(text: '¿Primera vez? '),
                  TextSpan(
                    text: 'Regístrate con tu cuponera',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
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
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppRadius.boton),
      boxShadow: alTocar == null ? null : AppColors.sombraPrimaria,
    ),
    child: FilledButton(
      onPressed: alTocar,
      child: cargando
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
            )
          : Text(texto),
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
        decoration: const InputDecoration(labelText: 'Correo', prefixIcon: Icon(Phosphor.envelope)),
        validator: (v) =>
            RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch((v ?? '').trim()) ? null : 'Escribe un correo válido.',
      ),
    ),
  );
}

/// Parte superior del ingreso: degradado turquesa muy claro que se funde con el crema, un círculo
/// blanco translúcido arriba a la derecha, la casita que flota, «Almira» y una frase.
class _ZonaClara extends StatelessWidget {
  const _ZonaClara({required this.arriba, required this.bajo});

  final double arriba;
  final bool bajo;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final logo = bajo ? AppSpacing.logoIngresoBajo : AppSpacing.logoIngreso;
    return ClipRect(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary100, AppColors.primary50, AppColors.background],
            stops: [0, 0.6, 1],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              right: -40,
              top: -38,
              child: Container(
                width: 156,
                height: 156,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.55), shape: BoxShape.circle),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, arriba + AppSpacing.md, 24, AppSpacing.md),
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
                          Rebote(
                            child: Flotar(
                              // Sombra con la forma de la casita: la misma imagen, en turquesa
                              // translúcido y desenfocada, un poco más abajo.
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Transform.translate(
                                    offset: const Offset(0, 10),
                                    child: ImageFiltered(
                                      imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                      child: SvgPicture.asset(
                                        'assets/marca/casita.svg',
                                        width: logo,
                                        height: logo,
                                        colorFilter: ColorFilter.mode(
                                          AppColors.primary.withValues(alpha: 0.25),
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SvgPicture.asset('assets/marca/casita.svg', width: logo, height: logo),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Aparecer(
                            paso: 2,
                            child: Text(
                              'Almira',
                              style: textos.headlineMedium!.copyWith(fontSize: 36, height: 1, letterSpacing: -1.08),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Aparecer(
                            paso: 3,
                            child: SizedBox(
                              width: 290,
                              child: Text(
                                'Tus pagos, reclamos y obras municipales en un solo lugar.',
                                style: textos.bodyLarge!.copyWith(
                                  fontSize: 16,
                                  height: 1.5,
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
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
      ),
    );
  }
}
