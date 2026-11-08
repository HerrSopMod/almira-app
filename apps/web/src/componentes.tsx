import { formatearNumero, type MesRecaudacion } from '@almira/shared';
import type { ReactNode } from 'react';
import { Icono } from './iconos';

export type TonoChip = 'rosa' | 'amarillo' | 'verde' | 'rojo';

export function Chip({ tono, children }: { tono: TonoChip; children: ReactNode }) {
  return <span className={`chip chip-${tono}`}>{children}</span>;
}

export function Encabezado({
  titulo,
  subtitulo,
  extra,
}: {
  titulo: string;
  subtitulo: string;
  extra?: ReactNode;
}) {
  return (
    <header className="encabezado">
      <div>
        <h1>{titulo}</h1>
        <p className="subtitulo">{subtitulo}</p>
      </div>
      <div className="encabezado-extra">
        {extra}
        <Chip tono="amarillo">Datos ficticios</Chip>
      </div>
    </header>
  );
}

// Tarjeta rosada con una cifra destacada.
export function Cifra({
  etiqueta,
  valor,
  detalle,
}: {
  etiqueta: string;
  valor: string;
  detalle: string;
}) {
  return (
    <section className="cifra">
      <h2 className="cifra-etiqueta">{etiqueta}</h2>
      <p className="cifra-valor">{valor}</p>
      <p className="cifra-detalle">{detalle}</p>
    </section>
  );
}

export function Tarjeta({
  titulo,
  subtitulo,
  children,
  className,
}: {
  titulo?: string;
  subtitulo?: string;
  children: ReactNode;
  className?: string;
}) {
  return (
    <section className={`tarjeta ${className ?? ''}`}>
      {titulo && (
        <header className="tarjeta-encabezado">
          <h2>{titulo}</h2>
          {subtitulo && <p className="subtitulo">{subtitulo}</p>}
        </header>
      )}
      {children}
    </section>
  );
}

export type FilaBarra = {
  nombre: string;
  valor: number;
  etiqueta?: string;
  tono?: 'primario' | 'secundario';
};

// Barras horizontales en HTML y CSS. La más larga llena la pista, salvo que
// se indique un máximo (por ejemplo, 100 para porcentajes).
export function BarrasHorizontales({
  filas,
  tono = 'primario',
  maximo,
}: {
  filas: FilaBarra[];
  tono?: 'primario' | 'secundario';
  maximo?: number;
}) {
  const tope = maximo ?? Math.max(...filas.map((fila) => fila.valor), 1);
  return (
    <ul className="barras-h">
      {filas.map((fila) => (
        <li key={fila.nombre}>
          <span>{fila.nombre}</span>
          <span className="barras-h-pista">
            <span
              className={`barras-h-barra ${fila.tono ?? tono}`}
              style={{ width: `${Math.min(100, (fila.valor / tope) * 100)}%` }}
            />
          </span>
          <strong className="monto">{fila.etiqueta ?? formatearNumero(fila.valor)}</strong>
        </li>
      ))}
    </ul>
  );
}

// Recaudación mensual (web-02 y web-03): barras verticales en HTML y CSS. Los
// meses con vencimiento del predial van en el color primario.
export function BarrasMensuales({ meses }: { meses: MesRecaudacion[] }) {
  const tope = Math.max(...meses.map((mes) => mes.millones), 1);
  return (
    <figure className="barras-v">
      <ol>
        {meses.map((mes) => (
          <li key={mes.mes}>
            <strong>{formatearNumero(mes.millones)}</strong>
            <span
              className={`barras-v-barra ${mes.vencimientoPredial ? 'primario' : 'secundario'}`}
              style={{ height: `calc(var(--p-bar-chart) * ${mes.millones / tope})` }}
            />
            <span className="barras-v-mes">{mes.mes}</span>
          </li>
        ))}
      </ol>
      <figcaption className="leyenda">
        <span>
          <i className="primario" />
          Mes con vencimiento de predial
        </span>
        <span>
          <i className="secundario" />
          Otros meses
        </span>
      </figcaption>
    </figure>
  );
}

export type Columna = { titulo: string; derecha?: boolean };

export function Tabla({ columnas, children }: { columnas: Columna[]; children: ReactNode }) {
  return (
    <div className="tabla">
      <table>
        <thead>
          <tr>
            {columnas.map(({ titulo, derecha }, indice) => (
              <th key={titulo || indice} className={derecha ? 'monto' : undefined}>
                {titulo}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>{children}</tbody>
      </table>
    </div>
  );
}

export function AvisoInfo({
  children,
  icono = 'info',
  fuerte = false,
}: {
  children: ReactNode;
  icono?: 'info' | 'alerta';
  // Fondo rosado más intenso, para alertas activas (web-08).
  fuerte?: boolean;
}) {
  return (
    <p className={`aviso-info ${fuerte ? 'fuerte' : ''}`}>
      <Icono nombre={icono} />
      <span>{children}</span>
    </p>
  );
}

// Aviso que aparece tras una acción: los cambios del panel no se guardan.
export function MensajeMemoria({ texto }: { texto: string | null }) {
  return (
    <p className="mensaje-memoria" role="status">
      {texto}
    </p>
  );
}

export function Progreso({ porcentaje }: { porcentaje: number }) {
  return (
    <span
      className={`progreso ${porcentaje >= 100 ? 'completo' : ''}`}
      role="progressbar"
      aria-valuemin={0}
      aria-valuemax={100}
      aria-valuenow={porcentaje}
    >
      <span style={{ width: `${porcentaje}%` }} />
    </span>
  );
}

export function Interruptor({
  activo,
  etiqueta,
  onCambiar,
}: {
  activo: boolean;
  etiqueta: string;
  onCambiar: () => void;
}) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={activo}
      aria-label={etiqueta}
      className="interruptor"
      onClick={onCambiar}
    >
      <span />
    </button>
  );
}

// Recordatorio de que la página solo muestra datos de ejemplo.
export function NotaEjemplo({ children }: { children: ReactNode }) {
  return <p className="nota-ejemplo">{children}</p>;
}
