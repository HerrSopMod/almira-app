import { colors, iniciales, sizes, spacing } from '@almira/shared';
import { router } from 'expo-router';
import { StyleSheet, View } from 'react-native';
import { CajaIcono, Tarjeta } from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Boton } from '@/components/Boton';
import { Interruptor } from '@/components/Interruptor';
import { Menu } from '@/components/Menu';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';
import { useDatosMunicipales, useSesion } from '@/sesion';
import { useTextoGrande } from '@/textoGrande';

// Pantalla 21 (maqueta 21-mi-perfil), dentro de la pestaña Inicio.
export default function Perfil() {
  const { municipalidad, vecino, predios } = useDatosMunicipales();
  const textoGrande = useTextoGrande();
  const { cerrarSesion: cerrarSesionCuenta } = useSesion();

  const cerrarSesion = () => {
    if (router.canDismiss()) router.dismissAll();
    router.replace('/ingreso');
    // Cierra la sesión de Supabase (signOut), si está configurado, y olvida el ingreso.
    // Va después de navegar: al olvidar el consentimiento se cierran las pantallas protegidas.
    void cerrarSesionCuenta();
  };

  return (
    <Pantalla
      conPestanas
      encabezadoHastaArriba
      encabezado={<BarraSuperior titulo="Mi perfil" />}
    >
      {vecino ? (
        <View style={estilos.fila}>
          <View style={estilos.avatar}>
            <Texto variante="headlineMd" peso="700" color={colors.onPrimary}>
              {iniciales(vecino.nombre)}
            </Texto>
          </View>
          <View style={estilos.flexible}>
            <Texto variante="headlineSm" accessibilityRole="header">
              {vecino.nombre}
            </Texto>
            {vecino.codigoContribuyente ? (
              <Texto variante="bodyMd" color={colors.textSecondary}>
                Código de contribuyente: {vecino.codigoContribuyente}
              </Texto>
            ) : null}
          </View>
        </View>
      ) : null}

      {predios.map((predio) => (
        <Tarjeta key={predio.id}>
          <View style={estilos.fila}>
            <CajaIcono icono="home" />
            <View style={estilos.flexible}>
              <Texto variante="bodyMd" color={colors.textSecondary}>
                Mi predio
              </Texto>
              <Texto variante="bodyLgMedium">{predio.direccion}</Texto>
            </View>
          </View>
        </Tarjeta>
      ))}

      <Menu
        opciones={[
          {
            titulo: 'Avisos y canales',
            icono: 'notifications-none',
            onPress: () => router.push('/inicio/recordatorios'),
          },
          {
            titulo: 'Privacidad y mis datos',
            icono: 'verified-user',
            onPress: () => router.push('/privacidad'),
          },
          {
            titulo: 'Atención presencial',
            icono: 'storefront',
            onPress: () => router.push('/sin-smartphone'),
          },
          {
            titulo: 'Mis constancias',
            icono: 'receipt-long',
            onPress: () => router.navigate('/cuenta'),
          },
          {
            titulo: 'Mi municipalidad',
            detalle: municipalidad.nombre,
            icono: 'location-city',
            // Solo cambia la municipalidad elegida: no cierra la sesión.
            onPress: () => router.push({ pathname: '/municipalidad', params: { modo: 'cambio' } }),
          },
        ]}
      />

      <Tarjeta>
        <Interruptor
          icono="format-size"
          titulo="Texto más grande"
          detalle="Mejora la lectura en toda la app"
          activo={textoGrande.activo}
          onCambiar={textoGrande.cambiar}
        />
      </Tarjeta>

      <Boton tipo="peligro" icono="logout" titulo="Cerrar sesión" onPress={cerrarSesion} />
    </Pantalla>
  );
}

const estilos = StyleSheet.create({
  fila: { flexDirection: 'row', alignItems: 'center', gap: spacing.md },
  flexible: { flex: 1 },
  avatar: {
    width: sizes.avatarLg,
    height: sizes.avatarLg,
    borderRadius: sizes.avatarLg / 2,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.primary,
  },
});
