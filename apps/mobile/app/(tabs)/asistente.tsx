import {
  bienvenidaAsistente,
  colors,
  PREGUNTAS_SUGERIDAS,
  radius,
  responderAsistente,
  sizes,
  spacing,
  typography,
  USUARIO_EJEMPLO,
  type AccionAsistente,
} from '@almira/shared';
import { Feather } from '@expo/vector-icons';
import { router } from 'expo-router';
import { useRef, useState } from 'react';
import {
  KeyboardAvoidingView,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  TextInput,
  View,
  type ScrollViewInstance,
} from 'react-native';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Boton } from '@/components/Boton';
import { Texto } from '@/components/Texto';
import { useDatosMunicipales } from '@/sesion';

type Mensaje = {
  id: number;
  autor: 'asistente' | 'vecino';
  texto: string;
  accion?: AccionAsistente;
};

const irASimulacion = () => router.push('/simulacion-cuotas');
const irAAtencionHumana = () => router.push('/atencion-humana');

// Pantalla 12 del prototipo. No hay IA: responderAsistente usa reglas fijas y la
// conversación vive solo en esta pantalla.
export default function Asistente() {
  const { deudas } = useDatosMunicipales();
  const [mensajes, setMensajes] = useState<Mensaje[]>([
    { id: 0, autor: 'asistente', texto: bienvenidaAsistente(USUARIO_EJEMPLO.nombre) },
  ]);
  const [consulta, setConsulta] = useState('');
  const lista = useRef<ScrollViewInstance>(null);

  const preguntar = (pregunta: string) => {
    const texto = pregunta.trim();
    if (texto === '') return;
    const respuesta = responderAsistente(texto, deudas);
    setMensajes((previos) => [
      ...previos,
      { id: previos.length, autor: 'vecino', texto },
      { id: previos.length + 1, autor: 'asistente', ...respuesta },
    ]);
    setConsulta('');
  };

  return (
    <View style={estilos.raiz}>
      <BarraSuperior variante="raiz" titulo="Asistente" />
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
        style={estilos.flexible}
      >
        <ScrollView
          ref={lista}
          keyboardShouldPersistTaps="handled"
          onContentSizeChange={() => lista.current?.scrollToEnd({ animated: true })}
          contentContainerStyle={estilos.mensajes}
        >
          <Texto variante="caption" color={colors.textSecondary} alineacion="center">
            Prototipo: respuestas fijas de ejemplo, sin IA real.
          </Texto>
          {mensajes.map((mensaje) =>
            mensaje.autor === 'vecino' ? (
              <View key={mensaje.id} style={[estilos.burbuja, estilos.vecino]}>
                <Texto color={colors.onPrimary}>{mensaje.texto}</Texto>
              </View>
            ) : (
              <View key={mensaje.id} style={[estilos.burbuja, estilos.asistente]}>
                <Texto>{mensaje.texto}</Texto>
                {mensaje.accion === 'simular_cuotas' ? (
                  <Boton titulo="Simular cuotas" onPress={irASimulacion} />
                ) : null}
              </View>
            ),
          )}
        </ScrollView>

        <View style={estilos.acciones}>
          <View style={estilos.fila}>
            <View style={estilos.flexible}>
              <Boton titulo="Simular cuotas" onPress={irASimulacion} />
            </View>
            <View style={estilos.flexible}>
              <Boton
                tipo="secundario"
                titulo="Hablar con una persona"
                onPress={irAAtencionHumana}
              />
            </View>
          </View>
          <Texto variante="bodyMd" color={colors.textSecondary} alineacion="center">
            La IA orienta, no decide.
          </Texto>
          <ScrollView
            horizontal
            showsHorizontalScrollIndicator={false}
            keyboardShouldPersistTaps="handled"
            contentContainerStyle={estilos.sugerencias}
          >
            {PREGUNTAS_SUGERIDAS.map((pregunta) => (
              <Pressable
                key={pregunta}
                accessibilityRole="button"
                onPress={() => preguntar(pregunta)}
                style={estilos.sugerencia}
              >
                <Texto variante="bodyMdMedium" color={colors.primary}>
                  {pregunta}
                </Texto>
              </Pressable>
            ))}
          </ScrollView>
        </View>

        <View style={estilos.entrada}>
          <TextInput
            accessibilityLabel="Escribe tu duda"
            placeholder="Escribe tu duda…"
            placeholderTextColor={colors.textSecondary}
            value={consulta}
            onChangeText={setConsulta}
            onSubmitEditing={() => preguntar(consulta)}
            returnKeyType="send"
            style={estilos.campo}
          />
          <Pressable
            accessibilityRole="button"
            accessibilityLabel="Enviar"
            onPress={() => preguntar(consulta)}
            style={estilos.enviar}
          >
            <Feather name="send" size={20} color={colors.onPrimary} />
          </Pressable>
        </View>
      </KeyboardAvoidingView>
    </View>
  );
}

const estilos = StyleSheet.create({
  raiz: { flex: 1, backgroundColor: colors.background },
  flexible: { flex: 1 },
  mensajes: {
    gap: spacing.sm,
    paddingHorizontal: spacing.margin,
    paddingVertical: spacing.md,
  },
  burbuja: {
    gap: spacing.md,
    paddingHorizontal: spacing.blockDense,
    paddingVertical: spacing.blockDense,
    borderRadius: radius.md,
  },
  asistente: {
    alignSelf: 'flex-start',
    width: sizes.bubbleWidth,
    borderTopLeftRadius: radius.sm,
    backgroundColor: colors.subtle,
  },
  vecino: {
    alignSelf: 'flex-end',
    maxWidth: sizes.bubbleWidth,
    borderTopRightRadius: radius.sm,
    backgroundColor: colors.primary,
  },
  acciones: { gap: spacing.sm, paddingTop: spacing.sm, paddingBottom: spacing.blockDense },
  fila: { flexDirection: 'row', gap: spacing.sm, paddingHorizontal: spacing.margin },
  sugerencias: { gap: spacing.sm, paddingHorizontal: spacing.margin },
  sugerencia: {
    height: sizes.suggestionChip,
    justifyContent: 'center',
    paddingHorizontal: spacing.blockDense,
    borderRadius: radius.full,
    borderWidth: sizes.borderWidth,
    borderColor: colors.border,
    backgroundColor: colors.surface,
  },
  entrada: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    paddingHorizontal: spacing.margin,
    paddingVertical: spacing.blockDense,
    borderTopWidth: sizes.borderWidth,
    borderTopColor: colors.border,
  },
  campo: {
    flex: 1,
    height: sizes.chatInput,
    paddingHorizontal: spacing.md,
    borderWidth: sizes.borderWidth,
    borderColor: colors.border,
    borderRadius: radius.md,
    color: colors.text,
    fontFamily: 'Inter_400Regular',
    fontSize: typography.bodyLg.fontSize,
  },
  enviar: {
    width: sizes.chatInput,
    height: sizes.chatInput,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.primary,
    borderRadius: radius.md,
  },
});
