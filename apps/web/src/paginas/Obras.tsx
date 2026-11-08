import { HOY_EJEMPLO, formatearPorcentaje, formatearSoles, haceDias, type Obra } from '@almira/shared';
import { useState, type FormEvent } from 'react';
import {
  AvisoInfo,
  Chip,
  Encabezado,
  Interruptor,
  MensajeMemoria,
  Progreso,
  Tabla,
  Tarjeta,
} from '../componentes';
import { diasSinActualizar, useSesion } from '../estado';
import { Icono } from '../iconos';

const PASO_AVANCE = 5;

// Obras publicadas (web-06). Publicar, sumar avance y "Nueva obra" cambian
// solo la copia en memoria: la app del vecino no cambia y nada se guarda.
export function Obras() {
  const { sesion, datos, cambiarDatos } = useSesion();
  const frecuencia = sesion.panel.frecuenciaObrasDias;
  const [mensaje, setMensaje] = useState<string | null>(null);
  const [creando, setCreando] = useState(false);

  const cambiar = (id: string, cambio: (obra: Obra) => Partial<Obra>) =>
    cambiarDatos((actual) => ({
      ...actual,
      obras: actual.obras.map((obra) => (obra.id === id ? { ...obra, ...cambio(obra) } : obra)),
    }));

  const alternarPublicada = (obra: Obra) => {
    cambiar(obra.id, (actual) => ({ publicada: !actual.publicada }));
    setMensaje(
      `${obra.nombre} ${obra.publicada ? 'dejó de estar publicada' : 'quedó publicada'} solo en esta sesión de ejemplo: la app del vecino no cambia.`,
    );
  };

  const sumarAvance = (obra: Obra) => {
    cambiar(obra.id, (actual) => {
      const avancePct = Math.min(100, actual.avancePct + PASO_AVANCE);
      return {
        avancePct,
        estado: avancePct >= 100 ? 'finalizada' : actual.estado,
        actualizadaEn: HOY_EJEMPLO,
      };
    });
    setMensaje(`Avance de ${obra.nombre} actualizado solo en esta sesión de ejemplo: no se guarda.`);
  };

  const agregar = (obra: Obra) => {
    cambiarDatos((actual) => ({ ...actual, obras: [...actual.obras, obra] }));
    setCreando(false);
    setMensaje(`${obra.nombre} se agregó sin publicar, solo en esta sesión de ejemplo: no se guarda.`);
  };

  return (
    <>
      <Encabezado
        titulo="Obras publicadas"
        subtitulo="Lo que ve el vecino en el mapa de la app"
        extra={
          <button
            type="button"
            className="boton boton-primario boton-bajo"
            onClick={() => {
              setCreando(true);
              setMensaje(null);
            }}
          >
            <Icono nombre="mas" />
            Nueva obra
          </button>
        }
      />

      {creando && (
        <NuevaObra
          municipalidadId={sesion.municipalidad.id}
          cantidad={datos.obras.length}
          onAgregar={agregar}
          onCancelar={() => setCreando(false)}
        />
      )}

      <section className="tarjeta">
        <Tabla
          columnas={[
            { titulo: 'Obra' },
            { titulo: 'Avance' },
            { titulo: 'Presupuesto', derecha: true },
            { titulo: 'Actualizada' },
            { titulo: 'Publicada' },
            { titulo: '' },
          ]}
        >
          {datos.obras.map((obra) => {
            const atrasada = diasSinActualizar(obra) > frecuencia;
            const actualizada = haceDias(obra.actualizadaEn, HOY_EJEMPLO);
            return (
              <tr key={obra.id} className="alta">
                <td>
                  <span className="doble">
                    <strong>{obra.nombre}</strong>
                    <span>{obra.ubicacion}</span>
                  </span>
                </td>
                <td>
                  <span className="avance">
                    <Progreso porcentaje={obra.avancePct} />
                    <strong>{formatearPorcentaje(obra.avancePct)}</strong>
                  </span>
                </td>
                <td className="monto">{formatearSoles(obra.montoAsignado, { sinDecimales: true })}</td>
                <td>{atrasada ? <Chip tono="amarillo">{actualizada}</Chip> : actualizada}</td>
                <td>
                  <Interruptor
                    activo={obra.publicada}
                    etiqueta={`Publicar ${obra.nombre}`}
                    onCambiar={() => alternarPublicada(obra)}
                  />
                </td>
                <td className="celda-accion">
                  {obra.avancePct < 100 && (
                    <button
                      type="button"
                      className="boton boton-secundario boton-fila"
                      onClick={() => sumarAvance(obra)}
                    >
                      +{formatearPorcentaje(PASO_AVANCE)} de avance
                    </button>
                  )}
                </td>
              </tr>
            );
          })}
        </Tabla>
      </section>

      <AvisoInfo>
        La municipalidad decide qué obras publica y con qué detalle. La frecuencia mínima de
        actualización se acuerda con Almira: {frecuencia} días.
      </AvisoInfo>
      <MensajeMemoria texto={mensaje} />
    </>
  );
}

function NuevaObra({
  municipalidadId,
  cantidad,
  onAgregar,
  onCancelar,
}: {
  municipalidadId: string;
  cantidad: number;
  onAgregar: (obra: Obra) => void;
  onCancelar: () => void;
}) {
  const [nombre, setNombre] = useState('');
  const [ubicacion, setUbicacion] = useState('');
  const [presupuesto, setPresupuesto] = useState('');
  const [error, setError] = useState<string | null>(null);

  const enviar = (evento: FormEvent) => {
    evento.preventDefault();
    const monto = Number(presupuesto.replace(/,/g, ''));
    if (!nombre.trim() || !ubicacion.trim() || !Number.isFinite(monto) || monto <= 0) {
      setError('Completa el nombre, la ubicación y un presupuesto mayor que cero.');
      return;
    }
    onAgregar({
      id: `o-nueva-${cantidad + 1}`,
      municipalidadId,
      nombre: nombre.trim(),
      nombreCorto: null,
      ubicacion: ubicacion.trim(),
      estado: 'en_ejecucion',
      avancePct: 0,
      meta: '',
      montoAsignado: monto,
      montoEjecutado: 0,
      fotos: 0,
      publicada: false,
      inicio: null,
      actualizadaEn: HOY_EJEMPLO,
      porcentajeTributos: null,
      hitos: [],
    });
  };

  return (
    <Tarjeta titulo="Nueva obra" subtitulo="Se agrega sin publicar y solo en esta sesión de ejemplo.">
      <form className="formulario-obra" onSubmit={enviar} noValidate>
        <label className="campo">
          Nombre de la obra
          <input value={nombre} onChange={(e) => setNombre(e.target.value)} autoFocus />
        </label>
        <label className="campo">
          Ubicación
          <input value={ubicacion} onChange={(e) => setUbicacion(e.target.value)} />
        </label>
        <label className="campo">
          Presupuesto (S/)
          <input
            inputMode="numeric"
            value={presupuesto}
            onChange={(e) => setPresupuesto(e.target.value)}
          />
        </label>
        {error && (
          <p className="campo-error" role="alert">
            {error}
          </p>
        )}
        <div className="acciones acciones-fila">
          <button type="submit" className="boton boton-primario">
            Agregar obra
          </button>
          <button type="button" className="boton boton-secundario" onClick={onCancelar}>
            Cancelar
          </button>
        </div>
      </form>
    </Tarjeta>
  );
}
