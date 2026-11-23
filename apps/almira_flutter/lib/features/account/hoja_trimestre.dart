import 'package:flutter/material.dart';
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
import '../../core/widgets/tributo.dart';
import '../payments/deuda_detalle_screen.dart';
import '../payments/detalle_deuda_logica.dart';
import 'estado_cuenta_logica.dart';
import 'pdf_documentos.dart';

/// Abre la hoja de un trimestre (mejora): fondo oscurecido que la cierra al tocarlo, radio de 28,
/// agarradera y botón Cerrar. Cubre la barra inferior. Al cerrarse, el foco vuelve a la fila.
Future<void> mostrarHojaTrimestre(
  BuildContext context, {
  required Deuda deuda,
  required DateTime hoy,
  required Iterable<Pago> pagos,
  Municipalidad? municipalidad,
  Vecino? vecino,
  bool esDemo = false,
}) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  barrierColor: const Color(0x8012393A),
  backgroundColor: AppColors.surface,
  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
  builder: (_) => Aparecer(
    child: HojaTrimestre(
      deuda: deuda,
      hoy: hoy,
      pagos: pagos,
      municipalidad: municipalidad,
      vecino: vecino,
      esDemo: esDemo,
      alPagar: () => context.push(Rutas.confirmarPago, extra: [deuda.id]),
      alVerDetalle: () => context.push(Rutas.deuda(deuda.id)),
    ),
  ),
);

/// Contenido de la hoja de un trimestre: cabecera, estado, fechas, cómo se calcula y acciones.
class HojaTrimestre extends StatefulWidget {
  const HojaTrimestre({
    super.key,
    required this.deuda,
    required this.hoy,
    required this.pagos,
    this.municipalidad,
    this.vecino,
    this.esDemo = false,
    this.alPagar,
    this.alVerDetalle,
  });

  final Deuda deuda;
  final DateTime hoy;
  final Iterable<Pago> pagos;
  final Municipalidad? municipalidad;
  final Vecino? vecino;
  final bool esDemo;

  /// Se llaman después de cerrar la hoja.
  final VoidCallback? alPagar;
  final VoidCallback? alVerDetalle;

  @override
  State<HojaTrimestre> createState() => _HojaTrimestreState();
}

class _HojaTrimestreState extends State<HojaTrimestre> {
  bool _generando = false;

