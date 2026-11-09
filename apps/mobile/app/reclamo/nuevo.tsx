import { colors, radius, sizes, spacing } from '@almira/shared';
import { MaterialIcons } from '@expo/vector-icons';
import * as ImagePicker from 'expo-image-picker';
import * as Location from 'expo-location';
import { router } from 'expo-router';
import { useMemo, useState } from 'react';
import { Image, Pressable, StyleSheet, View } from 'react-native';
import { Nota, Tarjeta } from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Boton } from '@/components/Boton';
import { Campo } from '@/components/Campo';
import { MapaLeaflet } from '@/components/MapaLeaflet';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';
import { useDatosMunicipales } from '@/sesion';

// Descripción de ejemplo del prototipo: el vecino puede cambiarla.
const DESCRIPCION_EJEMPLO =
  'Hay un bache grande en la pista frente a mi casa, los carros lo esquivan.';

const MAXIMO_DESCRIPCION = 500;

// Pantalla 16 (maqueta 16-nuevo-reclamo). La foto sale de la cámara del dispositivo y la
// ubicación del GPS, con permiso del vecino. La dirección parte de la del predio y se puede
// ajustar. La foto todavía no se sube a Storage: eso llega al conectar los reclamos reales.
export default function NuevoReclamo() {
  const { predios } = useDatosMunicipales();
  const [foto, setFoto] = useState<string | null>(null);
  const [coordenadas, setCoordenadas] = useState<{ latitud: number; longitud: number } | null>(null);
  const [avisoFoto, setAvisoFoto] = useState<string | null>(null);
  const [avisoGps, setAvisoGps] = useState<string | null>(null);
  const [direccion, setDireccion] = useState(predios[0]?.direccion ?? '');
  const [ajustando, setAjustando] = useState(direccion === '');
  const [descripcion, setDescripcion] = useState(DESCRIPCION_EJEMPLO);

  const tomarFoto = async () => {
    setAvisoFoto(null);
    const permiso = await ImagePicker.requestCameraPermissionsAsync();
    if (!permiso.granted) {
      setAvisoFoto('Necesitamos permiso para usar la cámara. Actívalo en los ajustes del teléfono.');
      return;
    }
    const resultado = await ImagePicker.launchCameraAsync({ quality: 0.6 });
    if (!resultado.canceled) setFoto(resultado.assets[0]?.uri ?? null);
  };

  const usarMiUbicacion = async () => {
    setAvisoGps(null);
    const permiso = await Location.requestForegroundPermissionsAsync();
    if (!permiso.granted) {
      setAvisoGps('Necesitamos permiso para ver tu ubicación. Puedes escribir la dirección.');
      return;
    }
    try {
      const { coords } = await Location.getCurrentPositionAsync({});
      setCoordenadas({ latitud: coords.latitude, longitud: coords.longitude });
    } catch {
      setAvisoGps('No pudimos obtener tu ubicación. Puedes escribir la dirección.');
    }
  };

  const marcadores = useMemo(
    () => (coordenadas ? [{ id: 'reclamo', ...coordenadas }] : []),
    [coordenadas],
  );

  const listo = foto !== null && direccion.trim() !== '' && descripcion.trim() !== '';

  return (
    <Pantalla
      encabezadoHastaArriba
      encabezado={<BarraSuperior titulo="Nuevo reclamo" iconoVolver="cerrar" paso="Paso 1 de 2" />}
    >
      <View style={estilos.grupo}>
        <Texto variante="bodyLgMedium">Foto del problema</Texto>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={foto ? 'Cambiar foto' : 'Tomar foto'}
          onPress={tomarFoto}
          style={[estilos.foto, foto && estilos.fotoLista]}
        >
          {foto ? (
            <Image source={{ uri: foto }} style={estilos.vista} resizeMode="cover" />
          ) : (
            <>
              <MaterialIcons name="add-a-photo" size={sizes.iconBox} color={colors.primary} />
              <Texto variante="bodyLgMedium" color={colors.primary}>
                Tomar foto
              </Texto>
            </>
          )}
        </Pressable>
        {foto ? (
          <Boton tipo="terciario" icono="photo-camera" titulo="Tomar otra foto" onPress={tomarFoto} />
        ) : null}
        {avisoFoto ? <Nota texto={avisoFoto} /> : null}
      </View>

      <View style={estilos.grupo}>
        <Texto variante="bodyLgMedium">Ubicación del problema</Texto>
        <Tarjeta style={estilos.ubicacion}>
          <MapaLeaflet
            alto={sizes.miniMap}
            marcadores={marcadores}
            interactivo={false}
            etiqueta="Mapa con la ubicación del reclamo"
          />
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
                    {coordenadas ? 'Ubicación del dispositivo' : 'Dirección del predio'}
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
        <Boton tipo="secundario" icono="my-location" titulo="Usar mi ubicación" onPress={usarMiUbicacion} />
        {avisoGps ? <Nota texto={avisoGps} /> : null}
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
  fotoLista: { borderStyle: 'solid', overflow: 'hidden', padding: 0 },
  vista: { width: '100%', height: '100%' },
  ubicacion: { padding: 0, gap: 0, overflow: 'hidden' },
  mapa: {
    height: sizes.miniMap,
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing.xs,
    backgroundColor: colors.subtle,
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
