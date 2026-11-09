import {
  formatearNumero,
  formatearPorcentaje,
  formatearVariacion,
  type CasoAtencion,
  type EstadoCaso,
  type OrigenCaso,
} from '@almira/shared';
import { useState } from 'react';
import {
  Chip,
  Cifra,
  Encabezado,
  MensajeMemoria,
  NotaEjemplo,
  Tabla,
  TarjetaTabla,
  type TonoChip,
} from '../componentes';
import { useSesion } from '../estado';
import { Icono, type NombreIcono } from '../iconos';

const ESTADO: Record<EstadoCaso, { texto: string; tono: TonoChip }> = {
  en_cola: { texto: 'En cola', tono: 'warn' },
  en_atencion: { texto: 'En atención', tono: 'info' },
  atendido: { texto: 'Atendido', tono: 'ok' },
};

const ICONO_ORIGEN: Record<OrigenCaso, NombreIcono> = {
  Asistente: 'personas',
  SMS: 'sms',
  WhatsApp: 'mensaje',
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
          avance={(enCola / atencion.umbralCola) * 100}
        />
        <Cifra
          etiqueta="Derivados por el asistente"
          valor={formatearPorcentaje(atencion.derivadosPct)}
          detalle={`De ${formatearNumero(atencion.conversaciones)} conversaciones`}
        />
        <Cifra
          etiqueta="Atenciones en el módulo asistido"
          valor={formatearNumero(atencion.atencionesModulo)}
          // Menos atenciones presenciales es una mejora: va en verde, como en web-07.
          tendencia={formatearVariacion(atencion.variacionModulo)}
          detalle="frente a la línea base"
        />
      </div>

      <TarjetaTabla>
        <Tabla
          columnas={[
            { titulo: 'Caso' },
            { titulo: 'Motivo' },
            { titulo: 'Origen' },
            { titulo: 'Área' },
            { titulo: 'Espera', derecha: true },
            { titulo: 'Estado' },
            { titulo: '' },
          ]}
        >
          {datos.casos.map((caso) => {
            const larga = caso.esperaMinutos !== null && caso.esperaMinutos >= atencion.esperaLargaMinutos;
            return (
              <tr key={caso.codigo}>
                <td className="num fuerte">{caso.codigo}</td>
                <td>{caso.motivo}</td>
                <td>
                  <span className="origen">
                    <Icono nombre={ICONO_ORIGEN[caso.origen]} tamano="sm" />
                    {caso.origen}
                  </span>
                </td>
                <td>{caso.area}</td>
                <td className={`monto ${larga ? 'espera-larga' : ''} ${caso.esperaMinutos === null ? 'secundario-texto' : ''}`}>
                  {caso.esperaMinutos === null ? '—' : `${caso.esperaMinutos} min`}
                </td>
                <td>
                  <Chip tono={ESTADO[caso.estado].tono}>{ESTADO[caso.estado].texto}</Chip>
                </td>
                <td className="celda-accion">
                  {caso.estado === 'en_cola' && (
                    <button
                      type="button"
                      className="boton boton-primario boton-sm"
                      onClick={() => tomar(caso)}
                      aria-label={`Tomar el caso ${caso.codigo}`}
                    >
                      Tomar
                    </button>
                  )}
                </td>
              </tr>
            );
          })}
        </Tabla>
      </TarjetaTabla>
      <MensajeMemoria texto={mensaje} />
      <NotaEjemplo>Casos de ejemplo: no hay vecinos reales esperando en esta cola.</NotaEjemplo>
    </>
  );
}
