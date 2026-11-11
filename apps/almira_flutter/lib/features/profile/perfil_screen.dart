import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/utils/formato.dart';
import '../../core/widgets/componentes.dart';
import '../../shared/services/proveedores.dart';
import '../payments/pagos_logica.dart';

/// Mi perfil: cabecera compacta y opciones agrupadas. Solo muestra el nombre
/// y el código de contribuyente; nunca el DNI ni el teléfono.
class PerfilScreen extends ConsumerWidget {
  const PerfilScreen({super.key});

  Future<void> _cerrarSesion(BuildContext context, WidgetRef ref) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogo, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(dialogo, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    // Al cerrarse, la app vuelve sola al ingreso.
    if (confirmar == true) await ref.read(sesionProvider.notifier).cerrarSesion();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = ref.watch(vistaProvider).valueOrNull;
    final sesion = ref.watch(sesionProvider);
    final textoGrande = ref.watch(textoGrandeProvider);
    final esDemo = ref.watch(esDemoProvider);
    final textos = Theme.of(context).textTheme;
    final vecino = v?.vecino;
    final nombre = vecino?.nombre ?? sesion.cuenta?.nombre;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        actions: [
          if (esDemo)
            const Padding(
              padding: EdgeInsets.only(right: AppSpacing.lg),
              child: Center(child: EtiquetaDemo(sobreTurquesa: true)),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.margen, AppSpacing.lg, AppSpacing.margen, AppSpacing.xl),
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
                  child: nombre == null
                      ? const Icon(Icons.person_outline_rounded, color: AppColors.primaryDark)
                      : ExcludeSemantics(
                          child: Text(
                            iniciales(nombre),
                            style: textos.titleMedium!.copyWith(color: AppColors.primaryDark),
                          ),
                        ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nombre ?? 'Tu cuenta', style: textos.titleLarge),
                      Text(
                        vecino?.codigoContribuyente == null
                            ? (vecino == null ? 'Sin código vinculado' : '')
                            : 'Contribuyente ${vecino!.codigoContribuyente}',
                        style: textos.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            espacioGrande,
            _Grupo(
              titulo: 'Cuenta y predio',
              hijos: [
                for (final predio in v?.predios ?? const [])
                  ListTile(
                    leading: const Icon(Icons.home_outlined),
                    title: Text(predio.direccion),
                    subtitle: Text('Predio ${predio.codigo}'),
                  ),
                _Opcion(
                  icono: Icons.badge_outlined,
                  titulo: vecino == null ? 'Vincular código de contribuyente' : 'Vincular otro código',
                  alTocar: () => context.push(Rutas.vincular),
                ),
                _Opcion(
                  icono: Icons.location_city_outlined,
                  titulo: 'Municipalidad',
                  detalle: v?.municipalidad?.nombre,
                  alTocar: () => context.push(Rutas.municipalidad),
                ),
              ],
            ),
            _Grupo(
              titulo: 'Preferencias',
              hijos: [
                _Opcion(
                  icono: Icons.notifications_none_rounded,
                  titulo: 'Avisos y canales',
                  alTocar: () => context.push(Rutas.avisos),
                ),
                _Opcion(
                  icono: Icons.shield_outlined,
                  titulo: 'Privacidad',
                  alTocar: () => context.push(Rutas.privacidad),
                ),
                SwitchListTile(
                  value: textoGrande,
                  onChanged: ref.read(textoGrandeProvider.notifier).cambiar,
                  secondary: const Icon(Icons.format_size_rounded),
                  title: const Text('Texto más grande'),
                ),
              ],
            ),
            _Grupo(
              titulo: 'Trámites y ayuda',
              hijos: [
                _Opcion(
                  icono: Icons.receipt_long_outlined,
                  titulo: 'Constancias de pago',
                  alTocar: () => context.go('${Rutas.pagos}?filtro=${FiltroDeuda.pagados.name}'),
                ),
                _Opcion(
                  icono: Icons.support_agent_rounded,
                  titulo: 'Atención',
                  alTocar: () => context.push(Rutas.atencion),
                ),
              ],
            ),
            Center(
              child: TextButton.icon(
                onPressed: () => _cerrarSesion(context, ref),
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: Text(esDemo ? 'Salir de la demostración' : 'Cerrar sesión'),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grupo de opciones: un rótulo y una sola tarjeta, sin bordes por fila.
class _Grupo extends StatelessWidget {
  const _Grupo({required this.titulo, required this.hijos});

  final String titulo;
  final List<Widget> hijos;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.sm),
              child: Semantics(
                header: true,
                child: Text(titulo, style: Theme.of(context).textTheme.labelMedium),
              ),
            ),
            Tarjeta(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Column(children: hijos),
            ),
          ],
        ),
      );
}

class _Opcion extends StatelessWidget {
  const _Opcion({required this.icono, required this.titulo, required this.alTocar, this.detalle});

  final IconData icono;
  final String titulo;
  final String? detalle;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icono),
        title: Text(titulo),
        subtitle: detalle == null ? null : Text(detalle!),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
        onTap: alTocar,
      );
}
