import { colors, radius, sizes } from '@almira/shared';
import { useRef, useState } from 'react';
import { PanResponder, StyleSheet, View, type GestureResponderEvent } from 'react-native';

type Props = {
  minimo: number;
  maximo: number;
  valor: number;
  onCambiar: (valor: number) => void;
  etiqueta: string;
};

// Deslizador de números enteros (pantalla 13), hecho con PanResponder para no
// sumar dependencias. Con lector de pantalla se ajusta deslizando arriba o abajo.
export function Deslizador({ minimo, maximo, valor, onCambiar, etiqueta }: Props) {
  const [ancho, setAncho] = useState(0);
  // PanResponder se crea una sola vez: lee los valores actuales desde esta referencia.
  const actual = useRef({ ancho, minimo, maximo, valor, onCambiar });
  actual.current = { ancho, minimo, maximo, valor, onCambiar };

  const mover = (evento: GestureResponderEvent) => {
    const { ancho: total, minimo: min, maximo: max, valor: previo, onCambiar: cambiar } =
      actual.current;
    if (total === 0) return;
    const proporcion = Math.min(Math.max(evento.nativeEvent.locationX / total, 0), 1);
    const nuevo = Math.round(min + proporcion * (max - min));
    if (nuevo !== previo) cambiar(nuevo);
  };

  const gestos = useRef(
    PanResponder.create({
      onStartShouldSetPanResponder: () => true,
      onMoveShouldSetPanResponder: () => true,
      onPanResponderTerminationRequest: () => false,
      onPanResponderGrant: mover,
      onPanResponderMove: mover,
    }),
  ).current;

  const proporcion = (valor - minimo) / (maximo - minimo);
  const centro = proporcion * ancho;

  return (
    <View
      accessible
      accessibilityRole="adjustable"
      accessibilityLabel={etiqueta}
      accessibilityValue={{ min: minimo, max: maximo, now: valor }}
      accessibilityActions={[{ name: 'increment' }, { name: 'decrement' }]}
      onAccessibilityAction={({ nativeEvent }) => {
        if (nativeEvent.actionName === 'increment' && valor < maximo) onCambiar(valor + 1);
        if (nativeEvent.actionName === 'decrement' && valor > minimo) onCambiar(valor - 1);
      }}
      onLayout={(evento) => setAncho(evento.nativeEvent.layout.width)}
      style={estilos.zona}
      {...gestos.panHandlers}
    >
      {/* Las piezas no reciben toques: así locationX siempre se mide sobre la zona. */}
      <View style={estilos.riel}>
        <View style={[estilos.relleno, { width: centro }]} />
      </View>
      <View style={[estilos.perilla, { left: centro - sizes.sliderThumb / 2 }]} />
    </View>
  );
}

const estilos = StyleSheet.create({
  zona: { height: sizes.sliderTouch, justifyContent: 'center' },
  riel: {
    height: sizes.progress,
    borderRadius: radius.full,
    backgroundColor: colors.backgroundPink,
    overflow: 'hidden',
    pointerEvents: 'none',
  },
  relleno: { height: '100%', backgroundColor: colors.primary },
  perilla: {
    position: 'absolute',
    width: sizes.sliderThumb,
    height: sizes.sliderThumb,
    borderRadius: sizes.sliderThumb / 2,
    borderWidth: sizes.sliderThumbBorder,
    borderColor: colors.primary,
    backgroundColor: colors.surface,
    pointerEvents: 'none',
  },
});
