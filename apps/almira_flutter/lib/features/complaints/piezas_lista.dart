import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/iconos.dart';
import '../../core/utils/formato.dart';
import '../../core/utils/plazos.dart';

/// Escala de lectura de las pantallas de Reclamos, Obras, Asistente y Perfil: título 20,
/// cuerpo 15 y secundario 13. Sale de los estilos del tema y solo ajusta el tamaño.
/// Pendiente: que el tema (`lib/app/theme`) los incorpore y este archivo los tome de ahí.
extension EscalaLectura on TextTheme {
  /// Título de tarjeta o de cabecera de detalle: 20 / 28, 600.
  TextStyle get titulo20 => titleLarge!.copyWith(fontSize: 20, height: 28 / 20);

  /// Cuerpo: 15 / 22.
  TextStyle get cuerpo15 => bodyLarge!.copyWith(fontSize: 15, height: 22 / 15);

  /// Nombre de una fila de lista: 15 / 22, 500.
  TextStyle get fila15 => cuerpo15.copyWith(fontWeight: FontWeight.w500);

  /// Secundario: 13 / 18, gris.
  TextStyle get secundario13 => bodyMedium!.copyWith(fontSize: 13, height: 18 / 13);
}

/// Fila de lista: nombre 15/500, línea gris 13, monto opcional a la derecha y flecha.
/// Las filas van sueltas sobre el fondo blanco, separadas por un divisor de 1 px.
class FilaLista extends StatelessWidget {
  const FilaLista({
    super.key,
    required this.titulo,
    this.detalle,
    this.estiloDetalle,
    this.debajo,
    this.monto,
    this.final_,
    this.alTocar,
    this.semantica,
  });

  final String titulo;
  final String? detalle;

  /// Para pintar la línea secundaria en un color de estado (plazo vencido).
  final TextStyle? estiloDetalle;

  /// Un elemento bajo la línea gris, por ejemplo una insignia de estado.
  final Widget? debajo;
  final String? monto;

  /// Lo que va antes de la flecha (una insignia, por ejemplo).
  final Widget? final_;
  final VoidCallback? alTocar;
  final String? semantica;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final fila = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSpacing.cajaGrande + AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(titulo, style: textos.fila15, maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (detalle != null) ...[
                    const SizedBox(height: 2),
                    Text(detalle!, style: estiloDetalle ?? textos.secundario13),
                  ],
                  if (debajo != null) ...[const SizedBox(height: AppSpacing.sm), debajo!],
                ],
              ),
            ),
            if (monto != null) ...[
              const SizedBox(width: AppSpacing.md),
              Text(
                monto!,
                textAlign: TextAlign.end,
                style: textos.fila15.copyWith(fontWeight: FontWeight.w600, fontFeatures: cifrasTabulares),
              ),
            ],
            if (final_ != null) ...[const SizedBox(width: AppSpacing.md), final_!],
            if (alTocar != null) ...[
              const SizedBox(width: AppSpacing.sm),
              const Icon(Phosphor.caretRight, size: AppIconos.lista, color: AppColors.textSecondary),
            ],
          ],
        ),
      ),
    );
    if (alTocar == null) return fila;
    return Semantics(
      button: true,
      label: semantica,
      excludeSemantics: semantica != null,
      child: InkWell(onTap: alTocar, child: fila),
    );
  }
}

/// Lista de [FilaLista] con divisores de 1 px entre filas, sin caja alrededor.
class ListaFilas extends StatelessWidget {
  const ListaFilas({super.key, required this.filas});

  final List<Widget> filas;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, fila) in filas.indexed) ...[
            if (i > 0) const Divider(),
            fila,
          ],
        ],
      );
}

/// Ficha de datos: cada dato con su rótulo gris pequeño arriba y el valor debajo, a todo
/// el ancho. Sin columnas ni bordes.
class FichaDatos extends StatelessWidget {
  const FichaDatos(this.datos, {super.key});

  final List<(String rotulo, String valor)> datos;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, (rotulo, valor)) in datos.indexed) ...[
          if (i > 0) const SizedBox(height: AppSpacing.lg),
          MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rotulo, style: textos.secundario13),
                const SizedBox(height: 2),
                Text(valor, style: textos.fila15),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Fecha de respuesta de un reclamo abierto, en una línea gris. Si ya venció, en rojo.
/// Reemplaza a la píldora «Quedan N días hábiles».
String textoPlazo(Plazo plazo) {
  final limite = plazo.limite;
  return switch (plazo.estado) {
    EstadoPlazo.porConfirmar => 'Fecha de respuesta por confirmar',
    EstadoPlazo.venceHoy => 'Respuesta hasta hoy',
    EstadoPlazo.vencido => limite == null ? 'Plazo de respuesta vencido' : 'Respuesta vencida el ${diaYMes(limite)}',
    _ => limite == null ? 'Fecha de respuesta por confirmar' : 'Respuesta hasta el ${diaYMes(limite)}',
  };
}

TextStyle estiloPlazo(BuildContext context, Plazo plazo) {
  final base = Theme.of(context).textTheme.secundario13;
  return plazo.estado == EstadoPlazo.vencido ? base.copyWith(color: AppColors.error) : base;
}

class LineaPlazo extends StatelessWidget {
  const LineaPlazo(this.plazo, {super.key});

  final Plazo plazo;

  @override
  Widget build(BuildContext context) => Text(textoPlazo(plazo), style: estiloPlazo(context, plazo));
}

/// Monto en una fila: rótulo 15 a la izquierda y el monto a la derecha, en cifras tabulares.
/// [nota] va en gris bajo el monto.
class FilaMonto extends StatelessWidget {
  const FilaMonto(this.rotulo, this.monto, {super.key, this.nota});

  final String rotulo;
  final String monto;
  final String? nota;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(rotulo, style: textos.cuerpo15.copyWith(color: AppColors.textSecondary))),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(monto, style: textos.fila15.copyWith(fontWeight: FontWeight.w600, fontFeatures: cifrasTabulares)),
                if (nota != null) Text(nota!, style: textos.secundario13),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Nombre de persona en tipo título: «ROSA QUISPE DE LA CRUZ» -> «Rosa Quispe de la Cruz».
String nombrePropio(String nombre) {
  const enlaces = {'de', 'del', 'la', 'las', 'los', 'y'};
  final palabras = nombre.trim().toLowerCase().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  return [
    for (final (i, p) in palabras.indexed)
      i > 0 && enlaces.contains(p) ? p : p[0].toUpperCase() + p.substring(1),
  ].join(' ');
}

/// Fila con interruptor: título 15/500, detalle gris 13 y el interruptor a la derecha.
/// Toda la fila cambia el valor; con [alTocar], tocar el texto hace otra cosa (gestionar).
class FilaInterruptor extends StatelessWidget {
  const FilaInterruptor({
    super.key,
    required this.titulo,
    required this.valor,
    required this.alCambiar,
    this.detalle,
    this.alTocar,
  });

  final String titulo;
  final String? detalle;
  final bool valor;
  final ValueChanged<bool>? alCambiar;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final cambiar = alCambiar;
    return MergeSemantics(
      child: InkWell(
      onTap: alTocar ?? (cambiar == null ? null : () => cambiar(!valor)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.cajaGrande + AppSpacing.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(titulo, style: textos.fila15),
                    if (detalle != null) ...[
                      const SizedBox(height: 2),
                      Text(detalle!, style: textos.secundario13),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Switch(value: valor, onChanged: alCambiar),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
