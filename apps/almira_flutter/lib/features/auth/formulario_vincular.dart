import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/componentes.dart';
import '../../shared/services/datos_demo.dart';
import '../../shared/services/proveedores.dart';

final _codigoValido = RegExp(r'^[A-Za-z0-9-]{4,20}$');
final _documentoValido = RegExp(r'^[A-Za-z0-9]{8,12}$');

/// Vincula el código de contribuyente con el DNI. El padrón se consulta en el
/// servidor (`vincular_contribuyente`); el DNI no se guarda en el teléfono.
class FormularioVincular extends ConsumerStatefulWidget {
  const FormularioVincular({super.key, required this.municipalidadId, this.alVincular});

  final String municipalidadId;
  final VoidCallback? alVincular;

  @override
  ConsumerState<FormularioVincular> createState() => _FormularioVincularState();
}

class _FormularioVincularState extends ConsumerState<FormularioVincular> {
  final _formulario = GlobalKey<FormState>();
  final _codigo = TextEditingController();
  final _dni = TextEditingController();
  bool _ocupado = false;
  String? _error;

  @override
  void dispose() {
    _codigo.dispose();
    _dni.dispose();
    super.dispose();
  }

  Future<void> _vincular() async {
    if (_ocupado || !_formulario.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _ocupado = true;
      _error = null;
    });
    final error = await ref
        .read(repositorioProvider)
        .vincularCodigo(widget.municipalidadId, _codigo.text, _dni.text);
    if (error == null) {
      // Ya vinculado, las políticas dejan ver sus tributos: se vuelven a leer.
      await ref.read(datosProvider.notifier).recargar();
    }
    if (!mounted) return;
    setState(() {
      _ocupado = false;
      _error = error;
    });
    if (error == null) {
      mostrarMensaje(context, 'Código vinculado.');
      widget.alVincular?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final esDemo = ref.watch(esDemoProvider);
    return Form(
      key: _formulario,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _codigo,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.next,
            inputFormatters: [LengthLimitingTextInputFormatter(20)],
            decoration: InputDecoration(
              labelText: 'Número de cuponera',
              helperText: esDemo
                  ? 'Demostración: usa ${DatosDemo.codigoContribuyente}'
                  : 'Está en tu cuponera o estado de cuenta.',
            ),
            validator: (valor) => _codigoValido.hasMatch((valor ?? '').trim())
                ? null
                : 'Usa de 4 a 20 letras, números o guiones.',
          ),
          espacio,
          TextFormField(
            controller: _dni,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.done,
            inputFormatters: [LengthLimitingTextInputFormatter(12)],
            onFieldSubmitted: (_) => _vincular(),
            decoration: InputDecoration(
              labelText: 'DNI o carné de extranjería',
              helperText: esDemo ? 'Demostración: usa ${DatosDemo.dni}' : null,
            ),
            validator: (valor) => _documentoValido.hasMatch((valor ?? '').trim())
                ? null
                : 'Escribe de 8 a 12 letras o números, sin espacios.',
          ),
          if (_error != null) ...[espacio, Aviso(_error!, tono: Tono.error)],
          espacio,
          OutlinedButton(
            onPressed: _ocupado ? null : _vincular,
            child: _ocupado
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Text('Vincular código'),
          ),
        ],
      ),
    );
  }
}
