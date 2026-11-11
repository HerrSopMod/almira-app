import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';
import '../../core/widgets/componentes.dart';
import '../../shared/models/modelos.dart';

/// Preferencias opcionales de privacidad. Cada una se activa con una acción
/// del vecino; ninguna viene encendida.
class InterruptoresPrivacidad extends StatelessWidget {
  const InterruptoresPrivacidad({
    super.key,
    required this.valor,
    required this.alCambiar,
    this.habilitado = true,
  });

  final Consentimientos valor;
  final ValueChanged<Consentimientos> alCambiar;
  final bool habilitado;

  @override
  Widget build(BuildContext context) => Tarjeta(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          children: [
            SwitchListTile(
              value: valor.asistente,
              onChanged: habilitado ? (v) => alCambiar(valor.con(asistente: v)) : null,
              secondary: const Icon(Icons.chat_bubble_outline_rounded),
              title: const Text('Guardar mis consultas al asistente'),
              subtitle: const Text('En este teléfono, para retomarlas. Apagado, se borran al salir.'),
            ),
            const Divider(indent: 56),
            SwitchListTile(
              value: valor.whatsapp,
              onChanged: habilitado ? (v) => alCambiar(valor.con(whatsapp: v)) : null,
              secondary: const Icon(Icons.forum_outlined),
              title: const Text('Avisos por WhatsApp'),
              subtitle: const Text('Recordatorios de vencimiento de tus tributos.'),
            ),
            const Divider(indent: 56),
            SwitchListTile(
              value: valor.sms,
              onChanged: habilitado ? (v) => alCambiar(valor.con(sms: v)) : null,
              secondary: const Icon(Icons.sms_outlined),
              title: const Text('Avisos por SMS'),
              subtitle: const Text('Los mismos recordatorios, por mensaje de texto.'),
            ),
          ],
        ),
      );
}

/// Información completa de privacidad, fuera de las pantallas operativas.
void mostrarInformacionPrivacidad(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) {
      final textos = Theme.of(context).textTheme;
      Widget bloque(String titulo, String cuerpo) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: textos.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(cuerpo, style: textos.bodyMedium),
              ],
            ),
          );
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (context, desplazamiento) => ListView(
          controller: desplazamiento,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.margen,
            0,
            AppSpacing.margen,
            AppSpacing.xl,
          ),
          children: [
            Semantics(
              header: true,
              child: Text('Cómo se usan tus datos', style: textos.titleLarge),
            ),
            espacio,
            bloque(
              'Qué datos usa Almira',
              'Tu cuenta de ingreso, tu código de contribuyente, los tributos y pagos que tu '
                  'municipalidad registra a tu nombre, y los reclamos que envías: texto, '
                  'fotografía y ubicación.',
            ),
            bloque(
              'Para qué',
              'Para mostrarte tus obligaciones, registrar y seguir tus reclamos, y enviarte '
                  'solo los avisos que actives.',
            ),
            bloque(
              'Quién responde por ellos',
              'Tu municipalidad es la responsable de la información tributaria y de la atención '
                  'de los reclamos. Almira es la aplicación que te la muestra.',
            ),
            bloque(
              'Fotos y ubicación',
              'Se usan únicamente para atender el reclamo al que pertenecen. La app pide la '
                  'cámara o el GPS solo cuando tú lo eliges.',
            ),
            bloque(
              'Tus derechos',
              'La Ley N.° 29733 te permite acceder a tus datos, corregirlos, pedir que se '
                  'eliminen u oponerte a su uso. Para ejercerlos, contacta a tu municipalidad.',
            ),
          ],
        ),
      );
    },
  );
}
