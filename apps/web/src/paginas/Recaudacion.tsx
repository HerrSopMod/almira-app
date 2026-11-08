import { formatearNumero, formatearPorcentaje, formatearSoles, formatearVariacion } from '@almira/shared';
import { BarrasHorizontales, BarrasMensuales, Cifra, Encabezado, Tabla, Tarjeta } from '../componentes';
import { useSesion } from '../estado';

// Recaudación y pagos a tiempo (web-03). Solo cifras agregadas: ningún vecino
// aparece con nombre ni en rankings.
export function Recaudacion() {
  const { sesion } = useSesion();
  const { panel } = sesion;

  return (
    <>
      <Encabezado
        titulo="Recaudación y pagos a tiempo"
        subtitulo={`${panel.periodo} · Solo datos agregados, sin rankings de vecinos`}
      />

      <div className="cifras cifras-3">
        <Cifra
          etiqueta="Recaudado en el mes"
          valor={formatearSoles(panel.recaudacion.mes, { sinDecimales: true })}
          detalle={`${formatearVariacion(panel.recaudacion.variacionLineaBase)} frente a la línea base`}
        />
        <Cifra
          etiqueta="Pagos a tiempo"
          valor={formatearPorcentaje(panel.pagosATiempo.porcentaje)}
          detalle={`Meta: ${formatearPorcentaje(panel.pagosATiempo.meta)}`}
        />
        <Cifra
          etiqueta="Pagos por la app"
          valor={formatearNumero(panel.pagosApp.cantidad)}
          detalle={`${formatearVariacion(panel.pagosApp.variacionPresencial)} de atención presencial por trámite`}
        />
      </div>

      <div className="fila fila-2">
        <Tarjeta titulo="Recaudación mensual" subtitulo="Millones de soles, 2026.">
          <BarrasMensuales meses={panel.recaudacionMensual} />
        </Tarjeta>
        <Tarjeta titulo="Recaudación por zona" subtitulo={`${panel.periodo}, en miles de soles.`}>
          <BarrasHorizontales
            filas={panel.recaudacionPorZona.map((zona) => ({
              nombre: zona.zona,
              valor: zona.soles,
              etiqueta: formatearSoles(zona.soles, { enMiles: true }),
            }))}
          />
        </Tarjeta>
      </div>

      <Tarjeta titulo="Pagos a tiempo por tributo" subtitulo="Frente a la línea base del distrito.">
        <Tabla
          columnas={[
            { titulo: 'Tributo' },
            { titulo: 'Línea base' },
            { titulo: 'Actual' },
            { titulo: 'Meta' },
          ]}
        >
          {panel.pagosPorTributo.map((fila) => (
            <tr key={fila.tributo}>
              <td>
                <strong>{fila.tributo}</strong>
              </td>
              <td>{formatearPorcentaje(fila.lineaBasePct)}</td>
              <td>{formatearPorcentaje(fila.actualPct)}</td>
              <td>{formatearPorcentaje(fila.metaPct)}</td>
            </tr>
          ))}
        </Tabla>
      </Tarjeta>
    </>
  );
}
