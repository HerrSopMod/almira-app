import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/utils/formato.dart';
import '../../shared/services/proveedores.dart';
import 'chat_asistente.dart';
import 'chat_modelo.dart';
import 'widgets_chat.dart';

const _maximoPregunta = 500;
const _sugerencias = ['¿Cuánto debo?', 'Mi último pago', '¿Cómo pago?', 'Mi estado de cuenta'];

/// Chat con el asistente, con aspecto de mensajería: encabezado con el avatar, burbujas
/// agrupadas, indicador de escritura, sugerencias y accesos rápidos. La conversación vive en
/// memoria mientras dura la sesión.
class AsistenteScreen extends ConsumerStatefulWidget {
  const AsistenteScreen({super.key});

  @override
  ConsumerState<AsistenteScreen> createState() => _AsistenteScreenState();
}

class _AsistenteScreenState extends ConsumerState<AsistenteScreen> {
  final _entrada = TextEditingController();
  final _desplazamiento = ScrollController();
  bool _lejosDelFinal = false;

  @override
  void initState() {
    super.initState();
    _desplazamiento.addListener(_vigilarDesplazamiento);
  }

  @override
  void dispose() {
    _entrada.dispose();
    _desplazamiento.dispose();
    super.dispose();
  }

  void _vigilarDesplazamiento() {
    if (!_desplazamiento.hasClients) return;
    final lejos = _desplazamiento.position.maxScrollExtent - _desplazamiento.position.pixels > 160;
    if (lejos != _lejosDelFinal) setState(() => _lejosDelFinal = lejos);
  }

  void _alFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_desplazamiento.hasClients) return;
      _desplazamiento.animateTo(
        _desplazamiento.position.maxScrollExtent,
        duration: duracionChat(context),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _enviar(String texto) async {
    final limpio = texto.trim();
    if (limpio.isEmpty || ref.read(chatAsistenteProvider).enviando) return;
    _entrada.clear();
    final futuro = ref.read(chatAsistenteProvider.notifier).enviar(limpio);
    _alFinal();
    await futuro;
    _alFinal();
  }

  Future<void> _reintentar() async {
    final futuro = ref.read(chatAsistenteProvider.notifier).reintentar();
    _alFinal();
    await futuro;
    _alFinal();
  }

  void _abrir(String ruta) {
    // Las pestañas se cambian; el resto se abre encima.
    final esPestana = !ruta.startsWith(Rutas.perfil) && ruta != Rutas.nuevoReclamo;
    esPestana ? context.go(ruta) : context.push(ruta);
  }

  String _saludo() {
    final v = ref.read(vistaProvider).valueOrNull;
    final nombre = v?.vecino?.nombres ?? v?.vecino?.nombre ?? ref.read(sesionProvider).cuenta?.nombre;
    final hola = nombre == null || nombre.trim().isEmpty ? 'Hola' : 'Hola, ${primerNombre(nombre)}';
    return '$hola. Soy Almira, tu asistente virtual. Te ayudo con tus tributos, pagos y estado de '
        'cuenta. Oriento, pero las decisiones son de tu municipalidad.';
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatAsistenteProvider);
    final hoy = ref.watch(relojProvider)();
    final textos = Theme.of(context).textTheme;

    // Lista que se dibuja: el saludo, lo conversado y, mientras se espera, el indicador.
    final saludo = MensajeChat(texto: _saludo(), mio: false, hora: hoy);
    final todos = [saludo, ...chat.mensajes];
    final posiciones = agruparMensajes(todos);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: 0,
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(Rutas.inicio),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const AvatarBot(lado: 36),
            ),
            const SizedBox(width: AppSpacing.md),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Asistente Almira',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textos.titleSmall!.copyWith(color: Colors.white, fontSize: 16),
                  ),
                  const EstadoEnLinea(),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
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
                    for (final (i, mensaje) in todos.indexed)
                      BurbujaChat(
                        key: ValueKey('mensaje-$i'),
                        mensaje: mensaje,
                        posicion: posiciones[i],
                        esElPrimero: i == 0,
                        alAbrir: _abrir,
                        alReintentar: _reintentar,
                      ),
                    if (!chat.hayMensajesDelVecino)
                      SugerenciasRapidas(preguntas: _sugerencias, alElegir: _enviar),
                    if (chat.enviando) const IndicadorEscritura(),
                  ],
                ),
              ),
              _BarraEntrada(controlador: _entrada, enviando: chat.enviando, alEnviar: _enviar),
            ],
          ),
          if (_lejosDelFinal)
            Positioned(
              right: AppSpacing.margen,
              bottom: 84,
              child: BotonBajar(alTocar: _alFinal),
            ),
        ],
      ),
    );
  }
}

/// Barra para escribir: campo redondeado de hasta 4 líneas y botón de enviar circular, que se
/// apaga si no hay texto o se espera una respuesta.
class _BarraEntrada extends StatelessWidget {
  const _BarraEntrada({required this.controlador, required this.enviando, required this.alEnviar});

  final TextEditingController controlador;
  final bool enviando;
  final void Function(String texto) alEnviar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        // La barra de navegación ya cubre el borde del sistema, salvo con el teclado abierto.
        bottom: MediaQuery.viewInsetsOf(context).bottom > 0,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.margen, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Semantics(
                  textField: true,
                  label: 'Escribe tu pregunta',
                  child: TextField(
                    controller: controlador,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: _maximoPregunta,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.send,
                    onSubmitted: enviando ? null : alEnviar,
                    style: textos.bodyLarge,
                    decoration: InputDecoration(
                      hintText: 'Escribe tu pregunta',
                      counterText: '',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                      border: _borde(),
                      enabledBorder: _borde(),
                      focusedBorder: _borde(AppColors.primary, 1.6),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controlador,
                builder: (context, valor, _) {
                  final puede = valor.text.trim().isNotEmpty && !enviando;
                  return Semantics(
                    button: true,
                    enabled: puede,
                    label: 'Enviar',
                    child: IconButton.filled(
                      tooltip: 'Enviar',
                      onPressed: puede ? () => alEnviar(controlador.text) : null,
                      icon: const Icon(Icons.arrow_upward_rounded),
                      style: IconButton.styleFrom(
                        minimumSize: const Size(AppSpacing.toque, AppSpacing.toque),
                        shape: const CircleBorder(),
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: AppColors.track,
                        foregroundColor: Colors.white,
                        disabledForegroundColor: AppColors.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _borde([Color color = Colors.transparent, double ancho = 0]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(26),
        borderSide: BorderSide(color: color, width: ancho),
      );
}
