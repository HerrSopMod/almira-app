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
import '../../core/widgets/escudo_municipal.dart';
import '../../core/widgets/movimiento.dart';
import '../../core/widgets/tributo.dart';
import '../../shared/models/modelos.dart';
import '../../shared/services/proveedores.dart';
import '../account/estado_cuenta_logica.dart';
import '../complaints/reclamos_logica.dart';
import '../payments/pagos_logica.dart';
import '../profile/foto_perfil.dart';
import '../public_works/obras_screen.dart';

/// Cuántas obligaciones se listan en Inicio; el resto está en Pagar.
const _maximoEnInicio = 3;

/// Inicio (rediseño): encabezado alto con degradado, el saludo, la campana y el avatar; la
/// tarjeta del saldo montada sobre el encabezado (total, vencidas, barra por concepto, próxima
/// fecha y «Ver detalle y pagar»); los cuatro accesos; las primeras obligaciones y un carrusel
/// con los reclamos abiertos y las obras en ejecución. Todo sale de los datos del vecino.
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
        cabecera: (v) {
          final conTarjeta = v?.vecino != null;
          return CabeceraMarca(
            decorado: conTarjeta,
            hijo: _Saludo(
              nombre: v?.vecino?.nombre ?? sesion.cuenta?.nombre,
              municipalidad: v?.municipalidad,
              esDemo: esDemo,
            ),
            // Con la tarjeta del saldo, el encabezado es más alto: la tarjeta sube sobre él.
            rellenoInferior: conTarjeta
                ? AppSpacing.solapeInicio + AppSpacing.md
                : AppSpacing.solapeHoja + AppSpacing.lg,
          );
        },
        flotante: (v) => v.vecino == null ? null : _Resumen(deudas: v.deudas, hoy: hoy),
        construir: (v) => v.vecino == null ? _sinVinculo(context, v) : _contenido(context, v, hoy),
      ),
    );
  }

  /// La cuenta todavía no tiene código vinculado: no hay deuda que mostrar,
  /// y no se inventa un "S/ 0.00".
  List<Widget> _sinVinculo(BuildContext context, VistaMunicipal v) {
    final obras = v.obras.where((o) => o.estado == EstadoObra.enEjecucion).toList();
    return [
      VistaVacia(
        icono: Phosphor.identificationBadge,
        ilustracion: Ilustracion.pasoCuponera,
        titulo: 'Vincula tu código de contribuyente',
        detalle: 'Así verás tus tributos y podrás enviar reclamos.',
        accion: 'Vincular código',
        alTocar: () => context.push(Rutas.vincular),
      ),
      if (obras.isNotEmpty) ...[
        const TituloSeccion('En tu distrito'),
        espacio,
        _Carrusel(tarjetas: [for (final o in obras) _TarjetaObra(obra: o)]),
      ],
    ];
  }

  List<Widget> _contenido(BuildContext context, VistaMunicipal v, DateTime hoy) {
    final pendientes = filtrarDeudas(v.deudas, FiltroDeuda.pendientes, hoy);
    final reclamos = v.reclamos.where((r) => !r.resuelto).toList();
    final obras = v.obras.where((o) => o.estado == EstadoObra.enEjecucion).toList();
    final enCurso = [
      for (final r in reclamos) _TarjetaReclamo(reclamo: r, hoy: hoy),
      for (final o in obras) _TarjetaObra(obra: o),
    ];

    return [
      const Aparecer(paso: 3, child: _Accesos()),
      if (pendientes.isNotEmpty) ...[
        espacioGrande,
        Aparecer(
          paso: 4,
          child: TituloSeccion(
            'Tus obligaciones',
            accion: _EnlaceSeccion(texto: 'Ver todo', alTocar: () => context.go(Rutas.pagos)),
          ),
        ),
        espacio,
        Aparecer(
          paso: 5,
          child: Tarjeta(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
            child: Column(
              children: [
                for (final (i, deuda) in pendientes.take(_maximoEnInicio).indexed) ...[
                  if (i > 0) const Divider(),
                  _FilaObligacion(deuda: deuda, hoy: hoy, alTocar: () => context.go(Rutas.deuda(deuda.id))),
                ],
              ],
            ),
          ),
        ),
      ],
      if (enCurso.isNotEmpty) ...[
        espacioGrande,
        const Aparecer(paso: 6, child: TituloSeccion('En curso')),
        espacio,
        _Carrusel(tarjetas: enCurso),
      ],
    ];
  }
}

/// Enlace a la derecha de un título de sección («Ver todo»), en turquesa y 700.
class _EnlaceSeccion extends StatelessWidget {
  const _EnlaceSeccion({required this.texto, required this.alTocar});

