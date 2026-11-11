import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/errors/error_app.dart';
import '../../core/utils/formato.dart';
import '../../core/widgets/componentes.dart';
import '../../shared/models/modelos.dart';
import '../../shared/services/proveedores.dart';

/// Texto del aviso, armado con los datos reales de la deuda.
String mensajeAviso(Recordatorio aviso, Deuda? deuda) {
  if (deuda == null) return aviso.tipo.etiqueta;
  final vence = deuda.vencimiento;
  final concepto = deuda.concepto;
  final monto = soles(deuda.total);
  return switch (aviso.tipo) {
    TipoRecordatorio.preventivo => vence == null
        ? '$concepto por $monto está por vencer.'
        : '$concepto por $monto vence el ${diaYMes(vence)}.',
    TipoRecordatorio.mora => vence == null
        ? '$concepto por $monto está vencido.'
        : '$concepto por $monto venció el ${diaYMes(vence)}.',
    TipoRecordatorio.previoCoactiva =>
      '$concepto por $monto podría pasar a cobranza coactiva, a cargo de tu municipalidad.',
  };
}

/// Avisos recibidos y canal por el que la municipalidad escribe.
class AvisosScreen extends ConsumerStatefulWidget {
  const AvisosScreen({super.key});

  @override
  ConsumerState<AvisosScreen> createState() => _AvisosScreenState();
}

class _AvisosScreenState extends ConsumerState<AvisosScreen> {
  CanalAviso? _guardando;
  String? _error;

  Future<void> _cambiarCanal(Vecino vecino, CanalAviso canal) async {
    if (_guardando != null || canal == vecino.canalPreferido) return;
    setState(() {
      _guardando = canal;
      _error = null;
    });
    try {
      await ref.read(repositorioProvider).cambiarCanal(vecino.id, canal);
      await ref.read(datosProvider.notifier).recargar();
    } catch (error) {
      if (mounted) setState(() => _error = ErrorApp.de(error).detalle);
    } finally {
      if (mounted) setState(() => _guardando = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vista = ref.watch(vistaProvider);
    final hoy = ref.watch(relojProvider)();
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Avisos')),
      body: SafeArea(
        top: false,
        child: CuerpoAsync<VistaMunicipal>(
          valor: vista,
          alRecargar: ref.read(datosProvider.notifier).recargar,
          construir: (v) {
            final vecino = v.vecino;
            if (vecino == null) {
              return [
                VistaVacia(
                  icono: Icons.badge_outlined,
                  titulo: 'Vincula tu código de contribuyente',
                  detalle: 'Así recibirás los avisos de tu municipalidad.',
                  accion: 'Vincular código',
                  alTocar: () => context.push(Rutas.vincular),
                ),
              ];
            }
            final recibidos = v.recordatorios.where((r) => r.recibido).toList()
              ..sort((a, b) => (b.fecha ?? DateTime(0)).compareTo(a.fecha ?? DateTime(0)));
            return [
              const TituloSeccion('Recibidos'),
              espacioChico,
              if (recibidos.isEmpty)
                const VistaVacia(
                  icono: Icons.notifications_none_rounded,
                  titulo: 'Aún no tienes avisos',
                )
              else
                for (final aviso in recibidos) ...[
                  _TarjetaAviso(
                    aviso: aviso,
                    deuda: v.deudas.where((d) => d.id == aviso.deudaId).firstOrNull,
                    hoy: hoy,
                  ),
                  espacioChico,
                ],
              espacio,
              const TituloSeccion('¿Por dónde te avisamos?'),
              espacioChico,
              Tarjeta(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: RadioGroup<CanalAviso>(
                  groupValue: _guardando ?? vecino.canalPreferido,
                  onChanged: (canal) {
                    if (canal != null) _cambiarCanal(vecino, canal);
                  },
                  child: Column(
                    children: [
                      for (final canal in CanalAviso.values)
                        RadioListTile<CanalAviso>(value: canal, title: Text(canal.etiqueta)),
                    ],
                  ),
                ),
              ),
              if (_error != null) ...[espacio, Aviso('No se guardó el cambio. ${_error!}', tono: Tono.error)],
              espacioChico,
              Text(
                'Los avisos por WhatsApp y SMS solo se envían si los activaste en Privacidad.',
                style: textos.bodySmall,
              ),
            ];
          },
        ),
      ),
    );
  }
}

class _TarjetaAviso extends StatelessWidget {
  const _TarjetaAviso({required this.aviso, required this.deuda, required this.hoy});

  final Recordatorio aviso;
  final Deuda? deuda;
  final DateTime hoy;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final fecha = aviso.fecha;
    final pagada = deuda?.estado == EstadoDeuda.pagada;
    return Tarjeta(
      onTap: deuda == null ? null : () => context.go(Rutas.deuda(deuda!.id)),
      semantica: deuda == null ? null : 'Aviso. Ver la obligación',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CajaIcono(
            aviso.tipo == TipoRecordatorio.preventivo
                ? Icons.notifications_none_rounded
                : Icons.error_outline_rounded,
            tono: aviso.tipo == TipoRecordatorio.preventivo ? Tono.primario : Tono.aviso,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(aviso.tipo.etiqueta, style: textos.titleSmall),
                const SizedBox(height: 2),
                Text(mensajeAviso(aviso, deuda), style: textos.bodyMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  [
                    if (fecha != null) '${haceDias(fecha, hoy)}, ${hora(fecha)}',
                    aviso.canal.etiqueta,
                    if (pagada) 'ya pagada',
                  ].join(' · '),
                  style: textos.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
