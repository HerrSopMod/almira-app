import {
  AREA_TIPO_RECLAMO,
  ETIQUETA_TIPO_RECLAMO,
  formatearFechaCorta,
  type Reclamo,
} from '@almira/shared';
import { useState } from 'react';
import { Chip, Encabezado, MensajeMemoria, Tabla, TarjetaTabla, type TonoChip } from '../componentes';
import { estaVencido, etiquetaPlazoReclamo, useSesion } from '../estado';

const FILTROS = ['Todos', 'Vencidos', 'Abiertos', 'Resueltos'] as const;
type Filtro = (typeof FILTROS)[number];

const AREAS = [...new Set(Object.values(AREA_TIPO_RECLAMO))];

// Desde cuántos días restantes el plazo deja de ir en ámbar (web-05).
const DIAS_PLAZO_CERCANO = 3;

const abierto = (reclamo: Reclamo) => reclamo.estado !== 'resuelto';

const CUMPLE: Record<Filtro, (reclamo: Reclamo) => boolean> = {
  Todos: () => true,
  Vencidos: estaVencido,
  Abiertos: abierto,
  Resueltos: (reclamo) => !abierto(reclamo),
};

// Orden por urgencia: más días vencido primero, luego menos días restantes y
// al final los resueltos.
function urgencia(etiqueta: string): number {
  const vencido = /^Vencido(?: (\d+) d)?$/.exec(etiqueta);
  if (vencido) return -Number(vencido[1] ?? 1);
  if (etiqueta === 'Vence hoy') return 0;
  const quedan = /^Quedan (\d+) d$/.exec(etiqueta);
  return quedan ? Number(quedan[1]) : Number.POSITIVE_INFINITY;
}

// Vencido en rojo, hasta 3 días en ámbar, más días en turquesa y resuelto en verde.
function tonoPlazo(etiqueta: string): TonoChip {
  if (etiqueta === 'Resuelto') return 'ok';
  const dias = urgencia(etiqueta);
  if (dias < 0) return 'bad';
  return dias <= DIAS_PLAZO_CERCANO ? 'warn' : 'info';
}

const plural = (n: number, singular: string, varios: string) => `${n} ${n === 1 ? singular : varios}`;

