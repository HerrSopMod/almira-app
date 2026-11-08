import {
  formatearNumero,
  formatearPorcentaje,
  formatearVariacion,
  type CasoAtencion,
  type EstadoCaso,
} from '@almira/shared';
import { useState } from 'react';
import {
  Chip,
  Cifra,
  Encabezado,
  MensajeMemoria,
  NotaEjemplo,
  Tabla,
  type TonoChip,
} from '../componentes';
import { useSesion } from '../estado';

const ESTADO: Record<EstadoCaso, { texto: string; tono: TonoChip }> = {
  en_cola: { texto: 'En cola', tono: 'neutral' },
  en_atencion: { texto: 'En atención', tono: 'warn' },
  atendido: { texto: 'Atendido', tono: 'ok' },
};

// Atención humana (web-07). Los casos son de ejemplo y "Tomar" solo cambia la
// copia en memoria.
export function AtencionHumana() {
  const { sesion, datos, cambiarDatos } = useSesion();
  const { atencion } = sesion.panel;
  const [mensaje, setMensaje] = useState<string | null>(null);
  const enCola = datos.casos.filter((caso) => caso.estado === 'en_cola').length;

  const tomar = (caso: CasoAtencion) => {
    cambiarDatos((actual) => ({
      ...actual,
      casos: actual.casos.map((c) => (c.codigo === caso.codigo ? { ...c, estado: 'en_atencion' } : c)),
    }));
    setMensaje(`Tomaste ${caso.codigo} solo en esta sesión de ejemplo: no se guarda.`);
  };

  return (
    <>
      <Encabezado titulo="Atención humana" subtitulo="Casos que superan la automatización" />

      <div className="cifras cifras-3">
        <Cifra
          etiqueta="En cola ahora"
          valor={formatearNumero(enCola)}
          detalle={`Umbral de alerta: ${atencion.umbralCola}`}
        />
        <Cifra
          etiqueta="Derivados por el asistente"
          valor={formatearPorcentaje(atencion.derivadosPct)}
          detalle={`De ${formatearNumero(atencion.conversaciones)} conversaciones`}
        />
        <Cifra
          etiqueta="Atenciones en el módulo asistido"
          valor={formatearNumero(atencion.atencionesModulo)}
          detalle={`${formatearVariacion(atencion.variacionModulo)} frente a la línea base`}
        />
      </div>

      <section className="tarjeta">
        <Tabla
          columnas={[
            { titulo: 'Caso' },
            { titulo: 'Motivo' },
            { titulo: 'Origen' },
            { titulo: 'Área' },
            { titulo: 'Espera' },
            { titulo: 'Estado' },
            { titulo: '' },
          ]}
        >
          {datos.casos.map((caso) => (
            <tr key={caso.codigo} className="alta">
              <td>{caso.codigo}</td>
              <td>
                <strong>{caso.motivo}</strong>
              </td>
              <td>{caso.origen}</td>
              <td>{caso.area}</td>
              <td>{caso.esperaMinutos === null ? '—' : `${caso.esperaMinutos} min`}</td>
              <td>
                <Chip tono={ESTADO[caso.estado].tono}>{ESTADO[caso.estado].texto}</Chip>
              </td>
              <td className="celda-accion">
                {caso.estado === 'en_cola' && (
                  <button
                    type="button"
                    className="boton boton-secundario boton-bajo"
                    onClick={() => tomar(caso)}
                    aria-label={`Tomar el caso ${caso.codigo}`}
                  >
                    Tomar
                  </button>
                )}
              </td>
            </tr>
          ))}
        </Tabla>
      </section>
      <MensajeMemoria texto={mensaje} />
      <NotaEjemplo>Casos de ejemplo: no hay vecinos reales esperando en esta cola.</NotaEjemplo>
    </>
  );
}
