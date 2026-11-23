import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';
import '../../core/utils/formato.dart';
import '../../core/utils/plazos.dart';
import '../../core/widgets/componentes.dart';

// Piezas de Reclamos, Obras y Perfil que la base (`componentes.dart`) aún no trae.

/// Fecha de respuesta de un reclamo abierto, para [TextoPlazo]. Reemplaza a la píldora
/// «Quedan N días hábiles».
String textoPlazo(Plazo plazo) {
  final limite = plazo.limite;
  return switch (plazo.estado) {
    EstadoPlazo.porConfirmar => 'Fecha de respuesta por confirmar',
    EstadoPlazo.venceHoy => 'Respuesta hasta hoy',
    EstadoPlazo.vencido => limite == null ? 'Plazo de respuesta vencido' : 'Respuesta vencida el ${diaYMes(limite)}',
    _ => limite == null ? 'Fecha de respuesta por confirmar' : 'Respuesta hasta el ${diaYMes(limite)}',
  };
}

/// Línea de plazo de un reclamo abierto: gris, o roja si ya venció.
class PlazoReclamo extends StatelessWidget {
  const PlazoReclamo(this.plazo, {super.key});

  final Plazo plazo;

  @override
  Widget build(BuildContext context) =>
      TextoPlazo(textoPlazo(plazo), vencido: plazo.estado == EstadoPlazo.vencido);
}

/// Filas ([FilaLista], [FilaInterruptor]) en una tarjeta blanca, con un divisor de 1 px entre
/// ellas (rediseño).
class ListaFilas extends StatelessWidget {
  const ListaFilas({super.key, required this.filas});

  final List<Widget> filas;

  @override
  Widget build(BuildContext context) => GrupoTarjeta(filas: filas);
}

/// Línea gris de 13 para el `detalle` de [FilaLista].
class DetalleFila extends StatelessWidget {
  const DetalleFila(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) => Text(texto, style: Theme.of(context).textTheme.bodyMedium);
}

/// Fila con interruptor, con las medidas de [FilaLista]: título 15/500, detalle gris de 13 y
/// el interruptor a la derecha. Tocar la fila cambia el valor; con [alTocar], hace otra cosa
/// (por ejemplo, gestionar lo que ya está activo).
class FilaInterruptor extends StatelessWidget {
  const FilaInterruptor({
    super.key,
    required this.titulo,
    required this.valor,
    required this.alCambiar,
    this.detalle,
    this.alTocar,
    this.inicio,
  });

  final String titulo;
  final String? detalle;
  final Widget? inicio;
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
          constraints: const BoxConstraints(minHeight: AppSpacing.cajaGrande),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              children: [
                if (inicio != null) ...[inicio!, const SizedBox(width: AppSpacing.md)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(titulo, style: textos.titleMedium),
                      if (detalle != null) ...[
                        const SizedBox(height: 2),
                        Text(detalle!, style: textos.bodyMedium),
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
