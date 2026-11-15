import 'package:flutter/material.dart';

import '../../shared/models/modelos.dart';

/// Escudos de las municipalidades que tienen imagen en `assets/escudos/`, por nombre de distrito
/// en minúsculas y sin tildes. Una municipalidad que no está aquí no muestra escudo.
const _escudos = {'lince': 'assets/escudos/lince.png'};

String _clave(String distrito) => distrito
    .toLowerCase()
    .replaceAll('á', 'a')
    .replaceAll('é', 'e')
    .replaceAll('í', 'i')
    .replaceAll('ó', 'o')
    .replaceAll('ú', 'u')
    .trim();

/// Ruta del escudo de [municipalidad], o null si no tiene.
String? rutaEscudo(Municipalidad? municipalidad) =>
    municipalidad == null ? null : _escudos[_clave(municipalidad.distrito)];

/// Escudo de la municipalidad, de [alto] de alto. Si no tiene, no ocupa lugar.
class EscudoMunicipal extends StatelessWidget {
  const EscudoMunicipal(this.municipalidad, {super.key, this.alto = 40});

  final Municipalidad? municipalidad;
  final double alto;

  @override
  Widget build(BuildContext context) {
    final ruta = rutaEscudo(municipalidad);
    if (ruta == null) return const SizedBox.shrink();
    return ExcludeSemantics(
      child: Image.asset(ruta, height: alto, fit: BoxFit.contain, filterQuality: FilterQuality.medium, cacheHeight: (alto * 4).round()),
    );
  }
}
