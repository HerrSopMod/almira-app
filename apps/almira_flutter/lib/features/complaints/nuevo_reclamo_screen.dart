import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme/iconos.dart';
import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../core/errors/error_app.dart';
import '../../core/utils/ubicacion.dart';
import '../../app/theme/iconos_almira.dart';
import '../../core/widgets/componentes.dart';
import '../../core/widgets/movimiento.dart';
import 'reclamos_screen.dart';
import '../../core/widgets/mapa_almira.dart';
import '../../shared/models/modelos.dart';
import '../../shared/services/proveedores.dart';
import '../../shared/services/repositorio.dart';
import 'clasificacion_foto/clasificador_foto.dart';
import 'clasificacion_foto/proveedor_clasificador.dart';
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

  // Revisión de la foto en el teléfono. Es solo una sugerencia: nunca bloquea el envío.
  ResultadoFoto? _resultadoFoto;
  bool _revisandoFoto = false;
  bool _fotoAceptada = false;
  int _turnoFoto = 0;

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
      final archivo = await _selector.pickImage(source: origen, maxWidth: 1600, maxHeight: 1600, imageQuality: 80);
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
      _revisarFoto(ImagenReclamo(ruta: archivo.path, bytes: bytes));
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

  /// Clasifica la foto sin congelar la pantalla. Si mientras tanto el vecino
  /// cambia o quita la foto, el resultado de la anterior se descarta.
  Future<void> _revisarFoto(ImagenReclamo imagen) async {
    final turno = ++_turnoFoto;
    setState(() {
      _revisandoFoto = true;
      _resultadoFoto = null;
      _fotoAceptada = false;
    });
    ResultadoFoto resultado;
    try {
      resultado = await ref.read(clasificadorFotoProvider).clasificar(imagen);
    } catch (error) {
      resultado = diagnosticoFotoActivo
          ? ResultadoFoto.enRevision.conDiagnostico(
              DiagnosticoFoto(implementacion: '?', error: '${error.runtimeType}: $error'),
            )
          : ResultadoFoto.enRevision;
    }
    if (!mounted || turno != _turnoFoto) return;
    setState(() {
      _resultadoFoto = resultado;
      _revisandoFoto = false;
    });
  }

  void _quitarFoto() {
    setState(() {
      _foto = null;
      _fotoRuta = null;
      _turnoFoto++;
      _resultadoFoto = null;
      _revisandoFoto = false;
      _fotoAceptada = false;
    });
  }

  void _menuFoto() {
    showModalBottomSheet<void>(
      context: context,
      builder: (hoja) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Phosphor.camera),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(hoja);
                _elegirFoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Phosphor.images),
              title: const Text('Elegir de la galería'),
              onTap: () {
                Navigator.pop(hoja);
                _elegirFoto(ImageSource.gallery);
              },
            ),
            if (_foto != null)
              ListTile(
                leading: const Icon(Phosphor.trash, color: AppColors.error),
                title: const Text('Quitar foto'),
                onTap: () {
                  Navigator.pop(hoja);
                  _quitarFoto();
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
        builder: (_) => SelectorUbicacionScreen(centro: base.centro, zoom: base.zoom, inicial: _punto),
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
      final id = await ref
          .read(repositorioProvider)
          .crearReclamo(
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
        appBar: BarraAlmira(titulo: 'Nuevo reclamo'),
        body: VistaVacia(
          icono: Phosphor.identificationBadge,
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
      appBar: BarraAlmira(
        titulo: 'Nuevo reclamo',
        cerrar: true,
        alVolver: () {
          if (!_enviando) context.pop();
        },
      ),
      // «Enviar reclamo» queda fijo abajo, siempre a la vista.
      bottomNavigationBar: MediaQuery.viewInsetsOf(context).bottom > 0
          ? null
          : _PieEnvio(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.boton),
                  boxShadow: _enviando ? null : AppColors.sombraPrimaria,
                ),
                child: FilledButton(
                  onPressed: _enviando ? null : () => _enviar(vista, fotoObligatoria),
                  child: _enviando
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5)),
                            const SizedBox(width: AppSpacing.md),
                            Text(switch (_etapa) {
                              EtapaEnvio.subiendoFoto => 'Subiendo foto…',
                              _ => 'Enviando reclamo…',
                            }),
                          ],
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const IconoAlmira(IconoA.enviar, tamano: 20, color: AppColors.onPrimary),
                            const SizedBox(width: AppSpacing.sm),
                            Text(_errorEnvio == null ? 'Enviar reclamo' : 'Reintentar envío'),
                          ],
                        ),
                ),
              ),
            ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formulario,
          autovalidateMode: _intentado ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(AppSpacing.margen, AppSpacing.xl, AppSpacing.margen, AppSpacing.xxl),
            children: [
              const TituloSeccion('¿Qué tipo de problema es?'),
              espacio,
              FormField<TipoReclamo>(
                // La clave rehace el campo cuando cambia la sugerencia.
                key: ValueKey(_tipo),
                initialValue: _tipo,
                validator: (_) => _tipo == null ? 'Elige una categoría.' : null,
                builder: (estado) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _GrillaCategorias(
                      elegida: _tipo,
                      alElegir: _enviando
                          ? null
                          : (tipo) => setState(() {
                              _tipo = tipo;
                              _tipoElegidoAMano = true;
                            }),
                    ),
                    if (estado.hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Text(estado.errorText!, style: textos.bodySmall!.copyWith(color: AppColors.error)),
                      )
                    else if (_tipo != null && !_tipoElegidoAMano)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Text('Sugerida por lo que escribiste. Puedes cambiarla.', style: textos.bodySmall),
                      ),
                  ],
                ),
              ),
              espacioGrande,
              _CampoFoto(
                obligatoria: fotoObligatoria,
                foto: _foto,
                cargando: _cargandoFoto,
                conError: _intentado && fotoObligatoria && _foto == null,
                alTocar: _enviando ? null : _menuFoto,
              ),
              if (_foto != null && (_revisandoFoto || _resultadoFoto != null)) ...[
                espacioChico,
                _revisandoFoto ? const _RevisandoFoto() : _EstadoFoto(_resultadoFoto!),
              ],
              if (_foto != null && _resultadoFoto?.estado == EstadoFoto.noValida && !_fotoAceptada) ...[
                espacio,
                OutlinedButton(onPressed: _enviando ? null : _menuFoto, child: const Text('Cambiar foto')),
                espacioChico,
                OutlinedButton(
                  onPressed: _enviando ? null : () => setState(() => _fotoAceptada = true),
                  child: const Text('Enviar a revisión'),
                ),
              ],
              // Con foto, el estado de la foto ocupa el lugar de la ayuda.
              if (_foto == null && _intentado && fotoObligatoria) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Adjunta una foto para enviar el reclamo.',
                  style: textos.bodyMedium!.copyWith(color: AppColors.error),
                ),
              ],
              if (_errorFoto != null) ...[espacioChico, Aviso(_errorFoto!, tono: Tono.error)],
              espacioGrande,
              CampoConRotulo(
                rotulo: 'Asunto',
                campo: TextFormField(
                  controller: _asunto,
                  enabled: !_enviando,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  maxLength: asuntoMaximo,
                  onChanged: (_) => _sugerirCategoria(),
                  decoration: const InputDecoration(hintText: 'Ejemplo: Poste sin luz'),
                  validator: validarAsunto,
                ),
              ),
              espacioChico,
              CampoConRotulo(
                rotulo: 'Descripción',
                campo: TextFormField(
                  controller: _descripcion,
                  enabled: !_enviando,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: descripcionMaxima,
                  onChanged: (_) => _sugerirCategoria(),
                  decoration: const InputDecoration(hintText: 'Qué pasa y desde cuándo'),
                  validator: validarDescripcion,
                ),
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
              // Apilados a todo el ancho: lado a lado, el texto se parte en teléfonos angostos.
              OutlinedButton.icon(
                onPressed: _enviando ? null : () => _elegirEnMapa(vista),
                icon: const Icon(Phosphor.mapPin, size: AppIconos.boton),
                label: Text(_punto == null ? 'Elegir en el mapa' : 'Cambiar en el mapa'),
              ),
              espacioChico,
              OutlinedButton.icon(
                onPressed: _enviando || _buscandoGps ? null : _usarMiUbicacion,
                icon: _buscandoGps
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Phosphor.crosshair, size: AppIconos.boton),
                label: const Text('Usar mi ubicación'),
              ),
              if (_fallaGps != null) ...[
                espacioChico,
                Aviso(
                  _fallaGps!.mensaje,
                  tono: Tono.aviso,
                  accion: _fallaGps!.ofrecerAjustes
                      ? TextButton(onPressed: abrirAjustesDeUbicacion, child: const Text('Abrir ajustes'))
                      : null,
                ),
              ],
              espacio,
              CampoConRotulo(
                rotulo: 'Dirección o referencia',
                campo: TextFormField(
                  controller: _direccion,
                  enabled: !_enviando,
                  textCapitalization: TextCapitalization.words,
                  maxLength: direccionMaxima,
                  decoration: InputDecoration(
                    hintText: 'Calle, número o cruce',
                    counterText: '',
                    suffixIcon: vista.predios.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Usar la dirección de mi predio',
                            icon: const Icon(Phosphor.house),
                            onPressed: _enviando
                                ? null
                                : () => setState(() => _direccion.text = vista.predios.first.direccion),
                          ),
                  ),
                  validator: validarDireccion,
                ),
              ),
              if (_errorEnvio != null) ...[
                espacio,
                Aviso('No se envió el reclamo. ${_errorEnvio!} Tus datos siguen aquí.', tono: Tono.error),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Mientras se revisa la foto: breve y sin bloquear nada.
class _RevisandoFoto extends StatelessWidget {
  const _RevisandoFoto();

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSpacing.altoInsignia),
      child: Row(
        children: [
          const SizedBox.square(dimension: AppSpacing.iconoInsignia, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: AppSpacing.sm),
          Flexible(child: Text('Revisando foto…', style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    ),
  );
}

/// Estado de la foto en una insignia y, debajo, el motivo en texto secundario.
class _EstadoFoto extends StatelessWidget {
  const _EstadoFoto(this.resultado);

  final ResultadoFoto resultado;

  @override
  Widget build(BuildContext context) {
    final (texto, tono, icono) = switch (resultado.estado) {
      EstadoFoto.valida => ('Foto válida', Tono.exito, Phosphor.check),
      EstadoFoto.noValida => ('Foto no válida', Tono.error, Phosphor.warningCircle),
      EstadoFoto.enRevision => ('En revisión', Tono.aviso, Phosphor.clock),
    };
    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Insignia(texto, tono: tono, icono: icono),
          const SizedBox(height: AppSpacing.xs),
          Text(resultado.motivo, style: Theme.of(context).textTheme.bodyMedium!),
          if (diagnosticoFotoActivo && resultado.diagnostico != null) ...[
            espacioChico,
            _PanelDiagnostico(resultado.diagnostico!),
          ],
        ],
      ),
    );
  }
}

