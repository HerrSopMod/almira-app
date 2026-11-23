import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/iconos.dart';
import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/iconos_almira.dart';
import '../../core/errors/error_app.dart';
import '../../core/widgets/componentes.dart';
import '../../core/widgets/scroll_formulario.dart';
import '../../shared/services/proveedores.dart';
import 'pasos_registro.dart';

const _claveMinima = 8;

/// Primera vez, tras vincular la cuponera: el contribuyente crea su clave web, con la que
/// entrará después con su correo o su código de contribuyente. Se puede dejar para más tarde
/// desde Mi perfil. La clave no se guarda en el teléfono.
class CrearClaveScreen extends ConsumerStatefulWidget {
  const CrearClaveScreen({super.key});

  @override
  ConsumerState<CrearClaveScreen> createState() => _CrearClaveScreenState();
}

class _CrearClaveScreenState extends ConsumerState<CrearClaveScreen> {
  final _formulario = GlobalKey<FormState>();
  final _clave = TextEditingController();
  final _repetir = TextEditingController();
  bool _ver = false;
  bool _ocupado = false;
  String? _error;

  @override
  void dispose() {
    _clave.clear();
    _repetir.clear();
    _clave.dispose();
    _repetir.dispose();
    super.dispose();
  }

  void _seguir() => context.push(Rutas.verificarCelular);

  Future<void> _guardar() async {
    if (_ocupado || !_formulario.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      await ref.read(servicioAuthProvider).crearClaveWeb(_clave.text);
      if (mounted) _seguir();
    } catch (error) {
      if (mounted) setState(() => _error = ErrorApp.de(error).detalle);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const BarraPasos(paso: 2, nombre: 'Clave web'),
    body: SafeArea(
      top: false,
      child: ScrollFormulario(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Form(
              key: _formulario,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const CabeceraPaso(
                    ilustracion: Ilustracion.pasoClave,
                    fondo: AppColors.sol100,
                    titulo: 'Crea tu clave web',
                    detalle: 'Con ella entrarás con tu correo o tu código de contribuyente.',
                  ),
                  CampoConRotulo(
                    rotulo: 'Clave web',
                    campo: TextFormField(
                      controller: _clave,
                      obscureText: !_ver,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Tu clave',
                        prefixIcon: const Icon(Phosphor.lock, size: 22),
                        suffixIcon: IconButton(
                          tooltip: _ver ? 'Ocultar clave' : 'Mostrar clave',
                          icon: Icon(_ver ? Phosphor.eyeSlash : Phosphor.eye, size: 22),
                          onPressed: () => setState(() => _ver = !_ver),
                        ),
                      ),
                      validator: (v) =>
                          (v ?? '').length >= _claveMinima ? null : 'Usa al menos $_claveMinima caracteres.',
                    ),
                  ),
                  MedidorClave(clave: _clave.text, minimo: _claveMinima),
                  espacio,
                  CampoConRotulo(
                    rotulo: 'Repite tu clave',
                    campo: TextFormField(
                      controller: _repetir,
                      obscureText: !_ver,
                      textInputAction: TextInputAction.done,
                      onChanged: (_) => setState(() {}),
                      onFieldSubmitted: (_) => _guardar(),
                      decoration: const InputDecoration(
                        hintText: 'Tu clave otra vez',
                        prefixIcon: Icon(Phosphor.lock, size: 22),
                      ),
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
                  BotonPaso(texto: 'Guardar clave', alTocar: _guardar, ocupado: _ocupado),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(onPressed: _ocupado ? null : _seguir, child: const Text('Ahora no')),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
