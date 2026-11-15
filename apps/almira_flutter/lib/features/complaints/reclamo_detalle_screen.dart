import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme/iconos.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/errors/error_app.dart';
import '../../core/utils/formato.dart';
import '../../core/widgets/componentes.dart';
import '../../core/widgets/mapa_almira.dart';
import '../../shared/models/modelos.dart';
import '../../shared/services/proveedores.dart';
import '../../shared/services/repositorio.dart';
import 'reclamos_logica.dart';
import 'piezas_lista.dart';
import 'reclamos_screen.dart';

/// Seguimiento de un reclamo: estado, plazo, foto, ubicación y cronología.
class ReclamoDetalleScreen extends ConsumerWidget {
  const ReclamoDetalleScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vista = ref.watch(vistaProvider);
    final hoy = ref.watch(relojProvider)();
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Seguimiento')),
      body: CuerpoAsync<VistaMunicipal>(
        valor: vista,
        alRecargar: () async {
          ref.invalidate(fotoReclamoProvider(id));
          await ref.read(datosProvider.notifier).recargar();
        },
        construir: (v) {
          final reclamo = v.reclamos.where((r) => r.id == id).firstOrNull;
          if (reclamo == null) {
            return const [
              VistaVacia(
                icono: Phosphor.magnifyingGlass,
                titulo: 'No encontramos este reclamo',
                detalle: 'Puede que pertenezca a otra municipalidad.',
              ),
            ];
          }
          final creado = reclamo.creadoEn;
          final plazo = plazoDe(reclamo, hoy);
          final descripcion = (reclamo.descripcion ?? '').trim();
          final area = (reclamo.area ?? '').trim();
          return [
            Text('Reclamo ${reclamo.codigo}', style: textos.bodyMedium!),
            const SizedBox(height: AppSpacing.xs),
            Semantics(
              header: true,
              child: Text(reclamo.titulo, style: textos.titleLarge!),
            ),
            espacioChico,
            Align(alignment: Alignment.centerLeft, child: InsigniaReclamo(reclamo: reclamo)),
            if (plazo != null) ...[
              const SizedBox(height: AppSpacing.xs),
              PlazoReclamo(plazo),
            ],
            espacioGrande,
            _Foto(reclamoId: reclamo.id, tieneFoto: reclamo.tieneFoto),
            if (descripcion.isNotEmpty) ...[
              espacio,
              Text(descripcion, style: textos.bodyLarge!),
            ],
            espacioGrande,
            Ficha('Categoría', reclamo.tipo.etiqueta),
            Ficha('Área a cargo', area.isEmpty ? 'Por asignar' : area),
            if (creado != null) Ficha('Enviado el', fechaLarga(creado)),
            espacioGrande,
            const TituloSeccion('Ubicación'),
            espacioChico,
            _Ubicacion(reclamo: reclamo),
            espacioGrande,
            const TituloSeccion('Seguimiento'),
            espacio,
            _LineaTiempo(pasos: pasosDe(reclamo)),
          ];
        },
      ),
    );
  }
}

/// Fotografía del reclamo: carga, error con reintento, o «Sin fotografía».
/// Nunca un recuadro vacío.
class _Foto extends ConsumerWidget {
  const _Foto({required this.reclamoId, required this.tieneFoto});

