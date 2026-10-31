import { colors, radius, sizes, spacing, USUARIO_EJEMPLO } from '@almira/shared';
import { MaterialIcons } from '@expo/vector-icons';
import { router } from 'expo-router';
import { useState } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { Boton } from '@/components/Boton';
import { Encabezado } from '@/components/Encabezado';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';

const LARGO_CODIGO = 6;
const TECLAS = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', 'borrar'];

export default function Verificacion() {
  const [codigo, setCodigo] = useState('');
  const [reenviado, setReenviado] = useState(false);

  const pulsar = (tecla: string) => {
    if (tecla === 'borrar') setCodigo((actual) => actual.slice(0, -1));
    else setCodigo((actual) => (actual.length < LARGO_CODIGO ? actual + tecla : actual));
  };

  return (
    <Pantalla
      encabezado={<Encabezado conVolver />}
      pie={
        <Boton
          titulo="Verificar"
          deshabilitado={codigo.length !== LARGO_CODIGO}
          onPress={() => router.replace('/municipalidad')}
        />
      }
    >
      <View style={estilos.titulos}>
        <Texto variante="headlineLg">Ingresa el código</Texto>
        <Texto color={colors.textSecondary}>
          Lo enviamos por SMS al {USUARIO_EJEMPLO.telefonoEnmascarado}
        </Texto>
      </View>

      <View style={estilos.casillas} accessibilityLabel={`Código: ${codigo.length} de 6 dígitos`}>
        {Array.from({ length: LARGO_CODIGO }, (_, indice) => (
          <View
            key={indice}
            style={[estilos.casilla, indice === codigo.length && estilos.casillaActiva]}
          >
            <Texto variante="headlineMd">{codigo[indice] ?? ''}</Texto>
          </View>
        ))}
      </View>

      {reenviado ? (
        <Texto variante="bodyMd" color={colors.success} alineacion="center">
          Código reenviado con éxito
        </Texto>
      ) : null}
      <Boton tipo="terciario" titulo="Reenviar código" onPress={() => setReenviado(true)} />
      <Boton tipo="terciario" titulo="Cambiar DNI" onPress={() => router.back()} />

      <View style={estilos.teclado}>
        {TECLAS.map((tecla, indice) =>
          tecla === '' ? (
            <View key={indice} style={estilos.tecla} />
          ) : (
            <Pressable
              key={indice}
              accessibilityRole="button"
              accessibilityLabel={tecla === 'borrar' ? 'Borrar número' : tecla}
              onPress={() => pulsar(tecla)}
              style={estilos.tecla}
            >
              {tecla === 'borrar' ? (
                <MaterialIcons name="backspace" size={24} color={colors.text} />
              ) : (
                <Texto variante="headlineMd">{tecla}</Texto>
              )}
            </Pressable>
          ),
        )}
      </View>
    </Pantalla>
  );
}

const estilos = StyleSheet.create({
  titulos: { gap: spacing.sm },
  casillas: { flexDirection: 'row', justifyContent: 'space-between', gap: spacing.sm },
  casilla: {
    flex: 1,
    height: 56,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: sizes.borderWidth,
    borderColor: colors.border,
    borderRadius: radius.md,
  },
  casillaActiva: { borderWidth: sizes.focusBorderWidth, borderColor: colors.primary },
  teclado: { flexDirection: 'row', flexWrap: 'wrap' },
  tecla: {
    width: '33.33%',
    height: sizes.button,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
