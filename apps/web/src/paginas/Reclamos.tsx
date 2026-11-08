import { reclamos as reclamosTodos } from '@almira/shared';
import { ETIQUETA_ESTADO_RECLAMO } from '@almira/shared';
import { Chip, Encabezado, Tabla } from '../componentes';
import { useSesion } from '../estado';

export function Reclamos() {
  const { sesion } = useSesion();
  const municipalidadNombre = sesion.municipalidad.nombre;
  const propios = <T extends { municipalidadId: string }>(filas: T[]) =>
    filas.filter((fila) => fila.municipalidadId === sesion.municipalidad.id);
  const reclamos = propios(reclamosTodos);

  return (
    <>
      <Encabezado titulo="Reclamos" subtitulo={municipalidadNombre} />
      <Tabla
        columnas={[
          { titulo: 'Código' },
          { titulo: 'Reclamo' },
          { titulo: 'Área' },
          { titulo: 'Plazo' },
          { titulo: 'Estado' },
        ]}
      >
        {reclamos.map((reclamo) => (
          <tr key={reclamo.id}>
            <td>{reclamo.codigo}</td>
            <td>{reclamo.titulo}</td>
            <td>{reclamo.area}</td>
            <td>{reclamo.plazo}</td>
            <td>
              <Chip tono={reclamo.estado === 'resuelto' ? 'verde' : 'amarillo'}>
                {ETIQUETA_ESTADO_RECLAMO[reclamo.estado]}
              </Chip>
            </td>
          </tr>
        ))}
      </Tabla>
    </>
  );
}
