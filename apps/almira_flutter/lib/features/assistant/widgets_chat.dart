import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/utils/formato.dart';
import '../../core/widgets/componentes.dart';
import 'chat_modelo.dart';

/// Avatar del asistente: un robot amable, ilustración original en `assets/bot_avatar.svg`.
/// Para poner tu propia imagen, reemplaza ese archivo.
class AvatarBot extends StatelessWidget {
  const AvatarBot({super.key, this.lado = 40});

  final double lado;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: ClipOval(
          child: SvgPicture.asset('assets/bot_avatar.svg', width: lado, height: lado, fit: BoxFit.cover),
        ),
      );
}

const double _radioGrande = 18;
const double _radioChico = 5;
const double _anchoAvatar = 28;
const double _separacionAvatar = AppSpacing.sm;

/// Burbuja de un mensaje. El vecino va a la derecha, en turquesa con texto blanco; el
/// asistente, a la izquierda, en gris muy claro, con su mini-avatar en el primer mensaje de cada
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

    final estiloTexto = textos.bodyMedium!.copyWith(
      color: mio ? Colors.white : AppColors.textPrimary,
      height: 1.4,
    );

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
                    child: Icon(Icons.error_outline_rounded, size: 18, color: AppColors.error),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(child: Text(mensaje.texto, style: estiloTexto)),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              TextButton.icon(
                onPressed: alReintentar,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reintentar'),
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 40),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                ),
              ),
            ],
          )
        : (mio ? Text(mensaje.texto, style: estiloTexto) : SelectableText(mensaje.texto, style: estiloTexto));

    final burbuja = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maximo),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mio
              ? AppColors.primary
              : (mensaje.fallo ? AppColors.errorSoft : const Color(0xFFF0F4F4)),
          borderRadius: borde,
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
                  OutlinedButton(
                    onPressed: () => alAbrir(a.ruta),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      shape: const StadiumBorder(),
                      textStyle: textos.labelMedium,
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
            child: Text(hora(mensaje.hora), style: textos.bodySmall),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!mio) ...[
              // El avatar va en el primer mensaje del grupo; en los demás queda el hueco.
              SizedBox(
                width: _anchoAvatar,
                child: posicion.primero ? const AvatarBot(lado: _anchoAvatar) : null,
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
  late final AnimationController _control =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

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
                color: Color(0xFFF0F4F4),
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
          color: AppColors.primary.withValues(alpha: 0.4 + 0.5 * altura),
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
              ActionChip(
                label: Text(p),
                onPressed: () => alElegir(p),
                backgroundColor: AppColors.primarySoft,
                side: BorderSide.none,
                labelStyle: Theme.of(context).textTheme.labelMedium!.copyWith(color: AppColors.primaryDark),
                shape: const StadiumBorder(),
                visualDensity: VisualDensity.standard,
                materialTapTargetSize: MaterialTapTargetSize.padded,
              ),
          ],
        ),
      );
}

/// Estado del asistente bajo su nombre, con un punto verde.
class EstadoEnLinea extends StatelessWidget {
  const EstadoEnLinea({super.key});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: Color(0xFF7BE0A8), shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            'En línea',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.white.withValues(alpha: 0.92)),
          ),
        ],
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
          elevation: 2,
          shadowColor: Colors.black26,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: alTocar,
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
            ),
          ),
        ),
      );
}

/// Duración de las animaciones del chat, respetando «reducir movimiento».
Duration duracionChat(BuildContext context) => duracionDe(context, 220);
