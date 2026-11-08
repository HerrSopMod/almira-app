import {
  colors,
  ETIQUETA_CANAL,
  fechaAviso,
  formatearFechaCorta,
  formatearSoles,
  HOY_EJEMPLO,
  mensajeAviso,
  momentoAviso,
  obraParaAvisos,
  spacing,
  totalDeuda,
  USUARIO_EJEMPLO,
} from '@almira/shared';
import { router, useLocalSearchParams } from 'expo-router';
import type { ReactNode } from 'react';
import { StyleSheet, View } from 'react-native';
import { ChipEstadoDeuda, PiePrototipo, Tarjeta, Vacio } from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Boton } from '@/components/Boton';
import { PasoAviso } from '@/components/Escalera';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';
import { useDatosMunicipales } from '@/sesion';

// Pantalla 10 del prototipo.
export default function DetalleAviso() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { recordatorios, deudas, obras } = useDatosMunicipales();
  const aviso = recordatorios.find((fila) => fila.id === id);
  const deuda = aviso ? deudas.find((fila) => fila.id === aviso.deudaId) : undefined;
  const encabezado = <BarraSuperior titulo="Detalle del aviso" />;

  if (!aviso || !deuda) {
    return (
      <Pantalla encabezadoHastaArriba encabezado={encabezado}>
        <Vacio texto="No encontramos este aviso en tu municipalidad." />
      </Pantalla>
    );
  }

  const mensaje = mensajeAviso({
    tipo: aviso.tipo,
    deuda,
    nombre: USUARIO_EJEMPLO.nombre,
    obra: obraParaAvisos(obras),
  });

  return (
    <Pantalla encabezadoHastaArriba separacion="block" encabezado={encabezado}>
      <PasoAviso tipo={aviso.tipo} />

      <Tarjeta>
        <View style={estilos.mensaje}>
          <Texto variante="bodyMd" color={colors.textSecondary}>
            {ETIQUETA_CANAL[aviso.canal]} · {momentoAviso(fechaAviso(aviso), HOY_EJEMPLO)}
          </Texto>
          <Texto>{mensaje}</Texto>
        </View>
      </Tarjeta>

      <Tarjeta>
        <View style={estilos.filas}>
          <Fila etiqueta="Deuda">
            <Texto variante="labelLg" alineacion="right">
              {deuda.concepto}
            </Texto>
          </Fila>
          <Fila etiqueta="Monto">
            <Texto variante="labelLg" alineacion="right" tabular>
              {formatearSoles(totalDeuda(deuda))}
            </Texto>
          </Fila>
          <Fila etiqueta="Vence">
            <Texto variante="labelLg" alineacion="right">
              {formatearFechaCorta(deuda.vencimiento)}
            </Texto>
          </Fila>
          <Fila etiqueta="Estado">
            <ChipEstadoDeuda estado={deuda.estado} />
          </Fila>
        </View>
      </Tarjeta>

      <Boton titulo="Ir a Mi cuenta" onPress={() => router.navigate('/cuenta')} />
      <Boton
        tipo="linea"
        titulo="No entiendo este aviso"
        onPress={() => router.navigate('/asistente')}
      />
      <PiePrototipo />
    </Pantalla>
  );
}

function Fila({ etiqueta, children }: { etiqueta: string; children: ReactNode }) {
  return (
    <View style={estilos.fila}>
      <Texto color={colors.textSecondary} style={estilos.flexible}>
        {etiqueta}
      </Texto>
      {children}
    </View>
  );
}

const estilos = StyleSheet.create({
  mensaje: { gap: spacing.sm },
  filas: { gap: spacing.sm },
  fila: { flexDirection: 'row', alignItems: 'center', gap: spacing.md },
  flexible: { flex: 1 },
});
