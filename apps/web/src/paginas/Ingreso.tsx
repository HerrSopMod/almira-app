import { PERSONAL_PANEL_EJEMPLO } from '@almira/shared';
import { useState, type FormEvent } from 'react';
import { Navigate, useNavigate } from 'react-router-dom';
import { municipalidadesConPanel, usePanel } from '../estado';

// Ingreso simulado (web-01): no hay autenticación real. Cualquier usuario y
// contraseña entran; los campos vienen llenos con el usuario de ejemplo.
export function Ingreso() {
  const { sesion, ingresar } = usePanel();
  const navegar = useNavigate();
  const [municipalidadId, setMunicipalidadId] = useState(municipalidadesConPanel[0]?.id ?? '');
  const [usuario, setUsuario] = useState<string>(PERSONAL_PANEL_EJEMPLO.usuario);
  const [contrasena, setContrasena] = useState('ejemplo1');
  const [error, setError] = useState<string | null>(null);

  if (sesion) return <Navigate to="/panel" replace />;

  const enviar = (evento: FormEvent) => {
    evento.preventDefault();
    if (!usuario.trim() || !contrasena) {
      setError('Escribe un usuario y una contraseña de ejemplo.');
      return;
    }
    ingresar(municipalidadId, usuario.trim());
    navegar('/panel');
  };

  const unica = municipalidadesConPanel.length === 1 ? municipalidadesConPanel[0] : undefined;

  return (
    <main className="ingreso">
      <form className="ingreso-tarjeta" onSubmit={enviar} noValidate>
        <h1>Panel municipal (web)</h1>
        <div className="ingreso-cuerpo">
          {unica ? (
            <p className="ingreso-municipalidad">{unica.nombre}</p>
          ) : (
            <label className="ingreso-municipalidad">
              <span className="oculto">Municipalidad</span>
              <select value={municipalidadId} onChange={(e) => setMunicipalidadId(e.target.value)}>
                {municipalidadesConPanel.map((m) => (
                  <option key={m.id} value={m.id}>
                    {m.nombre}
                  </option>
                ))}
              </select>
            </label>
          )}
          <label className="campo">
            Usuario institucional
            <input
              value={usuario}
              onChange={(e) => setUsuario(e.target.value)}
              autoComplete="username"
            />
          </label>
          <label className="campo">
            Contraseña
            <input
              type="password"
              value={contrasena}
              onChange={(e) => setContrasena(e.target.value)}
              autoComplete="current-password"
            />
          </label>
          {error && (
            <p className="campo-error" role="alert">
              {error}
            </p>
          )}
          <button type="submit" className="boton boton-primario">
            Ingresar
          </button>
          <p className="ingreso-nota">
            Datos de ejemplo. Ingreso simulado: entra con cualquier usuario y contraseña. Cada
            funcionario ve solo lo que su área necesita.
          </p>
        </div>
      </form>
    </main>
  );
}
