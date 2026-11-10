import { colors, sizes, spacing } from '@almira/shared';
import { MaterialIcons } from '@expo/vector-icons';
import { useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { Destacado, Nota, Rotulo } from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { InterruptoresConsentimiento } from '@/components/InterruptoresConsentimiento';
import { Menu } from '@/components/Menu';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';
import { useDatosMunicipales, useSesion } from '@/sesion';

const DERECHOS = [
  { titulo: 'Acceder a mis datos', icono: 'visibility' },
  { titulo: 'Rectificar un dato', icono: 'edit' },
  { titulo: 'Cancelar mi cuenta', icono: 'person-remove' },
  { titulo: 'Oponerme a un uso', icono: 'pan-tool' },
] as const;

const NO_HACE = [
  'No vende ni comparte tus datos con terceros.',
  'No te califica como «buen» o «mal» pagador.',
  'El asistente orienta, pero no toma decisiones tributarias.',
  'No ejecuta la cobranza coactiva ni sustituye a la municipalidad.',
];

// Pantalla 22 (maqueta 22-privacidad-y-mis-datos). Los permisos son los que guardó el consentimiento
// (pantalla 03) y se cambian aquí mismo. Las solicitudes ARCO son simuladas.
export default function Privacidad() {
  const { municipalidad } = useDatosMunicipales();
  const { consentimientos, guardarConsentimientos } = useSesion();
  const [solicitud, setSolicitud] = useState<string | null>(null);

  return (
    <Pantalla
      encabezadoHastaArriba
      encabezado={<BarraSuperior titulo="Privacidad y mis datos" />}
    >
      <Destacado
        icono="account-balance"
        titulo={`Responsable: ${municipalidad.nombre}`}
        texto="Almira trata tus datos por encargo, solo para la gestión municipal."
      />

      <View style={estilos.seccion}>
        <Rotulo texto="Mis derechos (ARCO)" />
        <Menu
          opciones={DERECHOS.map(({ titulo, icono }) => ({
            titulo,
            icono,
            onPress: () => setSolicitud(titulo),
          }))}
        />
        {solicitud ? (
          <Texto variante="bodyMd" color={colors.textSecondary} alineacion="center">
            {solicitud}: la atiende {municipalidad.nombre}, responsable de tus datos.
          </Texto>
        ) : null}
      </View>

      {/* Los permisos del consentimiento (pantalla 03) se siguen cambiando aquí. */}
      <View style={estilos.seccion}>
        <Rotulo texto="Autoriza lo que quieras usar" />
        <InterruptoresConsentimiento valor={consentimientos} onCambiar={guardarConsentimientos} />
      </View>

      <View style={estilos.seccion}>
        <Rotulo texto="Lo que Almira no hace" />
        {NO_HACE.map((texto) => (
          <View key={texto} style={estilos.fila}>
            <MaterialIcons name="block" size={sizes.icon} color={colors.textSecondary} />
            <Texto color={colors.textSecondary} style={estilos.flexible}>
              {texto}
            </Texto>
          </View>
        ))}
      </View>

    </Pantalla>
  );
}

const estilos = StyleSheet.create({
  seccion: { gap: spacing.blockDense },
  fila: { flexDirection: 'row', alignItems: 'flex-start', gap: spacing.blockDense },
  flexible: { flex: 1 },
});
