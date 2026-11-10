import { colors, MINUTOS_ESPERA_EJEMPLO, sizes, spacing } from '@almira/shared';
import { MaterialIcons } from '@expo/vector-icons';
import { router } from 'expo-router';
import { Fragment, useState } from 'react';
import { StyleSheet, View } from 'react-native';
import {
  CajaIcono,
  Insignia,
  Rotulo,
  Separador,
  Tarjeta,
  type NombreIcono,
} from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Boton } from '@/components/Boton';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';
import { useSesion } from '@/sesion';

// Pantalla 14 (maqueta 14-atencion-humana). Es simulada: el tiempo es de ejemplo,
// no hay nadie conectado y no se envía ningún aviso.
export default function AtencionHumana() {
  const { consentimientos } = useSesion();
  const [esperando, setEsperando] = useState(false);
  // Si el vecino no autorizó guardar sus consultas, no se le promete compartirlas.
  const loQueVera: { texto: string; icono: NombreIcono }[] = [
    ...(consentimientos.asistenteIa
      ? [{ texto: 'Tu consulta con el asistente, sin repetirla', icono: 'forum' as const }]
      : []),
    { texto: 'Tus deudas pendientes', icono: 'receipt-long' },
    { texto: 'Tus reclamos abiertos', icono: 'report-gmailerrorred' },
  ];

  return (
    <Pantalla encabezadoHastaArriba encabezado={<BarraSuperior titulo="Atención humana" />}>
      <View style={estilos.centro}>
        <CajaIcono icono="support-agent" grande redonda />
        <Texto variante="headlineMd" alineacion="center" accessibilityRole="header">
          Te pasamos con Atención al vecino
        </Texto>
        <Insignia texto={`Tiempo estimado: ${MINUTOS_ESPERA_EJEMPLO} minutos`} tono="info" centrada />
      </View>

      <View style={estilos.seccion}>
        <Rotulo texto="La persona ya verá" />
        <Tarjeta>
          {loQueVera.map(({ texto, icono }, indice) => (
            <Fragment key={texto}>
              {indice > 0 ? <Separador /> : null}
              <View style={estilos.item}>
                <MaterialIcons name={icono} size={sizes.icon} color={colors.primary} />
                <Texto style={estilos.flexible}>{texto}</Texto>
              </View>
            </Fragment>
          ))}
        </Tarjeta>
      </View>

      <View style={estilos.botones}>
        <Boton
          titulo={esperando ? 'En espera' : 'Esperar y avisarme'}
          deshabilitado={esperando}
          onPress={() => setEsperando(true)}
        />
        <Boton
          tipo="secundario"
          titulo="Prefiero ir al módulo presencial"
          onPress={() => router.push('/sin-smartphone')}
        />
        <Boton
          tipo="terciario"
          titulo="Volver al asistente"
          onPress={() => router.navigate('/asistente')}
        />
      </View>
    </Pantalla>
  );
}

const estilos = StyleSheet.create({
  centro: { alignItems: 'center', gap: spacing.blockDense, paddingTop: spacing.sm },
  seccion: { gap: spacing.blockDense },
  item: { flexDirection: 'row', alignItems: 'center', gap: spacing.md },
  flexible: { flex: 1 },
  botones: { gap: spacing.sm, marginTop: spacing.xl },
});
