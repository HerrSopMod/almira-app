import {
  colors,
  ETIQUETA_CANAL,
  ETIQUETA_TIPO_RECORDATORIO,
  fechaAviso,
  formatearFechaCorta,
  formatearSoles,
  HOY_EJEMPLO,
  mensajeAviso,
  momentoAviso,
  obraParaAvisos,
  sizes,
  spacing,
  totalDeuda,
  USUARIO_EJEMPLO,
} from '@almira/shared';
import { MaterialIcons } from '@expo/vector-icons';
import { router, useLocalSearchParams } from 'expo-router';
import { StyleSheet, View } from 'react-native';
import {
  ChipEstadoDeuda,
  FilaDato,
  Nota,
  PiePrototipo,
  Rotulo,
  Separador,
  Tarjeta,
  Vacio,
} from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Boton } from '@/components/Boton';
import { NumeroPaso } from '@/components/Escalera';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';
import { useDatosMunicipales } from '@/sesion';

// Pantalla 10 (maqueta 10-detalle-del-aviso).
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
    <Pantalla encabezadoHastaArriba encabezado={encabezado}>
      <View style={estilos.cabecera}>
        <NumeroPaso tipo={aviso.tipo} />
        <View style={estilos.flexible}>
          <Texto variante="headlineMd" accessibilityRole="header">
            {ETIQUETA_TIPO_RECORDATORIO[aviso.tipo]}
          </Texto>
          <Texto color={colors.textSecondary}>
            {ETIQUETA_CANAL[aviso.canal]} · {momentoAviso(fechaAviso(aviso), HOY_EJEMPLO)}
          </Texto>
        </View>
      </View>

      <Tarjeta grande>
        <View style={estilos.rotulo}>
          <MaterialIcons name="chat" size={sizes.iconSm} color={colors.primary} />
          <Rotulo texto="Mensaje recibido" />
        </View>
        <Texto>{mensaje}</Texto>
      </Tarjeta>

      <Tarjeta>
        <FilaDato etiqueta="Deuda" valor={deuda.concepto} />
        <Separador />
        <FilaDato etiqueta="Monto" valor={formatearSoles(totalDeuda(deuda))} />
        <Separador />
        <FilaDato etiqueta="Vence" valor={formatearFechaCorta(deuda.vencimiento)} />
        <Separador />
        <FilaDato etiqueta="Estado" valor={<ChipEstadoDeuda estado={deuda.estado} />} />
      </Tarjeta>

      <Nota texto="Antes de enviar cada aviso verificamos si ya pagaste." />

      <View style={estilos.botones}>
        <Boton titulo="Ir a pagar" onPress={() => router.navigate('/cuenta')} />
        <Boton
          tipo="secundario"
          titulo="No entiendo este aviso"
          onPress={() => router.navigate('/asistente')}
        />
      </View>
      <PiePrototipo />
    </Pantalla>
  );
}

const estilos = StyleSheet.create({
  cabecera: { flexDirection: 'row', alignItems: 'flex-start', gap: spacing.blockDense },
  flexible: { flex: 1 },
  rotulo: { flexDirection: 'row', alignItems: 'center', gap: spacing.sm },
  botones: { gap: spacing.sm, marginTop: spacing.sm },
});
