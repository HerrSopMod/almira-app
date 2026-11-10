import {
  AREA_TIPO_RECLAMO,
  clasificarReclamo,
  colors,
  ETIQUETA_TIPO_RECLAMO,
  PLAZO_DIAS_RECLAMO,
  sizes,
  spacing,
  TIPOS_RECLAMO,
  type TipoReclamo,
} from '@almira/shared';
import { MaterialIcons } from '@expo/vector-icons';
import { router, useLocalSearchParams } from 'expo-router';
import { useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { Destacado, FilaDato, Nota, Separador, Tarjeta, Vacio } from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Boton } from '@/components/Boton';
import { Chips } from '@/components/Chips';
import { MiniaturaFoto } from '@/components/FotoSimulada';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';
import { useSesion } from '@/sesion';

const CATEGORIAS = TIPOS_RECLAMO.map((valor) => ({ valor, titulo: ETIQUETA_TIPO_RECLAMO[valor] }));

// Pantalla 17 (maqueta 17-envio-al-area). La categoría sale de reglas fijas sobre la
// descripción (clasificarReclamo) y el área, de la categoría. El vecino puede corregirla.
export default function EnvioAlArea() {
  const {
    descripcion = '',
    direccion = '',
    foto,
    latitud,
    longitud,
  } = useLocalSearchParams<{
    descripcion?: string;
    direccion?: string;
    foto?: string;
    latitud?: string;
    longitud?: string;
  }>();
  const { registrarReclamo } = useSesion();
  const [tipo, setTipo] = useState<TipoReclamo>(() => clasificarReclamo(descripcion));
  const [enviando, setEnviando] = useState(false);
  const [error, setError] = useState(false);
  const area = AREA_TIPO_RECLAMO[tipo];
  const encabezado = <BarraSuperior titulo="Envío al área" paso="Paso 2 de 2" />;

  if (descripcion === '' || direccion === '') {
    return (
      <Pantalla encabezadoHastaArriba encabezado={encabezado}>
        <Vacio texto="No hay un reclamo por enviar." />
      </Pantalla>
    );
  }

  const confirmar = async () => {
    if (enviando) return;
    setEnviando(true);
    setError(false);
    const id = await registrarReclamo({
      tipo,
      descripcion,
      direccion,
      fotoUri: foto ?? null,
      latitud: latitud ? Number(latitud) : null,
      longitud: longitud ? Number(longitud) : null,
    });
    setEnviando(false);
    if (!id) {
      setError(true);
      return;
    }
    // Cierra Nuevo reclamo y Envío al área, y abre el seguimiento en la pestaña Reclamos.
    if (router.canDismiss()) router.dismissAll();
    router.navigate({ pathname: '/reclamos/[id]', params: { id } });
  };

  return (
    <Pantalla encabezadoHastaArriba encabezado={encabezado}>
      <Destacado
        icono="category"
        titulo="Lo clasificamos así"
        texto="Clasificación automática. Puedes corregirla."
      />

      <Tarjeta>
        <FilaDato etiqueta="Categoría" valor={ETIQUETA_TIPO_RECLAMO[tipo]} />
        <Separador />
        <FilaDato etiqueta="Área responsable" valor={area} />
        <Separador />
        <FilaDato etiqueta="Plazo de atención" valor={`${PLAZO_DIAS_RECLAMO} días hábiles`} />
      </Tarjeta>

      <View style={estilos.grupo}>
        <Texto variante="headlineSm" accessibilityRole="header">
          ¿Es otra categoría?
        </Texto>
        <Chips opciones={CATEGORIAS} elegida={tipo} onElegir={setTipo} />
      </View>

      <Tarjeta>
        <View style={estilos.resumen}>
          <MiniaturaFoto tipo={tipo} />
          <View style={estilos.textos}>
            <Texto>{descripcion}</Texto>
            <View style={estilos.fila}>
              <MaterialIcons name="place" size={sizes.iconSm} color={colors.textSecondary} />
              <Texto variante="bodyMd" color={colors.textSecondary} style={estilos.flexible}>
                {direccion}
              </Texto>
            </View>
          </View>
        </View>
      </Tarjeta>

      {error ? (
        <Nota texto="No pudimos enviar tu reclamo. Revisa tu conexión e inténtalo de nuevo." />
      ) : null}

      <Boton
        titulo={enviando ? 'Enviando…' : `Confirmar envío a ${area}`}
        deshabilitado={enviando}
        onPress={confirmar}
      />
    </Pantalla>
  );
}

const estilos = StyleSheet.create({
  grupo: { gap: spacing.blockDense },
  resumen: { flexDirection: 'row', alignItems: 'flex-start', gap: spacing.md },
  textos: { flex: 1, gap: spacing.sm },
  fila: { flexDirection: 'row', alignItems: 'center', gap: spacing.xs },
  flexible: { flex: 1 },
});
