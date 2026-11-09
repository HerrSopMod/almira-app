import { formatearNumero, formatearPorcentaje, formatearSoles, formatearVariacion } from '@almira/shared';
import {
  BarrasHorizontales,
  BarrasMensuales,
  Cifra,
  Encabezado,
  sube,
  Tabla,
  Tarjeta,
} from '../componentes';
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
          tendencia={sube(formatearPorcentaje(panel.recaudacion.variacionLineaBase))}
          detalle="frente a la línea base"
        />
        <Cifra
          etiqueta="Pagos a tiempo"
          valor={formatearPorcentaje(panel.pagosATiempo.porcentaje)}
          detalle={`Meta: ${formatearPorcentaje(panel.pagosATiempo.meta)}`}
          avance={panel.pagosATiempo.porcentaje}
        />
        <Cifra
          etiqueta="Pagos por la app"
          valor={formatearNumero(panel.pagosApp.cantidad)}
          // Menos atención presencial es una mejora: va en verde, como en web-03.
          tendencia={formatearVariacion(panel.pagosApp.variacionPresencial)}
          detalle="de atención presencial por trámite"
        />
      </div>

      <div className="fila fila-2">
        <Tarjeta titulo="Recaudación mensual" subtitulo="Millones de soles, 2026.">
          <BarrasMensuales meses={panel.recaudacionMensual} />
        </Tarjeta>
        <Tarjeta titulo="Recaudación por zona" subtitulo={`${panel.periodo}, en miles de soles.`}>
          <BarrasHorizontales
            variante="zona"
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
            { titulo: 'Línea base', derecha: true },
            { titulo: 'Actual', derecha: true },
            { titulo: 'Meta', derecha: true },
          ]}
        >
          {panel.pagosPorTributo.map((fila) => (
            <tr key={fila.tributo}>
              <td className="fuerte">{fila.tributo}</td>
              <td className="monto">{formatearPorcentaje(fila.lineaBasePct)}</td>
              <td className="monto fuerte">{formatearPorcentaje(fila.actualPct)}</td>
              <td className="monto">{formatearPorcentaje(fila.metaPct)}</td>
            </tr>
          ))}
        </Tabla>
      </Tarjeta>
    </>
  );
}
