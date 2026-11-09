import { formatearNumero, type MesRecaudacion } from '@almira/shared';
import type { ReactNode } from 'react';
import { Icono, type NombreIcono } from './iconos';

// Insignias de estado (LEEME.md → Insignia): el texto usa la variante …Text del color.
export type TonoChip = 'ok' | 'warn' | 'bad' | 'info' | 'neutral';

export function Chip({
  tono,
  icono,
  children,
}: {
  tono: TonoChip;
  // Con ícono, la insignia va sin punto (por ejemplo, el ciclo de web-02).
  icono?: NombreIcono;
  children: ReactNode;
}) {
  return (
    <span className={`insignia insignia-${tono} ${icono ? 'sin-punto' : ''}`}>
      {icono && <Icono nombre={icono} tamano="xs" />}
      {children}
    </span>
  );
}

export function Encabezado({
  titulo,
  subtitulo,
  extra,
  accion,
}: {
  titulo: string;
  subtitulo: string;
  // Antes de "Datos ficticios" (insignias) y después (botón de la página).
  extra?: ReactNode;
  accion?: ReactNode;
}) {
  return (
    <header className="encabezado">
      <div>
        <h1>{titulo}</h1>
        <p className="subtitulo">{subtitulo}</p>
      </div>
      <div className="encabezado-extra">
        {extra}
        <Chip tono="neutral">Datos ficticios</Chip>
        {accion}
      </div>
    </header>
  );
}