/// Solo con `--dart-define=DIAGNOSTICO_FOTO=true`: lo que devolvió el modelo.
class _PanelDiagnostico extends StatelessWidget {
  const _PanelDiagnostico(this.diagnostico);

  final DiagnosticoFoto diagnostico;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final estilo = textos.bodySmall!.copyWith(fontFeatures: cifrasTabulares);
    final umbral = diagnostico.umbralModelo;
    final lineas = [
      'Implementación: ${diagnostico.implementacion}',
      if (umbral != null) 'Umbral del modelo: ${umbral.toStringAsFixed(2)}',
      if (diagnostico.etiquetas.isEmpty)
        'Etiquetas: ninguna'
      else ...[
        'Etiquetas:',
        for (final (nombre, confianza) in diagnostico.etiquetas) '  ${confianza.toStringAsFixed(2)}  $nombre',
      ],
      if (diagnostico.error != null) 'Error: ${diagnostico.error}',
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadius.campo),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Diagnóstico de la foto', style: textos.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          SelectableText(lineas.join('\n'), style: estilo),
        ],
      ),
    );
  }
}

/// Pie fijo con el botón de enviar.
class _PieEnvio extends StatelessWidget {
  const _PieEnvio({required this.child});

  final Widget child;

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
        child: child,
      ),
    ),
  );
}

