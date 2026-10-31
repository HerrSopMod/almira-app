import { colors, fontFamily, radius, sizes, spacing } from '@almira/shared';

// estilos.css solo consume estas variables: los valores viven en @almira/shared.
export function aplicarTokens() {
  const raiz = document.documentElement.style;
  const variables = {
    '--color-primario': colors.primary,
    '--color-fondo': colors.background,
    '--color-texto': colors.text,
    '--color-texto-secundario': colors.textSecondary,
    '--color-borde': colors.border,
    '--color-destacado': colors.highlight,
    '--color-acento': colors.accent,
    '--color-exito': colors.success,
    '--color-exito-suave': colors.successSoft,
    '--color-atencion': colors.warning,
    '--color-atencion-suave': colors.warningSoft,
    '--color-critico': colors.danger,
    '--color-critico-suave': colors.dangerSoft,
    '--fuente': `${fontFamily}, system-ui, sans-serif`,
    '--radio-md': `${radius.md}px`,
    '--radio-insignia': `${radius.badge}px`,
    '--alto-boton': `${sizes.button}px`,
    '--alto-progreso': `${sizes.progress}px`,
    '--margen': `${spacing.margin}px`,
    '--espacio-sm': `${spacing.sm}px`,
    '--espacio-md': `${spacing.md}px`,
    '--espacio-xl': `${spacing.xl}px`,
  };
  for (const [nombre, valor] of Object.entries(variables)) raiz.setProperty(nombre, valor);
}
