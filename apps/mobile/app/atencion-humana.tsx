import { colors, MINUTOS_ESPERA_EJEMPLO, sizes, spacing } from '@almira/shared';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { router } from 'expo-router';
import { useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { PiePrototipo, Tarjeta } from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Boton } from '@/components/Boton';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';
import { useSesion } from '@/sesion';

// Pantalla 14 del prototipo. Es simulada: el tiempo es de ejemplo, no hay nadie
// conectado y no se envía ningún aviso.
export default function AtencionHumana() {
  const { consentimientos } = useSesion();
  const [esperando, setEsperando] = useState(false);
  // Si el vecino no autorizó guardar sus consultas, no se le promete compartirlas.
  const loQueVera = [
    ...(consentimientos.asistenteIa ? ['Tu consulta con el asistente, sin repetirla'] : []),
    'Tus deudas pendientes',
    'Tus reclamos abiertos',
  ];

  return (
    <Pantalla
      encabezadoHastaArriba
      separacion="block"
      encabezado={<BarraSuperior titulo="Atención humana" />}
    >
      <Tarjeta>
        <View style={estilos.centro}>
          <View style={estilos.icono}>
            <MaterialCommunityIcons
              name="account-multiple-outline"
              size={28}
              color={colors.primary}
            />
          </View>
          <Texto variante="headlineSm" fuente="poppins" alineacion="center">
            Te pasamos con Atención al vecino
          </Texto>
          <Texto variante="bodyMd" color={colors.textSecondary} alineacion="center">
            Tiempo estimado: {MINUTOS_ESPERA_EJEMPLO} minutos
          </Texto>
        </View>
      </Tarjeta>

      <Tarjeta>
        <View style={estilos.lista}>
          <Texto variante="labelLg">La persona ya verá</Texto>
          {loQueVera.map((item) => (
            <View key={item} style={estilos.item}>
              <MaterialCommunityIcons name="check" size={20} color={colors.textSecondary} />
              <Texto color={colors.textSecondary} style={estilos.flexible}>
                {item}
              </Texto>
            </View>
          ))}
        </View>
      </Tarjeta>

      <Boton
        titulo="Esperar y avisarme"
        deshabilitado={esperando}
        onPress={() => setEsperando(true)}
      />
      {esperando ? (
        <Texto variante="bodyMd" color={colors.textSecondary} alineacion="center">
          Espera simulada: en este prototipo no hay una persona conectada ni se envía ningún aviso.
        </Texto>
      ) : null}
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
      <PiePrototipo />
    </Pantalla>
  );
}

const estilos = StyleSheet.create({
  centro: { alignItems: 'center', gap: spacing.xs },
  icono: {
    width: sizes.attentionIcon,
    height: sizes.attentionIcon,
    marginBottom: spacing.sm,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: sizes.attentionIcon / 2,
    backgroundColor: colors.backgroundPink,
  },
  lista: { gap: spacing.sm },
  item: { flexDirection: 'row', alignItems: 'center', gap: spacing.block },
  flexible: { flex: 1 },
});
