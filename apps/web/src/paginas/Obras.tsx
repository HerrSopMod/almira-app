import { obras as obrasTodos } from '@almira/shared';
import { ETIQUETA_ESTADO_OBRA, formatearSoles } from '@almira/shared';
import { Chip, Encabezado, Progreso, Tabla } from '../componentes';
import { useSesion } from '../estado';

export function Obras() {
  const { sesion } = useSesion();
  const municipalidadNombre = sesion.municipalidad.nombre;
  const propios = <T extends { municipalidadId: string }>(filas: T[]) =>
    filas.filter((fila) => fila.municipalidadId === sesion.municipalidad.id);
  const obras = propios(obrasTodos);

  return (
    <>
      <Encabezado titulo="Obras" subtitulo={municipalidadNombre} />
      <Tabla
        columnas={[
          { titulo: 'Obra' },
          { titulo: 'Ubicación' },
          { titulo: 'Estado' },
          { titulo: 'Avance físico' },
          { titulo: 'Meta' },
          { titulo: 'Asignado', derecha: true },
          { titulo: 'Ejecutado', derecha: true },
        ]}
      >
        {obras.map((obra) => (
          <tr key={obra.id}>
            <td>{obra.nombre}</td>
            <td>{obra.ubicacion}</td>
            <td>
              <Chip tono={obra.estado === 'finalizada' ? 'verde' : 'amarillo'}>
                {ETIQUETA_ESTADO_OBRA[obra.estado]}
              </Chip>
            </td>
            <td>
              <Progreso porcentaje={obra.avancePct} /> {obra.avancePct}%
            </td>
            <td>{obra.meta}</td>
            <td className="monto">{formatearSoles(obra.montoAsignado)}</td>
            <td className="monto">{formatearSoles(obra.montoEjecutado)}</td>
          </tr>
        ))}
      </Tabla>
    </>
  );
}
