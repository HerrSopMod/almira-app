import {
  colors,
  deudasPendientes,
  formatearSoles,
  radius,
  sizes,
  spacing,
  sumarDeudas,
} from '@almira/shared';
import { MaterialIcons } from '@expo/vector-icons';
import { useState } from 'react';
import { Pressable, StyleSheet, TextInput, View } from 'react-native';
import { Destacado, FilaDato, Tarjeta } from '@/components/Bloques';
import { Boton } from '@/components/Boton';
import { Encabezado } from '@/components/Encabezado';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';
import { useDatosMunicipales } from '@/sesion';

const CUOTAS = [2, 3, 4, 6];
const BIENVENIDA =
  '¡Hola! Soy tu asistente de rentas. Puedes consultar tu estado de cuenta, cronograma tributario o cómo gestionar beneficios por pronto pago. ¿En qué te oriento hoy?';
const SIN_CONEXION =
  'Este esqueleto usa respuestas de ejemplo. Prueba con las preguntas frecuentes.';

export default function Asistente() {
  const { municipalidad, deudas } = useDatosMunicipales();
  const total = sumarDeudas(deudasPendientes(deudas));

  const [cuotas, setCuotas] = useState(3);
  const [simulador, setSimulador] = useState(false);
  const [consulta, setConsulta] = useState('');
  const [respuesta, setRespuesta] = useState(BIENVENIDA);

  const enviar = () => {
    if (consulta.trim() === '') return;
    setRespuesta(SIN_CONEXION);
    setConsulta('');
  };

  return (
    <Pantalla
      conPestanas
      encabezado={<Encabezado titulo="Asistente" conAvisos />}
      pie={
        <View style={estilos.entrada}>
          <TextInput
            accessibilityLabel="Escribe tu consulta tributaria"
            placeholder="Escribe tu consulta tributaria..."
            placeholderTextColor={colors.textSecondary}
            value={consulta}
            onChangeText={setConsulta}
            onSubmitEditing={enviar}
            style={estilos.campo}
          />
          <Pressable
            accessibilityRole="button"
            accessibilityLabel="Enviar consulta tributaria"
            onPress={enviar}
            style={estilos.enviar}
          >
            <MaterialIcons name="send" size={24} color={colors.onPrimary} />
          </Pressable>
        </View>
      }
    >
      <View style={estilos.grupo}>
        <Texto variante="headlineLg">Asistente tributario</Texto>
        <Texto color={colors.textSecondary}>Respuestas claras sobre tus arbitrios y predial.</Texto>
      </View>

      <Tarjeta>
        <Texto>{respuesta}</Texto>
      </Tarjeta>

      <View style={estilos.grupo}>
        <Texto variante="headlineMd">Preguntas frecuentes</Texto>
        <Boton
          tipo="secundario"
          titulo="¿Cuánto debo en total?"
          onPress={() =>
            setRespuesta(`Tu deuda total pendiente es ${formatearSoles(total)} en ${municipalidad.nombre}.`)
          }
        />
        <Boton tipo="secundario" titulo="Simular pago en cuotas" onPress={() => setSimulador(true)} />
        <Boton
          tipo="secundario"
          titulo="¿Cómo reclamar un arbitrio?"
          onPress={() =>
            setRespuesta(
              'Entra a Reclamos, elige Nuevo reclamo con evidencia y sigue los tres pasos: tipo, foto y GPS, y detalle.',
            )
          }
        />
      </View>

      {simulador ? (
        <>
          <Tarjeta>
            <Texto variante="headlineSm">Simulador de fraccionamiento</Texto>
            <FilaDato etiqueta="Deuda a simular" valor={formatearSoles(total)} />
            <Texto variante="bodyMdMedium">Selecciona número de cuotas:</Texto>
            <View style={estilos.cuotas}>
              {CUOTAS.map((opcion) => (
                <Pressable
                  key={opcion}
                  accessibilityRole="button"
                  accessibilityLabel={`${opcion} meses`}
                  accessibilityState={{ selected: cuotas === opcion }}
                  onPress={() => setCuotas(opcion)}
                  style={[estilos.cuota, cuotas === opcion && estilos.cuotaActiva]}
                >
                  <Texto
                    variante="bodyLgMedium"
                    color={cuotas === opcion ? colors.onPrimary : colors.text}
                  >
                    {opcion}
                  </Texto>
                  <Texto
                    variante="labelSm"
                    color={cuotas === opcion ? colors.onPrimary : colors.textSecondary}
                  >
                    meses
                  </Texto>
                </Pressable>
              ))}
            </View>
            <FilaDato
              etiqueta="Monto mensual proyectado"
              valor={`${cuotas} cuotas de ${formatearSoles(total / cuotas)}`}
            />
          </Tarjeta>
          <Destacado
            texto={`Simulación orientativa, no es un compromiso de pago. El fraccionamiento oficial requiere solicitud formal según TUPA de la ${municipalidad.nombre}.`}
          />
        </>
      ) : null}
    </Pantalla>
  );
}

const estilos = StyleSheet.create({
  grupo: { gap: spacing.sm },
  entrada: { flexDirection: 'row', gap: spacing.sm },
  campo: {
    flex: 1,
    height: sizes.input,
    paddingHorizontal: spacing.md,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: radius.md,
    color: colors.text,
    fontFamily: 'Inter_400Regular',
    fontSize: 16,
  },
  enviar: {
    width: sizes.button,
    height: sizes.button,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.primary,
    borderRadius: radius.md,
  },
  cuotas: { flexDirection: 'row', gap: spacing.sm },
  cuota: {
    flex: 1,
    minHeight: sizes.button,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: radius.md,
  },
  cuotaActiva: { backgroundColor: colors.primary, borderColor: colors.primary },
});
