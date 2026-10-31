import { ETIQUETA_ESTADO_OBRA, formatearSoles } from '@almira/shared';
import { Encabezado, Insignia, Progreso, Tabla } from '../componentes';
import { datosDeMunicipalidad, useContextoPanel } from '../datos';

export function Obras() {
  const { municipalidadId, municipalidadNombre } = useContextoPanel();
  const { obras } = datosDeMunicipalidad(municipalidadId);

  return (
    <>
      <Encabezado titulo="Obras" subtitulo={municipalidadNombre} />
      <Tabla
        vacio={obras.length === 0}
        columnas={[
          { titulo: 'Obra' },
          { titulo: 'Ubicación' },
          { titulo: 'Estado' },
          { titulo: 'Avance físico' },
          { titulo: 'Meta' },
          { titulo: 'Asignado', monto: true },
          { titulo: 'Ejecutado', monto: true },
        ]}
      >
        {obras.map((obra) => (
          <tr key={obra.id}>
            <td>{obra.nombre}</td>
            <td>{obra.ubicacion}</td>
            <td>
              <Insignia tono={obra.estado === 'finalizada' ? 'exito' : 'atencion'}>
                {ETIQUETA_ESTADO_OBRA[obra.estado]}
              </Insignia>
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
