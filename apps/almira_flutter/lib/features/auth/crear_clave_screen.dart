import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/errors/error_app.dart';
import '../../core/widgets/componentes.dart';
import '../../core/widgets/scroll_formulario.dart';
import '../../shared/services/proveedores.dart';

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
        appBar: AppBar(title: const Text('Crea tu clave web')),
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
                      Text(
                        'Con ella entrarás con tu correo o tu código de contribuyente.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      espacio,
                      TextFormField(
                        controller: _clave,
                        obscureText: !_ver,
                        autofillHints: const [AutofillHints.newPassword],
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Clave web',
                          helperText: 'Mínimo $_claveMinima caracteres.',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            tooltip: _ver ? 'Ocultar clave' : 'Mostrar clave',
                            icon: Icon(_ver ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                            onPressed: () => setState(() => _ver = !_ver),
                          ),
                        ),
                        validator: (v) =>
                            (v ?? '').length >= _claveMinima ? null : 'Usa al menos $_claveMinima caracteres.',
                      ),
                      espacio,
                      TextFormField(
                        controller: _repetir,
                        obscureText: !_ver,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _guardar(),
                        decoration: const InputDecoration(
                          labelText: 'Repite tu clave',
                          prefixIcon: Icon(Icons.lock_reset_rounded),
                        ),
                        validator: (v) => v == _clave.text ? null : 'Las claves no coinciden.',
                      ),
                      if (_error != null) ...[espacio, Aviso(_error!, tono: Tono.error)],
                      espacioGrande,
                      FilledButton(
                        onPressed: _ocupado ? null : _guardar,
                        child: _ocupado
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                              )
                            : const Text('Guardar clave'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton(onPressed: _ocupado ? null : _seguir, child: const Text('Ahora no')),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
