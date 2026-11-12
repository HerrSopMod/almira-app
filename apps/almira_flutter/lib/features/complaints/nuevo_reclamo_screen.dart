
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/errors/error_app.dart';
import '../../core/utils/ubicacion.dart';
import '../../core/widgets/componentes.dart';
import '../../core/widgets/mapa_almira.dart';
import '../../shared/models/modelos.dart';
import '../../shared/services/proveedores.dart';
import '../../shared/services/repositorio.dart';
import 'reclamos_logica.dart';
import 'selector_ubicacion_screen.dart';

/// Nuevo reclamo: foto, categoría, asunto, descripción y ubicación en una
/// sola pantalla. Si el envío falla, el formulario conserva todo y se puede
/// reintentar.
class NuevoReclamoScreen extends ConsumerStatefulWidget {
  const NuevoReclamoScreen({super.key});

  @override
  ConsumerState<NuevoReclamoScreen> createState() => _NuevoReclamoScreenState();
}

class _NuevoReclamoScreenState extends ConsumerState<NuevoReclamoScreen> {
  final _formulario = GlobalKey<FormState>();
  final _asunto = TextEditingController();
  final _descripcion = TextEditingController();
  final _direccion = TextEditingController();
  final _selector = ImagePicker();

  Uint8List? _foto;
  String? _fotoRuta;
  String? _errorFoto;
  bool _cargandoFoto = false;

  TipoReclamo? _tipo;
  bool _tipoElegidoAMano = false;

  LatLng? _punto;
  bool _buscandoGps = false;
  ResultadoUbicacion? _fallaGps;

  EtapaEnvio? _etapa;
  bool _enviando = false;
  String? _errorEnvio;
  bool _intentado = false;

  @override
  void dispose() {
    _asunto.dispose();
    _descripcion.dispose();
    _direccion.dispose();
    super.dispose();
  }

  // ---------- Foto ----------

