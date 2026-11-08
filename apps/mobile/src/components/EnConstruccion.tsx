import { colors } from '@almira/shared';
import { BarraSuperior } from './BarraSuperior';
import { Pantalla } from './Pantalla';
import { Texto } from './Texto';

// Pantalla provisional para las pantallas del prototipo que aún no se construyen.
export function EnConstruccion({ titulo }: { titulo: string }) {
  return (
    <Pantalla encabezadoHastaArriba encabezado={<BarraSuperior titulo={titulo} />}>
      <Texto color={colors.textSecondary} alineacion="center">
        Esta pantalla está en construcción.
      </Texto>
    </Pantalla>
  );
}
