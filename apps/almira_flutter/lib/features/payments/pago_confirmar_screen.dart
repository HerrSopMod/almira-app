import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../core/errors/error_app.dart';
import '../../core/utils/formato.dart';
import '../../core/widgets/componentes.dart';
import '../../shared/models/modelos.dart';
import '../../shared/services/proveedores.dart';
import '../account/estado_cuenta_logica.dart';

/// Confirmar el pago: resumen de los periodos, medio de pago y «Pagar». El servidor
/// toma los importes de la base y confirma el pago; después la pantalla muestra el
/// número de operación.
class PagoConfirmarScreen extends ConsumerStatefulWidget {
  const PagoConfirmarScreen({super.key, required this.deudaIds});

  final List<String> deudaIds;

  @override
  ConsumerState<PagoConfirmarScreen> createState() => _PagoConfirmarScreenState();
}

class _PagoConfirmarScreenState extends ConsumerState<PagoConfirmarScreen> {
  MedioPago _medio = MedioPago.yape;
  bool _ocupado = false;
  String? _error;
  String? _operacion;
  double _pagado = 0;

  Future<void> _pagar(double total) async {
    if (_ocupado) return;
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      final operacion = await ref.read(repositorioProvider).pagar(widget.deudaIds, _medio);
      await ref.read(datosProvider.notifier).recargar();
      if (mounted) {
        setState(() {
          _operacion = operacion;
          _pagado = total;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = ErrorApp.de(error).detalle);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vista = ref.watch(vistaProvider);
    final textos = Theme.of(context).textTheme;
    final v = vista.valueOrNull;
    final elegidas = [
      for (final d in v?.deudas ?? const <Deuda>[])
        if (widget.deudaIds.contains(d.id)) d,
    ];
    final total = sumarSaldos(elegidas.where((d) => d.pendiente));

    if (_operacion != null) return _Listo(operacion: _operacion!, monto: _pagado);

    return Scaffold(
      appBar: AppBar(title: const Text('Confirma tu pago')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.margen),
          children: [
            if (elegidas.isEmpty)
              const VistaVacia(icono: Icons.receipt_long_outlined, titulo: 'No hay periodos por pagar')
            else ...[
              Tarjeta(
                child: Column(
                  children: [
                    for (final d in elegidas)
                      FilaDato(
                        d.periodo.isEmpty ? d.concepto : '${d.concepto} · ${d.periodo}',
                        soles(d.saldo),
                      ),
                    const Divider(height: AppSpacing.xl),
                    FilaDato('Total a pagar', soles(total), destacado: true),
                  ],
                ),
              ),
              espacioGrande,
              TituloSeccion('¿Cómo quieres pagar?'),
              espacioChico,
              Tarjeta(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: RadioGroup<MedioPago>(
                  groupValue: _medio,
                  onChanged: (m) {
                    if (m != null && !_ocupado) setState(() => _medio = m);
                  },
                  child: Column(
                    children: [
                      for (final m in MedioPago.values)
                        RadioListTile<MedioPago>(
                          value: m,
                          title: Text(m.etiqueta),
                          subtitle: Text(m.detalle),
                        ),
                    ],
                  ),
                ),
              ),
              if (_error != null) ...[espacio, Aviso(_error!, tono: Tono.error)],
              espacioGrande,
              FilledButton.icon(
                onPressed: _ocupado || total <= 0 ? null : () => _pagar(total),
                icon: _ocupado
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Icon(Icons.lock_outline_rounded, size: 20),
                label: Text('Pagar ${soles(total)}'),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Tus avisos de estas deudas se detienen al confirmar.',
                style: textos.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Listo extends StatelessWidget {
  const _Listo({required this.operacion, required this.monto});

  final String operacion;
  final double monto;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Pago registrado'), automaticallyImplyLeading: false),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.margen),
          children: [
            const SizedBox(height: AppSpacing.xl),
            const Center(child: CajaIcono(Icons.check_rounded, tono: Tono.exito, lado: 72)),
            espacio,
            Text('¡Pago realizado!', style: textos.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
            Text(
              soles(monto),
              style: textos.displaySmall!.copyWith(fontFeatures: cifrasTabulares),
              textAlign: TextAlign.center,
            ),
            espacio,
            Tarjeta(
              child: Column(
                children: [
                  FilaDato('Operación', operacion),
                  FilaDato('Fecha', fechaLarga(DateTime.now())),
                ],
              ),
            ),
            espacioGrande,
            FilledButton(
              onPressed: () => context.go(Rutas.estadoCuenta),
              child: const Text('Ver estado de cuenta'),
            ),
            espacioChico,
            OutlinedButton(
              onPressed: () => context.go(Rutas.inicio),
              child: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    );
  }
}
