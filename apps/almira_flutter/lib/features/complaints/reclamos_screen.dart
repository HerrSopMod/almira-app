import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/iconos.dart';
import '../../app/theme/iconos_almira.dart';
import '../../core/utils/formato.dart';
import '../../core/utils/plazos.dart';
import '../../core/widgets/componentes.dart';
import '../../core/widgets/movimiento.dart';
import '../../shared/models/modelos.dart';
import '../../shared/services/proveedores.dart';
import 'reclamos_logica.dart';

/// Insignia del reclamo: solo su estado real (En atención, Derivado, Resuelto). Abierto, en coral
/// (etapa en curso); resuelto, en lima.
class InsigniaReclamo extends StatelessWidget {
  const InsigniaReclamo({super.key, required this.reclamo});

  final Reclamo reclamo;

  @override
  Widget build(BuildContext context) => reclamo.resuelto
      ? const Insignia('Resuelto', tono: Tono.exito, icono: Phosphor.check)
      : Insignia(reclamo.estado.etiqueta, tono: Tono.acento);
}

/// Ícono de la categoría de un reclamo, con su color de fondo.
(IconoA, Color) iconoCategoria(TipoReclamo tipo) => switch (tipo) {
  TipoReclamo.alumbrado => (IconoA.poste, AppColors.sol),
  TipoReclamo.pistasVeredas => (IconoA.bache, AppColors.primary),
  TipoReclamo.limpieza => (IconoA.arbitrios, AppColors.lima),
  TipoReclamo.vehiculoMalEstacionado || TipoReclamo.depositoVehicular => (IconoA.alerta, AppColors.coral),
  TipoReclamo.cobroIndebido => (IconoA.tarjeta, AppColors.sol),
  TipoReclamo.otro => (IconoA.chat, AppColors.primary),
};

/// Mis reclamos (rediseño): la tarjeta coral para reportar un problema, tres contadores y una
/// tarjeta por reclamo con su estado y la barra de etapas (sacada de su seguimiento).
class ReclamosScreen extends ConsumerWidget {
  const ReclamosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vista = ref.watch(vistaProvider);
    final hoy = ref.watch(relojProvider)();
    final esDemo = ref.watch(esDemoProvider);

