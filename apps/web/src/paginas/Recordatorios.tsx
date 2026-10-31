import {
  ETIQUETA_CANAL,
  ETIQUETA_ESTADO_RECORDATORIO,
  ETIQUETA_TIPO_RECORDATORIO,
  formatearFechaCorta,
} from '@almira/shared';
import { Encabezado, Insignia, Tabla } from '../componentes';
import { datosDeMunicipalidad, useContextoPanel } from '../datos';

export function Recordatorios() {
  const { municipalidadId, municipalidadNombre } = useContextoPanel();
  const { recordatorios, vecinos } = datosDeMunicipalidad(municipalidadId);

  return (
    <>
      <Encabezado titulo="Recordatorios" subtitulo={municipalidadNombre} />
      <Tabla
        vacio={recordatorios.length === 0}
        columnas={[
          { titulo: 'Código' },
          { titulo: 'Vecino' },
          { titulo: 'Tipo' },
          { titulo: 'Canal' },
          { titulo: 'Fecha' },
          { titulo: 'Estado' },
        ]}
      >
        {recordatorios.map((aviso) => (
          <tr key={aviso.id}>
            <td>{aviso.codigo}</td>
            <td>{vecinos.find((vecino) => vecino.id === aviso.vecinoId)?.nombre}</td>
            <td>{ETIQUETA_TIPO_RECORDATORIO[aviso.tipo]}</td>
            <td>{ETIQUETA_CANAL[aviso.canal]}</td>
            <td>{formatearFechaCorta(aviso.entregadoEn ?? aviso.programadoPara)}</td>
            <td>
              <Insignia tono={aviso.estado === 'entregado' ? 'exito' : 'atencion'}>
                {ETIQUETA_ESTADO_RECORDATORIO[aviso.estado]}
              </Insignia>
            </td>
          </tr>
        ))}
      </Tabla>
    </>
  );
}
