import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/utils/formato.dart';
import '../../core/widgets/cara_saldo.dart';
import '../../core/widgets/componentes.dart';
import '../../shared/models/modelos.dart';
import '../../shared/services/proveedores.dart';
import '../complaints/reclamos_logica.dart';
import '../payments/pagos_logica.dart';
import '../payments/widgets_deuda.dart';

/// Cuántas obligaciones se listan en Inicio; el resto está en Pagar.
const _maximoEnInicio = 3;

/// Inicio: primero lo que se debe y cuándo vence, con una sola acción
/// principal; después, accesos breves a lo que está en curso.
class InicioScreen extends ConsumerWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vista = ref.watch(vistaProvider);
    final sesion = ref.watch(sesionProvider);
    final esDemo = ref.watch(esDemoProvider);
    final hoy = ref.watch(relojProvider)();
    final v = vista.valueOrNull;
    final nombre = v?.vecino?.nombre ?? sesion.cuenta?.nombre;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 68,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              nombre == null ? 'Hola' : 'Hola, ${primerNombre(nombre)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (v?.municipalidad != null)
              Text(
                v!.municipalidad!.nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall!
                    .copyWith(color: Colors.white.withValues(alpha: 0.86)),
              ),
          ],
        ),
        actions: [
          if (esDemo) const Center(child: EtiquetaDemo(sobreTurquesa: true)),
          IconButton(
            tooltip: 'Avisos',
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => context.push(Rutas.avisos),
          ),
          IconButton(
            tooltip: 'Mi perfil',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push(Rutas.perfil),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: CuerpoAsync<VistaMunicipal>(
        valor: vista,
        alRecargar: ref.read(datosProvider.notifier).recargar,
        construir: (v) => v.vecino == null ? _sinVinculo(context, v) : _contenido(context, v, hoy),
      ),
    );
  }

  /// La cuenta todavía no tiene código vinculado: no hay deuda que mostrar,
  /// y no se inventa un "S/ 0.00".
  List<Widget> _sinVinculo(BuildContext context, VistaMunicipal v) => [
        VistaVacia(
          icono: Icons.badge_outlined,
          titulo: 'Vincula tu código de contribuyente',
          detalle: 'Así verás tus tributos y podrás enviar reclamos.',
          accion: 'Vincular código',
          alTocar: () => context.push(Rutas.vincular),
        ),
        if (v.obras.isNotEmpty) ...[
          TituloSeccion('En tu distrito'),
          espacioChico,
          _TarjetaObra(obra: v.obras.first),
        ],
      ];

  List<Widget> _contenido(BuildContext context, VistaMunicipal v, DateTime hoy) {
    final resumen = resumirDeuda(v.deudas, hoy);
    final pendientes = filtrarDeudas(v.deudas, FiltroDeuda.pendientes, hoy);
    final reclamo = v.reclamos.where((r) => !r.resuelto).firstOrNull;
    final obra = v.obras.where((o) => o.estado == EstadoObra.enEjecucion).firstOrNull;

    return [
      _TarjetaResumen(resumen: resumen, hoy: hoy, codigo: v.vecino?.codigoContribuyente),
      espacio,
      const _Accesos(),
      espacio,
      if (resumen.alDia)
        OutlinedButton(
          onPressed: () => context.go('${Rutas.pagos}?filtro=${FiltroDeuda.pagados.name}'),
          child: const Text('Ver historial de pagos'),
        )
      else
        FilledButton(
          onPressed: () => context.go(Rutas.pagos),
          child: const Text('Ver detalle y pagar'),
        ),
      if (pendientes.isNotEmpty) ...[
        espacioGrande,
        TituloSeccion(
          'Tus obligaciones',
          accion: pendientes.length > _maximoEnInicio
              ? TextButton(
                  onPressed: () => context.go(Rutas.pagos),
                  child: const Text('Ver todas'),
                )
              : null,
        ),
        espacioChico,
        for (final deuda in pendientes.take(_maximoEnInicio)) ...[
          FilaDeuda(
            deuda: deuda,
            hoy: hoy,
            alTocar: () => context.go(Rutas.deuda(deuda.id)),
          ),
          espacioChico,
        ],
      ],
      if (reclamo != null || obra != null) ...[
        espacio,
        TituloSeccion('En curso'),
        espacioChico,
        if (reclamo != null) ...[_TarjetaReclamo(reclamo: reclamo, hoy: hoy), espacioChico],
        if (obra != null) _TarjetaObra(obra: obra),
      ],
    ];
  }
}

class _TarjetaResumen extends StatelessWidget {
  const _TarjetaResumen({required this.resumen, required this.hoy, this.codigo});