// Reclamos por área y plazo (web-05). "Responder y cerrar" y "Corregir área"
// cambian solo la copia en memoria: no se guarda nada ni se avisa al vecino.
export function Reclamos() {
  const { sesion, datos, cambiarDatos } = useSesion();
  const [filtro, setFiltro] = useState<Filtro>('Todos');
  const [elegidoId, setElegidoId] = useState<string | null>(null);
  const [corrigiendo, setCorrigiendo] = useState(false);
  const [mensaje, setMensaje] = useState<string | null>(null);

  const ordenados = [...datos.reclamos].sort(
    (a, b) => urgencia(etiquetaPlazoReclamo(a)) - urgencia(etiquetaPlazoReclamo(b)),
  );
  const visibles = ordenados.filter(CUMPLE[filtro]);
  const elegido = visibles.find((reclamo) => reclamo.id === elegidoId) ?? visibles[0];
  const vencidos = datos.reclamos.filter(estaVencido).length;
  const abiertos = datos.reclamos.filter(abierto).length;
  // "Vencidos · 2" y "Abiertos · 6", como en la maqueta.
  const cantidad: Partial<Record<Filtro, number>> = { Vencidos: vencidos, Abiertos: abiertos };

  const elegir = (id: string) => {
    setElegidoId(id);
    setCorrigiendo(false);
    setMensaje(null);
  };

  const cambiar = (id: string, cambios: Partial<Reclamo>) =>
    cambiarDatos((actual) => ({
      ...actual,
      reclamos: actual.reclamos.map((reclamo) => (reclamo.id === id ? { ...reclamo, ...cambios } : reclamo)),
    }));

  const cerrar = (reclamo: Reclamo) => {
    cambiar(reclamo.id, { estado: 'resuelto', plazo: null });
    setCorrigiendo(false);
    setMensaje(
      `${reclamo.codigo} quedó resuelto.`,
    );
  };

  const corregirArea = (reclamo: Reclamo, area: string) => {
    cambiar(reclamo.id, { area });
    setCorrigiendo(false);
    setMensaje(`Área cambiada a ${area}.`);
  };

  return (
    <>
      <Encabezado
        titulo="Reclamos por área y plazo"
        subtitulo={`${plural(vencidos, 'vencido', 'vencidos')} · ${plural(abiertos, 'abierto', 'abiertos')}`}
      />

      <div className="filtros" role="group" aria-label="Filtrar reclamos">
        {FILTROS.map((opcion) => (
          <button
            key={opcion}
            type="button"
            className={`filtro ${opcion === filtro ? 'activo' : ''}`}
            aria-pressed={opcion === filtro}
            onClick={() => {
              setFiltro(opcion);
              setMensaje(null);
              setCorrigiendo(false);
            }}
          >
            {cantidad[opcion] ? `${opcion} · ${cantidad[opcion]}` : opcion}
          </button>
        ))}
      </div>

      <div className="fila fila-reclamos">
        <TarjetaTabla>
          {visibles.length === 0 ? (
            <p className="subtitulo">No hay reclamos en este filtro.</p>
          ) : (
            <Tabla
              columnas={[
                { titulo: 'N.°' },
                { titulo: 'Reclamo' },
                { titulo: 'Zona' },
                { titulo: 'Área' },
                { titulo: 'Plazo' },
              ]}
            >
              {visibles.map((reclamo) => {
                const plazo = etiquetaPlazoReclamo(reclamo);
                return (
                  <tr
                    key={reclamo.id}
                    className={`fila-elegible ${reclamo.id === elegido?.id ? 'elegida' : ''}`}
                    tabIndex={0}
                    aria-selected={reclamo.id === elegido?.id}
                    onClick={() => elegir(reclamo.id)}
                    onKeyDown={(evento) => {
                      if (evento.key === 'Enter' || evento.key === ' ') {
                        evento.preventDefault();
                        elegir(reclamo.id);
                      }
                    }}
                  >
                    <td className="num fuerte">{reclamo.codigo}</td>
                    <td>
                      <span className="doble">
                        <strong>{reclamo.titulo}</strong>
                        <span>{ETIQUETA_TIPO_RECLAMO[reclamo.tipo]}</span>
                      </span>
                    </td>
                    <td>{sesion.panel.zonaReclamo[reclamo.codigo] ?? '—'}</td>
                    <td>{reclamo.area ?? '—'}</td>
                    <td>
                      <Chip tono={tonoPlazo(plazo)}>{plazo}</Chip>
                    </td>
                  </tr>
                );
              })}
            </Tabla>
          )}
        </TarjetaTabla>

        {elegido && (
          <section className="tarjeta detalle-reclamo" aria-label={`Detalle del reclamo ${elegido.codigo}`}>
            <header className="detalle-cabecera">
              <h2>{elegido.codigo}</h2>
              <Chip tono={tonoPlazo(etiquetaPlazoReclamo(elegido))}>{etiquetaPlazoReclamo(elegido)}</Chip>
            </header>
            <div className="detalle-titulo">
              <strong>{elegido.titulo}</strong>
              <span>
                {[elegido.direccion, formatearFechaCorta(elegido.creadoEn)].filter(Boolean).join(' · ')}
              </span>
            </div>
            {elegido.descripcion && <p className="detalle-descripcion">{elegido.descripcion}</p>}
            {/* Sin porcentaje de confianza: la clasificación sale de reglas fijas. */}
            <dl className="clave-valor">
              <div>
                <dt>Clasificación automática</dt>
                <dd>{ETIQUETA_TIPO_RECLAMO[elegido.tipo]}</dd>
              </div>
              <div>
                <dt>Área responsable</dt>
                <dd>
                  {corrigiendo ? (
                    <label className="campo-en-linea">
                      <span className="oculto">Nueva área responsable</span>
                      <select
                        value={elegido.area ?? ''}
                        onChange={(e) => corregirArea(elegido, e.target.value)}
                        autoFocus
                      >
                        {AREAS.map((area) => (
                          <option key={area} value={area}>
                            {area}
                          </option>
                        ))}
                      </select>
                    </label>
                  ) : (
                    (elegido.area ?? '—')
                  )}
                </dd>
              </div>
            </dl>
            {abierto(elegido) && (
              <div className="acciones">
                <button type="button" className="boton boton-primario" onClick={() => cerrar(elegido)}>
                  Responder y cerrar
                </button>
                <button
                  type="button"
                  className="boton boton-secundario"
                  onClick={() => setCorrigiendo((valor) => !valor)}
                >
                  {corrigiendo ? 'Cancelar' : 'Corregir área'}
                </button>
              </div>
            )}
            <MensajeMemoria texto={mensaje} />
          </section>
        )}
      </div>
    </>
  );
}