  final String texto;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: alTocar,
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      textStyle: Theme.of(context).textTheme.titleMedium,
    ),
    child: Text(texto),
  );
}

/// «Hola, Rosa» con la municipalidad debajo (escudo si lo tiene, si no el pin), y a la derecha
/// la campana y el avatar con las iniciales (o la foto de perfil).
class _Saludo extends StatelessWidget {
  const _Saludo({this.nombre, this.municipalidad, required this.esDemo});

  final String? nombre;
  final Municipalidad? municipalidad;
  final bool esDemo;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final conEscudo = rutaEscudo(municipalidad) != null;
    final nombre = this.nombre;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.margen),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Aparecer(
                  child: Semantics(
                    header: true,
                    child: Text(
                      nombre == null ? 'Hola' : 'Hola, ${primerNombre(tipoTitulo(nombre))}',
                      style: textos.headlineSmall!.copyWith(color: AppColors.onPrimary, height: 1.15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (municipalidad != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (conEscudo) ...[
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(6)),
                          child: EscudoMunicipal(municipalidad, alto: 18),
                        ),
                        const SizedBox(width: 6),
                      ] else ...[
                        const IconoAlmira(IconoA.ubicacion, tamano: 16, color: AppColors.subtextoCabecera),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          municipalidad!.nombre,
                          style: textos.bodyMedium!.copyWith(fontSize: 14, color: AppColors.subtextoCabecera),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (esDemo && MediaQuery.textScalerOf(context).scale(1) <= 1.15) ...[
                  const SizedBox(height: AppSpacing.sm),
                  const EtiquetaDemo(sobreTurquesa: true),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          _BotonCabecera(
            semantica: 'Avisos',
            fondo: Colors.white.withValues(alpha: 0.16),
            alTocar: () => context.push(Rutas.avisos),
            child: const IconoAlmira(IconoA.campana, tamano: 22, color: AppColors.onPrimary),
          ),
          const SizedBox(width: AppSpacing.sm),
          _BotonCabecera(
            semantica: 'Mi perfil',
            fondo: AppColors.sol,
            alTocar: () => context.push(Rutas.perfil),
            child: _Avatar(nombre: nombre),
          ),
        ],
      ),
    );
  }
}

/// Botón cuadrado de 44 con radio de 14 del encabezado.
class _BotonCabecera extends StatelessWidget {
  const _BotonCabecera({required this.semantica, required this.fondo, required this.alTocar, required this.child});

  final String semantica;
  final Color fondo;
  final VoidCallback alTocar;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: semantica,
    excludeSemantics: true,
    child: Tooltip(
      message: semantica,
      excludeFromSemantics: true,
      child: Presionable(
        child: Material(
          color: fondo,
          borderRadius: BorderRadius.circular(AppRadius.caja),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: alTocar,
            child: SizedBox.square(
              dimension: AppSpacing.caja,
              child: Center(child: child),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Iniciales en tinta sobre sol; si el vecino subió una foto, la foto.
class _Avatar extends ConsumerWidget {
  const _Avatar({this.nombre});

  final String? nombre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conFoto = ref.watch(fotoPerfilProvider).valueOrNull != null;
    if (conFoto) return const AvatarPerfil(lado: AppSpacing.caja);
    final n = nombre;
    if (n == null || n.trim().isEmpty) {
      return const IconoAlmira(IconoA.perfil, tamano: 22, color: AppColors.textPrimary);
    }
    return Text(iniciales(n), style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w800));
  }
}

/// Colores de la barra por concepto, en orden.
const _coloresConcepto = [AppColors.coral, AppColors.primary500, AppColors.sol, AppColors.lima, AppColors.primary];

/// Tarjeta del saldo: total grande, cuántas vencidas, barra segmentada por concepto con su
/// leyenda, cuántas obligaciones y cuándo vence la próxima, y el botón principal.
class _Resumen extends StatelessWidget {
  const _Resumen({required this.deudas, required this.hoy});

  final List<Deuda> deudas;
  final DateTime hoy;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final resumen = resumirDeuda(deudas, hoy);
    final vence = resumen.proximoVencimiento;

    // Total pendiente por concepto (tipo de tributo), de mayor a menor.
    final porConcepto = <TipoDeuda, double>{};
    for (final d in deudas.where((d) => d.pendiente)) {
      porConcepto[d.tipo] = (porConcepto[d.tipo] ?? 0) + d.total;
    }
    final conceptos = porConcepto.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = conceptos.fold<double>(0, (s, e) => s + e.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total pendiente',
                    style: textos.titleSmall!.copyWith(fontSize: 14, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // El monto se achica antes que partirse en dos líneas.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Rebote(child: Monto(resumen.total)),
                  ),
                ],
              ),
            ),
            if (resumen.cantidadVencidas > 0)
              Insignia(
                plural(resumen.cantidadVencidas, 'vencida', 'vencidas'),
                tono: Tono.error,
                icono: Phosphor.warningCircle,
              )
            else if (resumen.alDia)
              const Insignia('Estás al día', tono: Tono.exito, icono: Phosphor.check),
          ],
        ),
        if (conceptos.isNotEmpty && total > 0) ...[
          const SizedBox(height: AppSpacing.lg),
          _BarraConceptos(conceptos: conceptos, total: total),
        ],
        if (!resumen.alDia) ...[
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IconoAlmira(IconoA.calendario, tamano: 18, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: textos.bodyMedium,
                    children: [
                      TextSpan(text: plural(resumen.cantidad, 'obligación', 'obligaciones')),
                      if (vence != null) ...[
                        const TextSpan(text: ' · la próxima vence el '),
                        TextSpan(
                          text: diaYMes(vence),
                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        if (resumen.alDia)
          OutlinedButton(
            onPressed: () => context.go('${Rutas.pagos}?filtro=${FiltroDeuda.pagados.name}'),
            child: const Text('Ver historial de pagos'),
          )
        else
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.boton),
              boxShadow: AppColors.sombraPrimaria,
            ),
            child: FilledButton(onPressed: () => context.go(Rutas.pagos), child: const Text('Ver detalle y pagar')),
          ),
      ],
    );
  }
}

