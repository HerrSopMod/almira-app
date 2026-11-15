import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/iconos.dart';
import '../../core/utils/formato.dart';
import '../../core/utils/plazos.dart';
import '../../core/widgets/cara_saldo.dart';
import '../../core/widgets/componentes.dart';
import '../../shared/models/modelos.dart';
import '../../shared/services/proveedores.dart';
import '../complaints/reclamos_logica.dart';
import '../payments/pagos_logica.dart';
import '../payments/widgets_deuda.dart';
import '../profile/foto_perfil.dart';

/// Cuántas obligaciones se listan en Inicio; el resto está en Pagar.
const _maximoEnInicio = 3;

/// Inicio: cabecera turquesa con el saludo, la tarjeta del total flotando sobre la unión con
/// la hoja blanca, una sola acción principal, los accesos rápidos y lo que está en curso.
class InicioScreen extends ConsumerWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vista = ref.watch(vistaProvider);
    final sesion = ref.watch(sesionProvider);
    final esDemo = ref.watch(esDemoProvider);
    final hoy = ref.watch(relojProvider)();

    return Scaffold(
      body: CuerpoAsync<VistaMunicipal>(
        valor: vista,
        alRecargar: ref.read(datosProvider.notifier).recargar,
        cabecera: (v) => CabeceraMarca(
          esDemo: esDemo,
          acciones: [
            IconButton(
              tooltip: 'Avisos',
              icon: const Icon(Phosphor.bell),
              onPressed: () => context.push(Rutas.avisos),
            ),
            IconButton(
              tooltip: 'Mi perfil',
              icon: const IconoPerfil(),
              onPressed: () => context.push(Rutas.perfil),
            ),
          ],
          hijo: _Saludo(
            nombre: v?.vecino?.nombre ?? sesion.cuenta?.nombre,
            municipalidad: v?.municipalidad?.nombre,
          ),
          // Con la tarjeta flotante, el turquesa baja un poco más para que la tarjeta lo monte.
          rellenoInferior: v?.vecino == null ? AppSpacing.solapeHoja + AppSpacing.lg : AppSpacing.xl,
        ),
        flotante: (v) => v.vecino == null ? null : _Resumen(resumen: resumirDeuda(v.deudas, hoy)),
        construir: (v) => v.vecino == null ? _sinVinculo(context, v) : _contenido(context, v, hoy),
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
          espacioChico,
          _FilaObra(obra: v.obras.first),
        ],
      ];

  List<Widget> _contenido(BuildContext context, VistaMunicipal v, DateTime hoy) {
    final resumen = resumirDeuda(v.deudas, hoy);
    final pendientes = filtrarDeudas(v.deudas, FiltroDeuda.pendientes, hoy);
    final reclamo = v.reclamos.where((r) => !r.resuelto).firstOrNull;
    final obra = v.obras.where((o) => o.estado == EstadoObra.enEjecucion).firstOrNull;
    final enCurso = [
      if (reclamo != null) _FilaReclamo(reclamo: reclamo, hoy: hoy),
      if (obra != null) _FilaObra(obra: obra),
    ];

    return [
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
      espacioGrande,
      const _Accesos(),
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
        ..._separadas([
          for (final deuda in pendientes.take(_maximoEnInicio))
            FilaDeuda(deuda: deuda, hoy: hoy, alTocar: () => context.go(Rutas.deuda(deuda.id))),
        ]),
      ],
      if (enCurso.isNotEmpty) ...[
        espacioGrande,
        const TituloSeccion('En curso'),
        espacioChico,
        ..._separadas(enCurso),
      ],
    ];
  }
}

/// Filas separadas por una línea fina, sin cajas.
List<Widget> _separadas(List<Widget> filas) => [
      for (final (i, f) in filas.indexed) ...[if (i > 0) const Divider(), f],
    ];

