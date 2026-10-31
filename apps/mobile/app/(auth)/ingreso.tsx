import { colors, spacing } from '@almira/shared';
import { router } from 'expo-router';
import { useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { Boton } from '@/components/Boton';
import { Campo } from '@/components/Campo';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';

export default function Ingreso() {
  const [dni, setDni] = useState('');

  return (
    <Pantalla>
      <View style={estilos.marca}>
        <Texto variante="headlineLg" color={colors.primary}>
          Almira
        </Texto>
      </View>
      <View style={estilos.titulos}>
        <Texto variante="headlineLg">Ingresa a tu cuenta</Texto>
        <Texto color={colors.textSecondary}>
          Consulta y paga tus tributos municipales con claridad.
        </Texto>
      </View>
      <Boton
        tipo="secundario"
        titulo="Continuar con Google"
        onPress={() => router.push('/vincular-dni')}
      />
      <Texto variante="bodyMd" color={colors.textSecondary} alineacion="center">
        o con tu DNI
      </Texto>
      <Campo
        etiqueta="Número de DNI"
        ayuda={`${dni.length}/8`}
        placeholder="Ingresa tus 8 dígitos"
        keyboardType="number-pad"
        maxLength={8}
        value={dni}
        onChangeText={(texto) => setDni(texto.replace(/\D/g, ''))}
      />
      <Boton
        icono="sms"
        titulo="Recibir código por SMS"
        deshabilitado={dni.length !== 8}
        onPress={() => router.push('/verificacion')}
      />
      <Texto variante="bodyMd" color={colors.textSecondary} alineacion="center">
        Al continuar, aceptas nuestros Términos de servicio y Política de privacidad.
      </Texto>
    </Pantalla>
  );
}

const estilos = StyleSheet.create({
  marca: { paddingTop: spacing.xl },
  titulos: { gap: spacing.sm },
});
