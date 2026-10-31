import { ETIQUETA_ESTADO_RECLAMO } from '@almira/shared';
import { Encabezado, Insignia, Tabla } from '../componentes';
import { datosDeMunicipalidad, useContextoPanel } from '../datos';

export function Reclamos() {
  const { municipalidadId, municipalidadNombre } = useContextoPanel();
  const { reclamos } = datosDeMunicipalidad(municipalidadId);

  return (
    <>
      <Encabezado titulo="Reclamos" subtitulo={municipalidadNombre} />
      <Tabla
        vacio={reclamos.length === 0}
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
              <Insignia tono={reclamo.estado === 'resuelto' ? 'exito' : 'atencion'}>
                {ETIQUETA_ESTADO_RECLAMO[reclamo.estado]}
              </Insignia>
            </td>
          </tr>
        ))}
      </Tabla>
    </>
  );
}
