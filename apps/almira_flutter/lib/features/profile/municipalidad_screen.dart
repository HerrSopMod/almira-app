import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_spacing.dart';
import '../../core/errors/error_app.dart';
import '../../core/widgets/componentes.dart';
import '../auth/pasos_registro.dart';
import '../../shared/services/proveedores.dart';

/// Cambia la municipalidad que se ve. No cierra la sesión ni borra nada.
class MunicipalidadScreen extends ConsumerStatefulWidget {
  const MunicipalidadScreen({super.key});

  @override
  ConsumerState<MunicipalidadScreen> createState() => _MunicipalidadScreenState();
}

class _MunicipalidadScreenState extends ConsumerState<MunicipalidadScreen> {
  String? _elegida;
  bool _guardando = false;
  String? _error;

  Future<void> _guardar(String id) async {
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await ref.read(sesionProvider.notifier).cambiarMunicipalidad(id);
      if (!mounted) return;
      mostrarMensaje(context, 'Municipalidad actualizada.');
      context.pop();
    } catch (error) {
      if (mounted) setState(() => _error = ErrorApp.de(error).detalle);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vista = ref.watch(vistaProvider);
    return Scaffold(
      appBar: BarraAlmira(titulo: 'Municipalidad'),
      body: SafeArea(
        top: false,
        child: CuerpoAsync<VistaMunicipal>(
          valor: vista,
          alRecargar: ref.read(datosProvider.notifier).recargar,
          construir: (v) {
            final actual = v.municipalidad?.id;
            final elegida = _elegida ?? actual;
            return [
              for (final m in v.municipalidades) ...[
                TarjetaOpcion(
                  titulo: m.nombre,
                  detalle: m.zona,
                  elegida: m.id == elegida,
                  alElegir: () {
                    if (!_guardando) setState(() => _elegida = m.id);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (_error != null) ...[espacio, Aviso(_error!, tono: Tono.error)],
              espacioGrande,
              FilledButton(
                onPressed: _guardando || elegida == null || elegida == actual ? null : () => _guardar(elegida),
                child: Text(_guardando ? 'Guardando…' : 'Guardar'),
              ),
            ];
          },
        ),
      ),
    );
  }
}
