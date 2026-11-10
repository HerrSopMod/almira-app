import {
  colors,
  HORARIO_MODULO_EJEMPLO,
  sizes,
  SMS_NUMERO_EJEMPLO,
  spacing,
} from '@almira/shared';
import { MaterialIcons } from '@expo/vector-icons';
import { useState, type ComponentProps, type ReactNode } from 'react';
import { router } from 'expo-router';
import { StyleSheet, View } from 'react-native';
import { CajaIcono, Rotulo, Tarjeta } from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Boton } from '@/components/Boton';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';
import { useSesion } from '@/sesion';

const EN_EL_MODULO = [
  'Consultar y pagar tus deudas',
  'Presentar un reclamo con foto y ubicación',
  'Recibir tu constancia impresa',
];

// Pantalla 23 (maqueta 23-sin-smartphone). El número SMS y el horario son de ejemplo, y la
// reserva de turno es simulada. Se abre sin sesión desde el ingreso, y también desde Mi
// perfil y Atención humana.
export default function SinSmartphone() {
  const { consentimientoAceptado } = useSesion();
  const [reservado, setReservado] = useState(false);

  // Si se abrió directo, sin pantalla anterior: sin sesión vuelve al ingreso.
  const volver = () => {
    if (router.canGoBack()) router.back();
    else router.replace(consentimientoAceptado ? '/inicio' : '/ingreso');
  };

  return (
    <Pantalla
      encabezadoHastaArriba
      encabezado={<BarraSuperior titulo="Sin smartphone" onVolver={volver} />}
    >
      <Texto color={colors.textSecondary}>
        La información es la misma en todos los canales. Elige el que te quede mejor.
      </Texto>

      <Tarjeta>
        <Canal
          icono="sms"
          titulo="Por SMS desde cualquier celular"
          detalle={
            <>
              Envía{' '}
              <Texto variante="bodyMd" peso="700" color={colors.text}>
                DEUDA
              </Texto>{' '}
              al {SMS_NUMERO_EJEMPLO} (número simulado). Es gratis.
            </>
          }
        />
      </Tarjeta>

      <Tarjeta>
        <Canal
          icono="storefront"
          titulo="Módulo asistido en el palacio municipal"
          detalle={`${HORARIO_MODULO_EJEMPLO}. Lleva tu DNI.`}
        />
      </Tarjeta>
      {/* El botón va fuera de la tarjeta (LEEME.md → Botones). */}
      <Boton
        icono="event-available"
        titulo={reservado ? 'Turno reservado' : 'Reservar turno sin cola'}
        deshabilitado={reservado}
        onPress={() => setReservado(true)}
      />

      <Tarjeta>
        <Canal
          icono="family-restroom"
          titulo="Un familiar puede ayudarte"
          detalle="Con tu autorización, puede consultar y pagar por ti."
        />
      </Tarjeta>

      <View style={estilos.seccion}>
        <Rotulo texto="Qué puedes hacer en el módulo" />
        {EN_EL_MODULO.map((texto) => (
          <View key={texto} style={estilos.fila}>
            <MaterialIcons name="check-circle-outline" size={sizes.icon} color={colors.primary} />
            <Texto style={estilos.flexible}>{texto}</Texto>
          </View>
        ))}
      </View>
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
  detalle: ReactNode;
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
  fila: { flexDirection: 'row', alignItems: 'center', gap: spacing.blockDense },
  flexible: { flex: 1 },
  seccion: { gap: spacing.blockDense },
});
