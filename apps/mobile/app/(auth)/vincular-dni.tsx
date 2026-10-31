import { colors, spacing } from '@almira/shared';
import { router } from 'expo-router';
import { useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { Destacado, Progreso } from '@/components/Bloques';
import { Boton } from '@/components/Boton';
import { Campo } from '@/components/Campo';
import { Encabezado } from '@/components/Encabezado';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';

export default function VincularDni() {
  const [dni, setDni] = useState('');

  return (
    <Pantalla
      encabezado={<Encabezado conVolver />}
      pie={
        <Boton
          icono="sms"
          titulo="Recibir código por SMS"
          deshabilitado={dni.length !== 8}
          onPress={() => router.push('/verificacion')}
        />
      }
    >
      <View style={estilos.grupo}>
        <Texto variante="labelSm" color={colors.textSecondary}>
          Paso 1 de 2
        </Texto>
        <Progreso porcentaje={50} />
      </View>
      <View style={estilos.grupo}>
        <Texto variante="headlineLg">Vincula tu DNI</Texto>
        <Texto color={colors.textSecondary}>
          Sirve para mostrar tus tributos municipales y predios registrados a tu nombre.
        </Texto>
      </View>
      <Campo
        etiqueta="Número de DNI"
        ayuda="Ingresa los 8 dígitos que figuran al frente de tu documento."
        placeholder="8 dígitos"
        keyboardType="number-pad"
        maxLength={8}
        value={dni}
        onChangeText={(texto) => setDni(texto.replace(/\D/g, ''))}
      />
      <Destacado
        icono="sms"
        titulo="Verificación por SMS"
        texto="Enviaremos un código temporal al número asociado a tu cuenta."
      />
      <Texto variante="bodyMd" color={colors.textSecondary}>
        Tus datos están protegidos bajo la Ley N° 29733 de Protección de Datos Personales de Perú.
      </Texto>
    </Pantalla>
  );
}

const estilos = StyleSheet.create({
  grupo: { gap: spacing.sm },
});
