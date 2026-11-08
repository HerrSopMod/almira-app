import { recordatorios as recordatoriosTodos, vecinos as vecinosTodos } from '@almira/shared';
import {
  ETIQUETA_CANAL,
  ETIQUETA_ESTADO_RECORDATORIO,
  ETIQUETA_TIPO_RECORDATORIO,
  formatearFechaCorta,
} from '@almira/shared';
import { Chip, Encabezado, Tabla } from '../componentes';
import { useSesion } from '../estado';

export function Recordatorios() {
  const { sesion } = useSesion();
  const municipalidadNombre = sesion.municipalidad.nombre;
  const propios = <T extends { municipalidadId: string }>(filas: T[]) =>
    filas.filter((fila) => fila.municipalidadId === sesion.municipalidad.id);
  const recordatorios = propios(recordatoriosTodos);
  const vecinos = propios(vecinosTodos);

  return (
    <>
      <Encabezado titulo="Recordatorios" subtitulo={municipalidadNombre} />
      <Tabla
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
              <Chip tono={aviso.estado === 'entregado' ? 'verde' : 'amarillo'}>
                {ETIQUETA_ESTADO_RECORDATORIO[aviso.estado]}
              </Chip>
            </td>
          </tr>
        ))}
      </Tabla>
    </>
  );
}
