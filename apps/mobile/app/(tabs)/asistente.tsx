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
import { MaterialIcons } from '@expo/vector-icons';
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
import { CajaIcono, Nota, Rotulo } from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Boton } from '@/components/Boton';
import { familiaInter, Texto, useEscalaTexto } from '@/components/Texto';
import { useDatosMunicipales } from '@/sesion';

type Mensaje = {
  id: number;
  autor: 'asistente' | 'vecino';
  texto: string;
  accion?: AccionAsistente;
};

const irASimulacion = () => router.push('/simulacion-cuotas');
const irAAtencionHumana = () => router.push('/atencion-humana');

// Pantalla 12 (Stitch 9). No hay IA: responderAsistente usa reglas fijas y la
// conversación vive solo en esta pantalla. El simulador está en la pantalla 13.
export default function Asistente() {
  const { deudas } = useDatosMunicipales();
  const escala = useEscalaTexto();
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
          // Al entrar se ve desde arriba; con cada respuesta baja hasta el final.
          onContentSizeChange={() => {
            if (mensajes.length > 1) lista.current?.scrollToEnd({ animated: true });
          }}
          contentContainerStyle={estilos.contenido}
        >
          <View style={estilos.rotulo}>
            <MaterialIcons name="support-agent" size={sizes.iconSm} color={colors.primary} />
            <Texto variante="overline" color={colors.primary} accessibilityRole="header">
              Asistente de Almira
            </Texto>
          </View>

          <View style={estilos.seccion}>
            <Rotulo texto="Preguntas sugeridas" />
            {PREGUNTAS_SUGERIDAS.map((pregunta) => (
              <Pressable
                key={pregunta}
                accessibilityRole="button"
                onPress={() => preguntar(pregunta)}
                style={estilos.sugerencia}
              >
                <MaterialIcons name="help-outline" size={sizes.iconSm} color={colors.primary} />
                <Texto variante="bodyLgMedium">{pregunta}</Texto>
              </Pressable>
            ))}
          </View>

          <View style={estilos.conversacion}>
            {mensajes.map((mensaje) =>
              mensaje.autor === 'vecino' ? (
                <View key={mensaje.id} style={[estilos.burbuja, estilos.vecino]}>
                  <Texto color={colors.onPrimary}>{mensaje.texto}</Texto>
                </View>
              ) : (
                <View key={mensaje.id} style={estilos.filaAsistente}>
                  <CajaIcono icono="support-agent" redonda />
                  <View style={estilos.columnaAsistente}>
                    <View style={[estilos.burbuja, estilos.asistente]}>
                      <Texto>{mensaje.texto}</Texto>
                    </View>
                    {/* La acción va debajo de la burbuja, no dentro. */}
                    {mensaje.accion === 'simular_cuotas' ? (
                      <Pressable
                        accessibilityRole="button"
                        onPress={irASimulacion}
                        style={estilos.accion}
                      >
                        <MaterialIcons name="calculate" size={sizes.iconSm} color={colors.primary} />
                        <Texto variante="bodyLgMedium" color={colors.primary}>
                          Simular cuotas
                        </Texto>
                      </Pressable>
                    ) : null}
                  </View>
                </View>
              ),
            )}
          </View>

          <View style={estilos.botones}>
            <Boton titulo="Simular cuotas" onPress={irASimulacion} />
            <Boton tipo="secundario" titulo="Hablar con una persona" onPress={irAAtencionHumana} />
          </View>
          <Nota texto="El asistente orienta, no decide. Prototipo: respuestas fijas de ejemplo." />
        </ScrollView>

        <View style={estilos.entrada}>
          <TextInput
            accessibilityLabel="Escribe tu duda"
            placeholder="Escribe tu duda…"
            placeholderTextColor={colors.textSecondary}
            value={consulta}
            onChangeText={setConsulta}
            onSubmitEditing={() => preguntar(consulta)}
            returnKeyType="send"
            style={[estilos.campo, { fontSize: typography.bodyLg.fontSize * escala }]}
          />
          <Pressable
            accessibilityRole="button"
            accessibilityLabel="Enviar"
            onPress={() => preguntar(consulta)}
            style={estilos.enviar}
          >
            <MaterialIcons name="send" size={sizes.icon} color={colors.onPrimary} />
          </Pressable>
        </View>
      </KeyboardAvoidingView>
    </View>
  );
}

const estilos = StyleSheet.create({
  raiz: { flex: 1, backgroundColor: colors.background },
  flexible: { flex: 1 },
  contenido: {
    gap: spacing.block,
    paddingHorizontal: spacing.margin,
    paddingTop: spacing.md,
    paddingBottom: spacing.lg,
  },
  rotulo: { flexDirection: 'row', alignItems: 'center', gap: spacing.sm },
  seccion: { gap: spacing.sm },
  sugerencia: {
    alignSelf: 'flex-start',
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    minHeight: sizes.buttonTertiary,
    paddingHorizontal: spacing.md,
    borderRadius: radius.full,
    borderWidth: sizes.borderWidth,
    borderColor: colors.border,
    backgroundColor: colors.surface,
  },
  conversacion: { gap: spacing.blockDense },
  filaAsistente: { flexDirection: 'row', alignItems: 'flex-start', gap: spacing.sm },
  columnaAsistente: { flex: 1, alignItems: 'flex-start', gap: spacing.xs },
  burbuja: {
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.blockDense,
    borderRadius: radius.lg,
  },
  asistente: {
    maxWidth: '100%',
    borderTopLeftRadius: radius.sm,
    backgroundColor: colors.subtle,
  },
  vecino: {
    alignSelf: 'flex-end',
    maxWidth: sizes.bubbleWidth,
    borderTopRightRadius: radius.sm,
    backgroundColor: colors.primary,
  },
  accion: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.xs,
    minHeight: sizes.buttonTertiary,
  },
  botones: { gap: spacing.sm },
  entrada: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    paddingHorizontal: spacing.margin,
    paddingVertical: spacing.blockDense,
    borderTopWidth: sizes.borderWidth,
    borderTopColor: colors.border,
    backgroundColor: colors.background,
  },
  campo: {
    flex: 1,
    height: sizes.input,
    paddingHorizontal: spacing.md,
    borderWidth: sizes.borderWidth,
    borderColor: colors.border,
    borderRadius: radius.md,
    color: colors.text,
    fontFamily: familiaInter('400'),
  },
  enviar: {
    width: sizes.input,
    height: sizes.input,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.primary,
    borderRadius: radius.md,
  },
});
