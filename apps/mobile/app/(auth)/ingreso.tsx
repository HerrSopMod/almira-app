import { colors, documentoValido, sizes, spacing } from '@almira/shared';
import { router } from 'expo-router';
import { useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { Nota, PiePrototipo, TituloPantalla } from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Boton } from '@/components/Boton';
import { CampoDocumento } from '@/components/CampoDocumento';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';
import { DOCUMENTO_EJEMPLO, useSesion } from '@/sesion';

// Pantalla 02a (Stitch 1). Con Google sigue a Vincula tu DNI; con DNI, al código.
// Todo es simulado: no se abre Google, no se envía ningún SMS ni se guarda nada.
export default function Ingreso() {
  const { iniciarConGoogle, iniciarConDni } = useSesion();
  const [documento, setDocumento] = useState(DOCUMENTO_EJEMPLO);
  const [falloGoogle, setFalloGoogle] = useState(false);

  const conGoogle = async () => {
    setFalloGoogle(false);
    try {
      await iniciarConGoogle();
      router.push('/vincular-dni');
    } catch {
      setFalloGoogle(true);
    }
  };

  const conDni = () => {
    iniciarConDni();
    router.push('/codigo');
  };

  return (
    <Pantalla encabezadoHastaArriba encabezado={<BarraSuperior titulo="Paso 1 de 3" />}>
      <TituloPantalla
        titulo="Ingresa a tu cuenta"
        texto="Usa los datos con los que figuras en el padrón municipal."
      />
      <Boton tipo="google" titulo="Continuar con Google" onPress={conGoogle} />
      {falloGoogle ? (
        <Nota texto="No pudimos ingresar con Google. Inténtalo de nuevo o usa tu DNI." />
      ) : null}

      <View style={estilos.divisor}>
        <View style={estilos.linea} />
        <Texto variante="bodyMd" color={colors.textSecondary}>
          o con tu DNI
        </Texto>
        <View style={estilos.linea} />
      </View>

      <CampoDocumento valor={documento} onCambiar={setDocumento} />
      <Boton
        icono="sms"
        titulo="Recibir código por SMS"
        deshabilitado={!documentoValido(documento)}
        onPress={conDni}
      />
      <Nota texto="Datos de ejemplo. En este prototipo no se envía ni se guarda ninguna información." />
      <PiePrototipo />
    </Pantalla>
  );
}

const estilos = StyleSheet.create({
  divisor: { flexDirection: 'row', alignItems: 'center', gap: spacing.blockDense },
  linea: { flex: 1, height: sizes.borderWidth, backgroundColor: colors.border },
});
