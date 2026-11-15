import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import 'componentes.dart';

/// Carita dibujada con vectores: feliz cuando no hay saldo pendiente y triste
/// cuando lo hay. Cambia con una pequeña animación cuando cambia el saldo.
class CaraSaldo extends StatelessWidget {
  const CaraSaldo({super.key, required this.alDia, this.lado = 72});

  final bool alDia;
  final double lado;

  @override
  Widget build(BuildContext context) => Semantics(
        label: alDia ? 'Estás al día' : 'Tienes saldo pendiente',
        image: true,
        child: ExcludeSemantics(
          child: AnimatedSwitcher(
            duration: duracionDe(context, 350),
            transitionBuilder: (hijo, animacion) => ScaleTransition(
              scale: CurvedAnimation(parent: animacion, curve: Curves.easeOutBack),
              child: FadeTransition(opacity: animacion, child: hijo),
            ),
            child: SizedBox(
              key: ValueKey(alDia),
              width: lado,
              height: lado,
              child: CustomPaint(painter: _PintorCara(alDia: alDia)),
            ),
          ),
        ),
      );
}

class _PintorCara extends CustomPainter {
  const _PintorCara({required this.alDia});

  final bool alDia;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    final radio = size.width / 2;
    final color = alDia ? AppColors.success : AppColors.warning;
    final fondo = alDia ? AppColors.successSoft : AppColors.warningSoft;

    canvas.drawCircle(centro, radio, Paint()..color = fondo);
    canvas.drawCircle(
      centro,
      radio - 1.5,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Ojos.
    final ojo = Paint()..color = color;
    final dy = centro.dy - radio * 0.18;
    canvas.drawCircle(Offset(centro.dx - radio * 0.34, dy), radio * 0.09, ojo);
    canvas.drawCircle(Offset(centro.dx + radio * 0.34, dy), radio * 0.09, ojo);

    // Cejas inclinadas hacia arriba cuando está triste.
    if (!alDia) {
      final ceja = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(centro.dx - radio * 0.5, dy - radio * 0.2),
        Offset(centro.dx - radio * 0.2, dy - radio * 0.3),
        ceja,
      );
      canvas.drawLine(
        Offset(centro.dx + radio * 0.5, dy - radio * 0.2),
        Offset(centro.dx + radio * 0.2, dy - radio * 0.3),
        ceja,
      );
    }

    // Boca: sonrisa o ceño.
    final boca = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round;
    final ancho = radio * 0.62;
    final base = centro.dy + radio * (alDia ? 0.2 : 0.46);
    final trazo = Path()
      ..moveTo(centro.dx - ancho, base)
      ..quadraticBezierTo(
        centro.dx,
        base + radio * (alDia ? 0.5 : -0.34) * math.sqrt1_2 * 1.4,
        centro.dx + ancho,
        base,
      );
    canvas.drawPath(trazo, boca);
  }

  @override
  bool shouldRepaint(_PintorCara anterior) => anterior.alDia != alDia;
}
