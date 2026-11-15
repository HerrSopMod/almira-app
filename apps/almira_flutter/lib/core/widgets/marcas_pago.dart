import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

/// Marcas de los medios de pago, dibujadas en código: el color y el nombre de cada una, no sus
/// logos oficiales. Para usar los oficiales, cambia el contenido de estos widgets por la imagen
/// que entregue cada marca.
enum MarcaPago { yape, visa, mastercard }

/// Marca de un medio de pago en una ficha de [alto] de alto.
class LogoMarca extends StatelessWidget {
  const LogoMarca(this.marca, {super.key, this.alto = 28});

  final MarcaPago marca;
  final double alto;

  @override
  Widget build(BuildContext context) => Semantics(
    label: switch (marca) {
      MarcaPago.yape => 'Yape',
      MarcaPago.visa => 'Visa',
      MarcaPago.mastercard => 'Mastercard',
    },
    excludeSemantics: true,
    child: switch (marca) {
      MarcaPago.yape => _FichaYape(alto: alto),
      MarcaPago.visa => _FichaBlanca(
        alto: alto,
        child: Text(
          'VISA',
          style: TextStyle(
            color: AppColors.marcaVisa,
            fontSize: alto * 0.42,
            fontWeight: FontWeight.w800,
            fontStyle: FontStyle.italic,
            letterSpacing: 0.4,
            height: 1,
          ),
        ),
      ),
      MarcaPago.mastercard => _FichaBlanca(alto: alto, child: _CirculosMastercard(lado: alto * 0.5)),
    },
  );
}

/// Ficha cuadrada morada con «yape» en blanco.
class _FichaYape extends StatelessWidget {
  const _FichaYape({required this.alto});

  final double alto;

  @override
  Widget build(BuildContext context) => Container(
    width: alto * 1.4,
    height: alto,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.marcaYape,
      borderRadius: BorderRadius.circular(alto * 0.28),
    ),
    child: Text(
      'yape',
      style: TextStyle(color: AppColors.onPrimary, fontSize: alto * 0.42, fontWeight: FontWeight.w800, height: 1),
    ),
  );
}

/// Ficha blanca con borde fino, para las marcas que van sobre fondo claro.
class _FichaBlanca extends StatelessWidget {
  const _FichaBlanca({required this.alto, required this.child});

  final double alto;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: alto * 1.4,
    height: alto,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(alto * 0.22),
      border: Border.all(color: AppColors.border),
    ),
    child: child,
  );
}

class _CirculosMastercard extends StatelessWidget {
  const _CirculosMastercard({required this.lado});

  final double lado;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: lado * 1.6,
    height: lado,
    child: Stack(
      children: [
        Positioned(left: 0, child: _Circulo(lado, AppColors.marcaMastercardRojo)),
        Positioned(
          right: 0,
          child: _Circulo(lado, AppColors.marcaMastercardNaranja.withValues(alpha: 0.9)),
        ),
      ],
    ),
  );
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
      SizedBox(width: AppSpacing.xs),
      LogoMarca(MarcaPago.mastercard, alto: 22),
    ],
  );
}
