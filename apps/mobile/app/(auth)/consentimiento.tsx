import { colors, radius, sizes, spacing } from '@almira/shared';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { router } from 'expo-router';
import { useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { Destacado, Separador, Tarjeta } from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Boton } from '@/components/Boton';
import { Interruptor } from '@/components/Interruptor';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';
import { useDatosMunicipales, useSesion } from '@/sesion';

// Pantalla 03 del prototipo. Los permisos se guardan solo en memoria.
export default function Consentimiento() {
  const { municipalidad } = useDatosMunicipales();
  const { consentimientos, guardarConsentimientos } = useSesion();
  const [permisos, setPermisos] = useState(consentimientos);

  const entrar = () => {
    guardarConsentimientos(permisos);
    // Al entrar, "volver" ya no regresa a las pantallas de entrada.
    if (router.canDismiss()) router.dismissAll();
    router.replace('/inicio');
  };

  return (
    <Pantalla
      encabezadoHastaArriba
      separacion="block"
      encabezado={<BarraSuperior titulo="Tus datos, tus reglas" />}
    >
      <Tarjeta>
        <View style={estilos.responsable}>
          <View style={estilos.escudo}>
            <MaterialCommunityIcons name="shield-check-outline" size={22} color={colors.primary} />
          </View>
          <View style={estilos.flexible}>
            <Texto variante="labelLg">{municipalidad.nombre} es responsable de tus datos</Texto>
            <Texto variante="bodyMd" color={colors.textSecondary}>
              Almira solo los trata por encargo (Ley N.° 29733).
            </Texto>
          </View>
        </View>
      </Tarjeta>

      <Texto variante="headlineSm" fuente="poppins" accessibilityRole="header" style={estilos.seccion}>
        Autoriza lo que quieras usar
      </Texto>
      <Tarjeta>
        <Interruptor
          titulo="Asistente con IA"
          detalle="Guarda tus consultas para orientarte mejor."
          activo={permisos.asistenteIa}
          onCambiar={(asistenteIa) => setPermisos((p) => ({ ...p, asistenteIa }))}
        />
        <Separador />
        <Interruptor
          titulo="Avisos por WhatsApp"
          detalle="Máximo 1 por día y 3 por semana."
          activo={permisos.avisosWhatsapp}
          onCambiar={(avisosWhatsapp) => setPermisos((p) => ({ ...p, avisosWhatsapp }))}
        />
        <Separador />
        <Interruptor
          titulo="Avisos por SMS"
          detalle="Canal alterno si WhatsApp falla."
          activo={permisos.avisosSms}
          onCambiar={(avisosSms) => setPermisos((p) => ({ ...p, avisosSms }))}
        />
      </Tarjeta>

      <Destacado
        tono="exito"
        icono="check"
        texto="Nunca vendemos tus datos ni te calificamos como «buen» o «mal» pagador."
      />
      <Boton titulo="Aceptar y entrar" onPress={entrar} />
      <Boton
        tipo="terciario"
        titulo="Leer la política de privacidad"
        onPress={() => router.push('/privacidad')}
      />
    </Pantalla>
  );
}

const estilos = StyleSheet.create({
  responsable: { flexDirection: 'row', alignItems: 'center', gap: spacing.block },
  escudo: {
    width: sizes.featureIcon,
    height: sizes.featureIcon,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: radius.md,
    backgroundColor: colors.backgroundPink,
  },
  flexible: { flex: 1 },
  seccion: { marginTop: spacing.sm },
});
