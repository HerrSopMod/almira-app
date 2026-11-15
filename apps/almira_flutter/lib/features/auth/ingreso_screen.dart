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
import '../carga/pantalla_carga.dart';

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

class _IngresoScreenState extends ConsumerState<IngresoScreen> with SingleTickerProviderStateMixin {
  /// La entrada animada se ve una sola vez por apertura de la app, al llegar desde el splash.
  static bool _entradaVista = false;

  /// Cuándo empezó la entrada. El router puede crear esta pantalla más de una vez al arrancar:
  /// la copia nueva sigue desde donde iba la anterior, sin reiniciar (eso se veía como un salto).
  static DateTime? _inicioEntrada;

  static const _duracionEntrada = Duration(milliseconds: 1300);

  /// Entrada: el ícono con «Almira» debajo empieza al centro, como en la pantalla de carga; tras
  /// una breve pausa todo sube hasta la cabecera mientras la hoja blanca sube con el formulario.
  late final AnimationController _entrada = AnimationController(
    vsync: this,
    duration: _duracionEntrada,
    value: _entradaVista ? 1 : _avanceEntrada(),
  );

  static double _avanceEntrada() {
    final inicio = _inicioEntrada;
    if (inicio == null) return 0;
    final pasado = DateTime.now().difference(inicio).inMicroseconds;
    return (pasado / _duracionEntrada.inMicroseconds).clamp(0, 1).toDouble();
  }

  /// El logo sube y se achica; la hoja sube con él.
  late final Animation<double> _subida = CurvedAnimation(
    parent: _entrada,
    curve: const Interval(0.3, 1, curve: Curves.easeInOutCubic),
  );

  final _formulario = GlobalKey<FormState>();
  final _usuario = TextEditingController();
  final _clave = TextEditingController();

  bool _verClave = false;
  bool _ocupado = false;
  bool _intentado = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (_entradaVista) return;
    // Se marca como vista al terminar: el router puede crear esta pantalla más de una vez al
    // arrancar, y la que queda en pantalla debe animarse.
    _entrada.addStatusListener((estado) {
      if (estado == AnimationStatus.completed) _entradaVista = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Con «reducir movimiento», sin animación.
      if (MediaQuery.maybeDisableAnimationsOf(context) == true) {
        _entrada.value = 1;
      } else {
        _inicioEntrada ??= DateTime.now();
        _entrada.value = _avanceEntrada();
        _entrada.forward();
      }
    });
  }

  @override
  void dispose() {
    _entrada.dispose();
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
      value: barraSobreTurquesa,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        resizeToAvoidBottomInset: true,
        body: AnimatedBuilder(
          animation: _entrada,
          builder: (context, _) => LayoutBuilder(
            builder: (context, caja) {
              final alto = caja.maxHeight;
              final bajo = MediaQuery.sizeOf(context).height < 700;
              // Cabecera turquesa alta (40 % de la pantalla, 34 % si es baja) con el logo blanco al
              // centro. Con el teclado abierto se reduce a la barra de estado para que los campos e
              // «Ingresar» queden a la vista.
              final destino = tecladoAbierto
                  ? arriba + AppSpacing.lg
                  : alto * (bajo ? AppSpacing.cabeceraIngresoBaja : AppSpacing.cabeceraIngreso);
              // Durante la entrada, la cabecera ocupa toda la pantalla y se recoge hasta su alto.
              final t = _subida.value;
              final cabecera = tecladoAbierto ? destino : alto + (destino - alto) * t;
              final icono =
                  AppSpacing.logoCarga +
                  ((bajo ? AppSpacing.logoIngresoBajo : AppSpacing.logoIngreso) - AppSpacing.logoCarga) * t;
              return SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: cabecera,
                      child: tecladoAbierto
                          ? null
                          : Padding(
                              // Al inicio, sin rellenos: el ícono queda en el centro exacto de la pantalla, como en el
                              // splash. Los rellenos llegan con la subida.
                              padding: EdgeInsets.only(top: arriba * t, bottom: AppSpacing.solapeHoja * t),
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: _LogoEntrada(
                                    lado: icono,
                                    // Al inicio el ícono queda justo al centro, donde lo dejó la
                                    // carga; «Almira» cuelga debajo sin moverlo.
                                    centrarIcono: 1 - t,
                                  ),
                                ),
                              ),
                            ),
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
          validator: (v) =>
              (v ?? '').length >= _claveMinima ? null : 'Usa al menos $_claveMinima caracteres.',
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
          onPressed: _ocupado
              ? null
              : () => _ejecutar(() => ref.read(servicioAuthProvider).ingresarConGoogle()),
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
        decoration: const InputDecoration(labelText: 'Correo', prefixIcon: Icon(Phosphor.envelope)),
        validator: (v) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch((v ?? '').trim())
            ? null
            : 'Escribe un correo válido.',
      ),
    ),
  );
}

/// Logo del ingreso durante la entrada: el ícono blanco y «Almira» debajo. Con [centrarIcono] en
/// 1, el grupo baja lo justo para que el ícono quede en el centro, como en la pantalla de carga;
/// en 0, el grupo entero va centrado, como [LogoVertical].
class _LogoEntrada extends StatelessWidget {
  const _LogoEntrada({required this.lado, required this.centrarIcono});

  final double lado;
  final double centrarIcono;

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme.headlineMedium!.copyWith(color: AppColors.onPrimary);
    final altoNombre =
        AppSpacing.lg + (estilo.fontSize! * estilo.height!) * MediaQuery.textScalerOf(context).scale(1);
    return Semantics(
      header: true,
      label: 'Almira',
      child: ExcludeSemantics(
        child: Transform.translate(
          offset: Offset(0, altoNombre / 2 * centrarIcono),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconoCarga(lado: lado),
              // La misma separación que la pantalla de carga.
              const SizedBox(height: AppSpacing.lg),
              Text('Almira', style: estilo),
            ],
          ),
        ),
      ),
    );
  }
}
