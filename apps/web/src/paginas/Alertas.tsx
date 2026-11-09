import { formatearNumero, formatearPorcentaje, superaUmbral, type Umbral } from '@almira/shared';
import { useState } from 'react';
import {
  AlertaActiva,
  BarrasHorizontales,
  Chip,
  Encabezado,
  Interruptor,
  MensajeMemoria,
  NotaEjemplo,
  Tabla,
  Tarjeta,
} from '../componentes';
import { useSesion } from '../estado';

function textoUmbral({ umbral, unidad }: Umbral): string {
  if (unidad === '%') return formatearPorcentaje(umbral);
  if (unidad === 'evento') return `${formatearNumero(umbral)} ${umbral === 1 ? 'evento' : 'eventos'}`;
  return `${formatearNumero(umbral)} por semana`;
}

const textoHoy = ({ hoy, unidad }: Umbral) =>
  unidad === '%' ? formatearPorcentaje(hoy) : formatearNumero(hoy);

// Alertas y auditoría (web-08). Todo es de ejemplo: no hay alertas ni
// auditorías reales conectadas al panel.
export function Alertas() {
  const { sesion, datos, cambiarDatos } = useSesion();
  const { panel } = sesion;
  const [mensaje, setMensaje] = useState<string | null>(null);

  const alternarSimulador = () => {
    cambiarDatos((actual) => ({ ...actual, simuladorActivo: !actual.simuladorActivo }));
    setMensaje('Cambio de ejemplo: no se guarda y el simulador de la app no cambia.');
  };

  return (
    <>
      <Encabezado
        titulo="Alertas y auditoría"
        subtitulo="Canal algedónico y control independiente (S3*)"
      />

      {panel.alertasActivas.map((alerta) => (
        <AlertaActiva key={alerta}>
          <strong>Alerta activa:</strong> {alerta}
        </AlertaActiva>
      ))}

      <Tarjeta titulo="Ruta de un incidente" subtitulo="Cómo sube desde la unidad hasta el S5.">
        <ol className="ciclo">
          {panel.rutaIncidente.map((paso) => (
            <li key={paso.titulo}>
              <strong>{paso.titulo}</strong>
              <span>{paso.texto}</span>
            </li>
          ))}
        </ol>
      </Tarjeta>

      <div className="fila fila-2">
        <Tarjeta titulo="Umbrales de disparo" subtitulo="Propuestos, por calibrar en el piloto.">
          <Tabla columnas={[{ titulo: 'Evento' }, { titulo: 'Umbral' }, { titulo: 'Hoy' }]}>
            {panel.umbrales.map((umbral) => (
              <tr key={umbral.evento}>
                <td>{umbral.evento}</td>
                <td>{textoUmbral(umbral)}</td>
                <td>
                  <Chip tono={superaUmbral(umbral) ? 'bad' : 'ok'}>{textoHoy(umbral)}</Chip>
                </td>
              </tr>
            ))}
          </Tabla>
        </Tarjeta>

        <Tarjeta
          titulo="Auditoría por muestreo (S3*)"
          subtitulo={`${panel.periodo}. Muestra revisada por personas.`}
        >
          <BarrasHorizontales
            maximo={100}
            filas={panel.auditoria.map((fila) => ({
              nombre: fila.nombre,
              valor: fila.porcentaje,
              etiqueta: formatearPorcentaje(fila.porcentaje),
            }))}
          />
          <div className="ajuste">
            <span className="decision-texto">
              <strong>
                {datos.simuladorActivo ? 'Simulador de cuotas activo' : 'Simulador de cuotas desactivado'}
              </strong>
              <span>Se desactiva ante errores de cálculo</span>
            </span>
            <Interruptor
              activo={datos.simuladorActivo}
              etiqueta="Simulador de cuotas"
              onCambiar={alternarSimulador}
            />
          </div>
          <MensajeMemoria texto={mensaje} />
        </Tarjeta>
      </div>

      <NotaEjemplo>
        Todo en esta página es de ejemplo: no hay alertas ni auditorías reales conectadas al panel.
      </NotaEjemplo>
    </>
  );
}
