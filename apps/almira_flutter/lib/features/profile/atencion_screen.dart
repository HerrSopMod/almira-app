import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme/iconos.dart';
import '../../app/router.dart';
import '../../core/widgets/componentes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/iconos_almira.dart';
import '../complaints/piezas_lista.dart';
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
      appBar: BarraAlmira(titulo: 'Atención'),
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
                  icono: Phosphor.phoneSlash,
                )
              else
                GrupoTarjeta(
                  filas: [
                    FilaLista(
                      inicio: const IconoColor.svg(IconoA.celular, color: AppColors.lima),
                      titulo: telefono,
                      detalle: DetalleFila('Teléfono de ayuda'),
                      alTocar: () async {
                        final abierto = await launchUrl(Uri(scheme: 'tel', path: telefono)).catchError((_) => false);
                        if (!abierto && context.mounted) {
                          mostrarMensaje(context, 'No se pudo abrir el marcador del teléfono.');
                        }
                      },
                    ),
                  ],
                ),
              espacioGrande,
              const TituloSeccion('También puedes'),
              espacioChico,
              GrupoTarjeta(
                filas: [
                  FilaLista(
                    inicio: const IconoColor.svg(IconoA.reclamos, color: AppColors.coral),
                    titulo: 'Enviar un reclamo',
                    detalle: DetalleFila('Con foto y ubicación, y seguir su atención.'),
                    alTocar: () => context.push(Rutas.nuevoReclamo),
                  ),
                  FilaLista(
                    inicio: const IconoColor.svg(IconoA.asistente, color: AppColors.primary),
                    titulo: 'Preguntar al asistente',
                    detalle: DetalleFila('Respuestas automáticas sobre tus datos.'),
                    alTocar: () => context.go(Rutas.asistente),
                  ),
                ],
              ),
            ];
          },
        ),
      ),
    );
  }
}
