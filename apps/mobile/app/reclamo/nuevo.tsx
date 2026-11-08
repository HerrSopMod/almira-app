import { colors, radius, sizes, spacing } from '@almira/shared';
import { MaterialIcons } from '@expo/vector-icons';
import { router } from 'expo-router';
import { useState } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { Destacado } from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Boton } from '@/components/Boton';
import { Campo } from '@/components/Campo';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';
import { useDatosMunicipales } from '@/sesion';

// Descripción de ejemplo del prototipo: el vecino puede cambiarla.
const DESCRIPCION_EJEMPLO =
  'Hay un bache grande en la pista frente a mi casa, los carros lo esquivan.';

// Pantalla 16 del prototipo. La foto y la ubicación son simuladas: no se usa la
// cámara ni el GPS. La ubicación parte de la dirección del predio y se puede ajustar.
export default function NuevoReclamo() {
  const { predios } = useDatosMunicipales();
  const [foto, setFoto] = useState(false);
  const [direccion, setDireccion] = useState(predios[0]?.direccion ?? '');
  const [ajustando, setAjustando] = useState(direccion === '');
  const [descripcion, setDescripcion] = useState(DESCRIPCION_EJEMPLO);

  const listo = foto && direccion.trim() !== '' && descripcion.trim() !== '';

  return (
    <Pantalla
      encabezadoHastaArriba
      separacion="blockDense"
      encabezado={<BarraSuperior titulo="Nuevo reclamo" />}
    >
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={foto ? 'Foto de ejemplo agregada' : 'Agregar foto'}
        disabled={foto}
        onPress={() => setFoto(true)}
        style={[estilos.foto, foto && estilos.fotoLista]}
      >
        <MaterialIcons
          name={foto ? 'check-circle-outline' : 'photo-camera'}
          size={40}
          color={foto ? colors.paidIcon : colors.primary}
        />
        <Texto variante="bodyLgMedium" color={foto ? colors.paidText : colors.primary}>
          {foto ? 'Foto de ejemplo agregada' : 'Agregar foto'}
        </Texto>
        <Texto variante="caption" color={colors.textSecondary} alineacion="center">
          Simulada: en este prototipo no se usa la cámara.
        </Texto>
      </Pressable>

      <View style={estilos.ubicacion}>
        <MaterialIcons name="place" size={28} color={colors.primary} />
        <View style={estilos.flexible}>
          <Texto variante="bodyLgMedium">Ubicación del problema</Texto>
          {ajustando ? (
            <Campo
              accessibilityLabel="Dirección del problema"
              placeholder="Escribe la dirección"
              value={direccion}
              onChangeText={setDireccion}
            />
          ) : (
            <Texto variante="bodyMd" color={colors.textSecondary}>
              {direccion} · GPS simulado
            </Texto>
          )}
        </View>
        {!ajustando ? (
          <Pressable accessibilityRole="button" hitSlop={8} onPress={() => setAjustando(true)}>
            <Texto variante="bodyLgMedium" color={colors.primary}>
              Ajustar
            </Texto>
          </Pressable>
        ) : null}
      </View>

      <Campo
        etiqueta="Describe el problema"
        multiline
        value={descripcion}
        onChangeText={setDescripcion}
        style={estilos.descripcion}
      />

      <Boton
        titulo="Enviar reclamo"
        deshabilitado={!listo}
        onPress={() =>
          router.push({
            pathname: '/reclamo/envio',
            params: { descripcion: descripcion.trim(), direccion: direccion.trim() },
          })
        }
      />
      <Texto variante="bodyMd" color={colors.textSecondary} alineacion="center">
        Se deriva al área correspondiente.
      </Texto>
      <Destacado
        icono="lock-outline"
        texto="La foto y la ubicación se usan solo para atender este reclamo."
      />
    </Pantalla>
  );
}

const estilos = StyleSheet.create({
  foto: {
    height: sizes.evidencePhoto,
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing.xs,
    paddingHorizontal: spacing.md,
    borderWidth: sizes.borderWidth,
    borderStyle: 'dashed',
    borderColor: colors.photoDashed,
    borderRadius: radius.md,
    backgroundColor: colors.backgroundPinkSoft,
  },
  fotoLista: { borderStyle: 'solid', borderColor: colors.paidSoft, backgroundColor: colors.paidSoft },
  ubicacion: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    padding: spacing.md,
    borderRadius: radius.md,
    backgroundColor: colors.backgroundPink,
  },
  flexible: { flex: 1, gap: spacing.xs },
  descripcion: {
    height: sizes.textArea,
    paddingTop: spacing.blockDense,
    textAlignVertical: 'top',
  },
});
