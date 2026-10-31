import type { ReactNode } from 'react';

export type Tono = 'exito' | 'atencion' | 'critico';

export function Encabezado({ titulo, subtitulo }: { titulo: string; subtitulo: string }) {
  return (
    <header>
      <h1>{titulo}</h1>
      <p className="subtitulo">{subtitulo}</p>
    </header>
  );
}

export function Indicador({ etiqueta, valor }: { etiqueta: string; valor: string }) {
  return (
    <div className="tarjeta">
      <span className="subtitulo">{etiqueta}</span>
      <span className="indicador-valor">{valor}</span>
    </div>
  );
}

export function Insignia({ tono, children }: { tono: Tono; children: ReactNode }) {
  return <span className={`insignia ${tono}`}>{children}</span>;
}

export function Progreso({ porcentaje }: { porcentaje: number }) {
  return (
    <div
      className="progreso"
      role="progressbar"
      aria-valuemin={0}
      aria-valuemax={100}
      aria-valuenow={porcentaje}
    >
      <span style={{ width: `${porcentaje}%` }} />
    </div>
  );
}

export function Tabla({
  columnas,
  vacio,
  children,
}: {
  columnas: { titulo: string; monto?: boolean }[];
  vacio: boolean;
  children: ReactNode;
}) {
  if (vacio) {
    return (
      <div className="tabla">
        <p className="vacio">No hay registros en esta municipalidad.</p>
      </div>
    );
  }
  return (
    <div className="tabla">
      <table>
        <thead>
          <tr>
            {columnas.map(({ titulo, monto }) => (
              <th key={titulo} className={monto ? 'monto' : undefined}>
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