  final String reclamoId;
  final bool tieneFoto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!tieneFoto) return const _SinFoto();
    final foto = ref.watch(fotoReclamoProvider(reclamoId));
    void reintentar() => ref.invalidate(fotoReclamoProvider(reclamoId));

    return foto.when(
      loading: () => const _MarcoFoto(child: Center(child: CircularProgressIndicator(strokeWidth: 3))),
      error: (error, _) => _ErrorFoto(error: error, alReintentar: reintentar),
      data: (f) {
        if (f == null) return const _SinFoto();
        final Widget imagen = f.bytes != null
            ? Image.memory(
                f.bytes!,
                fit: BoxFit.cover,
                semanticLabel: 'Fotografía del reclamo',
                errorBuilder: (_, _, _) => _ErrorFoto(alReintentar: reintentar, dentroDeMarco: true),
              )
            : Image.network(
                f.url!,
                fit: BoxFit.cover,
                semanticLabel: 'Fotografía del reclamo',
                loadingBuilder: (_, hijo, progreso) {
                  if (progreso == null) return hijo;
                  final total = progreso.expectedTotalBytes;
                  return Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      value: total == null ? null : progreso.cumulativeBytesLoaded / total,
                    ),
                  );
                },
                errorBuilder: (_, _, _) => _ErrorFoto(alReintentar: reintentar, dentroDeMarco: true),
              );
        return _MarcoFoto(
          child: Stack(
            fit: StackFit.expand,
            children: [
              imagen,
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _ampliar(context, f),
                    child: Semantics(button: true, label: 'Ampliar fotografía'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _ampliar(BuildContext context, FotoReclamo foto) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black, title: const Text('Fotografía')),
          body: Center(
            child: InteractiveViewer(
              maxScale: 5,
              child: foto.bytes != null
                  ? Image.memory(foto.bytes!, fit: BoxFit.contain)
                  : Image.network(foto.url!, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}

class _MarcoFoto extends StatelessWidget {
  const _MarcoFoto({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.tarjeta),
        child: Container(
          height: 200,
          width: double.infinity,
          color: AppColors.surfaceSubtle,
          child: child,
        ),
      );
}

class _SinFoto extends StatelessWidget {
  const _SinFoto();

  @override
  Widget build(BuildContext context) => const Aviso(
        'Sin fotografía adjunta',
        icono: Phosphor.cameraSlash,
      );
}

class _ErrorFoto extends StatelessWidget {
  const _ErrorFoto({this.error, required this.alReintentar, this.dentroDeMarco = false});

  final Object? error;
  final VoidCallback alReintentar;
  final bool dentroDeMarco;

  @override
  Widget build(BuildContext context) {
    final sinConexion = error != null && ErrorApp.de(error!).sinConexion;
    final contenido = Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Phosphor.imageBroken, color: AppColors.textSecondary, size: 32),
            const SizedBox(height: AppSpacing.sm),
            Text(
              sinConexion ? 'Sin conexión para cargar la foto' : 'No se pudo cargar la foto',
              style: Theme.of(context).textTheme.titleSmall,
              textAlign: TextAlign.center,
            ),
            OutlinedButton.icon(
              onPressed: alReintentar,
              icon: const Icon(Phosphor.arrowClockwise, size: 20),
              label: const Text('Reintentar'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
            ),
          ],
        ),
      ),
    );
    return dentroDeMarco
        ? ColoredBox(color: AppColors.surfaceSubtle, child: contenido)
        : _MarcoFoto(child: contenido);
  }
}

class _Ubicacion extends StatelessWidget {
  const _Ubicacion({required this.reclamo});

  final Reclamo reclamo;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final direccion = (reclamo.direccion ?? '').trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          direccion.isEmpty ? 'Sin dirección registrada' : direccion,
          style: textos.bodyLarge!,
        ),
        espacioChico,
        if (reclamo.tieneUbicacion)
          MarcoMapa(
            child: MapaAlmira(
              centro: LatLng(reclamo.latitud!, reclamo.longitud!),
              zoom: ConfigMapa.zoomCalle + 1,
              interactivo: false,
              marcadores: [
                MarcadorMapa(
                  id: reclamo.id,
                  punto: LatLng(reclamo.latitud!, reclamo.longitud!),
                  etiqueta: 'Ubicación del reclamo',
                ),
              ],
              descripcion: direccion.isEmpty
                  ? 'Mapa con la ubicación del reclamo'
                  : 'Mapa con la ubicación del reclamo: $direccion',
            ),
          )
        else
          Text('Sin punto en el mapa: se atenderá con la dirección.', style: textos.bodyMedium!),
      ],
    );
  }
}

class _LineaTiempo extends StatelessWidget {
  const _LineaTiempo({required this.pasos});

  final List<PasoSeguimiento> pasos;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Column(
      children: [
        for (final (i, paso) in pasos.indexed)
          Semantics(
            label: '${paso.titulo}: ${switch (paso.estado) {
              EstadoPaso.hecho => 'completado',
              EstadoPaso.actual => 'etapa actual',
              EstadoPaso.pendiente => 'pendiente',
            }}${paso.detalle == null ? '' : '. ${paso.detalle}'}',
            child: ExcludeSemantics(
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 28,
                      child: Column(
                        children: [
                          _Punto(estado: paso.estado),
                          if (i < pasos.length - 1)
                            Expanded(
                              child: Container(
                                width: 2,
                                color: paso.estado == EstadoPaso.hecho ? AppColors.primary : AppColors.track,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: i < pasos.length - 1 ? AppSpacing.lg : 0, top: 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              paso.titulo,
                              style: textos.titleMedium!.copyWith(
                                color: paso.estado == EstadoPaso.pendiente ? AppColors.textSecondary : null,
                                fontWeight: paso.estado == EstadoPaso.pendiente ? FontWeight.w400 : null,
                              ),
                            ),
                            if (paso.detalle != null) Text(paso.detalle!, style: textos.bodyMedium!),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Punto extends StatelessWidget {
  const _Punto({required this.estado});

  final EstadoPaso estado;

  @override
  Widget build(BuildContext context) => Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: switch (estado) {
            EstadoPaso.hecho => AppColors.primary,
            EstadoPaso.actual => AppColors.primarySoft,
            EstadoPaso.pendiente => AppColors.surface,
          },
          border: Border.all(
            width: 2,
            color: estado == EstadoPaso.pendiente ? AppColors.track : AppColors.primary,
          ),
        ),
        child: switch (estado) {
          EstadoPaso.hecho => const Icon(Phosphor.check, size: 14, color: Colors.white),
          EstadoPaso.actual => const Center(
              child: SizedBox(
                width: 8,
                height: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                ),
              ),
            ),
          EstadoPaso.pendiente => null,
        },
      );
}
