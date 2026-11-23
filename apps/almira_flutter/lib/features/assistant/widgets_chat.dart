import 'package:flutter/material.dart';

import '../../app/theme/iconos.dart';
import '../../app/theme/iconos_almira.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/utils/formato.dart';
import '../../core/widgets/componentes.dart';
import '../../core/widgets/movimiento.dart';
import 'chat_modelo.dart';

/// Avatar del asistente: Almi, la casita con cara del rediseño, en un círculo turquesa claro.
class AvatarBot extends StatelessWidget {
  const AvatarBot({super.key, this.lado = 40});

  final double lado;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: lado,
      height: lado,
      padding: EdgeInsets.all(lado * 0.08),
      decoration: const BoxDecoration(color: AppColors.primary100, shape: BoxShape.circle),
      child: const ImagenIlustracion(Ilustracion.almiBot),
    ),
  );
}

/// Una sugerencia de la bienvenida: pregunta, ícono y color de su caja.
class SugerenciaChat {
  const SugerenciaChat(this.pregunta, this.icono, this.color);

  final String pregunta;
  final IconoA icono;
  final Color color;
}

/// Bienvenida del asistente, antes del primer mensaje: Almi flotando, el saludo, las sugerencias
/// en tarjetas de dos en dos y el aviso de que las decisiones son de la municipalidad.
class BienvenidaAsistente extends StatelessWidget {
  const BienvenidaAsistente({super.key, required this.titulo, required this.sugerencias, required this.alElegir});

  /// «Hola, Rosa. Soy Almira».
  final String titulo;
  final List<SugerenciaChat> sugerencias;
  final void Function(String pregunta) alElegir;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.sm),
        const Center(
          child: Rebote(child: Flotar(child: ImagenIlustracion(Ilustracion.almiBot, alto: 132))),
        ),
        const SizedBox(height: AppSpacing.lg),
        Aparecer(
          paso: 1,
          child: Semantics(
            header: true,
            child: Text(titulo, textAlign: TextAlign.center, style: textos.headlineSmall),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Aparecer(
          paso: 2,
          child: Text(
            'Te ayudo con tus tributos, pagos y estado de cuenta.',
            textAlign: TextAlign.center,
            style: textos.bodyLarge!.copyWith(color: AppColors.textSecondary, height: 1.5),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Aparecer(
          paso: 3,
          child: Text(
            'PRUEBA PREGUNTANDO',
            style: textos.labelMedium!.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // De dos en dos; cada fila tan alta como su tarjeta más alta.
        for (var i = 0; i < sugerencias.length; i += 2) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          Aparecer(
            paso: 4 + i ~/ 2,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _TarjetaSugerencia(sugerencia: sugerencias[i], alElegir: alElegir),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: i + 1 < sugerencias.length
                        ? _TarjetaSugerencia(sugerencia: sugerencias[i + 1], alElegir: alElegir)
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Aparecer(
          paso: 6,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const IconoAlmira(IconoA.privacidad, tamano: 16, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Flexible(child: Text('Las decisiones finales son de tu municipalidad.', style: textos.bodyMedium)),
            ],
          ),
        ),
      ],
    );
  }
}

class _TarjetaSugerencia extends StatelessWidget {
  const _TarjetaSugerencia({required this.sugerencia, required this.alElegir});

  final SugerenciaChat sugerencia;
  final void Function(String pregunta) alElegir;

  @override
  Widget build(BuildContext context) => Tarjeta(
    onTap: () => alElegir(sugerencia.pregunta),
    semantica: 'Preguntar: ${sugerencia.pregunta}',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconoColor.svg(sugerencia.icono, color: sugerencia.color, lado: 40),
        const SizedBox(height: AppSpacing.md),
        Text(sugerencia.pregunta, style: Theme.of(context).textTheme.titleMedium),
      ],
    ),
  );
}

const double _radioGrande = 20;
const double _radioChico = 6;
const double _anchoAvatar = 32;
const double _separacionAvatar = AppSpacing.sm;

/// Burbuja de un mensaje. El vecino va a la derecha, en turquesa con texto blanco; el
/// asistente, a la izquierda, en blanco con sombra suave, con Almi en el último mensaje de cada
/// grupo. Los mensajes seguidos del mismo autor se juntan; la hora sale en el último.
class BurbujaChat extends StatelessWidget {
  const BurbujaChat({
    super.key,
    required this.mensaje,
    required this.posicion,
    required this.alAbrir,
    required this.alReintentar,
    this.esElPrimero = false,
  });

  final MensajeChat mensaje;
  final PosicionEnGrupo posicion;
  final void Function(String ruta) alAbrir;
  final VoidCallback alReintentar;
  final bool esElPrimero;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final mio = mensaje.mio;
    final ancho = MediaQuery.sizeOf(context).width;
    // 78 % de la pantalla como máximo, descontando el espacio del avatar.
    final maximo = ancho * 0.78;

    Radius r(bool grande) => Radius.circular(grande ? _radioGrande : _radioChico);
    // Los lados que dan al interior del grupo son chicos; los extremos, redondos.
    final borde = mio
        ? BorderRadius.only(
            topLeft: const Radius.circular(_radioGrande),
            bottomLeft: const Radius.circular(_radioGrande),
            topRight: r(posicion.primero),
            bottomRight: r(posicion.ultimo),
          )
        : BorderRadius.only(
            topRight: const Radius.circular(_radioGrande),
            bottomRight: const Radius.circular(_radioGrande),
            topLeft: r(posicion.primero),
            bottomLeft: r(posicion.ultimo),
          );

    final estiloTexto = textos.bodyLarge!.copyWith(color: mio ? AppColors.onPrimary : AppColors.textPrimary);

