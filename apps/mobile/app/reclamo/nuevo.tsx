import {
  centroMapaDe,
  colors,
  radius,
  sizes,
  spacing,
  UBICACIONES_PREDIO_EJEMPLO,
} from '@almira/shared';
import { MaterialIcons } from '@expo/vector-icons';
import { router } from 'expo-router';
import { useState } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { Nota, Tarjeta } from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Boton } from '@/components/Boton';
import { Campo } from '@/components/Campo';
import { MapaObras } from '@/components/MapaObras';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';
import { useDatosMunicipales } from '@/sesion';

// Descripción de ejemplo del prototipo: el vecino puede cambiarla.
const DESCRIPCION_EJEMPLO =
  'Hay un bache grande en la pista frente a mi casa, los carros lo esquivan.';

const MAXIMO_DESCRIPCION = 500;
// El minimapa solo marca la ubicación del reclamo.
const SIN_OBRAS: never[] = [];

// Pantalla 16 (maqueta 16-nuevo-reclamo). La foto y la ubicación son simuladas: no
// se usa la cámara ni el GPS. La ubicación parte de la dirección del predio y se
// puede ajustar. El minimapa real (MAPA.md) marca el punto simulado del predio; si el
// vecino cambia la dirección, el mapa queda en el distrito sin marcador.
export default function NuevoReclamo() {
  const { municipalidad, predios } = useDatosMunicipales();
  const [foto, setFoto] = useState(false);
  const [direccion, setDireccion] = useState(predios[0]?.direccion ?? '');
  const [ajustando, setAjustando] = useState(direccion === '');
  const [descripcion, setDescripcion] = useState(DESCRIPCION_EJEMPLO);

  const predio = predios.find((p) => p.direccion === direccion.trim());
  const punto = predio ? (UBICACIONES_PREDIO_EJEMPLO[predio.id] ?? null) : null;

  const listo = foto && direccion.trim() !== '' && descripcion.trim() !== '';

  return (
    <Pantalla
      encabezadoHastaArriba
      encabezado={<BarraSuperior titulo="Nuevo reclamo" iconoVolver="cerrar" paso="Paso 1 de 2" />}
    >
      <View style={estilos.grupo}>
        <Texto variante="bodyLgMedium">Foto del problema</Texto>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={foto ? 'Foto de ejemplo agregada' : 'Agregar foto'}
          disabled={foto}
          onPress={() => setFoto(true)}
          style={[estilos.foto, foto && estilos.fotoLista]}
        >
          <MaterialIcons
            name={foto ? 'check-circle-outline' : 'add-a-photo'}
            size={sizes.iconBox}
            color={colors.primary}
          />
          <Texto variante="bodyLgMedium" color={colors.primary}>
            {foto ? 'Foto de ejemplo agregada' : 'Agregar foto'}
          </Texto>
          <Texto variante="bodyMd" color={colors.textSecondary} alineacion="center">
            Simulada: en este prototipo no se usa la cámara.
          </Texto>
        </Pressable>
      </View>

      <View style={estilos.grupo}>
        <Texto variante="bodyLgMedium">Ubicación del problema</Texto>
        <Tarjeta style={estilos.ubicacion}>
          <View style={estilos.mapa}>
            <MapaObras
              obras={SIN_OBRAS}
              centro={centroMapaDe(municipalidad.id)}
              ubicacion={punto}
              interactivo={false}
              enTarjeta
              alto={sizes.miniMap}
              accessibilityLabel="Mapa de la ubicación del problema"
            />
          </View>
          <View style={estilos.direccion}>
            {ajustando ? (
              <View style={estilos.flexible}>
                <Campo
                  accessibilityLabel="Dirección del problema"
                  placeholder="Escribe la dirección"
                  value={direccion}
                  onChangeText={setDireccion}
                />
              </View>
            ) : (
              <>
                <View style={estilos.flexible}>
                  <Texto variante="bodyLgMedium">{direccion}</Texto>
                  <Texto variante="bodyMd" color={colors.textSecondary}>
                    GPS simulado
                  </Texto>
                </View>
                <Pressable
                  accessibilityRole="button"
                  accessibilityLabel="Ajustar ubicación"
                  onPress={() => setAjustando(true)}
                  style={estilos.ajustar}
                >
                  <Texto variante="bodyLgMedium" peso="600" color={colors.primary}>
                    Ajustar
                  </Texto>
                </Pressable>
              </>
            )}
          </View>
        </Tarjeta>
      </View>

      <View style={estilos.grupo}>
        <Campo
          etiqueta="Describe el problema"
          multiline
          maxLength={MAXIMO_DESCRIPCION}
          value={descripcion}
          onChangeText={setDescripcion}
          style={estilos.descripcion}
        />
        <Texto variante="bodyMd" color={colors.textSecondary} alineacion="right" tabular>
          {descripcion.length} / {MAXIMO_DESCRIPCION}
        </Texto>
      </View>

      <Nota
        icono="lock-outline"
        texto="La foto y la ubicación se usan solo para atender este reclamo."
      />

      <Boton
        titulo="Continuar"
        deshabilitado={!listo}
        onPress={() =>
          router.push({
            pathname: '/reclamo/envio',
            params: { descripcion: descripcion.trim(), direccion: direccion.trim() },
          })
        }
      />
    </Pantalla>
  );
}

const estilos = StyleSheet.create({
  grupo: { gap: spacing.sm },
  foto: {
    height: sizes.evidencePhoto,
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing.xs,
    paddingHorizontal: spacing.md,
    borderWidth: sizes.borderWidth,
    borderStyle: 'dashed',
    borderColor: colors.border,
    borderRadius: radius.md,
    backgroundColor: colors.surface,
  },
  fotoLista: { borderStyle: 'solid' },
  ubicacion: { padding: 0, gap: 0, overflow: 'hidden' },
  mapa: {
    borderBottomWidth: sizes.borderWidth,
    borderBottomColor: colors.border,
  },
  direccion: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.blockDense,
    padding: spacing.md,
  },
  flexible: { flex: 1 },
  ajustar: { minHeight: sizes.buttonTertiary, justifyContent: 'center' },
  descripcion: { height: sizes.textArea },
});
