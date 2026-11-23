import 'dart:math' as math;

import 'package:flutter/material.dart';

// Movimiento del rediseño (`Diseno/tokens/tokens.css`): una sola curva suave,
// cubic-bezier(.2, .8, .2, 1), de 550 a 600 ms. Con «reducir movimiento» del sistema no se
// anima nada: todo aparece en su lugar.

/// Curva de todas las animaciones del rediseño.
const curvaAlmira = Cubic(0.2, 0.8, 0.2, 1);

bool sinMovimiento(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) == true;

/// Entrada de un bloque: sube 16 px mientras aparece. [paso] escalona la entrada cada 50 ms
/// (hasta 9 pasos). Solo anima la primera vez que se construye.
class Aparecer extends StatefulWidget {
  const Aparecer({super.key, required this.child, this.paso = 0, this.desdeLado = false});

  final Widget child;
  final int paso;

  /// Entra desde la derecha (tarjetas horizontales, mensajes) en vez de desde abajo.
  final bool desdeLado;

  @override
  State<Aparecer> createState() => _AparecerState();
}

class _AparecerState extends State<Aparecer> with SingleTickerProviderStateMixin {
  // La espera del escalonado va dentro de la misma animación (sin temporizadores sueltos).
  late final int _espera = 50 * math.min(widget.paso, 9);
  late final int _dura = widget.desdeLado ? 550 : 600;
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _espera + _dura),
  );
  bool _iniciado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciado) return;
    _iniciado = true;
    if (sinMovimiento(context)) {
      _c.value = 1;
      return;
    }
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    child: widget.child,
    builder: (context, hijo) {
      final t = Interval(_espera / (_espera + _dura), 1, curve: curvaAlmira).transform(_c.value);
      return Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.translate(
          offset: widget.desdeLado ? Offset(28 * (1 - t), 0) : Offset(0, 16 * (1 - t)),
          child: hijo,
        ),
      );
    },
  );
}

/// Aparición con un pequeño rebote de escala, para montos grandes e ilustraciones.
class Rebote extends StatelessWidget {
  const Rebote({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (sinMovimiento(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: curvaAlmira,
      child: child,
      builder: (context, t, hijo) {
        // 0 → 0.86, 0.6 → 1.03, 1 → 1.
        final escala = t < 0.6 ? 0.86 + (1.03 - 0.86) * (t / 0.6) : 1.03 - 0.03 * ((t - 0.6) / 0.4);
        return Opacity(
          opacity: (t / 0.6).clamp(0, 1),
          child: Transform.scale(scale: escala, child: hijo),
        );
      },
    );
  }
}

/// Flota suavemente arriba y abajo (7 px, 4,5 s), sin fin. Para el logo y las ilustraciones.
class Flotar extends StatefulWidget {
  const Flotar({super.key, required this.child});

  final Widget child;

  @override
  State<Flotar> createState() => _FlotarState();
}

class _FlotarState extends State<Flotar> with SingleTickerProviderStateMixin {
  static final _enPrueba = WidgetsBinding.instance.runtimeType.toString().contains('TestWidgetsFlutterBinding');

  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 4500));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // En las pruebas automáticas no flota: una animación sin fin no deja «asentarse» la pantalla.
    if (sinMovimiento(context) || _enPrueba) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    child: widget.child,
    builder: (context, hijo) =>
        Transform.translate(offset: Offset(0, -7 * (0.5 - 0.5 * math.cos(2 * math.pi * _c.value))), child: hijo),
  );
}

/// Barra que crece desde la izquierda hasta [fraccion] (0 a 1), con 350 ms de espera.
class BarraCreciente extends StatelessWidget {
  const BarraCreciente({super.key, required this.fraccion, required this.color, this.alto = 8, this.retraso = 0});

  final double fraccion;
  final Color color;
  final double alto;

  /// Espera extra en milisegundos (para escalonar segmentos).
  final int retraso;

  @override
  Widget build(BuildContext context) {
    final barra = FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: fraccion.clamp(0, 1),
      child: Container(
        height: alto,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(alto)),
      ),
    );
    if (sinMovimiento(context)) return barra;
    return _Crecer(retraso: 350 + retraso, child: barra);
  }
}

/// Escala horizontal de 0 a 1 desde la izquierda.
class _Crecer extends StatefulWidget {
  const _Crecer({required this.child, required this.retraso});

  final Widget child;
  final int retraso;

  @override
  State<_Crecer> createState() => _CrecerState();
}

class _CrecerState extends State<_Crecer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.retraso + 1100),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    child: widget.child,
    builder: (context, hijo) => Transform(
      alignment: Alignment.centerLeft,
      transform: Matrix4.diagonal3Values(
        Interval(widget.retraso / (widget.retraso + 1100), 1, curve: curvaAlmira).transform(_c.value),
        1,
        1,
      ),
      child: hijo,
    ),
  );
}

/// Escala al 97 % mientras se presiona.
class Presionable extends StatefulWidget {
  const Presionable({super.key, required this.child});

  final Widget child;

  @override
  State<Presionable> createState() => _PresionableState();
}

class _PresionableState extends State<Presionable> {
  bool _abajo = false;

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => setState(() => _abajo = true),
    onPointerUp: (_) => setState(() => _abajo = false),
    onPointerCancel: (_) => setState(() => _abajo = false),
    child: AnimatedScale(
      scale: _abajo && !sinMovimiento(context) ? 0.97 : 1,
      duration: const Duration(milliseconds: 180),
      curve: curvaAlmira,
      child: widget.child,
    ),
  );
}
