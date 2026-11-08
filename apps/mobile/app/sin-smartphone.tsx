import { colors, HORARIO_MODULO_EJEMPLO, SMS_NUMERO_EJEMPLO, spacing } from '@almira/shared';
import { MaterialIcons } from '@expo/vector-icons';
import { useState, type ComponentProps } from 'react';
import { StyleSheet, View } from 'react-native';
import { CajaIcono, PiePrototipo, Separador, Tarjeta } from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Boton } from '@/components/Boton';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';

const EN_EL_MODULO = [
  'Consultar y pagar tus deudas',
  'Presentar un reclamo con foto y ubicación',
  'Recibir tu constancia impresa',
];

// Pantalla 23 del prototipo. El número SMS y el horario son de ejemplo, y la
// reserva de turno es simulada.
export default function SinSmartphone() {
  const [reservado, setReservado] = useState(false);

  return (
    <Pantalla
      encabezadoHastaArriba
      separacion="blockDense"
      encabezado={<BarraSuperior titulo="Sin smartphone" />}
    >
      <Texto color={colors.textSecondary}>
        La información es la misma en todos los canales. Elige el que te quede mejor.
      </Texto>

      <Tarjeta>
        <Canal
          icono="sms"
          titulo="Por SMS desde cualquier celular"
          detalle={`Envía DEUDA al ${SMS_NUMERO_EJEMPLO} (número simulado). Es gratis.`}
        />
      </Tarjeta>

      <Tarjeta>
        <Canal
          icono="people-outline"
          titulo="Módulo asistido en el palacio municipal"
          detalle={`${HORARIO_MODULO_EJEMPLO}. Lleva tu DNI.`}
        />
        <Separador />
        <Boton
          tipo="secundario"
          titulo="Reservar turno sin cola"
          deshabilitado={reservado}
          onPress={() => setReservado(true)}
        />
        {reservado ? (
          <Texto variante="bodyMd" color={colors.textSecondary} alineacion="center">
            Reserva simulada: en este prototipo no se reserva ningún turno.
          </Texto>
        ) : null}
      </Tarjeta>

      <Tarjeta>
        <Canal
          icono="volunteer-activism"
          titulo="Un familiar puede ayudarte"
          detalle="Con tu autorización, puede consultar y pagar por ti."
        />
      </Tarjeta>

      <Texto variante="headlineSm" accessibilityRole="header" style={estilos.seccion}>
        Qué puedes hacer en el módulo
      </Texto>
      <Tarjeta>
        {EN_EL_MODULO.map((texto) => (
          <View key={texto} style={estilos.fila}>
            <MaterialIcons name="check" size={20} color={colors.textSecondary} />
            <Texto color={colors.textSecondary} style={estilos.flexible}>
              {texto}
            </Texto>
          </View>
        ))}
      </Tarjeta>
      <PiePrototipo />
    </Pantalla>
  );
}

function Canal({
  icono,
  tono,
  titulo,
  detalle,
}: {
  icono: ComponentProps<typeof CajaIcono>['icono'];
  tono?: ComponentProps<typeof CajaIcono>['tono'];
  titulo: string;
  detalle: string;
}) {
  return (
    <View style={estilos.fila}>
      <CajaIcono icono={icono} tono={tono} />
      <View style={estilos.flexible}>
        <Texto variante="bodyLgMedium">{titulo}</Texto>
        <Texto variante="bodyMd" color={colors.textSecondary}>
          {detalle}
        </Texto>
      </View>
    </View>
  );
}

const estilos = StyleSheet.create({
  fila: { flexDirection: 'row', alignItems: 'center', gap: spacing.md },
  flexible: { flex: 1 },
  seccion: { marginTop: spacing.sm },
});
