import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme/iconos.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/errors/error_app.dart';
import '../../core/utils/formato.dart';
import '../../core/utils/plazos.dart';
import '../../core/widgets/componentes.dart';
import '../../core/widgets/movimiento.dart';
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
      appBar: BarraAlmira(titulo: 'Seguimiento'),
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
            Aparecer(
              child: Tarjeta(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Reclamo ${reclamo.codigo}',
                            style: textos.titleSmall!.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                        InsigniaReclamo(reclamo: reclamo),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Semantics(
                      header: true,
                      child: Text(reclamo.titulo, style: textos.headlineSmall!.copyWith(fontSize: 22)),
                    ),
                    if (plazo != null && !reclamo.resuelto) ...[espacio, _CuentaRegresiva(plazo: plazo)],
                  ],
                ),
              ),
            ),
            espacio,
            Aparecer(
              paso: 1,
              child: Tarjeta(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const TituloSeccion('Estado'),
                    espacio,
                    _LineaTiempo(pasos: pasosDe(reclamo)),
                  ],
                ),
              ),
            ),
            espacio,
            Aparecer(
              paso: 2,
              child: Tarjeta(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const TituloSeccion('Detalle'),
                    if (descripcion.isNotEmpty) ...[
                      espacioChico,
                      Text(descripcion, style: textos.bodyLarge!.copyWith(height: 1.55)),
                    ],
                    espacio,
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _Dato('Categoría', reclamo.tipo.etiqueta)),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(child: _Dato('Área a cargo', area.isEmpty ? 'Por asignar' : area)),
                        ],
                      ),
                    ),
                    if (creado != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _Dato('Enviado el', fechaLarga(creado)),
                    ],
                    espacio,
                    _Foto(reclamoId: reclamo.id, tieneFoto: reclamo.tieneFoto),
                  ],
                ),
              ),
            ),
            espacio,
            Aparecer(
              paso: 3,
              child: Tarjeta(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const TituloSeccion('Ubicación'),
                    espacioChico,
                    _Ubicacion(reclamo: reclamo),
                  ],
                ),
              ),
            ),
          ];
        },
      ),
    );
  }
}

/// «5 días hábiles para la respuesta» en una caja sol, con la fecha límite. Sale del plazo real
/// (fecha de registro y días del plazo); si ya venció o no se conoce, lo dice.
class _CuentaRegresiva extends StatelessWidget {
  const _CuentaRegresiva({required this.plazo});

  final Plazo plazo;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final limite = plazo.limite;
    final vencido = plazo.estado == EstadoPlazo.vencido;
    final restantes = plazo.restantes;
    final (numero, texto) = switch (plazo.estado) {
      EstadoPlazo.porConfirmar => (null, 'Fecha de respuesta por confirmar'),
      EstadoPlazo.venceHoy => ('0', 'La respuesta vence hoy'),
      EstadoPlazo.vencido => ('!', 'Plazo de respuesta vencido'),
      _ => ('${restantes ?? ''}', restantes == 1 ? 'día hábil para la respuesta' : 'días hábiles para la respuesta'),
    };
    final fondo = vencido ? AppColors.errorSoft : AppColors.sol100;
    final color = vencido ? AppColors.error : AppColors.solTexto;
    return Semantics(
      label: [
        if (numero != null && numero != '!') numero,
        texto,
        if (limite != null) 'Plazo: ${diaYMes(limite)}',
      ].join(' '),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(AppRadius.campo)),
        child: Row(
          children: [
            if (numero != null) ...[
              Rebote(
                child: Text(numero, style: textos.headlineMedium!.copyWith(color: AppColors.textPrimary)),
              ),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    texto,
                    style: textos.titleSmall!.copyWith(color: color, fontWeight: FontWeight.w800),
                  ),
                  if (limite != null)
                    Text('Plazo: ${diaYMes(limite)}', style: textos.bodyMedium!.copyWith(color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dato del detalle en una caja turquesa muy clara: rótulo arriba y valor debajo.
class _Dato extends StatelessWidget {
  const _Dato(this.rotulo, this.valor);

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: AppColors.primary50, borderRadius: BorderRadius.circular(AppRadius.caja)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rotulo, style: textos.labelMedium!.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(valor, style: textos.titleMedium),
        ],
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
    child: Container(height: 200, width: double.infinity, color: AppColors.surfaceSubtle, child: child),
  );
}

class _SinFoto extends StatelessWidget {
  const _SinFoto();

  @override
  Widget build(BuildContext context) => const Aviso('Sin fotografía adjunta', icono: Phosphor.cameraSlash);
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
    return dentroDeMarco ? ColoredBox(color: AppColors.surfaceSubtle, child: contenido) : _MarcoFoto(child: contenido);
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
        Text(direccion.isEmpty ? 'Sin dirección registrada' : direccion, style: textos.bodyLarge!),
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
            label:
                '${paso.titulo}: ${switch (paso.estado) {
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
                                color: paso.estado == EstadoPaso.hecho ? AppColors.primary : AppColors.bordeCampo,
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
                                fontWeight: paso.estado == EstadoPaso.pendiente ? FontWeight.w600 : FontWeight.w800,
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

class _Punto extends StatefulWidget {
  const _Punto({required this.estado});

  final EstadoPaso estado;

  @override
  State<_Punto> createState() => _PuntoState();
}

/// Punto de la línea de tiempo: hecho, turquesa con check; actual, coral con un halo que late
/// (quieto con «reducir movimiento»); pendiente, un círculo vacío.
class _PuntoState extends State<_Punto> with SingleTickerProviderStateMixin {
  static final _enPrueba = WidgetsBinding.instance.runtimeType.toString().contains('TestWidgetsFlutterBinding');
  late final AnimationController _pulso = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animar = widget.estado == EstadoPaso.actual && !sinMovimiento(context) && !_enPrueba;
    if (animar && !_pulso.isAnimating) _pulso.repeat();
    if (!animar) _pulso.stop();
  }

  @override
  void dispose() {
    _pulso.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _pulso,
    builder: (context, _) {
      final t = _pulso.value;
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: switch (widget.estado) {
            EstadoPaso.hecho => AppColors.primary,
            EstadoPaso.actual => AppColors.coral,
            EstadoPaso.pendiente => AppColors.surface,
          },
          border: widget.estado == EstadoPaso.pendiente ? Border.all(width: 2, color: AppColors.bordeCampo) : null,
          boxShadow: widget.estado == EstadoPaso.actual
              ? [
                  BoxShadow(
                    color: AppColors.coral.withValues(alpha: 0.55 * (1 - t)),
                    spreadRadius: 10 * t,
                  ),
                ]
              : null,
        ),
        child: widget.estado == EstadoPaso.hecho ? const Icon(Phosphor.check, size: 14, color: Colors.white) : null,
      );
    },
  );
}
