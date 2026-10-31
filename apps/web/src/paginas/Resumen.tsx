import { deudasPendientes, formatearSoles, sumarDeudas } from '@almira/shared';
import { Encabezado, Indicador } from '../componentes';
import { datosDeMunicipalidad, useContextoPanel } from '../datos';

export function Resumen() {
  const { municipalidadId, municipalidadNombre } = useContextoPanel();
  const { deudas, pagos, reclamos, obras } = datosDeMunicipalidad(municipalidadId);

  const recaudado = pagos
    .filter((pago) => pago.estado === 'confirmado')
    .reduce((suma, pago) => suma + pago.monto, 0);
  const reclamosAbiertos = reclamos.filter((reclamo) => reclamo.estado !== 'resuelto').length;
  const obrasEnEjecucion = obras.filter((obra) => obra.estado === 'en_ejecucion').length;

  return (
    <>
      <Encabezado titulo="Resumen" subtitulo={municipalidadNombre} />
      <section className="indicadores" aria-label="Indicadores">
        <Indicador etiqueta="Deuda pendiente" valor={formatearSoles(sumarDeudas(deudasPendientes(deudas)))} />
        <Indicador etiqueta="Recaudado" valor={formatearSoles(recaudado)} />
        <Indicador etiqueta="Reclamos abiertos" valor={String(reclamosAbiertos)} />
        <Indicador etiqueta="Obras en ejecución" valor={String(obrasEnEjecucion)} />
      </section>
    </>
  );
}
