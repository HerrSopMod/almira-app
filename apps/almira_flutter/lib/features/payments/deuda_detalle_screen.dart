import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/iconos.dart';
import '../../app/theme/iconos_almira.dart';
import '../../core/utils/formato.dart';
import '../../core/widgets/componentes.dart';
import '../../core/widgets/movimiento.dart';
import '../../shared/models/modelos.dart';
import '../../shared/services/proveedores.dart';
import '../account/estado_cuenta_logica.dart';
import '../complaints/piezas_lista.dart';
import 'detalle_deuda_logica.dart';

/// Detalle de deuda (mejora): tarjeta principal con el tributo, sus estados (coactiva, vencida),
/// el título en tipo oración y el saldo grande; «¿De qué se compone?» con una barra apilada; los
/// datos (fecha límite, predio, periodo); la nota de coactiva si corresponde; y un pie fijo para
/// pagar ese monto.
class DeudaDetalleScreen extends ConsumerWidget {
  const DeudaDetalleScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vista = ref.watch(vistaProvider);
    final esDemo = ref.watch(esDemoProvider);
    final hoy = ref.watch(relojProvider)();
    final deuda = vista.valueOrNull?.deudas.where((d) => d.id == id).firstOrNull;
    final pagable = deuda != null && deuda.pendiente && deuda.saldo > 0;

    return Scaffold(
      appBar: const BarraAlmira(titulo: 'Detalle de deuda'),
      // Pie fijo sobre la barra inferior: siempre a la vista.
      bottomNavigationBar: pagable
          ? PiePago(
              monto: deuda.saldo,
              // En demostración no hay pago.
              alPagar: esDemo ? null : () => context.push(Rutas.confirmarPago, extra: [deuda.id]),
            )
          : null,
      body: CuerpoAsync<VistaMunicipal>(
        valor: vista,
        alRecargar: ref.read(datosProvider.notifier).recargar,
        construir: (v) {
          final d = v.deudas.where((x) => x.id == id).firstOrNull;
          if (d == null) {
            return const [
              VistaVacia(
                icono: Phosphor.magnifyingGlass,
                titulo: 'No encontramos esta obligación',
                detalle: 'Puede que ya no esté registrada en tu municipalidad.',
              ),
            ];
          }
          return [
            ContenidoDetalleDeuda(
              deuda: d,
              predio: v.predios.where((p) => p.id == d.predioId).firstOrNull,
              hoy: hoy,
              esDemo: esDemo,
              alIrAAtencion: () => context.push(Rutas.atencion),
            ),
          ];
        },
      ),
    );
  }
}

/// Todo lo que va sobre el fondo crema del detalle, sin el pie de pago.
class ContenidoDetalleDeuda extends StatelessWidget {
  const ContenidoDetalleDeuda({
    super.key,
    required this.deuda,
    required this.hoy,
    this.predio,
    this.esDemo = false,
    this.alIrAAtencion,
  });

  final Deuda deuda;
  final Predio? predio;
  final DateTime hoy;
  final bool esDemo;
  final VoidCallback? alIrAAtencion;

  @override
  Widget build(BuildContext context) {
    final coactiva = enCoactiva(deuda);
    final vencimiento = deuda.vencimiento;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Aparecer(
          child: _TarjetaPrincipal(deuda: deuda, hoy: hoy, coactiva: coactiva),
        ),
        espacio,
        Aparecer(paso: 1, child: _Composicion(deuda: deuda)),
        espacio,
        Aparecer(
          paso: 2,
          child: GrupoTarjeta(
            filas: [
              FilaLista(
                inicio: const IconoColor.svg(IconoA.calendario, color: AppColors.sol),
                titulo: 'Fecha límite',
                detalle: DetalleFila(vencimiento == null ? 'Sin fecha registrada' : fechaLarga(vencimiento)),
              ),
              if (predio != null)
                FilaLista(
                  inicio: const IconoColor.svg(IconoA.predio, color: AppColors.primary),
                  titulo: 'Predio',
                  detalle: DetalleFila(predio!.direccion),
                ),
              FilaLista(
                inicio: const IconoColor.svg(IconoA.cuponera, color: AppColors.lima),
                titulo: 'Periodo',
                detalle: DetalleFila(periodoConAnio(deuda)),
              ),
              if (deuda.expCoactivo?.trim().isNotEmpty ?? false)
                FilaLista(
                  inicio: const IconoColor.svg(IconoA.alerta, color: AppColors.coral),
                  titulo: 'Expediente coactivo',
                  detalle: DetalleFila(deuda.expCoactivo!.trim()),
                ),
            ],
          ),
        ),
        if (coactiva) ...[espacio, Aparecer(paso: 3, child: _NotaCoactiva(alIrAAtencion: alIrAAtencion))],
        if (esDemo && deuda.pendiente) ...[
          espacio,
          const Aviso('En la demostración el pago no está disponible: usamos datos de ejemplo.', tono: Tono.aviso),
        ],
      ],
    );
  }
}

class _TarjetaPrincipal extends StatelessWidget {
  const _TarjetaPrincipal({required this.deuda, required this.hoy, required this.coactiva});

