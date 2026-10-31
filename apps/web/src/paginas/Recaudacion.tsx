import {
  ETIQUETA_ESTADO_DEUDA,
  ETIQUETA_ESTADO_PAGO,
  ETIQUETA_MEDIO_PAGO,
  deudasPendientes,
  formatearFechaCorta,
  formatearSoles,
  totalDeuda,
} from '@almira/shared';
import { Encabezado, Insignia, Tabla } from '../componentes';
import { datosDeMunicipalidad, useContextoPanel } from '../datos';

export function Recaudacion() {
  const { municipalidadId, municipalidadNombre } = useContextoPanel();
  const { pagos, deudas, vecinos } = datosDeMunicipalidad(municipalidadId);
  const nombreVecino = (id: string) => vecinos.find((vecino) => vecino.id === id)?.nombre ?? '';
  const conceptoDeuda = (id: string) => deudas.find((deuda) => deuda.id === id)?.concepto ?? '';

  return (
    <>
      <Encabezado titulo="Recaudación" subtitulo={municipalidadNombre} />
      <h2>Pagos recibidos</h2>
      <Tabla
        vacio={pagos.length === 0}
        columnas={[
          { titulo: 'Fecha' },
          { titulo: 'Vecino' },
          { titulo: 'Concepto' },
          { titulo: 'Medio de pago' },
          { titulo: 'Estado' },
          { titulo: 'Monto', monto: true },
        ]}
      >
        {pagos.map((pago) => (
          <tr key={pago.id}>
            <td>{formatearFechaCorta(pago.creadoEn)}</td>
            <td>{nombreVecino(pago.vecinoId)}</td>
            <td>{conceptoDeuda(pago.deudaId)}</td>
            <td>{ETIQUETA_MEDIO_PAGO[pago.medio]}</td>
            <td>
              <Insignia tono={pago.estado === 'confirmado' ? 'exito' : 'atencion'}>
                {ETIQUETA_ESTADO_PAGO[pago.estado]}
              </Insignia>
            </td>
            <td className="monto">{formatearSoles(pago.monto)}</td>
          </tr>
        ))}
      </Tabla>

      <h2>Deudas pendientes</h2>
      <Tabla
        vacio={deudasPendientes(deudas).length === 0}
        columnas={[
          { titulo: 'Vecino' },
          { titulo: 'Concepto' },
          { titulo: 'Vencimiento' },
          { titulo: 'Estado' },
          { titulo: 'Total', monto: true },
        ]}
      >
        {deudasPendientes(deudas).map((deuda) => (
          <tr key={deuda.id}>
            <td>{nombreVecino(deuda.vecinoId)}</td>
            <td>{deuda.concepto}</td>
            <td>{formatearFechaCorta(deuda.vencimiento)}</td>
            <td>
              <Insignia tono={deuda.estado === 'vencida' ? 'critico' : 'exito'}>
                {ETIQUETA_ESTADO_DEUDA[deuda.estado]}
              </Insignia>
            </td>
            <td className="monto">{formatearSoles(totalDeuda(deuda))}</td>
          </tr>
        ))}
      </Tabla>
    </>
  );
}
