import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/router.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/widgets/componentes.dart';
import '../../shared/services/proveedores.dart';

/// Atención: solo los canales que la municipalidad publicó. Almira no tiene
/// operadores propios, y no lo aparenta.
class AtencionScreen extends ConsumerWidget {
  const AtencionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vista = ref.watch(vistaProvider);
    final textos = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Atención')),
      body: SafeArea(
        top: false,
        child: CuerpoAsync<VistaMunicipal>(
          valor: vista,
          alRecargar: ref.read(datosProvider.notifier).recargar,
          construir: (v) {
            final telefono = v.municipalidad?.telefonoAyuda?.trim() ?? '';
            return [
              if (v.municipalidad != null) Text(v.municipalidad!.nombre, style: textos.titleMedium),
              espacio,
              if (telefono.isEmpty)
                const Aviso(
                  'Tu municipalidad aún no publicó un teléfono de atención en Almira.',
                  icono: Icons.phone_disabled_outlined,
                )
              else
                Tarjeta(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: const Icon(Icons.phone_outlined),
                    title: Text(telefono),
                    subtitle: const Text('Teléfono de ayuda'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      final abierto = await launchUrl(Uri(scheme: 'tel', path: telefono))
                          .catchError((_) => false);
                      if (!abierto && context.mounted) {
                        mostrarMensaje(context, 'No se pudo abrir el marcador del teléfono.');
                      }
                    },
                  ),
                ),
              espacioGrande,
              const TituloSeccion('También puedes'),
              espacioChico,
              Tarjeta(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.campaign_outlined),
                      title: const Text('Enviar un reclamo'),
                      subtitle: const Text('Con foto y ubicación, y seguir su atención.'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push(Rutas.nuevoReclamo),
                    ),
                    const Divider(indent: 56),
                    ListTile(
                      leading: const Icon(Icons.chat_bubble_outline_rounded),
                      title: const Text('Preguntar al asistente'),
                      subtitle: const Text('Respuestas automáticas sobre tus datos.'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.go(Rutas.asistente),
                    ),
                  ],
                ),
              ),
            ];
          },
        ),
      ),
    );
  }
}