    return Scaffold(
      body: CuerpoAsync<VistaMunicipal>(
        valor: vista,
        alRecargar: ref.read(datosProvider.notifier).recargar,
        cabecera: (_) => CabeceraMarca(titulo: 'Reclamos', esDemo: esDemo),
        construir: (v) {
          if (v.vecino == null) {
            return [
              VistaVacia(
                icono: Phosphor.identificationBadge,
                ilustracion: Ilustracion.pasoCuponera,
                titulo: 'Vincula tu código de contribuyente',
                detalle: 'Lo necesitas para enviar reclamos.',
                accion: 'Vincular código',
                alTocar: () => context.push(Rutas.vincular),
              ),
            ];
          }
          final abiertos = v.reclamos.where((r) => !r.resuelto).length;
          final resueltos = v.reclamos.length - abiertos;
          return [
            Aparecer(child: _NuevoReclamo(alTocar: () => context.push(Rutas.nuevoReclamo))),
            if (v.reclamos.isEmpty)
              const VistaVacia(
                icono: Phosphor.megaphone,
                ilustracion: Ilustracion.barrio,
                titulo: 'Aún no tienes reclamos',
                detalle: 'Reporta un problema con una foto y su ubicación.',
              )
            else ...[
              espacio,
              Aparecer(
                paso: 1,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Contador(
                          numero: v.reclamos.length,
                          texto: v.reclamos.length == 1 ? 'Reclamo' : 'Reclamos',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Contador(numero: abiertos, texto: 'En atención', tono: Tono.acento),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Contador(
                          numero: resueltos,
                          texto: resueltos == 1 ? 'Resuelto' : 'Resueltos',
                          tono: Tono.exito,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              espacioGrande,
              const Aparecer(paso: 2, child: TituloSeccion('Mis reclamos')),
              espacio,
              for (final (i, reclamo) in v.reclamos.indexed) ...[
                if (i > 0) const SizedBox(height: AppSpacing.md),
                Aparecer(
                  paso: 3 + i,
                  child: _TarjetaReclamo(reclamo: reclamo, hoy: hoy),
                ),
              ],
            ],
          ];
        },
      ),
    );
  }
}

/// Tarjeta coral para reportar un problema: la acción principal de la pantalla. El texto va en
/// tinta (sobre coral no va blanco).
class _NuevoReclamo extends StatelessWidget {
  const _NuevoReclamo({required this.alTocar});

  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: 'Nuevo reclamo. ¿Algo anda mal en tu barrio? Cuéntanos.',
      excludeSemantics: true,
      child: Presionable(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.tarjeta),
            boxShadow: AppColors.sombraCoral,
          ),
          child: Material(
            color: AppColors.coral,
            borderRadius: BorderRadius.circular(AppRadius.tarjeta),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: alTocar,
              child: Stack(
                children: [
                  Positioned(
                    right: 18,
                    bottom: -22,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(color: AppColors.sol.withValues(alpha: 0.9), shape: BoxShape.circle),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.cajaMediana),
                          ),
                          child: const Center(
                            child: IconoAlmira(IconoA.reclamos, tamano: 26, color: AppColors.textPrimary),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nuevo reclamo',
                                style: textos.titleLarge!.copyWith(fontSize: 18, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '¿Algo anda mal en tu barrio? Cuéntanos.',
                                style: textos.bodyMedium!.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(color: AppColors.textPrimary, shape: BoxShape.circle),
                          child: const Icon(Icons.add_rounded, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Número grande con su rótulo en una caja (blanca o del tono).
class Contador extends StatelessWidget {
  const Contador({super.key, required this.numero, required this.texto, this.tono});

  final int numero;
  final String texto;
  final Tono? tono;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final t = tono;
    return Semantics(
      label: '$numero $texto',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: t == null ? AppColors.surface : t.fondo,
          borderRadius: BorderRadius.circular(AppRadius.campo + 2),
          boxShadow: t == null ? AppColors.sombraCard : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$numero', style: textos.headlineSmall!.copyWith(fontSize: 26, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(
              texto,
              maxLines: 2,
              style: textos.labelMedium!.copyWith(color: t == null ? AppColors.textSecondary : t.texto),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reclamo como tarjeta: ícono de la categoría, título, código y plazo; abajo, el estado, cuántas
/// etapas lleva y la barra de etapas.
class _TarjetaReclamo extends StatelessWidget {
  const _TarjetaReclamo({required this.reclamo, required this.hoy});

  final Reclamo reclamo;
  final DateTime hoy;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final plazo = plazoDe(reclamo, hoy);
    final limite = plazo?.limite;
    final vencido = plazo?.estado == EstadoPlazo.vencido;
    final detalle = [
      reclamo.codigo,
      if (reclamo.resuelto)
        reclamo.tipo.etiqueta
      else if (limite != null)
        vencido ? 'Plazo vencido el ${diaYMes(limite)}' : 'Respuesta hasta el ${diaYMes(limite)}',
    ].join(' · ');
    final pasos = pasosDe(reclamo);
    final hechas = pasos.where((p) => p.estado != EstadoPaso.pendiente).length;
    final (icono, color) = iconoCategoria(reclamo.tipo);
    final colorBarra = reclamo.resuelto ? AppColors.lima : AppColors.coral;
    return Tarjeta(
      onTap: () => context.go(Rutas.reclamo(reclamo.id)),
      semantica:
          '${reclamo.titulo}. ${reclamo.resuelto ? 'Resuelto' : reclamo.estado.etiqueta}. $detalle. '
          '$hechas de ${pasos.length} etapas. Ver seguimiento',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconoColor.svg(icono, color: color),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reclamo.titulo, style: textos.titleMedium!.copyWith(fontWeight: FontWeight.w800)),
                    Text(
                      detalle,
                      style: textos.bodySmall!.copyWith(color: vencido ? AppColors.error : AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Phosphor.caretRight, size: AppIconos.lista, color: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Flexible(child: InsigniaReclamo(reclamo: reclamo)),
              const SizedBox(width: AppSpacing.sm),
              const Spacer(),
              Flexible(
                child: Text(
                  '$hechas de ${pasos.length} etapas',
                  style: textos.labelMedium,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              for (var i = 0; i < pasos.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.primary50,
                      borderRadius: BorderRadius.circular(AppRadius.pastilla),
                    ),
                    child: i < hechas
                        ? BarraCreciente(fraccion: 1, color: colorBarra, alto: 6, retraso: i * 120)
                        : null,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