/// Categorías como grilla de tres columnas, con su ícono. Elegida: borde turquesa y un check.
class _GrillaCategorias extends StatelessWidget {
  const _GrillaCategorias({required this.elegida, required this.alElegir});

  final TipoReclamo? elegida;
  final ValueChanged<TipoReclamo>? alElegir;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    const columnas = 3;
    const tipos = TipoReclamo.values;
    return Column(
      children: [
        for (var f = 0; f < tipos.length; f += columnas) ...[
          if (f > 0) const SizedBox(height: AppSpacing.sm),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var c = 0; c < columnas; c++) ...[
                  if (c > 0) const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: f + c < tipos.length
                        ? _Categoria(
                            tipo: tipos[f + c],
                            elegida: elegida == tipos[f + c],
                            alTocar: alElegir == null ? null : () => alElegir!(tipos[f + c]),
                            estilo: textos.labelMedium!,
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Categoria extends StatelessWidget {
  const _Categoria({required this.tipo, required this.elegida, required this.alTocar, required this.estilo});

  final TipoReclamo tipo;
  final bool elegida;
  final VoidCallback? alTocar;
  final TextStyle estilo;

  @override
  Widget build(BuildContext context) {
    final (icono, color) = iconoCategoria(tipo);
    final radio = BorderRadius.circular(AppRadius.campo + 2);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: elegida,
      button: true,
      label: tipo.etiqueta,
      excludeSemantics: true,
      child: Presionable(
        child: AnimatedContainer(
          duration: duracionDe(context),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: radio,
            border: Border.all(color: elegida ? AppColors.primary : AppColors.bordeCampo, width: elegida ? 2 : 1.5),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: radio,
              onTap: alTocar,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: AppSpacing.md),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconoColor.svg(icono, color: color),
                          const SizedBox(height: AppSpacing.sm),
                          Text(tipo.etiqueta, textAlign: TextAlign.center, style: estilo, maxLines: 2),
                        ],
                      ),
                    ),
                  ),
                  if (elegida)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Borde punteado redondeado (la invitación a agregar una foto).
class _BordePunteado extends CustomPainter {
  const _BordePunteado({required this.color, required this.radio});

  final Color color;
  final double radio;

  @override
  void paint(Canvas canvas, Size size) {
    final trazo = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final ruta = ui.Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radio)));
    for (final m in ruta.computeMetrics()) {
      for (double d = 0; d < m.length; d += 10) {
        canvas.drawPath(m.extractPath(d, d + 5), trazo);
      }
    }
  }

  @override
  bool shouldRepaint(_BordePunteado old) => old.color != color;
}

/// Zona de la foto: invita a adjuntar o muestra la miniatura real.
class _CampoFoto extends StatelessWidget {
  const _CampoFoto({
    required this.foto,
    required this.cargando,
    required this.conError,
    required this.obligatoria,
    this.alTocar,
  });

