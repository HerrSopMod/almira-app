import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';
import 'componentes.dart';

/// Contenido de un formulario en una pantalla con scroll, para que el teclado no tape nada. El
/// `Scaffold` ya reduce el espacio cuando sale el teclado; además, al enfocar un campo, el
/// contenido se desplaza (150 ms) para que el campo se vea completo y, debajo, su botón.
class ScrollFormulario extends StatefulWidget {
  const ScrollFormulario({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.margen),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  State<ScrollFormulario> createState() => _ScrollFormularioState();
}

class _ScrollFormularioState extends State<ScrollFormulario> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_alCambiarElFoco);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_alCambiarElFoco);
    _scroll.dispose();
    super.dispose();
  }

  void _alCambiarElFoco() {
    final contexto = FocusManager.instance.primaryFocus?.context;
    if (contexto == null || !mounted) return;
    // Solo los campos de este formulario (el campo de texto tiene su propio scroll interno, así
    // que se busca hacia arriba este estado y no el `Scrollable` más cercano).
    if (contexto.findAncestorStateOfType<_ScrollFormularioState>() != this) return;
    // Se espera a que el teclado termine de abrirse para medir bien.
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      final actual = FocusManager.instance.primaryFocus?.context;
      if (!mounted || actual == null || !actual.mounted) return;
      if (!_scroll.hasClients) return;
      Scrollable.ensureVisible(
        actual,
        alignment: 0.2,
        duration: duracionDe(context, 150),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        controller: _scroll,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: widget.padding,
        child: widget.child,
      );
}
