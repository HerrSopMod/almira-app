import { pagos as pagosTodos, deudas as deudasTodos, vecinos as vecinosTodos } from '@almira/shared';
import {
  ETIQUETA_ESTADO_DEUDA,
  ETIQUETA_ESTADO_PAGO,
  ETIQUETA_MEDIO_PAGO,
  deudasPendientes,
  formatearFechaCorta,
  formatearSoles,
  totalDeuda,
} from '@almira/shared';
import { Chip, Encabezado, Tabla } from '../componentes';
import { useSesion } from '../estado';

export function Recaudacion() {
  const { sesion } = useSesion();
  const municipalidadNombre = sesion.municipalidad.nombre;
  const propios = <T extends { municipalidadId: string }>(filas: T[]) =>
    filas.filter((fila) => fila.municipalidadId === sesion.municipalidad.id);
  const pagos = propios(pagosTodos);
  const deudas = propios(deudasTodos);
  const vecinos = propios(vecinosTodos);
  const nombreVecino = (id: string) => vecinos.find((vecino) => vecino.id === id)?.nombre ?? '';
  const conceptoDeuda = (id: string) => deudas.find((deuda) => deuda.id === id)?.concepto ?? '';

  return (
    <>
      <Encabezado titulo="Recaudación" subtitulo={municipalidadNombre} />
      <h2>Pagos recibidos</h2>
      <Tabla
        columnas={[
          { titulo: 'Fecha' },
          { titulo: 'Vecino' },
          { titulo: 'Concepto' },
          { titulo: 'Medio de pago' },
          { titulo: 'Estado' },
          { titulo: 'Monto', derecha: true },
        ]}
      >
        {pagos.map((pago) => (
          <tr key={pago.id}>
            <td>{formatearFechaCorta(pago.creadoEn)}</td>
            <td>{nombreVecino(pago.vecinoId)}</td>
            <td>{conceptoDeuda(pago.deudaId)}</td>
            <td>{ETIQUETA_MEDIO_PAGO[pago.medio]}</td>
            <td>
              <Chip tono={pago.estado === 'confirmado' ? 'verde' : 'amarillo'}>
                {ETIQUETA_ESTADO_PAGO[pago.estado]}
              </Chip>
            </td>
            <td className="monto">{formatearSoles(pago.monto)}</td>
          </tr>
        ))}
      </Tabla>

      <h2>Deudas pendientes</h2>
      <Tabla
        columnas={[
          { titulo: 'Vecino' },
          { titulo: 'Concepto' },
          { titulo: 'Vencimiento' },
          { titulo: 'Estado' },
          { titulo: 'Total', derecha: true },
        ]}
      >
        {deudasPendientes(deudas).map((deuda) => (
          <tr key={deuda.id}>
            <td>{nombreVecino(deuda.vecinoId)}</td>
            <td>{deuda.concepto}</td>
            <td>{formatearFechaCorta(deuda.vencimiento)}</td>
            <td>
              <Chip tono={deuda.estado === 'vencida' ? 'rojo' : 'amarillo'}>
                {ETIQUETA_ESTADO_DEUDA[deuda.estado]}
              </Chip>
            </td>
            <td className="monto">{formatearSoles(totalDeuda(deuda))}</td>
          </tr>
        ))}
      </Tabla>
    </>
  );
}
