import {
  HOY_EJEMPLO,
  formatearNumero,
  formatearPorcentaje,
  formatearSoles,
  haceDias,
  mejorVariante,
} from '@almira/shared';
import { Link } from 'react-router-dom';
import {
  BarrasHorizontales,
  BarrasMensuales,
  CajaIcono,
  Chip,
  Cifra,
  Encabezado,
  sube,
  Tarjeta,
} from '../componentes';
import { diasSinActualizar, pendientes, useSesion } from '../estado';
import { Icono, type NombreIcono } from '../iconos';

// Los reclamos vencidos van en rojo y las obras atrasadas en ámbar, como en web-02.
type Decision = {
  icono: NombreIcono;
  tono?: 'bad' | 'warn';
  titulo: string;
  detalle: string;
  ruta: string;
};

const plural = (n: number, singular: string, varios: string) => (n === 1 ? singular : varios);

// "Rentas", "Rentas y Depósito" o "Rentas, Obras y Depósito".
function enumerar(nombres: string[]): string {
  if (nombres.length <= 1) return nombres.join('');
  return `${nombres.slice(0, -1).join(', ')} y ${nombres[nombres.length - 1]}`;
}

export function PanelMunicipal() {
  const { sesion, datos } = useSesion();
  const { panel } = sesion;
  const { reclamosVencidos, casosEnCola } = pendientes({ sesion, datos });

  // Solo excepciones, calculadas con los datos en memoria del panel.
  const decisiones: Decision[] = [];
  if (reclamosVencidos.length > 0) {
    const n = reclamosVencidos.length;
    const areas = [...new Set(reclamosVencidos.map((r) => r.area ?? 'Sin área'))];
    decisiones.push({
      icono: 'reloj',
      tono: 'bad',
      titulo: `${n} ${plural(n, 'reclamo vencido', 'reclamos vencidos')}`,
      detalle: `${enumerar(areas)} ${plural(areas.length, 'superó', 'superaron')} su plazo`,
      ruta: '/reclamos',
    });
  }
  const obrasAtrasadas = datos.obras.filter(
    (obra) => obra.publicada && diasSinActualizar(obra) > panel.frecuenciaObrasDias,
  );
  const primeraAtrasada = obrasAtrasadas[0];
  if (primeraAtrasada) {
    const n = obrasAtrasadas.length;
    const otras = n > 1 ? ` y ${n - 1} más` : '';
    decisiones.push({
      icono: 'casco',
      tono: 'warn',
      titulo: `${n} ${plural(n, 'obra sin actualizar', 'obras sin actualizar')}`,
      detalle: `${primeraAtrasada.nombre}: ${haceDias(primeraAtrasada.actualizadaEn, HOY_EJEMPLO)}${otras}`,
      ruta: '/obras',
    });
  }
  const mejor = mejorVariante(panel.pruebaAB.variantes);
  if (mejor && !datos.varianteElegida) {
    decisiones.push({
      icono: 'matraz',
      titulo: 'Prueba A/B lista para decidir',
      detalle: `La variante ${mejor.letra} mejora el pago en ${mejor.puntos} puntos`,
      ruta: '/avisos',
    });
  }
  if (casosEnCola.length > 0) {
    const n = casosEnCola.length;
    const espera = Math.max(...casosEnCola.map((caso) => caso.esperaMinutos ?? 0));
    decisiones.push({
      icono: 'personas',
      titulo: `${n} ${plural(n, 'caso en cola humana', 'casos en cola humana')}`,
      detalle: `Espera máxima: ${espera} minutos`,
      ruta: '/atencion',
    });
  }

  const { aprendizaje } = panel;
  const ciclo = [
    { titulo: 'Recuerda', texto: `${formatearNumero(aprendizaje.avisosEntregados)} avisos entregados` },
    { titulo: 'Paga', texto: `${formatearNumero(aprendizaje.pagosApp)} pagos en la app` },
    { titulo: 'Ve la obra', texto: `${formatearNumero(aprendizaje.consultasMapa)} consultas al mapa` },
    {
      titulo: 'Reclama',
      texto: `${formatearNumero(aprendizaje.reclamosConEvidencia)} reclamos con evidencia`,
    },
    { titulo: 'Aprende', texto: aprendizaje.aprende },
  ];

  return (
    <>
      <Encabezado
        titulo="Panel municipal"
        subtitulo={`${panel.periodo} · Revisión mensual con Almira: ${panel.revisionMensual}`}
        extra={
          <Chip tono="info" icono="calendario">
            Ciclo: {panel.ciclo}
          </Chip>
        }
      />

      <div className="cifras cifras-4">
        <Cifra
          etiqueta="Recaudación"
          valor={formatearSoles(panel.recaudacion.mes, { sinDecimales: true })}
          tendencia={sube(formatearPorcentaje(panel.recaudacion.variacionLineaBase))}
          detalle="frente a la línea base"
        />
        <Cifra
          etiqueta="Pagos a tiempo"
          valor={formatearPorcentaje(panel.pagosATiempo.porcentaje)}
          tendencia={sube(`${panel.pagosATiempo.puntos} puntos`)}
          detalle={`· Meta: ${formatearPorcentaje(panel.pagosATiempo.meta)}`}
          avance={panel.pagosATiempo.porcentaje}
        />
        <Cifra
          etiqueta="Reclamos en plazo"
          valor={formatearPorcentaje(panel.reclamosEnPlazo.porcentaje)}
          tendencia={sube(`${panel.reclamosEnPlazo.puntos} puntos`)}
          detalle={`· Meta: ${formatearPorcentaje(panel.reclamosEnPlazo.meta)}`}
          avance={panel.reclamosEnPlazo.porcentaje}
        />
        <Cifra
          etiqueta="Avisos"
          valor={formatearNumero(panel.avisos.total)}
          detalle={`${formatearPorcentaje(panel.avisos.entregadosPct)} entregados · ${formatearPorcentaje(panel.avisos.pagaronPct)} pagó tras el aviso`}
        />
      </div>

      <div className="fila fila-decision">
        <Tarjeta
          titulo="Recaudación mensual"
          subtitulo="Millones de soles, 2026. Los picos coinciden con el vencimiento del predial."
        >
          <BarrasMensuales meses={panel.recaudacionMensual} />
        </Tarjeta>
        <Tarjeta
          titulo="Requiere tu decisión"
          subtitulo="Solo excepciones. La rutina la resuelve el S2 local."
          className="tarjeta-decision"
        >
          {decisiones.length > 0 ? (
            <ul className="decisiones">
              {decisiones.map((decision) => (
                <li key={decision.titulo}>
                  <Link to={decision.ruta}>
                    <CajaIcono icono={decision.icono} tono={decision.tono} />
                    <span className="decision-texto">
                      <strong>{decision.titulo}</strong>
                      <span>{decision.detalle}</span>
                    </span>
                    <Icono nombre="flecha" tamano="lg" />
                  </Link>
                </li>
              ))}
            </ul>
          ) : (
            <p className="subtitulo">No hay excepciones pendientes.</p>
          )}
        </Tarjeta>
      </div>

      <div className="fila fila-2">
        <Tarjeta titulo="Reclamos por área" subtitulo="Últimos 30 días.">
          <BarrasHorizontales
            filas={panel.reclamosPorArea.map((f) => ({ nombre: f.nombre, valor: f.cantidad }))}
          />
        </Tarjeta>
        <Tarjeta titulo="Reclamos más frecuentes" subtitulo="Últimos 30 días, por categoría.">
          <BarrasHorizontales
            filas={panel.reclamosFrecuentes.map((f) => ({ nombre: f.nombre, valor: f.cantidad }))}
          />
        </Tarjeta>
      </div>

      <Tarjeta titulo="Cómo aprende la municipalidad" subtitulo="Lo que pasó este mes en el ciclo del producto.">
        <ol className="ciclo">
          {ciclo.map((paso, indice) => (
            <li key={paso.titulo}>
              <strong>
                {indice + 1} · {paso.titulo}
              </strong>
              <span>{paso.texto}</span>
            </li>
          ))}
        </ol>
      </Tarjeta>
    </>
  );
}
