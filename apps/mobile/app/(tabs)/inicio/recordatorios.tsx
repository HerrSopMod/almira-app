import {
  avisosRecibidos,
  colors,
  ETIQUETA_CANAL,
  fechaAviso,
  HOY_EJEMPLO,
  momentoAviso,
  radius,
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
import { Destacado, IconoCuadro, PiePrototipo, Separador, Tarjeta, Vacio } from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Boton } from '@/components/Boton';
import { EscaleraAvisos } from '@/components/Escalera';
import { Pantalla } from '@/components/Pantalla';
import { Radio } from '@/components/Radio';
import { Texto } from '@/components/Texto';
import { useDatosMunicipales, useSesion } from '@/sesion';

const CANALES: CanalAviso[] = ['whatsapp', 'sms', 'app'];

// Pantalla 09 del prototipo.
export default function Recordatorios() {
  const { deudas, recordatorios, canalAviso } = useDatosMunicipales();
  const { elegirCanalAviso } = useSesion();
  const avisos = avisosRecibidos(recordatorios).flatMap((aviso) => {
    const deuda = deudas.find((fila) => fila.id === aviso.deudaId);
    return deuda ? [{ aviso, deuda }] : [];
  });

  return (
    <Pantalla
      conPestanas
      encabezadoHastaArriba
      separacion="block"
      encabezado={<BarraSuperior titulo="Recordatorios" />}
    >
      <Seccion titulo="Mis avisos" primera />
      {avisos.length === 0 ? (
        <Vacio texto="Aún no tienes avisos en esta municipalidad." />
      ) : (
        avisos.map(({ aviso, deuda }) => {
          const titulo = tituloAviso(aviso.tipo, deuda);
          const detalle = `${ETIQUETA_CANAL[aviso.canal]} · ${momentoAviso(fechaAviso(aviso), HOY_EJEMPLO)}`;
          return (
            <Pressable
              key={aviso.id}
              accessibilityRole="button"
              accessibilityLabel={`${titulo}. ${detalle}`}
              onPress={() => router.push({ pathname: '/avisos/[id]', params: { id: aviso.id } })}
            >
              <Tarjeta>
                <View style={estilos.fila}>
                  <IconoCuadro icono="message-outline" />
                  <View style={estilos.flexible}>
                    <Texto variante="labelLg">{titulo}</Texto>
                    <Texto variante="bodyMd" color={colors.textSecondary}>
                      {detalle}
                    </Texto>
                  </View>
                  <MaterialIcons name="chevron-right" size={24} color={colors.text} />
                </View>
              </Tarjeta>
            </Pressable>
          );
        })
      )}

      <Seccion titulo="Tres pasos, de menor a mayor presión" />
      <EscaleraAvisos actual={tipoAvisoActual(recordatorios, deudas)} />
      <Boton
        tipo="secundario"
        titulo="Ver cómo llegan por WhatsApp y SMS"
        onPress={() => router.push('/avisos/como-llegan')}
      />

      <Seccion titulo="¿Por dónde te avisamos?" />
      <View accessibilityRole="radiogroup" style={estilos.canales}>
        {CANALES.map((canal, indice) => (
          <Fragment key={canal}>
            {indice > 0 ? <Separador /> : null}
            <Pressable
              accessibilityRole="radio"
              accessibilityState={{ checked: canalAviso === canal }}
              onPress={() => elegirCanalAviso(canal)}
              style={[estilos.fila, estilos.canal]}
            >
              <Texto variante="bodyLgMedium" style={estilos.flexible}>
                {ETIQUETA_CANAL[canal]}
              </Texto>
              <Radio marcado={canalAviso === canal} />
            </Pressable>
          </Fragment>
        ))}
      </View>

      <Destacado
        tono="informacion"
        icono="schedule"
        texto="Te contactamos 1 vez por día y 3 por semana como máximo, de 8:00 a 20:00 h. Antes de avisar verificamos si ya pagaste."
      />
      <PiePrototipo />
    </Pantalla>
  );
}

function Seccion({ titulo, primera }: { titulo: string; primera?: boolean }) {
  return (
    <Texto
      variante="headlineSm"
      fuente="poppins"
      accessibilityRole="header"
      style={primera ? undefined : estilos.seccion}
    >
      {titulo}
    </Texto>
  );
}

const estilos = StyleSheet.create({
  fila: { flexDirection: 'row', alignItems: 'center', gap: spacing.block },
  flexible: { flex: 1 },
  seccion: { marginTop: spacing.sm },
  canales: {
    paddingHorizontal: spacing.md,
    borderWidth: sizes.borderWidth,
    borderColor: colors.border,
    borderRadius: radius.md,
  },
  canal: { minHeight: sizes.button },
});
