import { formatearFechaCorta, nombreDistrito, type EstadoArco } from '@almira/shared';
import { Chip, Encabezado, NotaEjemplo, Tabla, Tarjeta, type TonoChip } from '../componentes';
import { useSesion } from '../estado';
import { Icono, type NombreIcono } from '../iconos';

const ESTADO_ARCO: Record<EstadoArco, { texto: string; tono: TonoChip }> = {
  en_plazo: { texto: 'En plazo', tono: 'info' },
  atendida: { texto: 'Atendida', tono: 'ok' },
};

// "28 oct", sin el año.
const diaMes = (fechaIso: string) => formatearFechaCorta(fechaIso).replace(/ \d{4}$/, '');

// Datos y accesos (web-09). El registro y las solicitudes son de ejemplo.
export function DatosAccesos() {
  const { sesion } = useSesion();
  const { panel } = sesion;

  const principios: { icono: NombreIcono; titulo: string; texto: string }[] = [
    {
      icono: 'candado',
      titulo: 'Datos aislados',
      texto: `${nombreDistrito(sesion.municipalidad)} nunca ve datos de otra municipalidad. Lo común es la plataforma.`,
    },
    {
      icono: 'personas',
      titulo: 'Acceso por rol',
      texto: 'Previsto: cada funcionario verá solo lo que su área necesita.',
    },
    {
      icono: 'prohibido',
      titulo: 'Sin scoring',
      texto: 'El panel no muestra rankings de vecinos ni clasifica pagadores.',
    },
  ];

  return (
    <>
      <Encabezado
        titulo="Datos y accesos"
        subtitulo="La municipalidad es responsable. Almira es encargado."
      />

      <div className="cifras cifras-3">
        {principios.map((principio) => (
          <section key={principio.titulo} className="tarjeta principio">
            <span className="icono-cuadro">
              <Icono nombre={principio.icono} />
            </span>
            <div>
              <h2>{principio.titulo}</h2>
              <p>{principio.texto}</p>
            </div>
          </section>
        ))}
      </div>

      <div className="fila fila-2 fila-arriba">
        <Tarjeta titulo="Registro de accesos" subtitulo="Trazabilidad para auditoría y reclamos.">
          <Tabla columnas={[{ titulo: 'Hora' }, { titulo: 'Rol' }, { titulo: 'Acción' }]}>
            {panel.registroAccesos.map((acceso) => (
              <tr key={`${acceso.hora}-${acceso.accion}`}>
                <td>{acceso.hora}</td>
                <td>{acceso.rol}</td>
                <td>{acceso.accion}</td>
              </tr>
            ))}
          </Tabla>
        </Tarjeta>

        <Tarjeta
          titulo="Solicitudes ARCO"
          subtitulo="Derechos de los vecinos, gestionados por la municipalidad."
        >
          <Tabla columnas={[{ titulo: 'Tipo' }, { titulo: 'Recibida' }, { titulo: 'Estado' }]}>
            {panel.solicitudesArco.map((solicitud) => (
              <tr key={solicitud.tipo}>
                <td>{solicitud.tipo}</td>
                <td>{diaMes(solicitud.recibida)}</td>
                <td>
                  <Chip tono={ESTADO_ARCO[solicitud.estado].tono}>
                    {ESTADO_ARCO[solicitud.estado].texto}
                  </Chip>
                </td>
              </tr>
            ))}
          </Tabla>
        </Tarjeta>
      </div>

      <NotaEjemplo>
        Todo en esta página es de ejemplo: el registro de accesos y las solicitudes ARCO no son
        reales.
      </NotaEjemplo>
    </>
  );
}
