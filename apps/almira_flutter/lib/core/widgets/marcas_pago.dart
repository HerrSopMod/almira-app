import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

/// Marcas de los medios de pago. Yape, Plin y Visa son las imágenes de `assets/marcas_pago/`;
/// Mastercard va dibujada con sus dos círculos, porque no hay imagen suya en el proyecto.
enum MarcaPago { yape, plin, visa, mastercard }

/// Marca de un medio de pago, de [alto] de alto.
class LogoMarca extends StatelessWidget {
  const LogoMarca(this.marca, {super.key, this.alto = 28});

  final MarcaPago marca;
  final double alto;

  @override
  Widget build(BuildContext context) => Semantics(
    label: switch (marca) {
      MarcaPago.yape => 'Yape',
      MarcaPago.plin => 'Plin',
      MarcaPago.visa => 'Visa',
      MarcaPago.mastercard => 'Mastercard',
    },
    excludeSemantics: true,
    child: switch (marca) {
      MarcaPago.yape => _Imagen('assets/marcas_pago/yape.png', ancho: alto, alto: alto, radio: alto * 0.24),
      MarcaPago.plin => _Imagen('assets/marcas_pago/plin.png', ancho: alto, alto: alto, radio: alto * 0.24),
      // La imagen de Visa es una tarjeta de 561 × 356.
      MarcaPago.visa => _Imagen('assets/marcas_pago/visa.png', ancho: alto * 561 / 356, alto: alto, radio: alto * 0.12, borde: true),
      MarcaPago.mastercard => _FichaMastercard(alto: alto),
    },
  );
}

class _Imagen extends StatelessWidget {
  const _Imagen(this.ruta, {required this.ancho, required this.alto, required this.radio, this.borde = false});

  final String ruta;
  final double ancho;
  final double alto;
  final double radio;
  final bool borde;

  @override
  Widget build(BuildContext context) => Container(
    width: ancho,
    height: alto,
    decoration: borde
        ? BoxDecoration(
            borderRadius: BorderRadius.circular(radio),
            border: Border.all(color: AppColors.border),
          )
        : null,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(radio),
      child: Image.asset(ruta, fit: BoxFit.cover, filterQuality: FilterQuality.medium, cacheHeight: 160),
    ),
  );
}

/// Ficha blanca con los dos círculos de Mastercard.
class _FichaMastercard extends StatelessWidget {
  const _FichaMastercard({required this.alto});

  final double alto;

  @override
  Widget build(BuildContext context) {
    final lado = alto * 0.5;
    return Container(
      width: alto * 561 / 356,
      height: alto,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(alto * 0.12),
        border: Border.all(color: AppColors.border),
      ),
      child: SizedBox(
        width: lado * 1.6,
        height: lado,
        child: Stack(
          children: [
            Positioned(left: 0, child: _Circulo(lado, AppColors.marcaMastercardRojo)),
            Positioned(right: 0, child: _Circulo(lado, AppColors.marcaMastercardNaranja.withValues(alpha: 0.9))),
          ],
        ),
      ),
    );
  }
}

class _Circulo extends StatelessWidget {
  const _Circulo(this.lado, this.color);

  final double lado;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Container(width: lado, height: lado, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
}

/// La marca de una tarjeta por su primer dígito: 4 es Visa, 5 y 2 son Mastercard. Sin más, null.
MarcaPago? marcaDeTarjeta(String numero) {
  final d = numero.replaceAll(RegExp(r'\D'), '');
  if (d.isEmpty) return null;
  if (d.startsWith('4')) return MarcaPago.visa;
  if (d.startsWith('5') || d.startsWith('2')) return MarcaPago.mastercard;
  return null;
}

/// Las marcas de tarjeta que se aceptan, en una fila pequeña.
class FilaMarcasTarjeta extends StatelessWidget {
  const FilaMarcasTarjeta({super.key});

  @override
  Widget build(BuildContext context) => const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      LogoMarca(MarcaPago.visa, alto: 22),
      SizedBox(width: AppSpacing.sm),
      LogoMarca(MarcaPago.mastercard, alto: 22),
    ],
  );
}
