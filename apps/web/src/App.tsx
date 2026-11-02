import { municipalidades } from '@almira/shared';
import { useState } from 'react';
import { NavLink, Navigate, Outlet, Route, Routes } from 'react-router-dom';
import type { ContextoPanel } from './datos';
import { Obras } from './paginas/Obras';
import { Recaudacion } from './paginas/Recaudacion';
import { Reclamos } from './paginas/Reclamos';
import { Recordatorios } from './paginas/Recordatorios';
import { Resumen } from './paginas/Resumen';

const SECCIONES = [
  { ruta: '/resumen', titulo: 'Resumen' },
  { ruta: '/recaudacion', titulo: 'Recaudación' },
  { ruta: '/recordatorios', titulo: 'Recordatorios' },
  { ruta: '/reclamos', titulo: 'Reclamos' },
  { ruta: '/obras', titulo: 'Obras' },
];

function Marco() {
  const [municipalidadId, setMunicipalidadId] = useState(municipalidades[0]!.id);
  const municipalidad = municipalidades.find((m) => m.id === municipalidadId)!;
  const contexto: ContextoPanel = { municipalidadId, municipalidadNombre: municipalidad.nombre };

  return (
    <div className="panel">
      <aside className="lateral">
        <div className="marca-wrap">
          <span className="marca">Almira</span>
          <span className="marca-chip">Panel municipal</span>
        </div>
        <label className="selector">
          Municipalidad
          <select value={municipalidadId} onChange={(e) => setMunicipalidadId(e.target.value)}>
            {municipalidades.map((m) => (
              <option key={m.id} value={m.id}>
                {m.nombre}
              </option>
            ))}
          </select>
        </label>
        <nav className="menu" aria-label="Secciones del panel">
          {SECCIONES.map(({ ruta, titulo }) => (
            <NavLink key={ruta} to={ruta}>
              {titulo}
            </NavLink>
          ))}
        </nav>
      </aside>
      <main className="contenido">
        <Outlet context={contexto} />
      </main>
    </div>
  );
}

export function App() {
  return (
    <Routes>
      <Route element={<Marco />}>
        <Route index element={<Navigate to="/resumen" replace />} />
        <Route path="resumen" element={<Resumen />} />
        <Route path="recaudacion" element={<Recaudacion />} />
        <Route path="recordatorios" element={<Recordatorios />} />
        <Route path="reclamos" element={<Reclamos />} />
        <Route path="obras" element={<Obras />} />
        <Route path="*" element={<Navigate to="/resumen" replace />} />
      </Route>
    </Routes>
  );
}