/// Barra de 10 px dividida por concepto, y debajo la leyenda con el punto de color y el monto.
class _BarraConceptos extends StatelessWidget {
  const _BarraConceptos({required this.conceptos, required this.total});

  final List<MapEntry<TipoDeuda, double>> conceptos;
  final double total;

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme.labelMedium!
        .copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600);
    Color color(int i) => _coloresConcepto[i % _coloresConcepto.length];
    return Semantics(
      label: conceptos.map((e) => '${e.key.etiqueta} ${soles(e.value)}').join(', '),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pastilla),
            child: Container(
              height: 10,
              color: AppColors.primary50,
              child: Row(
                children: [
                  for (final (i, e) in conceptos.indexed)
                    Expanded(
                      flex: (e.value / total * 1000).round().clamp(1, 1000),
                      child: BarraCreciente(fraccion: 1, color: color(i), alto: 10, retraso: i * 150),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.xs,
            alignment: WrapAlignment.spaceBetween,
            children: [
              for (final (i, e) in conceptos.indexed)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: color(i), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    // Con letra muy grande, la leyenda baja de línea en vez de salirse.
                    Flexible(child: Text('${e.key.etiqueta} ${soles(e.value)}', style: estilo)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Fila de una obligación en Inicio: caja de ícono pastel, tributo y periodo, el vencimiento
/// (en rojo si ya venció) y, a la derecha, el monto con su estado.
class _FilaObligacion extends StatelessWidget {
  const _FilaObligacion({required this.deuda, required this.hoy, required this.alTocar});

  final Deuda deuda;
  final DateTime hoy;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final estado = deuda.estadoAl(hoy);
    final vencida = estado == EstadoDeuda.vencida;
    final icono = switch (deuda.tipo) {
      TipoDeuda.multa => IconoA.multa,
      TipoDeuda.arbitrios => IconoA.arbitrios,
      TipoDeuda.predial => IconoA.predio,
      _ => IconoA.cuponera,
    };
    final color = switch (deuda.tipo) {
      TipoDeuda.multa || TipoDeuda.coactivo => AppColors.coral,
      TipoDeuda.arbitrios => AppColors.lima,
      TipoDeuda.predial => AppColors.sol,
      _ => AppColors.primary,
    };
    final monto = Text(
      soles(deuda.total),
      style: textos.titleMedium!.copyWith(fontSize: 16, fontWeight: FontWeight.w800),
    );
    final insignia = vencida
        ? Insignia(estado.etiqueta, tono: Tono.error, icono: Phosphor.warningCircle)
        : Insignia(estado.etiqueta, tono: Tono.aviso);
    // Con letra muy grande, el monto y el estado bajan debajo del texto en vez de apretarlo.
    final grande = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return Semantics(
      button: true,
      label: '${deuda.tipo.nombre}, ${soles(deuda.total)}, ${estado.etiqueta}. Ver detalle',
      excludeSemantics: true,
      child: InkWell(
        onTap: alTocar,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconoColor.svg(icono, color: color),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(deuda.tipo.nombre, style: textos.titleMedium),
                    const SizedBox(height: 2),
                    Text.rich(
                      TextSpan(
                        style: textos.bodyMedium!.copyWith(height: 1.35),
                        children: [
                          TextSpan(text: periodoConAnio(deuda)),
                          const TextSpan(text: ' · '),
                          TextSpan(
                            text: vencimientoDe(deuda, hoy).replaceFirst('V', 'v'),
                            style: vencida
                                ? const TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)
                                : null,
                          ),
                        ],
                      ),
                    ),
                    if (grande) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [monto, insignia],
                      ),
                    ],
                  ],
                ),
              ),
              if (!grande) ...[
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [monto, const SizedBox(height: 6), insignia],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Fila horizontal de tarjetas que se desliza, a sangre con los márgenes de la pantalla.
class _Carrusel extends StatelessWidget {
  const _Carrusel({required this.tarjetas});

  final List<Widget> tarjetas;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    clipBehavior: Clip.none,
    child: IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, t) in tarjetas.indexed) ...[
            if (i > 0) const SizedBox(width: AppSpacing.md),
            Aparecer(
              paso: 6 + i,
              desdeLado: true,
              child: SizedBox(width: 220, child: t),
            ),
          ],
        ],
      ),
    ),
  );
}