  Future<void> _descargarConstancia(Pago pago) async {
    if (_generando) return;
    setState(() => _generando = true);
    try {
      final d = widget.deuda;
      final bytes = await pdfComprobante(
        municipalidad: widget.municipalidad,
        vecino: widget.vecino,
        operacion: pago.referencia!.trim(),
        fecha: pago.creadoEn ?? widget.hoy,
        medio: MedioPago.values.firstWhere((m) => m.clave == pago.medio),
        lineas: [LineaComprobante(concepto: d.tipo.nombre, periodo: periodoConAnio(d), monto: pago.monto)],
      );
      await compartirPdf(bytes, 'constancia-${pago.referencia!.trim()}.pdf');
    } catch (_) {
      if (mounted) mostrarMensaje(context, 'No pudimos generar la constancia. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }

  void _cerrarY(VoidCallback? accion) {
    Navigator.of(context).pop();
    accion?.call();
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final d = widget.deuda;
    final pagadoEl = fechaDePago(d, widget.pagos);
    final estado = estadoCuota(d, widget.hoy, pagadoEl: pagadoEl);
    final (icono, color) = iconoTributo(d.tipo);
    final constancia = estado.pagada ? pagoConConstancia(d, widget.pagos) : null;
    final saldo = d.saldo;
    final vence = d.vencimiento;

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: '${etiquetaPeriodo(d)} ${d.anioTributo}',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.margen, 0, AppSpacing.margen, AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconoColor.svg(icono, color: color, lado: 48),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(tituloCuota(d), style: textos.headlineSmall!.copyWith(fontSize: 22)),
                      ),
                      Text(tipoOracion(d.tipo.nombre), style: textos.bodyMedium),
                    ],
                  ),
                ),
                BotonCuadro(
                  semantica: 'Cerrar',
                  fondo: AppColors.primary50,
                  alTocar: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
                ),
              ],
            ),
            espacio,
            _BannerEstado(estado: estado),
            const SizedBox(height: AppSpacing.md),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _FichaFecha(
                      rotulo: 'Vencimiento',
                      valor: vence == null ? 'Sin fecha' : fechaCorta(vence),
                      tono: estado.situacion == SituacionCuota.vencida ? Tono.error : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _FichaFecha(
                      rotulo: 'Fecha de pago',
                      valor: estado.pagada ? (pagadoEl == null ? 'Pagado' : fechaCorta(pagadoEl)) : 'Sin pago',
                      tono: estado.pagada ? Tono.exito : null,
                    ),
                  ),
                ],
              ),
            ),
            espacioGrande,
            const RotuloGrupo('Cómo se calcula'),
            _LineaCalculo(operador: null, rotulo: 'Insoluto', monto: d.montoInsoluto),
            _LineaCalculo(operador: '+', rotulo: 'Gastos de emisión', monto: d.gastosEmision),
            _LineaCalculo(operador: '+', rotulo: 'Interés de actualización', monto: interesesDe(d), esInteres: true),
            _LineaCalculo(operador: '−', rotulo: 'Descuento', monto: d.descuento),
            _LineaCalculo(operador: '−', rotulo: 'Pagos', monto: pagosDe(d), esPago: true),
            const SizedBox(height: AppSpacing.sm),
            const LineaPunteada(),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Text('Saldo', style: textos.titleMedium!.copyWith(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(width: AppSpacing.sm),
                if (saldo <= 0)
                  const Insignia('Sin deuda', tono: Tono.exito, icono: Phosphor.check)
                else
                  const Insignia('Por pagar', tono: Tono.error),
                const Spacer(),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      soles(saldo),
                      style: textos.headlineSmall!.copyWith(fontSize: 26, fontFeatures: cifrasTabulares),
                    ),
                  ),
                ),
              ],
            ),
            espacioGrande,
            if (saldo > 0) ...[
              BotonPagar(monto: saldo, alPagar: widget.esDemo ? null : () => _cerrarY(widget.alPagar)),
              const SizedBox(height: AppSpacing.sm),
              TextButton(onPressed: () => _cerrarY(widget.alVerDetalle), child: const Text('Ver detalle completo')),
            ] else if (constancia != null)
              FilledButton.icon(
                onPressed: _generando ? null : () => _descargarConstancia(constancia),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary100,
                  foregroundColor: AppColors.primary,
                ),
                icon: _generando
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5))
                    : const IconoAlmira(IconoA.descargar, tamano: 20, color: AppColors.primary),
                label: const Text('Descargar constancia de pago'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Banner del estado de la cuota (lima pagado, rojo vencido, sol por vencer).
class _BannerEstado extends StatelessWidget {
  const _BannerEstado({required this.estado});

  final EstadoCuota estado;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final (fondo, color, icono) = switch (estado.situacion) {
      SituacionCuota.vencida => (AppColors.errorSoft, AppColors.error, IconoA.alerta),
      SituacionCuota.porVencer => (AppColors.sol100, AppColors.solTexto, IconoA.calendario),
      _ => (AppColors.lima100, AppColors.limaTexto, null),
    };
    final detalle = estado.detalle;
    return Semantics(
      liveRegion: true,
      label: [estado.titulo, ?detalle].join(', '),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(AppRadius.campo)),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Center(
                child: icono == null
                    ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                    : IconoAlmira(icono, tamano: 16, color: Colors.white),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: textos.titleSmall!.copyWith(color: color, fontWeight: FontWeight.w600),
                  children: [
                    TextSpan(
                      text: estado.titulo,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    if (detalle != null) TextSpan(text: ' · $detalle'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ficha de una fecha, coloreada según el estado (lima pagado, rojo vencido, neutra si no).
class _FichaFecha extends StatelessWidget {
  const _FichaFecha({required this.rotulo, required this.valor, this.tono});

  final String rotulo;
  final String valor;
  final Tono? tono;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final t = tono;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: t == null ? AppColors.primary50 : t.fondo,
        borderRadius: BorderRadius.circular(AppRadius.campo - 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rotulo, style: textos.labelMedium!.copyWith(color: t == null ? AppColors.textSecondary : t.texto)),
          const SizedBox(height: 2),
          Text(valor, style: textos.titleMedium!.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

/// Una línea de «Cómo se calcula», con su operador visible. Los montos en 0 van en gris y peso
/// 500; los demás en 800 (pagos en lima e intereses en coral oscuro).
class _LineaCalculo extends StatelessWidget {
  const _LineaCalculo({
    required this.operador,
    required this.rotulo,
    required this.monto,
    this.esInteres = false,
    this.esPago = false,
  });

  final String? operador;
  final String rotulo;
  final double monto;
  final bool esInteres;
  final bool esPago;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final cero = monto == 0;
    final color = cero
        ? AppColors.textSecondary
        : (esPago ? AppColors.limaTexto : (esInteres ? AppColors.coralTexto : AppColors.textPrimary));
    final peso = cero ? FontWeight.w500 : FontWeight.w800;
    return Semantics(
      label: '${operador == '−' ? 'menos ' : (operador == '+' ? 'más ' : '')}$rotulo ${soles(monto)}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: operador == null
                  ? null
                  : DecoratedBox(
                      decoration: BoxDecoration(color: AppColors.primary50, borderRadius: BorderRadius.circular(6)),
                      child: Center(
                        child: Text(
                          operador!,
                          style: textos.titleSmall!.copyWith(color: AppColors.textSecondary, height: 1),
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                rotulo,
                style: textos.bodyLarge!.copyWith(
                  color: cero ? AppColors.textSecondary : (esInteres ? AppColors.coralTexto : AppColors.textPrimary),
                  fontWeight: operador == null ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            Text(
              soles(monto),
              style: textos.bodyLarge!.copyWith(color: color, fontWeight: peso, fontFeatures: cifrasTabulares),
            ),
          ],
        ),
      ),
    );
  }
}