  final Deuda deuda;
  final DateTime hoy;
  final bool coactiva;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final estado = deuda.estadoAl(hoy);
    final vencida = estado == EstadoDeuda.vencida;
    final vence = deuda.vencimiento;
    final (icono, color) = iconoTributo(deuda.tipo);
    final bajada = bajadaDeuda(deuda);
    return Tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconoColor.svg(icono, color: color, lado: 48),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      if (coactiva) const Insignia('Cobranza coactiva', tono: Tono.acento),
                      if (vencida) const Insignia('Vencida', tono: Tono.error, icono: Phosphor.warningCircle),
                      if (estado == EstadoDeuda.pagada)
                        const Insignia('Pagada', tono: Tono.exito, icono: Phosphor.check),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Semantics(header: true, child: Text(tituloDeuda(deuda), style: textos.headlineSmall!.copyWith(fontSize: 22))),
          if (bajada != null) Text(bajada, style: textos.bodyMedium),
          espacio,
          Text(
            deuda.pendiente ? 'Saldo a pagar' : 'Total pagado',
            style: textos.titleSmall!.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Rebote(child: Monto(deuda.total)),
          ),
          if (vencida && vence != null) ...[
            espacio,
            Semantics(
              label: 'Venció el ${fechaLarga(vence)}, ${haceTiempo(vence, hoy)}',
              excludeSemantics: true,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.errorSoft,
                  borderRadius: BorderRadius.circular(AppRadius.campo - 2),
                ),
                child: Row(
                  children: [
                    const IconoAlmira(IconoA.calendario, tamano: 18, color: AppColors.error),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: textos.titleSmall!.copyWith(color: AppColors.error, fontWeight: FontWeight.w600),
                          children: [
                            const TextSpan(text: 'Venció el '),
                            TextSpan(
                              text: fechaCorta(vence),
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            TextSpan(text: ' · ${haceTiempo(vence, hoy)}'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// «¿De qué se compone?»: barra apilada proporcional, una fila por concepto con su porcentaje y
/// el saldo al final.
class _Composicion extends StatelessWidget {
  const _Composicion({required this.deuda});

  final Deuda deuda;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final conceptos = conceptosDe(deuda);
    final suman = conceptos.where((c) => !c.resta && c.monto > 0).toList();
    final total = suman.fold<double>(0, (s, c) => s + c.monto);
    String pct(double m) => total <= 0 ? '' : '${(m / total * 100).round()}%';
    return Tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TituloSeccion('¿De qué se compone?'),
          if (total > 0) ...[
            espacio,
            Semantics(
              label: suman.map((c) => '${c.nombre} ${pct(c.monto)}').join(', '),
              excludeSemantics: true,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pastilla),
                child: Container(
                  height: 10,
                  color: AppColors.primary50,
                  child: Row(
                    children: [
                      for (final (i, c) in suman.indexed) ...[
                        if (i > 0) const SizedBox(width: 3),
                        Expanded(
                          flex: (c.monto / total * 1000).round().clamp(1, 1000),
                          child: BarraCreciente(fraccion: 1, color: c.color!, alto: 10, retraso: i * 150),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          for (final c in conceptos)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  if (c.resta)
                    const SizedBox(width: 10, child: Text('−', textAlign: TextAlign.center))
                  else
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: c.color, shape: BoxShape.circle),
                    ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Text(c.nombre, style: textos.bodyLarge)),
                  if (!c.resta)
                    SizedBox(
                      width: 44,
                      child: Text(
                        pct(c.monto),
                        textAlign: TextAlign.end,
                        style: textos.labelMedium!.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    '${c.resta ? '- ' : ''}${soles(c.monto)}',
                    style: textos.titleMedium!.copyWith(
                      fontWeight: FontWeight.w800,
                      color: c.resta ? AppColors.limaTexto : null,
                      fontFeatures: cifrasTabulares,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          const LineaPunteada(),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  deuda.pendiente ? 'Saldo' : 'Total pagado',
                  style: textos.titleMedium!.copyWith(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                soles(deuda.total),
                style: textos.headlineSmall!.copyWith(fontSize: 22, fontFeatures: cifrasTabulares),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Nota de cobranza coactiva (fondo sol) con el enlace a Atención.
class _NotaCoactiva extends StatelessWidget {
  const _NotaCoactiva({this.alIrAAtencion});

  final VoidCallback? alIrAAtencion;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: AppColors.sol100, borderRadius: BorderRadius.circular(AppRadius.campo + 2)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IconoAlmira(IconoA.alerta, tamano: 22, color: AppColors.solTexto),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Esta deuda está en cobranza coactiva. Si ya la pagaste o tienes dudas, escríbenos en Atención.',
                  style: textos.bodyMedium!.copyWith(color: AppColors.solTexto, fontWeight: FontWeight.w600),
                ),
                if (alIrAAtencion != null)
                  TextButton(
                    onPressed: alIrAAtencion,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      foregroundColor: AppColors.solTexto,
                      textStyle: textos.titleSmall!.copyWith(fontWeight: FontWeight.w800),
                    ),
                    child: const Text('Ir a Atención'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pie fijo con «Pagar S/ X» (ícono de tarjeta). Sin [alPagar] queda desactivado.
class PiePago extends StatelessWidget {
  const PiePago({super.key, required this.monto, required this.alPagar});

  final double monto;
  final VoidCallback? alPagar;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: AppColors.surface,
      border: Border(top: BorderSide(color: AppColors.border)),
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.margen, AppSpacing.md, AppSpacing.margen, AppSpacing.md),
        child: BotonPagar(monto: monto, alPagar: alPagar),
      ),
    ),
  );
}

/// Botón principal «Pagar S/ X» con el ícono de tarjeta y sombra turquesa.
class BotonPagar extends StatelessWidget {
  const BotonPagar({super.key, required this.monto, required this.alPagar});

  final double monto;
  final VoidCallback? alPagar;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppRadius.boton),
      boxShadow: alPagar == null ? null : AppColors.sombraPrimaria,
    ),
    child: FilledButton(
      onPressed: alPagar,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconoAlmira(
            IconoA.tarjeta,
            tamano: 20,
            color: alPagar == null ? Colors.white.withValues(alpha: 0.8) : AppColors.onPrimary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(child: Text('Pagar ${soles(monto)}', overflow: TextOverflow.ellipsis)),
        ],
      ),
    ),
  );
}
