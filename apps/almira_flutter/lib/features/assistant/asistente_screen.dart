import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/iconos_almira.dart';
import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/utils/formato.dart';
import '../../core/widgets/componentes.dart';
import '../../core/widgets/movimiento.dart';
import '../../shared/services/proveedores.dart';
import 'chat_asistente.dart';
import 'chat_modelo.dart';
import 'widgets_chat.dart';

const _maximoPregunta = 500;
const _sugerencias = [
  SugerenciaChat('¿Cuánto debo?', IconoA.pagar, AppColors.sol),
  SugerenciaChat('Mi último pago', IconoA.historial, AppColors.lima),
  SugerenciaChat('¿Cómo pago?', IconoA.tarjeta, AppColors.coral),
  SugerenciaChat('Mi estado de cuenta', IconoA.estado, AppColors.primary),
];

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
  final _foco = FocusNode();

  @override
  void initState() {
    super.initState();
    _desplazamiento.addListener(_vigilarDesplazamiento);
    _foco.addListener(_alEnfocar);
  }

  // Al abrirse el teclado, la conversación baja hasta el último mensaje.
  // También compacta la cabecera mientras se escribe.
  void _alEnfocar() {
    setState(() {});
    if (_foco.hasFocus) Future<void>.delayed(const Duration(milliseconds: 300), _alFinal);
  }

  @override
  void dispose() {
    _foco.dispose();
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

  /// «Hola, Rosa» (o solo «Hola» si no hay nombre).
  String _hola() {
    final v = ref.read(vistaProvider).valueOrNull;
    final nombre = v?.vecino?.nombres ?? v?.vecino?.nombre ?? ref.read(sesionProvider).cuenta?.nombre;
    return nombre == null || nombre.trim().isEmpty ? 'Hola' : 'Hola, ${primerNombre(tipoTitulo(nombre))}';
  }

  String _saludo() => '${_hola()}. Soy Almira. Te ayudo con tus tributos, pagos y estado de cuenta.';

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatAsistenteProvider);
    final hoy = ref.watch(relojProvider)();
    final esDemo = ref.watch(esDemoProvider);

    // Antes del primer mensaje se ve la bienvenida; después, el saludo como primer mensaje, lo
    // conversado y, mientras se espera, el indicador.
    final bienvenida = chat.mensajes.isEmpty;
    final saludo = MensajeChat(texto: _saludo(), mio: false, hora: hoy);
    final todos = [saludo, ...chat.mensajes];
    final posiciones = agruparMensajes(todos);

    // Pestaña raíz: cabecera turquesa y la conversación en la hoja blanca. Con el teclado
    // abierto, la hoja se encoge y el campo queda justo encima del teclado.
    return Scaffold(
      body: Column(
        children: [
          CabeceraMarca(
            titulo: 'Asistente',
            esDemo: esDemo,
            // Mientras se escribe, el turquesa se reduce para dejar sitio a la conversación.
            rellenoInferior: _foco.hasFocus ? AppSpacing.solapeHoja : AppSpacing.solapeHoja + AppSpacing.lg,
          ),
          Expanded(
            child: HojaBlanca(
              padding: EdgeInsets.zero,
              // Los mensajes no se salen de las esquinas redondeadas al desplazarse.
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.hoja)),
                child: Stack(
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
                              if (bienvenida)
                                BienvenidaAsistente(
                                  titulo: '${_hola()}. Soy Almira',
                                  sugerencias: _sugerencias,
                                  alElegir: _enviar,
                                )
                              else
                                for (final (i, mensaje) in todos.indexed)
                                  Aparecer(
                                    key: ValueKey('mensaje-$i'),
                                    desdeLado: true,
                                    child: BurbujaChat(
                                      mensaje: mensaje,
                                      posicion: posiciones[i],
                                      esElPrimero: i == 0,
                                      alAbrir: _abrir,
                                      alReintentar: _reintentar,
                                    ),
                                  ),
                              if (chat.enviando) const IndicadorEscritura(),
                            ],
                          ),
                        ),
                        _BarraEntrada(controlador: _entrada, foco: _foco, enviando: chat.enviando, alEnviar: _enviar),
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra para escribir: campo redondeado de hasta 4 líneas y botón de enviar circular, que se
/// apaga si no hay texto o se espera una respuesta.
class _BarraEntrada extends StatelessWidget {
  const _BarraEntrada({required this.controlador, required this.foco, required this.enviando, required this.alEnviar});

  final TextEditingController controlador;
  final FocusNode foco;
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
          padding: const EdgeInsets.fromLTRB(AppSpacing.margen, AppSpacing.md, AppSpacing.margen, AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Semantics(
                  textField: true,
                  label: 'Escribe tu pregunta',
                  child: TextField(
                    controller: controlador,
                    focusNode: foco,
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
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                      border: _borde(),
                      enabledBorder: _borde(),
                      focusedBorder: _borde(AppColors.foco, 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
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
                      icon: IconoAlmira(
                        IconoA.enviar,
                        tamano: 22,
                        color: puede ? AppColors.onPrimary : AppColors.textSecondary,
                      ),
                      style: IconButton.styleFrom(
                        minimumSize: const Size(52, 52),
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
