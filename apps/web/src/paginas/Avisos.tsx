import {
  formatearNumero,
  formatearPorcentaje,
  mejorVariante,
  nombreDistrito,
} from '@almira/shared';
import { useState } from 'react';
import {
  AvisoInfo,
  BarrasHorizontales,
  Chip,
  Cifra,
  Encabezado,
  MensajeMemoria,
  Tabla,
  Tarjeta,
} from '../componentes';
import { useSesion } from '../estado';

// Avisos enviados y respuestas (web-04). Las cifras son de ejemplo.
export function Avisos() {
  const { sesion, datos, cambiarDatos } = useSesion();
  const { panel } = sesion;
  const [mensaje, setMensaje] = useState<string | null>(null);
  const mejor = mejorVariante(panel.pruebaAB.variantes);

  const elegir = (letra: string) => {
    cambiarDatos((actual) => ({ ...actual, varianteElegida: letra }));
    setMensaje('Elección de ejemplo: no se guarda ni cambia los avisos que se envían.');
  };

  return (
    <>
      <Encabezado
        titulo="Avisos enviados y respuestas"
        subtitulo={`Qué aviso funciona mejor en ${nombreDistrito(sesion.municipalidad)}`}
      />

      <div className="fila fila-2">
        <Tarjeta
          titulo="Escalera de avisos"
          subtitulo={`${panel.periodo}. Pagos dentro de los ${panel.diasRespuestaAviso} días posteriores al aviso.`}
        >
          <Tabla
            columnas={[
              { titulo: 'Aviso' },
              { titulo: 'Enviados' },
              { titulo: 'Entregados' },
              { titulo: 'Pagaron' },
            ]}
          >
            {panel.escalera.map((paso) => (
              <tr key={paso.numero}>
                <td>
                  <span className="escalon">
                    <span className={`escalon-numero aviso-${paso.numero}`}>{paso.numero}</span>
                    {paso.nombre}
                  </span>
                </td>
                <td>{formatearNumero(paso.enviados)}</td>
                <td>{formatearPorcentaje(paso.entregadosPct)}</td>
                <td>
                  <strong>{formatearPorcentaje(paso.pagaronPct)}</strong>
                </td>
              </tr>
            ))}
          </Tabla>
        </Tarjeta>

        <Tarjeta titulo={panel.pruebaAB.titulo} subtitulo={panel.pruebaAB.politica}>
          <BarrasHorizontales
            filas={panel.pruebaAB.variantes.map((variante) => ({
              nombre: `${variante.letra} · ${variante.nombre}`,
              valor: variante.pagoPct,
              etiqueta: formatearPorcentaje(variante.pagoPct),
              tono: variante.letra === mejor?.letra ? 'primario' : 'secundario',
            }))}
          />
          <AvisoInfo>{panel.pruebaAB.nota}</AvisoInfo>
          {mejor &&
            (datos.varianteElegida ? (
              <p className="variante-elegida">
                <Chip tono="verde">Variante {datos.varianteElegida} elegida para el próximo ciclo</Chip>
              </p>
            ) : (
              <button type="button" className="boton boton-primario boton-bajo" onClick={() => elegir(mejor.letra)}>
                Usar variante {mejor.letra} en el próximo ciclo
              </button>
            ))}
          <MensajeMemoria texto={mensaje} />
        </Tarjeta>
      </div>

      <div className="cifras cifras-3">
        {panel.controlesAvisos.map((control) => (
          <Cifra
            key={control.etiqueta}
            etiqueta={control.etiqueta}
            valor={formatearPorcentaje(control.porcentaje)}
            detalle={control.detalle}
          />
        ))}
      </div>

      <Tarjeta
        titulo="Canales"
        subtitulo="Avisos entregados por canal. El SMS cubre a vecinos sin smartphone."
      >
        <BarrasHorizontales
          filas={panel.canales.map((canal) => ({ nombre: canal.nombre, valor: canal.cantidad }))}
        />
      </Tarjeta>
    </>
  );
}
