import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/widgets/componentes.dart';
import '../../shared/services/proveedores.dart';
import 'asistente_logica.dart';

const _claveHistorial = 'asistente.historial';
const _maximoGuardado = 60;
const _maximoPregunta = 300;

class _Mensaje {
  const _Mensaje(this.texto, {required this.mio, this.accion, this.ruta});

  final String texto;
  final bool mio;
  final String? accion;
  final String? ruta;

  Map<String, dynamic> aJson() => {'t': texto, 'm': mio, 'a': accion, 'r': ruta};

  factory _Mensaje.deJson(Map json) => _Mensaje(
        (json['t'] ?? '').toString(),
        mio: json['m'] == true,
        accion: json['a'] as String?,
        ruta: json['r'] as String?,
      );
}

/// Asistente de preguntas frecuentes. Dice con claridad que responde solo, con
/// los datos de la cuenta, y que no decide nada. La conversación se guarda en
/// el teléfono únicamente si el vecino lo activó en Privacidad.
class AsistenteScreen extends ConsumerStatefulWidget {
  const AsistenteScreen({super.key});

  @override
  ConsumerState<AsistenteScreen> createState() => _AsistenteScreenState();
}

class _AsistenteScreenState extends ConsumerState<AsistenteScreen> {
  final _entrada = TextEditingController();
  final _desplazamiento = ScrollController();
  final _mensajes = <_Mensaje>[];

  bool get _guardar => ref.read(sesionProvider).consentimientos.asistente;

  @override
  void initState() {
    super.initState();
    if (_guardar) {
      final texto = ref.read(preferenciasProvider).getString(_claveHistorial);
      if (texto != null) {
        try {
          _mensajes.addAll((jsonDecode(texto) as List).map((m) => _Mensaje.deJson(m as Map)));
        } catch (_) {
          // Historial ilegible: se empieza de cero.
        }
      }
    }
  }

  @override
  void dispose() {
    _entrada.dispose();
    _desplazamiento.dispose();
    super.dispose();
  }

  Future<void> _persistir() async {
    final preferencias = ref.read(preferenciasProvider);
    if (!_guardar || _mensajes.isEmpty) {
      await preferencias.remove(_claveHistorial);
      return;
    }
    final recientes = _mensajes.length > _maximoGuardado
        ? _mensajes.sublist(_mensajes.length - _maximoGuardado)
        : _mensajes;
    await preferencias.setString(
      _claveHistorial,
      jsonEncode(recientes.map((m) => m.aJson()).toList()),
    );
  }

  void _preguntar(String pregunta) {
    final texto = pregunta.trim();
    if (texto.isEmpty) return;
    final vista = ref.read(vistaProvider).valueOrNull;
    final _Mensaje respuesta;
    if (vista == null) {
      // Sin datos cargados no se responde con cifras.
      respuesta = const _Mensaje(
        'No pude leer tus datos en este momento. Revisa tu conexión e inténtalo de nuevo.',
        mio: false,
      );
    } else {
      final r = responder(texto, vista, ref.read(relojProvider)());
      respuesta = _Mensaje(r.texto, mio: false, accion: r.accion, ruta: r.ruta);
    }
    setState(() {
      _mensajes
        ..add(_Mensaje(texto, mio: true))
        ..add(respuesta);
      _entrada.clear();
    });
    _persistir();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_desplazamiento.hasClients) return;
      _desplazamiento.animateTo(
        _desplazamiento.position.maxScrollExtent,
        duration: duracionDe(context, 220),
        curve: Curves.easeOut,
      );
    });
  }

  void _borrar() {
    setState(_mensajes.clear);
    _persistir();
  }

  void _abrir(String ruta) {
    // Las pestañas se cambian; el resto se abre encima.
    final esPestana = !ruta.startsWith(Rutas.perfil) && ruta != Rutas.nuevoReclamo;
    esPestana ? context.go(ruta) : context.push(ruta);
  }

  @override
  Widget build(BuildContext context) {
    // Si apaga el permiso en Privacidad, lo guardado se borra.
    ref.listen(sesionProvider.select((s) => s.consentimientos.asistente), (_, _) => _persistir());
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistente'),
        actions: [
          if (_mensajes.isNotEmpty)
            IconButton(
              tooltip: 'Borrar conversación',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _borrar,
            ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _desplazamiento,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.margen,
                AppSpacing.lg,
                AppSpacing.margen,
                AppSpacing.lg,
              ),
              children: [
                const Aviso(
                  'Respuestas automáticas con los datos de tu cuenta. No es una persona ni una decisión oficial.',
                  icono: Icons.smart_toy_outlined,
                ),
                espacio,
                const _Burbuja(mensaje: _Mensaje(saludoAsistente, mio: false)),
                for (final mensaje in _mensajes)
                  _Burbuja(
                    mensaje: mensaje,
                    alAbrir: mensaje.ruta == null ? null : () => _abrir(mensaje.ruta!),
                  ),
              ],
            ),
          ),
          DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              top: false,
              // La barra inferior ya cubre el borde del sistema, salvo con el teclado abierto.
              bottom: MediaQuery.viewInsetsOf(context).bottom > 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 56,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margen, vertical: 8),
                      itemCount: preguntasSugeridas.length,
                      separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (_, i) => ActionChip(
                        label: Text(preguntasSugeridas[i]),
                        onPressed: () => _preguntar(preguntasSugeridas[i]),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.margen, 0, AppSpacing.sm, AppSpacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _entrada,
                            minLines: 1,
                            maxLines: 4,
                            maxLength: _maximoPregunta,
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.send,
                            onSubmitted: _preguntar,
                            style: textos.bodyLarge,
                            decoration: const InputDecoration(
                              hintText: 'Escribe tu pregunta',
                              counterText: '',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        IconButton.filled(
                          tooltip: 'Enviar',
                          icon: const Icon(Icons.arrow_upward_rounded),
                          onPressed: () => _preguntar(_entrada.text),
                          style: IconButton.styleFrom(
                            minimumSize: const Size(AppSpacing.toque, AppSpacing.toque),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Burbuja extends StatelessWidget {
  const _Burbuja({required this.mensaje, this.alAbrir});

  final _Mensaje mensaje;
  final VoidCallback? alAbrir;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final mio = mensaje.mio;
    const radio = Radius.circular(18);
    return Semantics(
      label: mio ? 'Tú' : 'Asistente',
      child: Align(
        alignment: mio ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: mio ? AppColors.primary : AppColors.surfaceSubtle,
              borderRadius: BorderRadius.only(
                topLeft: radio,
                topRight: radio,
                bottomLeft: mio ? radio : const Radius.circular(4),
                bottomRight: mio ? const Radius.circular(4) : radio,
              ),
              border: mio ? null : Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  mensaje.texto,
                  style: textos.bodyLarge!.copyWith(color: mio ? Colors.white : AppColors.textPrimary),
                ),
                if (mensaje.accion != null && alAbrir != null)
                  TextButton(
                    onPressed: alAbrir,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      textStyle: textos.labelMedium,
                    ),
                    child: Text(mensaje.accion!),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