  Future<void> _elegirFoto(ImageSource origen) async {
    setState(() {
      _cargandoFoto = true;
      _errorFoto = null;
    });
    try {
      // Se reduce antes de subirla: suficiente para ver el problema, liviana
      // para datos móviles.
      final archivo = await _selector.pickImage(
        source: origen,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
      );
      if (archivo == null) return;
      final bytes = await archivo.readAsBytes();
      if (bytes.length > fotoMaximaBytes) {
        setState(() => _errorFoto = 'La foto pesa demasiado. Elige otra o toma una nueva.');
        return;
      }
      setState(() {
        _foto = bytes;
        _fotoRuta = archivo.path;
      });
    } on PlatformException catch (error) {
      final sinPermiso = error.code.contains('denied');
      setState(
        () => _errorFoto = sinPermiso
            ? 'Sin permiso para usar la ${origen == ImageSource.camera ? 'cámara' : 'galería'}. '
                'Actívalo en los ajustes del teléfono o elige la otra opción.'
            : 'No pudimos abrir la ${origen == ImageSource.camera ? 'cámara' : 'galería'}. Inténtalo de nuevo.',
      );
    } catch (_) {
      setState(() => _errorFoto = 'No pudimos cargar la foto. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _cargandoFoto = false);
    }
  }

  void _menuFoto() {
    showModalBottomSheet<void>(
      context: context,
      builder: (hoja) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(hoja);
                _elegirFoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () {
                Navigator.pop(hoja);
                _elegirFoto(ImageSource.gallery);
              },
            ),
            if (_foto != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                title: const Text('Quitar foto'),
                onTap: () {
                  Navigator.pop(hoja);
                  setState(() {
                    _foto = null;
                    _fotoRuta = null;
                  });
                },
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  // ---------- Ubicación ----------

  Future<void> _elegirEnMapa(VistaMunicipal vista) async {
    FocusScope.of(context).unfocus();
    final base = centroDe(vista);
    final elegido = await Navigator.of(context, rootNavigator: true).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => SelectorUbicacionScreen(
          centro: base.centro,
          zoom: base.zoom,
          inicial: _punto,
        ),
      ),
    );
    if (elegido != null && mounted) {
      setState(() {
        _punto = elegido;
        _fallaGps = null;
      });
    }
  }

  Future<void> _usarMiUbicacion() async {
    setState(() {
      _buscandoGps = true;
      _fallaGps = null;
    });
    final resultado = await ubicacionActual();
    if (!mounted) return;
    setState(() {
      _buscandoGps = false;
      if (resultado.punto != null) {
        _punto = resultado.punto;
      } else {
        _fallaGps = resultado;
      }
    });
  }

  // ---------- Envío ----------

  Future<void> _enviar(VistaMunicipal vista, bool fotoObligatoria) async {
    if (_enviando) return; // Evita envíos dobles.
    setState(() => _intentado = true);
    final valido = _formulario.currentState!.validate();
    if (!valido || (fotoObligatoria && _foto == null)) {
      mostrarMensaje(context, 'Revisa los datos marcados.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _enviando = true;
      _errorEnvio = null;
      _etapa = null;
    });
    try {
      final id = await ref.read(repositorioProvider).crearReclamo(
            NuevoReclamo(
              tipo: _tipo ?? clasificarReclamo('${_asunto.text} ${_descripcion.text}'),
              titulo: _asunto.text.trim(),
              descripcion: _descripcion.text.trim(),
              direccion: _direccion.text.trim(),
              latitud: _punto?.latitude,
              longitud: _punto?.longitude,
              fotoRuta: _fotoRuta,
              fotoBytes: _foto,
            ),
            municipalidadId: vista.municipalidad!.id,
            vecinoId: vista.vecino!.id,
            alAvanzar: (etapa) {
              if (mounted) setState(() => _etapa = etapa);
            },
          );
      await ref.read(datosProvider.notifier).recargar();
      if (!mounted) return;
      mostrarMensaje(context, 'Reclamo enviado.');
      context.go(Rutas.reclamo(id));
    } catch (error) {
      if (mounted) setState(() => _errorEnvio = ErrorApp.de(error).detalle);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _sugerirCategoria() {
    if (_tipoElegidoAMano) return;
    final sugerida = clasificarReclamo('${_asunto.text} ${_descripcion.text}');
    if (sugerida != _tipo && (sugerida != TipoReclamo.otro || _tipo != null)) {
      setState(() => _tipo = sugerida);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vista = ref.watch(vistaProvider).valueOrNull;
    final esDemo = ref.watch(esDemoProvider);
    final textos = Theme.of(context).textTheme;

    if (vista == null || vista.vecino == null || vista.municipalidad == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nuevo reclamo')),
        body: VistaVacia(
          icono: Icons.badge_outlined,
          titulo: 'Vincula tu código de contribuyente',
          detalle: 'Lo necesitas para enviar reclamos a tu municipalidad.',
          accion: 'Vincular código',
          alTocar: () => context.push(Rutas.vincular),
        ),
      );
    }

    // La base exige la foto; en la demostración es opcional.
    final fotoObligatoria = !esDemo;
    final base = centroDe(vista);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo reclamo'),
        leading: IconButton(
          tooltip: 'Cerrar',
          icon: const Icon(Icons.close_rounded),
          onPressed: _enviando ? null : () => context.pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formulario,
          autovalidateMode: _intentado ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.margen,
              AppSpacing.lg,
              AppSpacing.margen,
              AppSpacing.xl,
            ),
            children: [
              TituloSeccion(fotoObligatoria ? 'Foto del problema' : 'Foto del problema (opcional)'),
              espacioChico,
              _CampoFoto(
                foto: _foto,
                cargando: _cargandoFoto,
                conError: _intentado && fotoObligatoria && _foto == null,
                alTocar: _enviando ? null : _menuFoto,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _intentado && fotoObligatoria && _foto == null
                    ? 'Adjunta una foto para enviar el reclamo.'
                    : 'Una foto, de la cámara o la galería. La reducimos antes de enviarla.',
                style: textos.bodySmall!.copyWith(
                  color: _intentado && fotoObligatoria && _foto == null ? AppColors.error : null,
                ),
              ),
              if (_errorFoto != null) ...[espacioChico, Aviso(_errorFoto!, tono: Tono.error)],
              espacioGrande,
              TextFormField(
                controller: _asunto,
                enabled: !_enviando,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                maxLength: asuntoMaximo,
                onChanged: (_) => _sugerirCategoria(),
                decoration: const InputDecoration(
                  labelText: 'Asunto',
                  hintText: 'Ejemplo: Poste sin luz',
                ),
                validator: validarAsunto,
              ),
              espacioChico,
              TextFormField(
                controller: _descripcion,
                enabled: !_enviando,
                textCapitalization: TextCapitalization.sentences,
                minLines: 3,
                maxLines: 6,
                maxLength: descripcionMaxima,
                onChanged: (_) => _sugerirCategoria(),
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Qué pasa y desde cuándo',
                  alignLabelWithHint: true,
                ),
                validator: validarDescripcion,
              ),
              espacioChico,
              DropdownButtonFormField<TipoReclamo>(
                // La clave rehace el campo cuando cambia la sugerencia.
                key: ValueKey(_tipo),
                initialValue: _tipo,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Categoría',
                  helperText: _tipo != null && !_tipoElegidoAMano
                      ? 'Sugerida por tu descripción. Puedes cambiarla.'
                      : null,
                ),
                items: [
                  for (final tipo in TipoReclamo.values)
                    DropdownMenuItem(value: tipo, child: Text(tipo.etiqueta)),
                ],
                onChanged: _enviando
                    ? null
                    : (tipo) => setState(() {
                          _tipo = tipo;
                          _tipoElegidoAMano = true;
                        }),
                validator: (tipo) => tipo == null ? 'Elige una categoría.' : null,
              ),
              espacioGrande,
              const TituloSeccion('Ubicación'),
              espacioChico,
              MarcoMapa(
                alto: 170,
                child: Stack(
                  children: [
                    MapaAlmira(
                      // Se rehace al cambiar el punto: el mapa es una vista previa fija.
                      key: ValueKey(_punto),
                      centro: _punto ?? base.centro,
                      zoom: _punto == null ? base.zoom : ConfigMapa.zoomCalle + 1,
                      interactivo: false,
                      marcadores: [
                        if (_punto != null)
                          MarcadorMapa(id: 'reclamo', punto: _punto!, etiqueta: 'Ubicación del problema'),
                      ],
                      descripcion: _punto == null
                          ? 'Mapa sin ubicación elegida'
                          : 'Mapa con la ubicación elegida para el reclamo',
                    ),
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _enviando ? null : () => _elegirEnMapa(vista),
                          child: Semantics(
                            button: true,
                            label: _punto == null ? 'Elegir ubicación en el mapa' : 'Cambiar ubicación en el mapa',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              espacioChico,
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _enviando ? null : () => _elegirEnMapa(vista),
                      icon: const Icon(Icons.place_outlined, size: 20),
                      label: Text(_punto == null ? 'Elegir en mapa' : 'Mover pin'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _enviando || _buscandoGps ? null : _usarMiUbicacion,
                      icon: _buscandoGps
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location_rounded, size: 20),
                      label: const Text('Mi ubicación'),
                    ),
                  ),
                ],
              ),
              if (_fallaGps != null) ...[
                espacioChico,
                Aviso(
                  _fallaGps!.mensaje,
                  tono: Tono.aviso,
                  accion: _fallaGps!.ofrecerAjustes
                      ? OutlinedButton(
                          onPressed: abrirAjustesDeUbicacion,
                          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                          child: const Text('Abrir ajustes'),
                        )
                      : null,
                ),
              ],
              espacio,
              TextFormField(
                controller: _direccion,
                enabled: !_enviando,
                textCapitalization: TextCapitalization.words,
                maxLength: direccionMaxima,
                decoration: InputDecoration(
                  labelText: 'Dirección o referencia',
                  hintText: 'Calle, número o cruce',
                  counterText: '',
                  suffixIcon: vista.predios.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Usar la dirección de mi predio',
                          icon: const Icon(Icons.home_outlined),
                          onPressed: _enviando
                              ? null
                              : () => setState(() => _direccion.text = vista.predios.first.direccion),
                        ),
                ),
                validator: validarDireccion,
              ),
              if (_errorEnvio != null) ...[
                espacio,
                Aviso('No se envió el reclamo. ${_errorEnvio!} Tus datos siguen aquí.', tono: Tono.error),
              ],
              espacioGrande,
              FilledButton(
                onPressed: _enviando ? null : () => _enviar(vista, fotoObligatoria),
                child: _enviando
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text(switch (_etapa) {
                            EtapaEnvio.subiendoFoto => 'Subiendo foto…',
                            _ => 'Enviando reclamo…',
                          }),
                        ],
                      )
                    : Text(_errorEnvio == null ? 'Enviar reclamo' : 'Reintentar envío'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Zona de la foto: invita a adjuntar o muestra la miniatura real.
class _CampoFoto extends StatelessWidget {
  const _CampoFoto({required this.foto, required this.cargando, required this.conError, this.alTocar});

  final Uint8List? foto;
  final bool cargando;
  final bool conError;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final borde = BorderRadius.circular(AppRadius.tarjeta);
    return Semantics(
      button: true,
      label: foto == null ? 'Adjuntar foto' : 'Foto adjunta. Cambiar o quitar',
      child: Material(
        color: AppColors.surfaceSubtle,
        shape: RoundedRectangleBorder(
          borderRadius: borde,
          side: BorderSide(color: conError ? AppColors.error : AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: alTocar,
          child: SizedBox(
            height: 180,
            width: double.infinity,
            child: cargando
                ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
                : foto == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_a_photo_outlined, size: 32, color: AppColors.primary),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Adjuntar foto',
                            style: textos.labelLarge!.copyWith(color: AppColors.primary),
                          ),
                        ],
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(foto!, fit: BoxFit.cover, gaplessPlayback: true),
                          Positioned(
                            right: AppSpacing.sm,
                            bottom: AppSpacing.sm,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(AppRadius.pastilla),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.edit_outlined, size: 16, color: AppColors.primaryDark),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Cambiar',
                                    style: textos.labelMedium!.copyWith(color: AppColors.primaryDark),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
          ),
        ),
      ),
    );
  }
}
