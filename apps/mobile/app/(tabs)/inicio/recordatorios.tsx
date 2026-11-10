import {
  avisosRecibidos,
  CANALES_AVISO,
  colors,
  ETIQUETA_CANAL,
  fechaAviso,
  HOY_EJEMPLO,
  momentoAviso,
  sizes,
  spacing,
  tipoAvisoActual,
  tituloAviso,
  type CanalAviso,
} from '@almira/shared';
import { MaterialIcons } from '@expo/vector-icons';
import { router } from 'expo-router';
import { Fragment } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import {
  CajaIcono,
  Destacado,
  Nota,
  Rotulo,
  Separador,
  Tarjeta,
  Vacio,
  type NombreIcono,
} from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Boton } from '@/components/Boton';
import { EscaleraAvisos } from '@/components/Escalera';
import { Interruptor } from '@/components/Interruptor';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';
import { VincularWhatsapp } from '@/components/VincularWhatsapp';
import { useDatosMunicipales, useSesion } from '@/sesion';

const ICONO_CANAL: Record<CanalAviso, NombreIcono> = {
  whatsapp: 'chat-bubble-outline',
  sms: 'sms',
  app: 'notifications-none',
};

// Pantalla 09 (Stitch 8). Los canales van con interruptores porque se pueden
// elegir varios; siempre queda al menos uno prendido.
export default function Recordatorios() {
  const { deudas, recordatorios, canalesAviso } = useDatosMunicipales();
  const { alternarCanalAviso } = useSesion();
  const avisos = avisosRecibidos(recordatorios).flatMap((aviso) => {
    const deuda = deudas.find((fila) => fila.id === aviso.deudaId);
    return deuda ? [{ aviso, deuda }] : [];
  });

  return (
    <Pantalla
      conPestanas
      encabezadoHastaArriba
      encabezado={<BarraSuperior titulo="Recordatorios" />}
    >
      <Destacado icono="shield" titulo="Almira te avisa; no ejecuta cobranzas coactivas" />

      <View style={estilos.seccion}>
        <Rotulo texto="Mis avisos" />
        {avisos.length === 0 ? (
          <Vacio texto="Aún no tienes avisos en esta municipalidad." />
        ) : (
          <Tarjeta>
            {avisos.map(({ aviso, deuda }, indice) => {
              const titulo = tituloAviso(aviso.tipo, deuda);
              const detalle = `${ETIQUETA_CANAL[aviso.canal]} · ${momentoAviso(fechaAviso(aviso), HOY_EJEMPLO)}`;
              return (
                <Fragment key={aviso.id}>
                  {indice > 0 ? <Separador /> : null}
                  <Pressable
                    accessibilityRole="button"
                    accessibilityLabel={`${titulo}. ${detalle}`}
                    onPress={() =>
                      router.push({ pathname: '/avisos/[id]', params: { id: aviso.id } })
                    }
                    style={estilos.fila}
                  >
                    <CajaIcono icono="chat-bubble-outline" />
                    <View style={estilos.flexible}>
                      <Texto variante="bodyLgMedium">{titulo}</Texto>
                      <Texto variante="bodyMd" color={colors.textSecondary}>
                        {detalle}
                      </Texto>
                    </View>
                    <MaterialIcons
                      name="chevron-right"
                      size={sizes.icon}
                      color={colors.textSecondary}
                    />
                  </Pressable>
                </Fragment>
              );
            })}
          </Tarjeta>
        )}
      </View>

      <View style={estilos.seccion}>
        <Rotulo texto="Tres pasos, de menor a mayor presión" />
        <EscaleraAvisos actual={tipoAvisoActual(recordatorios, deudas)} />
      </View>
      <Boton
        tipo="terciario"
        titulo="Ver cómo llegan por WhatsApp y SMS"
        onPress={() => router.push('/avisos/como-llegan')}
      />

      <View style={estilos.seccion}>
        <Rotulo texto="¿Por dónde te avisamos?" />
        <Tarjeta>
          {CANALES_AVISO.map((canal, indice) => (
            <Fragment key={canal}>
              {indice > 0 ? <Separador /> : null}
              <Interruptor
                icono={ICONO_CANAL[canal]}
                titulo={ETIQUETA_CANAL[canal]}
                activo={canalesAviso.includes(canal)}
                onCambiar={() => alternarCanalAviso(canal)}
              />
            </Fragment>
          ))}
        </Tarjeta>
      </View>

      <VincularWhatsapp />

      <Nota
        icono="schedule"
        texto="Te contactamos 1 vez por día y 3 por semana como máximo, de 8:00 a 20:00 h. Antes de avisar verificamos si ya pagaste."
      />
    </Pantalla>
  );
}

const estilos = StyleSheet.create({
  seccion: { gap: spacing.blockDense },
  fila: { flexDirection: 'row', alignItems: 'center', gap: spacing.blockDense },
  flexible: { flex: 1 },
});
