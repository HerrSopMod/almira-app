import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_spacing.dart';
import '../../core/errors/error_app.dart';
import '../../core/widgets/componentes.dart';
import '../../shared/models/modelos.dart';
import '../../shared/services/proveedores.dart';
import '../complaints/piezas_lista.dart';
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
    final valor = _pendiente ?? ref.watch(sesionProvider).consentimientos;
    final habilitado = _pendiente == null;
    return Scaffold(
      appBar: BarraAlmira(titulo: 'Privacidad'),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.margen, AppSpacing.xl, AppSpacing.margen, AppSpacing.xl),
          children: [
            const TituloSeccion('Preferencias opcionales'),
            const SizedBox(height: AppSpacing.xs),
            ListaFilas(
              filas: [
                FilaInterruptor(
                  titulo: 'Guardar mis consultas al asistente',
                  detalle: 'En este teléfono, para retomarlas. Apagado, se borran al salir.',
                  valor: valor.asistente,
                  alCambiar: habilitado ? (v) => _cambiar(valor.con(asistente: v)) : null,
                ),
                FilaInterruptor(
                  titulo: 'Avisos por WhatsApp',
                  detalle: 'Recordatorios de vencimiento de tus tributos.',
                  valor: valor.whatsapp,
                  alCambiar: habilitado ? (v) => _cambiar(valor.con(whatsapp: v)) : null,
                ),
                FilaInterruptor(
                  titulo: 'Avisos por SMS',
                  detalle: 'Los mismos recordatorios, por mensaje de texto.',
                  valor: valor.sms,
                  alCambiar: habilitado ? (v) => _cambiar(valor.con(sms: v)) : null,
                ),
              ],
            ),
            if (_error != null) ...[espacio, Aviso('No se guardó el cambio. ${_error!}', tono: Tono.error)],
            espacioGrande,
            const TituloSeccion('Tus datos'),
            const SizedBox(height: AppSpacing.xs),
            FilaLista(
              titulo: 'Cómo se usan tus datos',
              detalle: DetalleFila('Qué datos usa Almira, para qué y tus derechos.'),
              alTocar: () => mostrarInformacionPrivacidad(context),
            ),
          ],
        ),
      ),
    );
  }
}
