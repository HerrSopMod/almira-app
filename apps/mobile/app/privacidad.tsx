import { colors, spacing } from '@almira/shared';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { Destacado, IconoCuadro, Tarjeta } from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { InterruptoresConsentimiento } from '@/components/InterruptoresConsentimiento';
import { Menu } from '@/components/Menu';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';
import { useDatosMunicipales, useSesion } from '@/sesion';

const DERECHOS = [
  { titulo: 'Acceder a mis datos', icono: 'eye-outline' },
  { titulo: 'Rectificar un dato', icono: 'file-document-outline' },
  { titulo: 'Cancelar mi cuenta', icono: 'close' },
  { titulo: 'Oponerme a un uso', icono: 'alert-outline' },
] as const;

const NO_HACE = [
  'No vende ni comparte tus datos con terceros.',
  'No te califica como «buen» o «mal» pagador.',
  'La IA orienta, pero no toma decisiones tributarias.',
  'No ejecuta la cobranza coactiva ni sustituye a la municipalidad.',
];

// Pantalla 22 del prototipo. Los permisos son los que guardó el consentimiento
// (pantalla 03) y se cambian aquí mismo. Las solicitudes ARCO son simuladas.
export default function Privacidad() {
  const { municipalidad } = useDatosMunicipales();
  const { consentimientos, guardarConsentimientos } = useSesion();
  const [solicitud, setSolicitud] = useState<string | null>(null);

  return (
    <Pantalla
      encabezadoHastaArriba
      separacion="block"
      encabezado={<BarraSuperior titulo="Privacidad y mis datos" />}
    >
      <Tarjeta>
        <View style={estilos.fila}>
          <IconoCuadro icono="bank-outline" />
          <View style={estilos.flexible}>
            <Texto variante="labelLg">Responsable: {municipalidad.nombre}</Texto>
            <Texto variante="bodyMd" color={colors.textSecondary}>
              Almira trata tus datos por encargo, solo para la gestión municipal.
            </Texto>
          </View>
        </View>
      </Tarjeta>

      <Seccion titulo="Autoriza lo que quieras usar" />
      <InterruptoresConsentimiento valor={consentimientos} onCambiar={guardarConsentimientos} />

      <Seccion titulo="Mis derechos (ARCO)" />
      <Menu
        opciones={DERECHOS.map(({ titulo, icono }) => ({
          titulo,
          icono,
          onPress: () => setSolicitud(titulo),
        }))}
      />
      {solicitud ? (
        <Texto variante="bodyMd" color={colors.textSecondary} alineacion="center">
          {solicitud}: solicitud simulada. En este prototipo no se envía; la atiende{' '}
          {municipalidad.nombre}, responsable de tus datos.
        </Texto>
      ) : null}

      <Seccion titulo="Lo que Almira no hace" />
      <Tarjeta>
        {NO_HACE.map((texto) => (
          <View key={texto} style={estilos.filaArriba}>
            <MaterialCommunityIcons name="close" size={20} color={colors.header} />
            <Texto color={colors.textSecondary} style={estilos.flexible}>
              {texto}
            </Texto>
          </View>
        ))}
      </Tarjeta>

      {/* El prototipo afirma cifrado y registro de accesos, que aún no existen. */}
      <Destacado
        tono="informacion"
        icono="lock-outline"
        texto="En este prototipo los datos son ficticios y no salen de tu teléfono. El cifrado y el registro de accesos aún no están implementados."
      />
    </Pantalla>
  );
}

function Seccion({ titulo }: { titulo: string }) {
  return (
    <Texto variante="headlineSm" fuente="poppins" accessibilityRole="header" style={estilos.seccion}>
      {titulo}
    </Texto>
  );
}

const estilos = StyleSheet.create({
  fila: { flexDirection: 'row', alignItems: 'center', gap: spacing.md },
  filaArriba: { flexDirection: 'row', alignItems: 'flex-start', gap: spacing.md },
  flexible: { flex: 1 },
  seccion: { marginTop: spacing.sm },
});
