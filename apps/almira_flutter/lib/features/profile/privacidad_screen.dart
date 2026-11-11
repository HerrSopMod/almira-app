import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_spacing.dart';
import '../../core/errors/error_app.dart';
import '../../core/widgets/componentes.dart';
import '../../shared/models/modelos.dart';
import '../../shared/services/proveedores.dart';
import '../onboarding/privacidad_widgets.dart';

/// Privacidad: las mismas preferencias opcionales del ingreso, que se guardan
/// al cambiarlas. Apagarlas no bloquea ninguna función básica.
class PrivacidadScreen extends ConsumerStatefulWidget {
  const PrivacidadScreen({super.key});

  @override
  ConsumerState<PrivacidadScreen> createState() => _PrivacidadScreenState();
}

class _PrivacidadScreenState extends ConsumerState<PrivacidadScreen> {
  Consentimientos? _pendiente;
  String? _error;

  Future<void> _cambiar(Consentimientos nuevo) async {
    setState(() {
      _pendiente = nuevo;
      _error = null;
    });
    try {
      await ref.read(sesionProvider.notifier).guardarConsentimientos(nuevo);
    } catch (error) {
      // No se guardó: el interruptor vuelve a su valor real.
      if (mounted) setState(() => _error = ErrorApp.de(error).detalle);
    } finally {
      if (mounted) setState(() => _pendiente = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final guardados = ref.watch(sesionProvider).consentimientos;
    final textos = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Privacidad')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.margen, AppSpacing.lg, AppSpacing.margen, AppSpacing.xl),
          children: [
            const TituloSeccion('Preferencias opcionales'),
            espacioChico,
            InterruptoresPrivacidad(
              valor: _pendiente ?? guardados,
              habilitado: _pendiente == null,
              alCambiar: _cambiar,
            ),
            if (_error != null) ...[espacio, Aviso('No se guardó el cambio. ${_error!}', tono: Tono.error)],
            espacioGrande,
            const TituloSeccion('Tus datos'),
            espacioChico,
            Text(
              'Almira usa los datos de tu cuenta y los que registra tu municipalidad para '
              'mostrarte tus tributos y atender tus reclamos.',
              style: textos.bodyMedium,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => mostrarInformacionPrivacidad(context),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: const Text('Leer la información completa'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
