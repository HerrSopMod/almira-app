import { colors, iniciales, sizes, spacing } from '@almira/shared';
import { router } from 'expo-router';
import { StyleSheet, View } from 'react-native';
import { PiePrototipo, Tarjeta } from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Boton } from '@/components/Boton';
import { Interruptor } from '@/components/Interruptor';
import { Menu } from '@/components/Menu';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';
import { useDatosMunicipales } from '@/sesion';
import { useTextoGrande } from '@/textoGrande';

// Pantalla 21 del prototipo, dentro de la pestaña Inicio.
export default function Perfil() {
  const { vecino, predios } = useDatosMunicipales();
  const textoGrande = useTextoGrande();

  const cerrarSesion = () => {
    // El ingreso es simulado: cerrar sesión vuelve a la entrada.
    if (router.canDismiss()) router.dismissAll();
    router.replace('/entrada');
  };

  return (
    <Pantalla
      conPestanas
      encabezadoHastaArriba
      separacion="blockDense"
      encabezado={<BarraSuperior titulo="Mi perfil" />}
    >
      {vecino ? (
        <Tarjeta>
          <View style={estilos.fila}>
            <View style={estilos.avatar}>
              <Texto variante="bodyLgMedium" color={colors.onPrimary}>
                {iniciales(vecino.nombre)}
              </Texto>
            </View>
            <View style={estilos.flexible}>
              <Texto variante="bodyLgMedium">{vecino.nombre}</Texto>
              {vecino.codigoContribuyente ? (
                <Texto variante="bodyMd" color={colors.textSecondary}>
                  Código de contribuyente: {vecino.codigoContribuyente}
                </Texto>
              ) : null}
            </View>
          </View>
        </Tarjeta>
      ) : null}

      {predios.map((predio) => (
        <Tarjeta key={predio.id}>
          <View style={estilos.predio}>
            <Texto variante="bodyMd" color={colors.textSecondary}>
              Mi predio
            </Texto>
            <Texto variante="bodyLgMedium">{predio.direccion}</Texto>
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
            icono: 'people-outline',
            onPress: () => router.push('/sin-smartphone'),
          },
          {
            titulo: 'Mis constancias',
            icono: 'description',
            onPress: () => router.navigate('/cuenta'),
          },
        ]}
      />

      <Tarjeta>
        <Interruptor
          titulo="Texto más grande"
          detalle="Mejora la lectura en toda la app"
          activo={textoGrande.activo}
          onCambiar={textoGrande.cambiar}
        />
      </Tarjeta>

      <Boton tipo="secundario" titulo="Cerrar sesión" onPress={cerrarSesion} />
      <PiePrototipo />
    </Pantalla>
  );
}

const estilos = StyleSheet.create({
  fila: { flexDirection: 'row', alignItems: 'center', gap: spacing.md },
  flexible: { flex: 1 },
  predio: { gap: spacing.xs },
  avatar: {
    width: sizes.avatar,
    height: sizes.avatar,
    borderRadius: sizes.avatar / 2,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.primary,
  },
});
