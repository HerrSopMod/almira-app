import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/widgets/componentes.dart';
import '../../shared/models/modelos.dart';
import '../../shared/services/proveedores.dart';
import 'pdf_documentos.dart';

/// Cuponera: Hoja de Resumen (HR) y, por cada predio, las hojas de liquidación
/// predial (HLP) y de arbitrios (HLA) del año en curso, para descargar en PDF.
class CuponeraScreen extends ConsumerStatefulWidget {
  const CuponeraScreen({super.key});

  @override
  ConsumerState<CuponeraScreen> createState() => _CuponeraScreenState();
}

class _CuponeraScreenState extends ConsumerState<CuponeraScreen> {
  String? _generando;

  Future<void> _generar(String clave, String archivo, Future<dynamic> Function() crear) async {
    if (_generando != null) return;
    setState(() => _generando = clave);
    try {
      final bytes = await crear();
      await compartirPdf(bytes, archivo);
    } catch (_) {
      if (mounted) mostrarMensaje(context, 'No pudimos generar el PDF. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _generando = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vista = ref.watch(vistaProvider);
    final anio = ref.watch(relojProvider)().year;

    return Scaffold(
      appBar: AppBar(title: const Text('Cuponera')),
      body: CuerpoAsync<VistaMunicipal>(
        valor: vista,
        alRecargar: ref.read(datosProvider.notifier).recargar,
        construir: (v) {
          final vecino = v.vecino;
          if (vecino == null) {
            return [
              VistaVacia(
                icono: Icons.badge_outlined,
                titulo: 'Vincula tu código de contribuyente',
                accion: 'Vincular código',
                alTocar: () => context.push(Rutas.vincular),
              ),
            ];
          }
          return [
            TituloSeccion('Hoja de Resumen · $anio'),
            espacioChico,
            _Documento(
              icono: Icons.summarize_outlined,
              titulo: 'Hoja de Resumen (HR)',
              detalle: 'Resumen de tus tributos del ejercicio',
              ocupado: _generando == 'hr',
              alTocar: () => _generar(
                'hr',
                'hoja-de-resumen-$anio.pdf',
                () => pdfHojaResumen(
                  municipalidad: v.municipalidad,
                  vecino: vecino,
                  predios: v.predios,
                  deudas: v.deudas,
                  anio: anio,
                ),
              ),
            ),
            for (final predio in v.predios) ...[
              espacioGrande,
              TituloSeccion(predio.direccion),
              espacioChico,
              _Documento(
                icono: Icons.home_work_outlined,
                titulo: 'Liquidación Predial (HLP)',
                detalle: 'Impuesto predial $anio',
                ocupado: _generando == 'hlp-${predio.id}',
                alTocar: () => _generar(
                  'hlp-${predio.id}',
                  'hlp-${predio.codigo}-$anio.pdf',
                  () => pdfLiquidacion(
                    municipalidad: v.municipalidad,
                    vecino: vecino,
                    predio: predio,
                    deudas: v.deudas,
                    tributo: TipoDeuda.predial,
                    anio: anio,
                  ),
                ),
              ),
              espacioChico,
              _Documento(
                icono: Icons.cleaning_services_outlined,
                titulo: 'Liquidación de Arbitrios (HLA)',
                detalle: 'Arbitrios municipales $anio',
                ocupado: _generando == 'hla-${predio.id}',
                alTocar: () => _generar(
                  'hla-${predio.id}',
                  'hla-${predio.codigo}-$anio.pdf',
                  () => pdfLiquidacion(
                    municipalidad: v.municipalidad,
                    vecino: vecino,
                    predio: predio,
                    deudas: v.deudas,
                    tributo: TipoDeuda.arbitrios,
                    anio: anio,
                  ),
                ),
              ),
            ],
            if (v.predios.isEmpty) ...[
              espacio,
              const VistaVacia(icono: Icons.home_work_outlined, titulo: 'No tienes predios registrados'),
            ],
          ];
        },
      ),
    );
  }
}

class _Documento extends StatelessWidget {
  const _Documento({
    required this.icono,
    required this.titulo,
    required this.detalle,
    required this.alTocar,
    required this.ocupado,
  });

  final IconData icono;
  final String titulo;
  final String detalle;
  final VoidCallback alTocar;
  final bool ocupado;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Tarjeta(
      onTap: ocupado ? null : alTocar,
      semantica: '$titulo. Descargar PDF',
      child: Row(
        children: [
          CajaIcono(icono),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: textos.titleSmall),
                Text(detalle, style: textos.bodySmall),
              ],
            ),
          ),
          if (ocupado)
            const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
          else
            const Icon(Icons.download_rounded),
        ],
      ),
    );
  }
}
