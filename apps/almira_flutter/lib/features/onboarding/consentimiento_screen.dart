import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_spacing.dart';
import '../../core/errors/error_app.dart';
import '../../core/widgets/componentes.dart';
import '../../shared/models/modelos.dart';
import '../../shared/services/proveedores.dart';
import 'privacidad_widgets.dart';

/// Último paso del primer ingreso. Separa lo necesario para dar el servicio
/// (se informa) de lo opcional (se elige, y empieza apagado). «Continuar» no
/// activa nada opcional.
class ConsentimientoScreen extends ConsumerStatefulWidget {
  const ConsentimientoScreen({super.key});

  @override
  ConsumerState<ConsentimientoScreen> createState() => _ConsentimientoScreenState();
}

class _ConsentimientoScreenState extends ConsumerState<ConsentimientoScreen> {
  Consentimientos _elegidos = const Consentimientos();
  bool _guardando = false;
  String? _error;

  Future<void> _continuar() async {
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      // Al guardarse, la sesión queda lista y la app pasa sola a Inicio.
      await ref.read(sesionProvider.notifier).completarIngreso(_elegidos);
    } catch (error) {
      if (mounted) setState(() => _error = ErrorApp.de(error).detalle);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Privacidad')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.margen,
            AppSpacing.lg,
            AppSpacing.margen,
            AppSpacing.xl,
          ),
          children: [
            Semantics(
              header: true,
              child: Text('Tus datos', style: textos.headlineSmall),
            ),
            espacioChico,
            Text(
              'Almira usa los datos de tu cuenta y los que registra tu municipalidad para '
              'mostrarte tus tributos y atender tus reclamos.',
              style: textos.bodyLarge,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => mostrarInformacionPrivacidad(context),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: const Text('Leer la información completa'),
              ),
            ),
            espacio,
            TituloSeccion('Opcional'),
            espacioChico,
            InterruptoresPrivacidad(
              valor: _elegidos,
              habilitado: !_guardando,
              alCambiar: (valor) => setState(() => _elegidos = valor),
            ),
            espacioChico,
            Text('Puedes cambiarlo cuando quieras en Mi perfil.', style: textos.bodySmall),
            if (_error != null) ...[espacio, Aviso(_error!, tono: Tono.error)],
            espacioGrande,
            FilledButton(
              onPressed: _guardando ? null : _continuar,
              child: _guardando
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
  }
}
