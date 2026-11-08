import {
  AREA_TIPO_RECLAMO,
  clasificarReclamo,
  colors,
  ETIQUETA_TIPO_RECLAMO,
  PLAZO_DIAS_RECLAMO,
  spacing,
  TIPOS_RECLAMO,
  type TipoReclamo,
} from '@almira/shared';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { router, useLocalSearchParams } from 'expo-router';
import { useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { FilaDato, IconoCuadro, Separador, Tarjeta, Vacio } from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Boton } from '@/components/Boton';
import { Chips } from '@/components/Chips';
import { FotoSimulada } from '@/components/FotoSimulada';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';
import { useSesion } from '@/sesion';

const CATEGORIAS = TIPOS_RECLAMO.map((valor) => ({ valor, titulo: ETIQUETA_TIPO_RECLAMO[valor] }));

// Pantalla 17 del prototipo. La categoría sale de reglas fijas sobre la
// descripción (clasificarReclamo) y el área, de la categoría. El vecino puede corregirla.
export default function EnvioAlArea() {
  const { descripcion = '', direccion = '' } = useLocalSearchParams<{
    descripcion?: string;
    direccion?: string;
  }>();
  const { registrarReclamo } = useSesion();
  const [tipo, setTipo] = useState<TipoReclamo>(() => clasificarReclamo(descripcion));
  const area = AREA_TIPO_RECLAMO[tipo];
  const encabezado = <BarraSuperior titulo="Envío al área" />;

  if (descripcion === '' || direccion === '') {
    return (
      <Pantalla encabezadoHastaArriba encabezado={encabezado}>
        <Vacio texto="No hay un reclamo por enviar." />
      </Pantalla>
    );
  }

  const confirmar = () => {
    const id = registrarReclamo({ tipo, descripcion, direccion });
    if (!id) return;
    // Cierra Nuevo reclamo y Envío al área, y abre el seguimiento en la pestaña Reclamos.
    if (router.canDismiss()) router.dismissAll();
    router.navigate({ pathname: '/reclamos/[id]', params: { id } });
  };

  return (
    <Pantalla encabezadoHastaArriba separacion="block" encabezado={encabezado}>
      <Tarjeta>
        <View style={estilos.fila}>
          <IconoCuadro icono="robot-outline" />
          <View style={estilos.flexible}>
            <Texto variante="labelLg">Lo clasificamos así</Texto>
            <Texto variante="bodyMd" color={colors.textSecondary}>
              Clasificación automática. Puedes corregirla.
            </Texto>
          </View>
        </View>
        <View style={estilos.filas}>
          <FilaDato etiqueta="Categoría" valor={<Valor texto={ETIQUETA_TIPO_RECLAMO[tipo]} />} />
          <FilaDato etiqueta="Área responsable" valor={<Valor texto={area} />} />
          <FilaDato
            etiqueta="Plazo de atención"
            valor={<Valor texto={`${PLAZO_DIAS_RECLAMO} días hábiles`} />}
          />
        </View>
      </Tarjeta>

      <Texto variante="headlineSm" fuente="poppins" accessibilityRole="header" style={estilos.seccion}>
        ¿Es otra categoría?
      </Texto>
      <Chips opciones={CATEGORIAS} elegida={tipo} onElegir={setTipo} />

      <FotoSimulada tipo={tipo} />

      <Tarjeta>
        <Texto color={colors.textSecondary}>{descripcion}</Texto>
        <Separador />
        <View style={estilos.fila}>
          <MaterialCommunityIcons name="map-marker-outline" size={20} color={colors.textSecondary} />
          <Texto variante="bodyMd" color={colors.textSecondary} style={estilos.flexible}>
            {direccion}
          </Texto>
        </View>
      </Tarjeta>

      <Boton titulo={`Confirmar envío a ${area}`} onPress={confirmar} />
    </Pantalla>
  );
}

function Valor({ texto }: { texto: string }) {
  return (
    <Texto variante="labelLg" alineacion="right">
      {texto}
    </Texto>
  );
}

const estilos = StyleSheet.create({
  fila: { flexDirection: 'row', alignItems: 'center', gap: spacing.blockDense },
  flexible: { flex: 1 },
  filas: { gap: spacing.sm },
  seccion: { marginTop: spacing.sm },
});