  final ResumenDeuda resumen;
  final DateTime hoy;
  final String? codigo;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    if (resumen.alDia) {
      return Tarjeta(
        color: AppColors.successSoft,
        conBorde: false,
        padding: const EdgeInsets.all(AppSpacing.margen),
        child: Row(
          children: [
            const CaraSaldo(alDia: true),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('¡Estás al día con tus tributos!', style: textos.titleLarge),
                  if (codigo != null) Text('Cuponera $codigo', style: textos.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final vence = resumen.proximoVencimiento;
    return Tarjeta(
      color: AppColors.primarySoft,
      conBorde: false,
      padding: const EdgeInsets.all(AppSpacing.margen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CaraSaldo(alDia: false, lado: 56),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tienes ${soles(resumen.total)} pendientes',
                      style: textos.titleSmall!.copyWith(color: AppColors.primaryDark),
                    ),
                    if (codigo != null) Text('Cuponera $codigo', style: textos.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Total pendiente',
            style: textos.titleSmall!.copyWith(color: AppColors.primaryDark),
          ),
          const SizedBox(height: AppSpacing.xs),
          // El monto se achica antes que partirse en dos líneas.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(soles(resumen.total), style: textos.displaySmall),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            [
              plural(resumen.cantidad, 'obligación', 'obligaciones'),
              if (vence != null) 'próximo vencimiento: ${diaYMes(vence)}',
            ].join(' · '),
            style: textos.bodyMedium!.copyWith(color: AppColors.textPrimary),
          ),
          if (resumen.cantidadVencidas > 0 && resumen.cantidadPorVencer > 0) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                Insignia(
                  '${plural(resumen.cantidadVencidas, 'vencida', 'vencidas')} · ${soles(resumen.montoVencido)}',
                  tono: Tono.error,
                  icono: Icons.error_outline_rounded,
                ),
                Insignia(
                  '${resumen.cantidadPorVencer} por vencer · ${soles(resumen.montoPorVencer)}',
                  tono: Tono.aviso,
                  icono: Icons.schedule_rounded,
                ),
              ],
            ),
          ] else if (resumen.cantidadVencidas > 0) ...[
            const SizedBox(height: AppSpacing.md),
            Insignia(
              resumen.cantidadVencidas == 1 ? 'Vencida' : 'Vencidas',
              tono: Tono.error,
              icono: Icons.error_outline_rounded,
            ),
          ],
        ],
      ),
    );
  }
}

class _TarjetaReclamo extends StatelessWidget {
  const _TarjetaReclamo({required this.reclamo, required this.hoy});

  final Reclamo reclamo;
  final DateTime hoy;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final plazo = plazoDe(reclamo, hoy);
    return Tarjeta(
      onTap: () => context.go(Rutas.reclamo(reclamo.id)),
      semantica: 'Reclamo ${reclamo.titulo}. Ver seguimiento',
      child: Row(
        children: [
          const CajaIcono(Icons.campaign_outlined),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reclamo.titulo, style: textos.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                Text(
                  plazo == null ? reclamo.estado.etiqueta : '${reclamo.estado.etiqueta} · ${plazo.etiqueta}',
                  style: textos.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _TarjetaObra extends StatelessWidget {
  const _TarjetaObra({required this.obra});

  final Obra obra;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Tarjeta(
      onTap: () => context.go(Rutas.obra(obra.id)),
      semantica: 'Obra ${obra.nombre}. Ver detalle',
      child: Row(
        children: [
          const CajaIcono(Icons.construction_rounded),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(obra.nombre, style: textos.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                Text(
                  '${obra.estado.etiqueta} · avance físico ${obra.avancePct.round()} %',
                  style: textos.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

/// Accesos rápidos a lo que más se usa, en dos filas para que quepan con letra grande.
class _Accesos extends StatelessWidget {
  const _Accesos();

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    Widget acceso(IconData icono, String texto, String ruta) => Expanded(
          child: Tarjeta(
            onTap: () => context.go(ruta),
            semantica: texto,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.md),
            child: Row(
              children: [
                CajaIcono(icono, lado: 36),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(texto, style: textos.labelLarge, maxLines: 2)),
              ],
            ),
          ),
        );
    Widget fila(Widget a, Widget b) => IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [a, const SizedBox(width: AppSpacing.sm), b],
          ),
        );
    return Column(
      children: [
        fila(
          acceso(Icons.lock_outline_rounded, 'Pagar en línea', Rutas.pagoEnLinea),
          acceso(Icons.receipt_long_outlined, 'Estado de cuenta', Rutas.estadoCuenta),
        ),
        const SizedBox(height: AppSpacing.sm),
        fila(
          acceso(Icons.description_outlined, 'Cuponera', Rutas.cuponera),
          acceso(Icons.history_rounded, 'Historial', Rutas.estadoCuenta),
        ),
      ],
    );
  }
}