// Indicador: etiqueta, cifra grande y detalle. La tendencia ("↑ 7.7 %") va en
// verde delante del detalle y el avance, si lo hay, en una barra debajo.
export function Cifra({
  etiqueta,
  valor,
  tendencia,
  detalle,
  avance,
}: {
  etiqueta: string;
  valor: string;
  tendencia?: string;
  detalle?: string;
  avance?: number;
}) {
  return (
    <section className="cifra">
      <h2 className="cifra-etiqueta">{etiqueta}</h2>
      <p className="cifra-valor">{valor}</p>
      <p className="cifra-detalle">
        {tendencia && <span className="tendencia">{tendencia}</span>}
        {tendencia && detalle ? ' ' : null}
        {detalle}
      </p>
      {avance !== undefined && <Progreso porcentaje={avance} etiqueta={etiqueta} ancho />}
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

// Tarjeta que solo lleva una tabla, con el relleno corto de las maquetas.
export function TarjetaTabla({ children }: { children: ReactNode }) {
  return <section className="tarjeta tarjeta-tabla">{children}</section>;
}

export type FilaBarra = {
  nombre: string;
  valor: number;
  etiqueta?: string;
  tono?: 'primario' | 'secundario';
  // Nombre en negrita (la variante ganadora de la prueba A/B).
  destacada?: boolean;
};

// Anchos de nombre y cifra según la tarjeta (LEEME.md → Gráficos).
export type VarianteBarras = 'normal' | 'zona' | 'prueba' | 'canal' | 'auditoria';

// Barras horizontales en HTML y CSS, cada una con su cifra escrita. La más larga
// llena el riel, salvo que se indique un máximo (por ejemplo, 100 para porcentajes).
export function BarrasHorizontales({
  filas,
  maximo,
  variante = 'normal',
}: {
  filas: FilaBarra[];
  maximo?: number;
  variante?: VarianteBarras;
}) {
  const tope = maximo ?? Math.max(...filas.map((fila) => fila.valor), 1);
  return (
    <ul className={`barras-h barras-h-${variante}`}>
      {filas.map((fila) => (
        <li key={fila.nombre}>
          <span className={fila.destacada ? 'fuerte' : undefined}>{fila.nombre}</span>
          <span className="barras-h-riel">
            <span
              className={`barras-h-barra ${fila.tono ?? 'primario'}`}
              style={{ width: `${Math.min(100, (fila.valor / tope) * 100)}%` }}
            />
          </span>
          <strong className="monto">{fila.etiqueta ?? formatearNumero(fila.valor)}</strong>
        </li>
      ))}
    </ul>
  );
}

export type Serie = { nombre: string; tono: 'primario' | 'secundario' };

// Leyenda de los gráficos de dos series.
export function Leyenda({ series }: { series: Serie[] }) {
  return (
    <p className="leyenda">
      {series.map((serie) => (
        <span key={serie.nombre}>
          <i className={serie.tono} />
          {serie.nombre}
        </span>
      ))}
    </p>
  );
}

// Recaudación mensual (web-02 y web-03): barras verticales en HTML y CSS. Los
// meses con vencimiento del predial van en el color primario.
export function BarrasMensuales({ meses }: { meses: MesRecaudacion[] }) {
  const tope = Math.max(...meses.map((mes) => mes.millones), 1);
  return (
    <figure className="barras-v">
      <div>
        <ol>
          {meses.map((mes) => (
            <li key={mes.mes}>
              <strong>{formatearNumero(mes.millones)}</strong>
              <span
                className={`barras-v-barra ${mes.vencimientoPredial ? 'primario' : 'secundario'}`}
                style={{ height: `${(mes.millones / tope) * 100}%` }}
                aria-hidden="true"
              />
            </li>
          ))}
        </ol>
        <ol className="barras-v-meses" aria-hidden="true">
          {meses.map((mes) => (
            <li key={mes.mes}>{mes.mes}</li>
          ))}
        </ol>
      </div>
      <figcaption>
        <Leyenda
          series={[
            { nombre: 'Mes con vencimiento de predial', tono: 'primario' },
            { nombre: 'Otros meses', tono: 'secundario' },
          ]}
        />
      </figcaption>
    </figure>
  );
}

export type Columna = { titulo: string; derecha?: boolean; clase?: string };

export function Tabla({ columnas, children }: { columnas: Columna[]; children: ReactNode }) {
  return (
    <div className="tabla">
      <table>
        <thead>
          <tr>
            {columnas.map(({ titulo, derecha, clase }, indice) => (
              <th
                key={titulo || indice}
                className={[derecha ? 'monto' : '', clase ?? ''].join(' ').trim() || undefined}
              >
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

// Nota (LEEME.md → Nota): ícono y texto secundarios, sin fondo.
export function Nota({ children, icono = 'info' }: { children: ReactNode; icono?: NombreIcono }) {
  return (
    <p className="nota">
      <Icono nombre={icono} />
      <span>{children}</span>
    </p>
  );
}

// Nota con borde, para avisos sueltos como el error del mapa (MapaObras.tsx).
export function AvisoInfo({ children }: { children: ReactNode }) {
  return (
    <p className="nota con-borde">
      <Icono nombre="info" />
      <span>{children}</span>
    </p>
  );
}

// Alerta activa (web-08): borde rojo y fondo suave.
export function AlertaActiva({ children }: { children: ReactNode }) {
  return (
    <p className="alerta-activa" role="alert">
      <Icono nombre="error" />
      <span>{children}</span>
    </p>
  );
}

// Caja de ícono de 40 px. Los tonos de estado marcan excepciones (web-02).
export function CajaIcono({
  icono,
  tono = 'normal',
}: {
  icono: NombreIcono;
  tono?: 'normal' | 'bad' | 'warn';
}) {
  return (
    <span className={`icono-cuadro ${tono}`}>
      <Icono nombre={icono} />
    </span>
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

export function Progreso({
  porcentaje,
  etiqueta,
  ancho = false,
}: {
  porcentaje: number;
  etiqueta?: string;
  // Ocupa todo el ancho disponible (indicadores y columna de avance).
  ancho?: boolean;
}) {
  return (
    <span
      className={`progreso ${porcentaje >= 100 ? 'completo' : ''} ${ancho ? 'ancho' : ''}`}
      role="progressbar"
      aria-label={etiqueta}
      aria-valuemin={0}
      aria-valuemax={100}
      aria-valuenow={porcentaje}
    >
      <span style={{ width: `${Math.min(100, porcentaje)}%` }} />
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
