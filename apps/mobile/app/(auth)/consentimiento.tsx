import { colors, radius, sizes, spacing } from '@almira/shared';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { router } from 'expo-router';
import { useEffect, useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { Destacado, Tarjeta } from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Boton } from '@/components/Boton';
import { InterruptoresConsentimiento } from '@/components/InterruptoresConsentimiento';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';
import { useDatosMunicipales, useSesion } from '@/sesion';

// Pantalla 03 del prototipo. Los permisos se guardan solo en memoria.
export default function Consentimiento() {
  const { municipalidad } = useDatosMunicipales();
  const { consentimientos, guardarConsentimientos } = useSesion();
  const [permisos, setPermisos] = useState(consentimientos);
  // Si los cambia en Privacidad y mis datos (desde "Leer la política"), se reflejan aquí.
  useEffect(() => setPermisos(consentimientos), [consentimientos]);

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
      <InterruptoresConsentimiento valor={permisos} onCambiar={setPermisos} />

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
