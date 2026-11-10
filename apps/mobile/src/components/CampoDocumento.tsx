import { Campo } from './Campo';

// Campo "DNI o carné de extranjería" de las pantallas 02a y 02c.
export function CampoDocumento({
  valor,
  onCambiar,
}: {
  valor: string;
  onCambiar: (valor: string) => void;
}) {
  return (
    <Campo
      etiqueta="DNI o carné de extranjería"
      autoCapitalize="characters"
      autoComplete="off"
      autoCorrect={false}
      maxLength={12}
      value={valor}
      onChangeText={(texto) => onCambiar(texto.replace(/[^A-Za-z0-9]/g, ''))}
    />
  );
}