  final Uint8List? foto;
  final bool cargando;
  final bool conError;
  final bool obligatoria;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final borde = BorderRadius.circular(AppRadius.tarjeta - 4);
    if (foto == null && !cargando) {
      // Sin foto: una invitación con borde punteado coral.
      return Semantics(
        button: true,
        label: 'Adjuntar foto',
        excludeSemantics: true,
        child: CustomPaint(
          painter: _BordePunteado(color: conError ? AppColors.error : AppColors.coral, radio: AppRadius.tarjeta - 4),
          child: Material(
            color: AppColors.coral100.withValues(alpha: 0.45),
            borderRadius: borde,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: alTocar,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.coral100,
                        borderRadius: BorderRadius.circular(AppRadius.cajaMediana),
                      ),
                      child: const Center(child: IconoAlmira(IconoA.camara, tamano: 24, color: AppColors.textPrimary)),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Agrega una foto', style: textos.titleMedium!.copyWith(fontWeight: FontWeight.w800)),
                          Text(
                            obligatoria ? 'De la cámara o la galería' : 'Opcional · de la cámara o la galería',
                            style: textos.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.add_rounded, color: AppColors.textPrimary),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
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
                      const Icon(Phosphor.cameraPlus, size: AppIconos.vacio, color: AppColors.primary),
                      const SizedBox(height: AppSpacing.sm),
                      Text('Adjuntar foto', style: textos.labelLarge!.copyWith(color: AppColors.primary)),
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
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.pastilla),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Phosphor.pencilSimple, size: AppIconos.insignia, color: AppColors.primaryDark),
                              const SizedBox(width: 6),
                              Text('Cambiar', style: textos.labelMedium!.copyWith(color: AppColors.primaryDark)),
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
