import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../core/widgets/componentes.dart';

class _Destino {
  const _Destino(this.etiqueta, this.icono, this.iconoActivo);
  final String etiqueta;
  final IconData icono;
  final IconData iconoActivo;
}

// Una sola familia de íconos, redondeada: contorno en reposo, relleno al elegir.
const _destinos = [
  _Destino('Inicio', Icons.home_outlined, Icons.home_rounded),
  _Destino('Pagar', Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded),
  _Destino('Reclamos', Icons.campaign_outlined, Icons.campaign_rounded),
  _Destino('Obras', Icons.map_outlined, Icons.map_rounded),
  _Destino('Asistente', Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded),
];

/// Marco de las cinco secciones principales, con la barra inferior.
/// Cada pestaña conserva su estado (filtro, scroll, pantalla abierta).
class ShellPrincipal extends StatelessWidget {
  const ShellPrincipal({super.key, required this.navegacion});

  final StatefulNavigationShell navegacion;

  @override
  Widget build(BuildContext context) {
    // Con el teclado abierto la barra se oculta: no roba espacio ni salta.
    final conTeclado = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      body: navegacion,
      bottomNavigationBar: conTeclado
          ? null
          : DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              // Las etiquetas de la barra son de una sola palabra y el ancho es fijo: se limita el
              // aumento de letra a 1.15 para que «Reclamos» no se parta.
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.15),
                ),
                child: NavigationBar(
                selectedIndex: navegacion.currentIndex,
                animationDuration: duracionDe(context, 220),
                onDestinationSelected: (indice) => navegacion.goBranch(
                  indice,
                  // Tocar la pestaña ya elegida vuelve a su pantalla principal.
                  initialLocation: indice == navegacion.currentIndex,
                ),
                destinations: [
                  for (final d in _destinos)
                    NavigationDestination(
                      icon: Icon(d.icono),
                      selectedIcon: Icon(d.iconoActivo),
                      label: d.etiqueta,
                      tooltip: d.etiqueta,
                    ),
                ],
              ),
              ),
            ),
    );
  }
}
