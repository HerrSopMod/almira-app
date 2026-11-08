import { colors, radius, sizes, spacing } from '@almira/shared';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { router } from 'expo-router';
import { useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { PiePrototipo } from '@/components/Bloques';
import { Boton } from '@/components/Boton';
import { Campo } from '@/components/Campo';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';

const LARGO_DNI = 8;

// Login estático. Google y el SMS son solo diseño: no hay cuenta, sesión ni envío real.
export default function Login() {
  const [dni, setDni] = useState('');

  return (
    <Pantalla separacion="block">
      <View style={estilos.cabecera}>
        <View style={estilos.icono}>
          <MaterialCommunityIcons name="bank" size={32} color={colors.primary} />
        </View>
        <View style={estilos.chip}>
          <View style={estilos.punto} />
          <Texto variante="labelSm" color={colors.header}>
            SERVICIOS TRIBUTARIOS MUNICIPALES
          </Texto>
        </View>
        <Texto variante="headlineLg" fuente="poppins" color={colors.header} accessibilityRole="header">
          Ingresa a tu cuenta
        </Texto>
        <Texto color={colors.textSecondary} alineacion="center">
          Consulta y paga tus tributos municipales con claridad.
        </Texto>
      </View>

      <Boton
        tipo="linea"
        titulo="Continuar con Google"
        izquierda={<MaterialCommunityIcons name="google" size={20} color={colors.text} />}
        onPress={() => router.push('/entrada')}
      />

      <View style={estilos.separador}>
        <View style={estilos.linea} />
        <Texto variante="bodyMd" color={colors.textSecondary}>
          o con tu DNI
        </Texto>
        <View style={estilos.linea} />
      </View>

      <View style={estilos.grupo}>
        <View style={estilos.etiqueta}>
          <Texto variante="label">Número de DNI</Texto>
          <Texto variante="caption" color={colors.textSecondary}>
            {dni.length}/{LARGO_DNI}
          </Texto>
        </View>
        <Campo
          accessibilityLabel="Número de DNI"
          placeholder="Ingresa tus 8 dígitos"
          keyboardType="number-pad"
          autoComplete="off"
          maxLength={LARGO_DNI}
          value={dni}
          onChangeText={(texto) => setDni(texto.replace(/\D/g, ''))}
        />
      </View>

      <Boton
        titulo="Recibir código por SMS"
        icono="sms"
        deshabilitado={dni.length !== LARGO_DNI}
        onPress={() => router.push('/ingreso')}
      />

      <Texto variante="caption" color={colors.textSecondary} alineacion="center">
        Al continuar, aceptas los términos de servicio y la política de privacidad.
      </Texto>
      <PiePrototipo />
    </Pantalla>
  );
}

const estilos = StyleSheet.create({
  cabecera: { alignItems: 'center', gap: spacing.block, paddingTop: spacing.lg },
  icono: {
    width: sizes.brandIcon,
    height: sizes.brandIcon,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: radius.md,
    backgroundColor: colors.backgroundPink,
  },
  chip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    paddingHorizontal: spacing.md,
    height: sizes.badge + spacing.sm,
    borderRadius: radius.full,
    backgroundColor: colors.backgroundPink,
  },
  punto: {
    width: spacing.sm,
    height: spacing.sm,
    borderRadius: radius.full,
    backgroundColor: colors.primary,
  },
  separador: { flexDirection: 'row', alignItems: 'center', gap: spacing.md },
  linea: { flex: 1, height: sizes.borderWidth, backgroundColor: colors.border },
  grupo: { gap: spacing.sm },
  etiqueta: { flexDirection: 'row', justifyContent: 'space-between' },
});
