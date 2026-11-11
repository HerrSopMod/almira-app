import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_spacing.dart';
import '../../core/errors/error_app.dart';
import '../../core/widgets/componentes.dart';
import '../../shared/services/proveedores.dart';
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
      await ref.read(servicioAuthProvider).verificarCuponera(
            slug: municipalidad.slug,
            cuponera: _cuponera.text,
            dni: _dni.text,
          );
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
    _ejecutar(() => ref.read(servicioAuthProvider).registrarConCuponera(
          slug: municipalidad.slug,
          cuponera: _cuponera.text,
          dni: _dni.text,
          correo: _correo.text,
          clave: _clave.text,
          celular: _celular.text,
        ));
  }

  @override
  Widget build(BuildContext context) {
    const titulos = ['Tu cuponera', 'Tu cuenta', 'Verifica tu celular'];
    return PopScope(
      canPop: _paso == 0,
      onPopInvokedWithResult: (volvio, _) {
        if (!volvio) _atras();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(titulos[_paso]),
          leading: IconButton(
            tooltip: 'Volver',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _ocupado ? null : _atras,
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(3),
            child: LinearProgressIndicator(
              value: (_paso + 1) / 3,
              minHeight: 3,
              backgroundColor: Colors.white24,
              color: Colors.white,
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.margen),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: switch (_paso) {
                  0 => _vistaCuponera(),
                  1 => _vistaCuenta(),
                  _ => _vistaCelular(),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _boton(String texto, VoidCallback alTocar) => FilledButton(
        onPressed: _ocupado ? null : alTocar,
        child: _ocupado
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : Text(texto),
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
            data: (municipalidades) => DropdownButtonFormField<MunicipalidadRegistro>(
              initialValue: _municipalidad,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Municipalidad'),
              items: [
                for (final m in municipalidades) DropdownMenuItem(value: m, child: Text(m.nombre)),
              ],
              onChanged: (m) => setState(() => _municipalidad = m),
              validator: (m) => m == null ? 'Elige tu municipalidad.' : null,
            ),
          ),
          espacio,
          TextFormField(
            controller: _cuponera,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.next,
            inputFormatters: [LengthLimitingTextInputFormatter(20)],
            decoration: const InputDecoration(
              labelText: 'Número de cuponera',
              prefixIcon: Icon(Icons.badge_outlined),
              helperText: 'Es el número privado de tu cuponera impresa.',
            ),
            validator: (v) => RegExp(r'^[A-Za-z0-9-]{4,20}$').hasMatch((v ?? '').trim())
                ? null
                : 'Escribe tu número de cuponera.',
          ),
          espacio,
          TextFormField(
            controller: _dni,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
            onFieldSubmitted: (_) => _paso1(),
            decoration: const InputDecoration(labelText: 'DNI', prefixIcon: Icon(Icons.credit_card_outlined)),
            validator: (v) => (v ?? '').length == 8 ? null : 'Escribe los 8 dígitos de tu DNI.',
          ),
          if (_error != null) ...[espacio, Aviso(_error!, tono: Tono.error)],
          espacio,
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
            TextFormField(
              controller: _correo,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Correo', prefixIcon: Icon(Icons.mail_outline_rounded)),
              validator: (v) =>
                  _correoValido.hasMatch((v ?? '').trim()) ? null : 'Escribe un correo válido.',
            ),
            espacio,
            TextFormField(
              controller: _clave,
              obscureText: !_verClave,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Clave web',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                helperText: 'Mínimo $_claveMinima caracteres.',
                suffixIcon: IconButton(
                  tooltip: _verClave ? 'Ocultar clave' : 'Mostrar clave',
                  icon: Icon(_verClave ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                  onPressed: () => setState(() => _verClave = !_verClave),
                ),
              ),
              validator: (v) =>
                  (v ?? '').length >= _claveMinima ? null : 'Usa al menos $_claveMinima caracteres.',
            ),
            espacio,
            TextFormField(
              controller: _repetir,
              obscureText: !_verClave,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _paso2(),
              decoration: const InputDecoration(labelText: 'Repite tu clave', prefixIcon: Icon(Icons.lock_reset_rounded)),
              validator: (v) => v == _clave.text ? null : 'Las claves no coinciden.',
            ),
            if (_error != null) ...[espacio, Aviso(_error!, tono: Tono.error)],
            espacio,
            _boton('Continuar', _paso2),
          ],
        ),
      );

  Widget _vistaCelular() => Form(
        key: _formularios[2],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _celular,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumberNational],
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
              onChanged: (_) {
                if (_codigoPedido) setState(() => _codigoPedido = false);
              },
              decoration: const InputDecoration(labelText: 'Celular', prefixText: '+51 ', prefixIcon: Icon(Icons.smartphone_rounded)),
              validator: (v) =>
                  _celularValido.hasMatch(v ?? '') ? null : 'Escribe los 9 dígitos de tu celular.',
            ),
            if (_codigoPedido) ...[
              espacio,
              TextFormField(
                controller: _codigo,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                onFieldSubmitted: (_) => _crearCuenta(),
                decoration: const InputDecoration(labelText: 'Código de 6 dígitos', prefixIcon: Icon(Icons.pin_outlined)),
                validator: (v) => (v ?? '').length == 6 ? null : 'Escribe el código de 6 dígitos.',
              ),
            ],
            if (_error != null) ...[espacio, Aviso(_error!, tono: Tono.error)],
            espacio,
            _boton(_codigoPedido ? 'Verificar y crear cuenta' : 'Recibir código', _codigoPedido ? _crearCuenta : _pedirCodigo),
          ],
        ),
      );
}