/// «Hola, Rosa», en blanco y grande, con la municipalidad debajo (viene de los datos).
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
            style: textos.headlineSmall!.copyWith(color: AppColors.onPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (municipalidad != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            municipalidad!,
            style: textos.bodyLarge!.copyWith(color: AppColors.onPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

/// Tarjeta del total pendiente que flota sobre la unión: la carita (feliz sin deuda, triste con
/// deuda) junto al monto, una línea con cuántas obligaciones hay y cuándo vence la próxima, y una
/// insignia solo si algo ya venció.
class _Resumen extends StatelessWidget {
  const _Resumen({required this.resumen});

  final ResumenDeuda resumen;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final vence = resumen.proximoVencimiento;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CaraSaldo(alDia: resumen.alDia, lado: 64),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total pendiente', style: textos.bodyMedium),
                  // El monto se achica antes que partirse en dos líneas.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(soles(resumen.total), style: textos.displaySmall),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (resumen.alDia)
          const Insignia('Estás al día', tono: Tono.exito, icono: Phosphor.check)
        else ...[
          Text(
            [
              plural(resumen.cantidad, 'obligación', 'obligaciones'),
              if (vence != null) 'vence el ${diaYMes(vence)}',
            ].join(' · '),
            style: textos.bodyMedium,
          ),
          if (resumen.cantidadVencidas > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Insignia(
              '${plural(resumen.cantidadVencidas, 'vencida', 'vencidas')} · ${soles(resumen.montoVencido)}',
              tono: Tono.error,
              icono: Phosphor.warningCircle,
            ),
          ],
        ],
      ],
    );
  }
}

/// Reclamo en curso: título, estado real en insignia y la fecha de respuesta en texto.
class _FilaReclamo extends StatelessWidget {
  const _FilaReclamo({required this.reclamo, required this.hoy});

  final Reclamo reclamo;
  final DateTime hoy;

  @override
  Widget build(BuildContext context) {
    final plazo = plazoDe(reclamo, hoy);
    final limite = plazo?.limite;
    final vencido = plazo?.estado == EstadoPlazo.vencido;
    final texto = switch (plazo?.estado) {
      null => null,
      EstadoPlazo.porConfirmar => 'Plazo por confirmar',
      EstadoPlazo.vencido => limite == null ? 'Plazo vencido' : 'Plazo vencido el ${diaYMes(limite)}',
      _ => limite == null ? null : 'Respuesta hasta el ${diaYMes(limite)}',
    };
    return FilaLista(
      titulo: reclamo.titulo,
      alTocar: () => context.go(Rutas.reclamo(reclamo.id)),
      semantica: 'Reclamo ${reclamo.titulo}. Ver seguimiento',
      detalle: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Insignia(reclamo.estado.etiqueta, tono: Tono.primario),
          if (texto != null) TextoPlazo(texto, vencido: vencido),
        ],
      ),
    );
  }
}

/// Obra en ejecución: nombre y avance en una línea gris.
class _FilaObra extends StatelessWidget {
  const _FilaObra({required this.obra});

  final Obra obra;

  @override
  Widget build(BuildContext context) => FilaLista(
        titulo: obra.nombre,
        alTocar: () => context.go(Rutas.obra(obra.id)),
        semantica: 'Obra ${obra.nombre}. Ver detalle',
        detalle: Text(
          '${obra.estado.etiqueta} · avance ${obra.avancePct.round()} %',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
}

/// Accesos rápidos: una fila de cuatro círculos turquesa claro con su etiqueta debajo.
class _Accesos extends StatelessWidget {
  const _Accesos();

  @override
  Widget build(BuildContext context) {
    Widget acceso(IconData icono, String texto, String ruta) => Expanded(
          child: Acceso(icono: icono, texto: texto, alTocar: () => context.go(ruta)),
        );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        acceso(Phosphor.creditCard, 'Pagar en línea', Rutas.pagoEnLinea),
        acceso(Phosphor.receipt, 'Estado de cuenta', Rutas.estadoCuenta),
        acceso(Phosphor.fileText, 'Cuponera', Rutas.cuponera),
        acceso(Phosphor.clockCounterClockwise, 'Historial', Rutas.estadoCuenta),
      ],
    );
  }
}
