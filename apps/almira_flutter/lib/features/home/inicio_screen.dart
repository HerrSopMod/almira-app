import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/iconos.dart';
import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/utils/formato.dart';
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
        title: const MarcaAlmira(),
        actions: [
          // Con letra muy grande no entra junto a la marca.
          if (esDemo && MediaQuery.textScalerOf(context).scale(1) <= 1.15)
            const Center(child: EtiquetaDemo()),
          IconButton(
            tooltip: 'Avisos',
            icon: const Icon(Phosphor.bell),
            onPressed: () => context.push(Rutas.avisos),
          ),
          IconButton(
            tooltip: 'Mi perfil',
            icon: const Icon(Phosphor.userCircle),
            onPressed: () => context.push(Rutas.perfil),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: CuerpoAsync<VistaMunicipal>(
        valor: vista,
        alRecargar: ref.read(datosProvider.notifier).recargar,
        construir: (v) => [
          _Saludo(nombre: nombre, municipalidad: v.municipalidad?.nombre),
          espacioGrande,
          ...v.vecino == null ? _sinVinculo(context, v) : _contenido(context, v, hoy),
        ],
      ),
    );
  }

  /// La cuenta todavía no tiene código vinculado: no hay deuda que mostrar,
  /// y no se inventa un "S/ 0.00".
  List<Widget> _sinVinculo(BuildContext context, VistaMunicipal v) => [
        VistaVacia(
          icono: Phosphor.identificationBadge,
          titulo: 'Vincula tu código de contribuyente',
          detalle: 'Así verás tus tributos y podrás enviar reclamos.',
          accion: 'Vincular código',
          alTocar: () => context.push(Rutas.vincular),
        ),
        if (v.obras.isNotEmpty) ...[
          const TituloSeccion('En tu distrito'),
          espacio,
          _TarjetaObra(obra: v.obras.first),
        ],
      ];

  List<Widget> _contenido(BuildContext context, VistaMunicipal v, DateTime hoy) {
    final resumen = resumirDeuda(v.deudas, hoy);
    final pendientes = filtrarDeudas(v.deudas, FiltroDeuda.pendientes, hoy);
    final reclamo = v.reclamos.where((r) => !r.resuelto).firstOrNull;
    final obra = v.obras.where((o) => o.estado == EstadoObra.enEjecucion).firstOrNull;

    return [
      _Resumen(resumen: resumen),
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
      espacioSeccion,
      const _Accesos(),
      if (pendientes.isNotEmpty) ...[
        espacioSeccion,
        TituloSeccion(
          'Tus obligaciones',
          accion: pendientes.length > _maximoEnInicio
              ? TextButton(
                  onPressed: () => context.go(Rutas.pagos),
                  child: const Text('Ver todas'),
                )
              : null,
        ),
        espacio,
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
        espacioSeccion,
        const TituloSeccion('En curso'),
        espacio,
        if (reclamo != null) ...[_TarjetaReclamo(reclamo: reclamo, hoy: hoy), espacioChico],
        if (obra != null) _TarjetaObra(obra: obra),
      ],
    ];
  }
}

/// «Hola, Rosa» y la municipalidad, que viene de los datos.
class _Saludo extends StatelessWidget {
  const _Saludo({this.nombre, this.municipalidad});

  final String? nombre;
  final String? municipalidad;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            nombre == null ? 'Hola' : 'Hola, ${primerNombre(nombre!)}',
            style: textos.headlineSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (municipalidad != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(municipalidad!, style: textos.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ],
    );
  }
}

/// Bloque Destacado del inicio: el monto pendiente, grande y con aire, una línea con cuántas
/// obligaciones hay y cuándo vence la próxima, y una sola insignia si algo ya venció.
class _Resumen extends StatelessWidget {
  const _Resumen({required this.resumen});

  final ResumenDeuda resumen;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final vence = resumen.proximoVencimiento;
    return Destacado(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total pendiente', style: textos.bodyMedium),
          const SizedBox(height: AppSpacing.xs),
          // El monto se achica antes que partirse en dos líneas.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(soles(resumen.total), style: textos.displaySmall),
          ),
          const SizedBox(height: AppSpacing.md),
          if (resumen.alDia)
            const Insignia('Estás al día', tono: Tono.exito, icono: Phosphor.check)
          else ...[
            Text(
              [
                plural(resumen.cantidad, 'obligación', 'obligaciones'),
                if (vence != null) 'próximo vencimiento ${diaYMes(vence)}',
              ].join(' · '),
              style: textos.bodyMedium!.copyWith(color: AppColors.textPrimary),
            ),
            if (resumen.cantidadVencidas > 0) ...[
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: Insignia(
                  '${plural(resumen.cantidadVencidas, 'vencida', 'vencidas')} · ${soles(resumen.montoVencido)}',
                  tono: Tono.error,
                  icono: Phosphor.warningCircle,
                ),
              ),
            ],
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
          const CajaIcono(Phosphor.megaphone),
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
          const Icon(Phosphor.caretRight, color: AppColors.textSecondary),
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
          const CajaIcono(Phosphor.barricade),
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
          const Icon(Phosphor.caretRight, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

/// Accesos rápidos a lo que más se usa, en dos filas: caja de ícono turquesa sobre gris claro y
/// el nombre al lado, en una tarjeta blanca con borde.
class _Accesos extends StatelessWidget {
  const _Accesos();

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    Widget acceso(IconData icono, String texto, String ruta) => Expanded(
          child: Tarjeta(
            onTap: () => context.go(ruta),
            semantica: texto,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                CajaIcono(icono),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(texto, style: textos.titleSmall, maxLines: 3, overflow: TextOverflow.ellipsis),
                ),
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
          acceso(Phosphor.lock, 'Pagar en línea', Rutas.pagoEnLinea),
          acceso(Phosphor.receipt, 'Estado de cuenta', Rutas.estadoCuenta),
        ),
        const SizedBox(height: AppSpacing.sm),
        fila(
          acceso(Phosphor.fileText, 'Cuponera', Rutas.cuponera),
          acceso(Phosphor.clockCounterClockwise, 'Historial', Rutas.estadoCuenta),
        ),
      ],
    );
  }
}