    final contenido = mensaje.fallo
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Phosphor.warningCircle, size: 18, color: AppColors.error),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(child: Text(mensaje.texto, style: estiloTexto)),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              OutlinedButton.icon(
                onPressed: alReintentar,
                icon: const Icon(Phosphor.arrowClockwise, size: 18),
                label: const Text('Reintentar'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 40),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  backgroundColor: AppColors.surface,
                  shape: const StadiumBorder(),
                ),
              ),
            ],
          )
        : (mio ? Text(mensaje.texto, style: estiloTexto) : SelectableText(mensaje.texto, style: estiloTexto));

    final burbuja = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maximo),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: mio ? AppColors.primary : (mensaje.fallo ? AppColors.errorSoft : AppColors.surface),
          borderRadius: borde,
          boxShadow: mio || mensaje.fallo ? null : AppColors.sombraCard,
        ),
        child: contenido,
      ),
    );

    final columna = Column(
      crossAxisAlignment: mio ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        burbuja,
        if (mensaje.acciones.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maximo),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final a in mensaje.acciones)
                  // Acciones del asistente: botones turquesa claro, como «Ver detalle».
                  FilledButton(
                    onPressed: () => alAbrir(a.ruta),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      backgroundColor: AppColors.primary100,
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.caja)),
                      textStyle: textos.titleMedium,
                    ),
                    child: Text(a.etiqueta),
                  ),
              ],
            ),
          ),
        ],
        if (posicion.ultimo)
          Padding(
            padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
            child: Text(hora(mensaje.hora), style: textos.bodySmall!),
          ),
      ],
    );

    return Semantics(
      container: true,
      label: mio ? 'Tú, ${hora(mensaje.hora)}' : 'Asistente, ${hora(mensaje.hora)}',
      child: Padding(
        padding: EdgeInsets.only(
          top: esElPrimero ? 0 : (posicion.primero ? AppSpacing.md : 2),
          bottom: posicion.ultimo ? AppSpacing.xs : 0,
        ),
        child: Row(
          mainAxisAlignment: mio ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!mio) ...[
              // Almi va al pie del último mensaje del grupo; en los demás queda el hueco.
              SizedBox(
                width: _anchoAvatar,
                child: posicion.ultimo
                    ? const Padding(
                        padding: EdgeInsets.only(bottom: 20),
                        child: AvatarBot(lado: _anchoAvatar),
                      )
                    : null,
              ),
              const SizedBox(width: _separacionAvatar),
            ],
            Flexible(child: columna),
          ],
        ),
      ),
    );
  }
}

/// «Escribiendo…»: tres puntos que suben y bajan dentro de una burbuja del asistente.
class IndicadorEscritura extends StatefulWidget {
  const IndicadorEscritura({super.key});

  @override
  State<IndicadorEscritura> createState() => _IndicadorEscrituraState();
}

class _IndicadorEscrituraState extends State<IndicadorEscritura> with SingleTickerProviderStateMixin {
  late final AnimationController _control = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _control.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quieto = MediaQuery.maybeDisableAnimationsOf(context) == true;
    return Semantics(
      liveRegion: true,
      label: 'El asistente está escribiendo',
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const AvatarBot(lado: _anchoAvatar),
            const SizedBox(width: _separacionAvatar),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                boxShadow: AppColors.sombraCard,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(_radioChico),
                  topRight: Radius.circular(_radioGrande),
                  bottomLeft: Radius.circular(_radioGrande),
                  bottomRight: Radius.circular(_radioGrande),
                ),
              ),
              child: ExcludeSemantics(
                child: AnimatedBuilder(
                  animation: _control,
                  builder: (context, _) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < 3; i++) ...[
                        if (i > 0) const SizedBox(width: 5),
                        _Punto(fase: quieto ? 1 : ((_control.value * 3 - i) % 3) / 3),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Punto extends StatelessWidget {
  const _Punto({required this.fase});

  /// 0 a 1 en cada vuelta: el punto sube y se aclara en la primera parte.
  final double fase;

  @override
  Widget build(BuildContext context) {
    final salto = fase < 0.5 ? (fase * 2) : 0.0;
    final altura = salto < 0.5 ? salto * 2 : (1 - salto) * 2;
    return Transform.translate(
      offset: Offset(0, -4 * altura),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: AppColors.textSecondary.withValues(alpha: 0.25 + 0.75 * altura),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Sugerencias rápidas: botones que mandan la pregunta tal cual.
class SugerenciasRapidas extends StatelessWidget {
  const SugerenciasRapidas({super.key, required this.preguntas, required this.alElegir});

  final List<String> preguntas;
  final void Function(String pregunta) alElegir;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.md, left: _anchoAvatar + _separacionAvatar),
    child: Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final p in preguntas)
          // Sugerencias con borde fino: blancas, texto turquesa.
          ActionChip(
            label: Text(p),
            onPressed: () => alElegir(p),
            backgroundColor: AppColors.surface,
            side: const BorderSide(color: AppColors.border),
            labelStyle: Theme.of(context).textTheme.titleMedium!.copyWith(color: AppColors.primary),
            shape: const StadiumBorder(),
            visualDensity: VisualDensity.standard,
            materialTapTargetSize: MaterialTapTargetSize.padded,
          ),
      ],
    ),
  );
}

/// Botón flotante para volver al último mensaje.
class BotonBajar extends StatelessWidget {
  const BotonBajar({super.key, required this.alTocar});

  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Ir al último mensaje',
    child: Material(
      color: AppColors.surface,
      shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: alTocar,
        child: const SizedBox(width: 44, height: 44, child: Icon(Phosphor.caretDown, color: AppColors.primary)),
      ),
    ),
  );
}

/// Duración de las animaciones del chat, respetando «reducir movimiento».
Duration duracionChat(BuildContext context) => duracionDe(context, 220);
