import { PERSONAL_PANEL_EJEMPLO } from '@almira/shared';
import { useState, type FormEvent } from 'react';
import { Navigate, useNavigate } from 'react-router-dom';
import { Chip, Nota } from '../componentes';
import { municipalidadesConPanel, usePanel } from '../estado';
import { Icono } from '../iconos';

// Ingreso simulado (web-01): no hay autenticación real. Cualquier usuario y
// contraseña entran; los campos vienen llenos con el usuario de ejemplo.
export function Ingreso() {
  const { sesion, ingresar } = usePanel();
  const navegar = useNavigate();
  const [municipalidadId, setMunicipalidadId] = useState(municipalidadesConPanel[0]?.id ?? '');
  const [usuario, setUsuario] = useState<string>(PERSONAL_PANEL_EJEMPLO.usuario);
  const [contrasena, setContrasena] = useState('ejemplo1');
  const [verContrasena, setVerContrasena] = useState(false);
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

  return (
    <main className="ingreso">
      <div className="ingreso-columna">
        <div className="ingreso-marca">
          <span className="logo" aria-hidden="true">
            a
          </span>
          <strong>Almira</strong>
          <Chip tono="neutral">Panel municipal</Chip>
        </div>

        <form className="ingreso-tarjeta" onSubmit={enviar} noValidate>
          <div className="ingreso-titulo">
            <h1>Ingresa al panel</h1>
            <p className="subtitulo">Solo para personal de la municipalidad.</p>
          </div>

          {/* Las municipalidades salen de los datos: solo las que tienen cifras de panel. */}
          <label className="campo">
            Municipalidad
            <span className="campo-caja">
              <Icono nombre="ciudad" />
              <select value={municipalidadId} onChange={(e) => setMunicipalidadId(e.target.value)}>
                {municipalidadesConPanel.map((m) => (
                  <option key={m.id} value={m.id}>
                    {m.nombre}
                  </option>
                ))}
              </select>
              <Icono nombre="desplegar" tamano="lg" />
            </span>
          </label>

          <label className="campo">
            Usuario institucional
            <span className="campo-caja">
              <input
                value={usuario}
                onChange={(e) => setUsuario(e.target.value)}
                autoComplete="username"
              />
            </span>
          </label>

          <div className="campo">
            <label htmlFor="contrasena">Contraseña</label>
            <span className="campo-caja">
              <input
                id="contrasena"
                type={verContrasena ? 'text' : 'password'}
                value={contrasena}
                onChange={(e) => setContrasena(e.target.value)}
                autoComplete="current-password"
              />
              <button
                type="button"
                className="campo-ojo"
                aria-label={verContrasena ? 'Ocultar contraseña' : 'Mostrar contraseña'}
                aria-pressed={verContrasena}
                onClick={() => setVerContrasena((valor) => !valor)}
              >
                <Icono nombre={verContrasena ? 'ojoTachado' : 'ojo'} />
              </button>
            </span>
          </div>

          {error && (
            <p className="campo-error" role="alert">
              {error}
            </p>
          )}

          <button type="submit" className="boton boton-primario boton-grande">
            Ingresar
          </button>
        </form>
      </div>
    </main>
  );
}
