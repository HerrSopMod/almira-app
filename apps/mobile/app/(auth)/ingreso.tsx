import { colors, nombreDistrito, spacing, USUARIO_EJEMPLO } from '@almira/shared';
import { router } from 'expo-router';
import { useState } from 'react';
import { StyleSheet } from 'react-native';
import { Destacado, PiePrototipo } from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Boton } from '@/components/Boton';
import { Campo } from '@/components/Campo';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';
import { useDatosMunicipales } from '@/sesion';

const LARGO_CODIGO = 6;

// Pantalla 02 del prototipo. Todo es simulado: no se envía ningún SMS ni se guarda nada.
export default function Ingreso() {
  const { municipalidad } = useDatosMunicipales();
  const [documento, setDocumento] = useState<string>(USUARIO_EJEMPLO.dniEnmascarado);
  const [celular, setCelular] = useState<string>(USUARIO_EJEMPLO.telefonoEnmascarado);
  const [codigo, setCodigo] = useState<string>(USUARIO_EJEMPLO.codigoSmsEjemplo);

  return (
    <Pantalla
      encabezadoHastaArriba
      separacion="block"
      encabezado={<BarraSuperior titulo="Ingresa a tu cuenta" />}
    >
      <Texto variante="bodyMd" color={colors.textSecondary}>
        Usa los datos con los que figuras en el padrón municipal de{' '}
        {nombreDistrito(municipalidad)}.
      </Texto>
      <Campo
        etiqueta="DNI o carné de extranjería"
        autoComplete="off"
        value={documento}
        onChangeText={setDocumento}
      />
      <Campo
        etiqueta="Celular para recibir tu código"
        keyboardType="phone-pad"
        autoComplete="off"
        value={celular}
        onChangeText={setCelular}
      />
      <Campo
        etiqueta="Código de 6 dígitos enviado por SMS"
        keyboardType="number-pad"
        textContentType="oneTimeCode"
        maxLength={LARGO_CODIGO}
        value={codigo}
        onChangeText={(texto) => setCodigo(texto.replace(/\D/g, ''))}
        style={estilos.codigo}
      />
      <Destacado
        tono="informacion"
        texto="Datos de ejemplo. En este prototipo no se envía ni se guarda ninguna información."
      />
      <Boton
        titulo="Continuar"
        deshabilitado={codigo.length !== LARGO_CODIGO}
        onPress={() => router.push('/consentimiento')}
      />
      <PiePrototipo />
    </Pantalla>
  );
}

const estilos = StyleSheet.create({
  codigo: { letterSpacing: spacing.xs },
});
