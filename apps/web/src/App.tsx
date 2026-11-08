import { iniciales, PERSONAL_PANEL_EJEMPLO } from '@almira/shared';
import { NavLink, Navigate, Outlet, Route, Routes } from 'react-router-dom';
import { pendientes, usePanel, useSesion } from './estado';
import { Icono, type NombreIcono } from './iconos';
import { Alertas } from './paginas/Alertas';
import { AtencionHumana } from './paginas/AtencionHumana';
import { Avisos } from './paginas/Avisos';
import { DatosAccesos } from './paginas/DatosAccesos';
import { Ingreso } from './paginas/Ingreso';
import { Obras } from './paginas/Obras';
import { PanelMunicipal } from './paginas/PanelMunicipal';
import { Recaudacion } from './paginas/Recaudacion';
import { Reclamos } from './paginas/Reclamos';

type Modulo = { ruta: string; titulo: string; icono: NombreIcono; cifra?: number };

function Marco() {
  const { sesion, datos } = useSesion();
  const { reclamosVencidos, casosEnCola, alertas } = pendientes({ sesion, datos });

  const modulos: Modulo[] = [
    { ruta: '/panel', titulo: 'Panel municipal', icono: 'grafico' },
    { ruta: '/recaudacion', titulo: 'Recaudación y pagos', icono: 'soles' },
    { ruta: '/avisos', titulo: 'Avisos y respuestas', icono: 'mensaje' },
    { ruta: '/reclamos', titulo: 'Reclamos por área', icono: 'reclamo', cifra: reclamosVencidos.length },
    { ruta: '/obras', titulo: 'Obras publicadas', icono: 'casco' },
    { ruta: '/atencion', titulo: 'Atención humana', icono: 'personas', cifra: casosEnCola.length },
    { ruta: '/alertas', titulo: 'Alertas y auditoría', icono: 'alerta', cifra: alertas.length },
    { ruta: '/datos', titulo: 'Datos y accesos', icono: 'escudo' },
  ];

  return (
    <div className="panel">
      <aside className="lateral">
        <div className="lateral-marca">
          <span className="logo" aria-hidden="true">
            a
          </span>
          <div>
            <strong>Almira</strong>
            <span>{sesion.municipalidad.nombre}</span>
          </div>
        </div>
        <nav className="menu" aria-label="Módulos del panel">
          {modulos.map(({ ruta, titulo, icono, cifra }) => (
            <NavLink key={ruta} to={ruta}>
              <Icono nombre={icono} />
              <span className="menu-titulo">{titulo}</span>
              {cifra ? (
                <span className="menu-cifra" aria-label={`${cifra} pendientes`}>
                  {cifra}
                </span>
              ) : null}
            </NavLink>
          ))}
        </nav>
        <div className="lateral-pie">
          <span className="avatar" aria-hidden="true">
            {iniciales(PERSONAL_PANEL_EJEMPLO.cargo)}
          </span>
          <div>
            <strong>{PERSONAL_PANEL_EJEMPLO.cargo}</strong>
            <span>{PERSONAL_PANEL_EJEMPLO.area} · Acceso por rol</span>
          </div>
        </div>
      </aside>
      <main className="contenido">
        <Outlet />
      </main>
    </div>
  );
}

function ConSesion() {
  const { sesion } = usePanel();
  return sesion ? <Marco /> : <Navigate to="/ingreso" replace />;
}

export function App() {
  return (
    <Routes>
      <Route path="ingreso" element={<Ingreso />} />
      <Route element={<ConSesion />}>
        <Route index element={<Navigate to="/panel" replace />} />
        <Route path="panel" element={<PanelMunicipal />} />
        <Route path="recaudacion" element={<Recaudacion />} />
        <Route path="avisos" element={<Avisos />} />
        <Route path="reclamos" element={<Reclamos />} />
        <Route path="obras" element={<Obras />} />
        <Route path="atencion" element={<AtencionHumana />} />
        <Route path="alertas" element={<Alertas />} />
        <Route path="datos" element={<DatosAccesos />} />
        <Route path="*" element={<Navigate to="/panel" replace />} />
      </Route>
    </Routes>
  );
}
