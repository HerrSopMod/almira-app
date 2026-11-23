import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/iconos.dart';
import '../../app/theme/iconos_almira.dart';
import '../../app/router.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/errors/error_app.dart';
import '../../core/utils/formato.dart';
import '../../core/widgets/componentes.dart';
import '../../core/widgets/movimiento.dart';
import '../auth/pasos_registro.dart';
import '../../shared/models/modelos.dart';
import '../../shared/services/proveedores.dart';

/// Texto del aviso, armado con los datos reales de la deuda.
String mensajeAviso(Recordatorio aviso, Deuda? deuda) {
  if (deuda == null) return aviso.tipo.etiqueta;
  final vence = deuda.vencimiento;
  final concepto = deuda.concepto;
  final monto = soles(deuda.total);
  return switch (aviso.tipo) {
    TipoRecordatorio.preventivo =>
      vence == null ? '$concepto por $monto está por vencer.' : '$concepto por $monto vence el ${diaYMes(vence)}.',
    TipoRecordatorio.mora =>
      vence == null ? '$concepto por $monto está vencido.' : '$concepto por $monto venció el ${diaYMes(vence)}.',
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
      appBar: BarraAlmira(titulo: 'Avisos'),
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
                  icono: Phosphor.identificationBadge,
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
                const VistaVacia(icono: Phosphor.bell, titulo: 'Aún no tienes avisos')
              else
                for (final (i, aviso) in recibidos.indexed) ...[
                  Aparecer(
                    paso: i,
                    child: _TarjetaAviso(
                      aviso: aviso,
                      deuda: v.deudas.where((d) => d.id == aviso.deudaId).firstOrNull,
                      hoy: hoy,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              espacio,
              const TituloSeccion('¿Por dónde te avisamos?'),
              espacio,
              for (final canal in CanalAviso.values) ...[
                TarjetaOpcion(
                  titulo: canal.etiqueta,
                  detalle: switch (canal) {
                    CanalAviso.whatsapp => 'Recordatorios por WhatsApp',
                    CanalAviso.sms => 'Mensaje de texto',
                    CanalAviso.app => 'Solo dentro de Almira',
                  },
                  icono: switch (canal) {
                    CanalAviso.whatsapp => IconoA.chat,
                    CanalAviso.sms => IconoA.sms,
                    CanalAviso.app => IconoA.campana,
                  },
                  color: switch (canal) {
                    CanalAviso.whatsapp => AppColors.lima,
                    CanalAviso.sms => AppColors.sol,
                    CanalAviso.app => AppColors.coral,
                  },
                  elegida: (_guardando ?? vecino.canalPreferido) == canal,
                  alElegir: () => _cambiarCanal(vecino, canal),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
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
          IconoColor.svg(
            aviso.tipo == TipoRecordatorio.preventivo ? IconoA.campana : IconoA.alerta,
            color: aviso.tipo == TipoRecordatorio.preventivo ? AppColors.sol : AppColors.coral,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(aviso.tipo.etiqueta, style: textos.titleMedium!.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  mensajeAviso(aviso, deuda),
                  style: textos.bodyLarge!.copyWith(fontSize: 14, color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const IconoAlmira(IconoA.chat, tamano: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        [
                          if (fecha != null) '${haceDias(fecha, hoy)}, ${hora(fecha)}',
                          aviso.canal.etiqueta,
                          if (pagada) 'ya pagada',
                        ].join(' · '),
                        style: textos.bodySmall,
                      ),
                    ),
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
