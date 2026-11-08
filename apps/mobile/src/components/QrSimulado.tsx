import { colors, sizes } from '@almira/shared';
import { StyleSheet, View } from 'react-native';

// Dibujo fijo que imita un QR (pantalla 08). No codifica nada: el QR es simulado.
const MATRIZ = [
  '111111101101001111111',
  '100000101001101000001',
  '101110100000001011101',
  '101110101101101011101',
  '101110100010001011101',
  '100000101000001000001',
  '111111101010101111111',
  '000000000101000000000',
  '001111101101100111111',
  '101000010100111001110',
  '010000100101001001101',
  '101101011011000000110',
  '001010110000101011110',
  '000000000001001001110',
  '111111100011110001011',
  '100000101010000000001',
  '101110101001111011101',
  '101110100011101000000',
  '101110101011000110111',
  '100000101111111000001',
  '111111101000011011101',
];

// Agrupa los módulos seguidos del mismo color para dibujar menos vistas.
function tramos(fila: string): { lleno: boolean; largo: number }[] {
  const resultado: { lleno: boolean; largo: number }[] = [];
  for (const modulo of fila) {
    const lleno = modulo === '1';
    const ultimo = resultado[resultado.length - 1];
    if (ultimo && ultimo.lleno === lleno) ultimo.largo += 1;
    else resultado.push({ lleno, largo: 1 });
  }
  return resultado;
}

const FILAS = MATRIZ.map(tramos);

export function QrSimulado() {
  return (
    <View accessible accessibilityRole="image" accessibilityLabel="QR simulado" style={estilos.qr}>
      {FILAS.map((fila, indice) => (
        <View key={indice} style={estilos.fila}>
          {fila.map((tramo, posicion) => (
            <View
              key={posicion}
              style={[{ flex: tramo.largo }, tramo.lleno && estilos.lleno]}
            />
          ))}
        </View>
      ))}
    </View>
  );
}

const estilos = StyleSheet.create({
  qr: { width: sizes.qr, height: sizes.qr, alignSelf: 'center' },
  fila: { flex: 1, flexDirection: 'row' },
  lleno: { backgroundColor: colors.text },
});
