import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/iconos.dart';
import '../../app/theme/iconos_almira.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/errors/error_app.dart';
import '../../core/widgets/componentes.dart';
import '../../core/widgets/scroll_formulario.dart';
import '../../shared/services/proveedores.dart';
import 'pasos_registro.dart';
import 'servicio_auth.dart';

const _claveMinima = 8;
final _correoValido = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
final _celularValido = RegExp(r'^9\d{8}$');

/// Municipalidades que se pueden elegir al registrarse (la función del servidor
/// las entrega, porque todavía no hay sesión).
final _municipalidadesRegistroProvider = FutureProvider.autoDispose<List<MunicipalidadRegistro>>(
  (ref) => ref.watch(servicioAuthProvider).municipalidadesRegistro(),
);

/// Registro con la cuponera: municipalidad, número de cuponera y DNI; correo y clave web
/// (que el contribuyente crea aquí); y la verificación del celular. La cuponera es un dato
/// privado, distinto del código de contribuyente: solo la tiene quien recibe la cuponera
/// impresa. El servidor la valida y no dice cuál dato falló.
class RegistroScreen extends ConsumerStatefulWidget {
  const RegistroScreen({super.key});

  @override
  ConsumerState<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends ConsumerState<RegistroScreen> {
  final _formularios = [GlobalKey<FormState>(), GlobalKey<FormState>(), GlobalKey<FormState>()];
  final _cuponera = TextEditingController();
  final _dni = TextEditingController();
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  final _repetir = TextEditingController();
  final _celular = TextEditingController();
  final _codigo = TextEditingController();

  int _paso = 0;
  MunicipalidadRegistro? _municipalidad;
  bool _verClave = false;
  bool _codigoPedido = false;
  bool _ocupado = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_cuponera, _dni, _correo, _clave, _repetir, _celular, _codigo]) {
      c.dispose();
    }
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

  void _atras() {
    if (_paso == 0) {
      context.pop();
    } else {
      setState(() {
        _paso--;
        _error = null;
      });
    }
  }

  void _paso1() {
    if (!_formularios[0].currentState!.validate()) return;
    final municipalidad = _municipalidad;
    if (municipalidad == null) {
      setState(() => _error = 'Elige tu municipalidad.');
      return;
    }
    _ejecutar(() async {
      await ref
          .read(servicioAuthProvider)
          .verificarCuponera(slug: municipalidad.slug, cuponera: _cuponera.text, dni: _dni.text);
      if (mounted) setState(() => _paso = 1);
    });
  }

  void _paso2() {
    if (!_formularios[1].currentState!.validate()) return;
    setState(() {
      _paso = 2;
      _error = null;
    });
  }

  void _pedirCodigo() {
    if (!_formularios[2].currentState!.validate()) return;
    setState(() {
      _codigoPedido = true;
      _error = null;
    });
  }

  void _crearCuenta() {
    if (!_formularios[2].currentState!.validate()) return;
    final municipalidad = _municipalidad!;
    // La municipalidad elegida pasa a la sesión, para seguir con el consentimiento.
    ref.read(sesionProvider.notifier).elegirMunicipalidad(municipalidad.id);
    _ejecutar(
      () => ref
          .read(servicioAuthProvider)
          .registrarConCuponera(
            slug: municipalidad.slug,
            cuponera: _cuponera.text,
            dni: _dni.text,
            correo: _correo.text,
            clave: _clave.text,
            celular: _celular.text,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Los tres primeros pasos del registro; el cuarto (Privacidad) viene después.
    const nombres = ['Cuponera', 'Clave web', 'Celular'];
    final cabecera = switch (_paso) {
      0 => const CabeceraPaso(
        ilustracion: Ilustracion.pasoCuponera,
        fondo: AppColors.primary50,
        titulo: 'Vincula tu cuponera',
        detalle: 'Así vemos tus tributos y pagos de tu casa.',
      ),
      1 => const CabeceraPaso(
        ilustracion: Ilustracion.pasoClave,
        fondo: AppColors.sol100,
        titulo: 'Crea tu clave web',
        detalle: 'Con ella entrarás con tu correo o tu código de contribuyente.',
      ),
      _ => const CabeceraPaso(
        ilustracion: Ilustracion.pasoCelular,
        fondo: AppColors.coral100,
        titulo: 'Verifica tu celular',
        detalle: 'Es el número donde recibirás tus avisos.',
      ),
    };
    return PopScope(
      canPop: _paso == 0,
      onPopInvokedWithResult: (volvio, _) {
        if (!volvio) _atras();
      },
      child: Scaffold(
        appBar: BarraPasos(
          paso: _paso + 1,
          nombre: nombres[_paso],
          alVolver: () {
            if (!_ocupado) _atras();
          },
        ),
        body: SafeArea(
          top: false,
          child: ScrollFormulario(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    KeyedSubtree(key: ValueKey('cabecera-$_paso'), child: cabecera),
                    switch (_paso) {
                      0 => _vistaCuponera(),
                      1 => _vistaCuenta(),
                      _ => _vistaCelular(),
                    },
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _boton(String texto, VoidCallback alTocar) => BotonPaso(texto: texto, alTocar: alTocar, ocupado: _ocupado);

  Widget _rotulo(String texto) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Semantics(
      header: true,
      child: Text(texto, style: Theme.of(context).textTheme.titleSmall!.copyWith(fontSize: 14)),
    ),
  );

  Widget _vistaCuponera() {
    final lista = ref.watch(_municipalidadesRegistroProvider);
    return Form(
      key: _formularios[0],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          lista.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Aviso(
              ErrorApp.de(error).detalle,
              tono: Tono.error,
              accion: TextButton(
                onPressed: () => ref.invalidate(_municipalidadesRegistroProvider),
                child: const Text('Reintentar'),
              ),
            ),
            data: (municipalidades) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _rotulo('Tu municipalidad'),
                for (final m in municipalidades) ...[
                  TarjetaOpcion(
                    titulo: m.nombre,
                    detalle: m.zona,
                    elegida: m.id == _municipalidad?.id,
                    alElegir: () => setState(() {
                      _municipalidad = m;
                      _error = null;
                    }),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
          ),
          espacioChico,
          CampoConRotulo(
            rotulo: 'Tu número de cuponera',
            campo: TextFormField(
              controller: _cuponera,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.next,
              inputFormatters: [LengthLimitingTextInputFormatter(20)],
              decoration: const InputDecoration(
                hintText: 'Ejemplo: 0048217',
                prefixIcon: Icon(Phosphor.identificationBadge, size: 22),
                helperText: 'Es un dato privado: confirma que eres contribuyente.',
              ),
              validator: (v) =>
                  RegExp(r'^[A-Za-z0-9-]{4,20}$').hasMatch((v ?? '').trim()) ? null : 'Escribe tu número de cuponera.',
            ),
          ),
          espacio,
          CampoConRotulo(
            rotulo: 'DNI',
            campo: TextFormField(
              controller: _dni,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
              onFieldSubmitted: (_) => _paso1(),
              decoration: const InputDecoration(hintText: '8 dígitos', prefixIcon: Icon(Phosphor.creditCard, size: 22)),
              validator: (v) => (v ?? '').length == 8 ? null : 'Escribe los 8 dígitos de tu DNI.',
            ),
          ),
          if (_error != null) ...[espacio, Aviso(_error!, tono: Tono.error)],
          espacioGrande,
          _boton('Continuar', _paso1),
        ],
      ),
    );
  }

  Widget _vistaCuenta() => Form(
    key: _formularios[1],
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CampoConRotulo(
          rotulo: 'Correo',
          campo: TextFormField(
            controller: _correo,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'ejemplo@correo.com',
              prefixIcon: Icon(Phosphor.envelope, size: 22),
            ),
            validator: (v) => _correoValido.hasMatch((v ?? '').trim()) ? null : 'Escribe un correo válido.',
          ),
        ),
        espacio,
        CampoConRotulo(
          rotulo: 'Clave web',
          campo: TextFormField(
            controller: _clave,
            obscureText: !_verClave,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
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
        MedidorClave(clave: _clave.text, minimo: _claveMinima),
        espacio,
        CampoConRotulo(
          rotulo: 'Repite tu clave',
          campo: TextFormField(
            controller: _repetir,
            obscureText: !_verClave,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onFieldSubmitted: (_) => _paso2(),
            decoration: const InputDecoration(hintText: 'Tu clave otra vez', prefixIcon: Icon(Phosphor.lock, size: 22)),
            validator: (v) => v == _clave.text ? null : 'Las claves no coinciden.',
          ),
        ),
        ReglasClave(
          reglas: [
            ('Mínimo $_claveMinima caracteres', _clave.text.length >= _claveMinima),
            ('Ambas claves coinciden', _repetir.text.isNotEmpty && _repetir.text == _clave.text),
          ],
        ),
        if (_error != null) ...[espacio, Aviso(_error!, tono: Tono.error)],
        espacioGrande,
        _boton('Continuar', _paso2),
      ],
    ),
  );

  Widget _vistaCelular() => Form(
    key: _formularios[2],
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CampoConRotulo(
          rotulo: 'Celular',
          campo: TextFormField(
            controller: _celular,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumberNational],
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
            onChanged: (_) {
              if (_codigoPedido) setState(() => _codigoPedido = false);
            },
            decoration: const InputDecoration(hintText: '987 654 321', prefixIcon: PrefijoPeru()),
            validator: (v) => _celularValido.hasMatch(v ?? '') ? null : 'Escribe los 9 dígitos de tu celular.',
          ),
        ),
        if (_codigoPedido) ...[
          espacio,
          CampoConRotulo(
            rotulo: 'Código de 6 dígitos',
            campo: CampoCodigo(
              controller: _codigo,
              validator: (v) => (v ?? '').length == 6 ? null : 'Escribe el código de 6 dígitos.',
            ),
          ),
        ],
        if (_error != null) ...[espacio, Aviso(_error!, tono: Tono.error)],
        espacioGrande,
        _boton(
          _codigoPedido ? 'Verificar y crear cuenta' : 'Recibir código',
          _codigoPedido ? _crearCuenta : _pedirCodigo,
        ),
      ],
    ),
  );
}
