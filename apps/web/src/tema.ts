import {
  colors,
  displayFontFamily,
  fontFamily,
  panelSizes,
  panelTypography,
  radius,
  sizes,
  spacing,
} from '@almira/shared';

const kebab = (nombre: string) => nombre.replace(/[A-Z]/g, (letra) => `-${letra.toLowerCase()}`);
const px = (valor: number | string) => (typeof valor === 'number' ? `${valor}px` : valor);

const FUENTES = {
  display: `${displayFontFamily}, ${fontFamily}, system-ui, sans-serif`,
  text: `${fontFamily}, system-ui, sans-serif`,
} as const;

// estilos.css solo consume estas variables: los valores viven en @almira/shared.
//   --c-*: colores · --s-*: espacios · --r-*: radios · --z-*: medidas móviles
//   --p-*: medidas del panel · --t-*: estilos de texto (para la propiedad font)
export function aplicarTokens() {
  const raiz = document.documentElement.style;
  const variables: Record<string, string> = {
    '--fuente': FUENTES.text,
    '--fuente-titulos': FUENTES.display,
  };
  for (const [nombre, valor] of Object.entries(colors)) variables[`--c-${kebab(nombre)}`] = valor;
  for (const [nombre, valor] of Object.entries(spacing)) variables[`--s-${kebab(nombre)}`] = px(valor);
  for (const [nombre, valor] of Object.entries(radius)) variables[`--r-${kebab(nombre)}`] = px(valor);
  for (const [nombre, valor] of Object.entries(sizes)) variables[`--z-${kebab(nombre)}`] = px(valor);
  for (const [nombre, valor] of Object.entries(panelSizes)) variables[`--p-${kebab(nombre)}`] = px(valor);
  for (const [nombre, estilo] of Object.entries(panelTypography)) {
    variables[`--t-${kebab(nombre)}`] =
      `${estilo.fontWeight} ${estilo.fontSize}px/${estilo.lineHeight}px ${FUENTES[estilo.familia]}`;
  }
  for (const [nombre, valor] of Object.entries(variables)) raiz.setProperty(nombre, valor);
}