/// Reclamo abierto: caja de ícono por categoría, título, estado y fecha de respuesta.
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
    final texto = switch (plazo?.estado) {
      null => null,
      EstadoPlazo.porConfirmar => 'Plazo por confirmar',
      EstadoPlazo.vencido => limite == null ? 'Plazo vencido' : 'Plazo vencido el ${diaYMes(limite)}',
      _ => limite == null ? null : 'Respuesta hasta el ${diaYMes(limite)}',
    };
    return Tarjeta(
      onTap: () => context.go(Rutas.reclamo(reclamo.id)),
      semantica: 'Reclamo ${reclamo.titulo}, ${reclamo.estado.etiqueta}. Ver seguimiento',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconoColor.svg(iconoDeReclamo(reclamo.tipo), color: AppColors.sol, lado: 40),
          const SizedBox(height: 10),
          Text(reclamo.titulo, style: textos.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Insignia(reclamo.estado.etiqueta, tono: Tono.acento),
          if (texto != null) ...[
            const SizedBox(height: 10),
            Text(texto, style: textos.bodySmall!.copyWith(color: vencido ? AppColors.error : AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}

/// Ícono de una categoría de reclamo.
IconoA iconoDeReclamo(TipoReclamo tipo) => switch (tipo) {
  TipoReclamo.alumbrado => IconoA.poste,
  TipoReclamo.pistasVeredas => IconoA.bache,
  TipoReclamo.cobroIndebido => IconoA.tarjeta,
  _ => IconoA.reclamos,
};

/// Obra en ejecución: ilustración arriba, nombre y barra de avance con el porcentaje.
class _TarjetaObra extends StatelessWidget {
  const _TarjetaObra({required this.obra});

  final Obra obra;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final avance = obra.avancePct.clamp(0, 100) / 100;
    return Tarjeta(
      padding: EdgeInsets.zero,
      onTap: () => context.go(Rutas.obra(obra.id)),
      semantica: 'Obra ${obra.nombre}, avance ${obra.avancePct.round()} %. Ver detalle',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 76, child: ImagenIlustracion(ilustracionDeObra(obra), ajuste: BoxFit.cover)),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(obra.nombre, style: textos.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.primary50,
                          borderRadius: BorderRadius.circular(AppRadius.pastilla),
                        ),
                        child: BarraCreciente(fraccion: avance.toDouble(), color: AppColors.primary500),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text('${obra.avancePct.round()} %', style: textos.titleSmall),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Accesos rápidos: cuatro cajas pastel de 58 con el ícono en tinta y la etiqueta debajo.
class _Accesos extends StatelessWidget {
  const _Accesos();

  @override
  Widget build(BuildContext context) {
    Widget acceso(IconoA icono, Color color, String texto, String ruta) => Expanded(
      child: Acceso(icono: Phosphor.info, svg: icono, color: color, texto: texto, alTocar: () => context.go(ruta)),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        acceso(IconoA.tarjeta, AppColors.sol, 'Pagar en línea', Rutas.pagoEnLinea),
        const SizedBox(width: AppSpacing.sm),
        acceso(IconoA.estado, AppColors.coral, 'Estado de cuenta', Rutas.estadoCuenta),
        const SizedBox(width: AppSpacing.sm),
        acceso(IconoA.cuponera, AppColors.primary, 'Cuponera', Rutas.cuponera),
        const SizedBox(width: AppSpacing.sm),
        acceso(IconoA.historial, AppColors.lima, 'Historial', Rutas.estadoCuenta),
      ],
    );
  }
}
