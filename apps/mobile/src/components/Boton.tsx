import { colors, radius, sizes, spacing } from "@almira/shared";
import { FontAwesome, MaterialIcons } from "@expo/vector-icons";
import { useRef } from "react";
import { Animated, Pressable, StyleSheet, View } from "react-native";
import { Texto } from "./Texto";

export type TipoBoton =
  "primario" | "secundario" | "terciario" | "google" | "peligro";

type Props = {
  titulo: string;
  onPress: () => void;
  tipo?: TipoBoton;
  icono?: keyof typeof MaterialIcons.glyphMap;
  deshabilitado?: boolean;
};

const COLOR_TEXTO: Record<TipoBoton, string> = {
  primario: colors.onPrimary,
  secundario: colors.primary,
  terciario: colors.primary,
  google: colors.text,
  peligro: colors.dangerText,
};

// LEEME.md → Botones. Ocupan todo el ancho: los márgenes de 20 px los pone Pantalla.
// Si van varios, se apilan con 8 px: primario, secundario y terciario. Nunca dentro de tarjetas.
export function Boton({
  titulo,
  onPress,
  tipo = "primario",
  icono,
  deshabilitado,
}: Props) {
  const colorTexto =
    deshabilitado && tipo !== "primario"
      ? colors.primaryDisabled
      : COLOR_TEXTO[tipo];
  // Al presionar, el botón se encoge un poco y vuelve con un rebote suave.
  const escala = useRef(new Animated.Value(1)).current;
  const mover = (a: number) =>
    Animated.spring(escala, {
      toValue: a,
      speed: 40,
      bounciness: 6,
      useNativeDriver: true,
    }).start();
  return (
    <Animated.View
      style={[estilos.envoltura, { transform: [{ scale: escala }] }]}
    >
      <Pressable
        onPressIn={() => !deshabilitado && mover(0.97)}
        onPressOut={() => mover(1)}
        accessibilityRole="button"
        accessibilityState={{ disabled: !!deshabilitado }}
        disabled={deshabilitado}
        onPress={onPress}
        style={({
          pressed,
          hovered,
        }: {
          pressed: boolean;
          hovered?: boolean;
        }) => [
          estilos.base,
          estilos[tipo],
          (pressed || hovered) &&
            tipo === "primario" &&
            estilos.primarioPresionado,
          hovered && tipo !== "primario" && !deshabilitado && estilos.resaltado,
          deshabilitado &&
            (tipo === "primario"
              ? estilos.primarioDeshabilitado
              : estilos.deshabilitado),
        ]}
      >
        <View style={estilos.contenido}>
          {tipo === "google" ? (
            // Logo de Google: viene en @expo/vector-icons, sin paquetes nuevos.
            <FontAwesome name="google" size={sizes.iconSm} color={colorTexto} />
          ) : icono ? (
            <MaterialIcons
              name={icono}
              size={sizes.iconSm}
              color={colorTexto}
            />
          ) : null}
          <Texto
            variante={
              tipo === "terciario" || tipo === "google"
                ? "bodyLgMedium"
                : "button"
            }
            color={colorTexto}
          >
            {titulo}
          </Texto>
        </View>
      </Pressable>
    </Animated.View>
  );
}

const estilos = StyleSheet.create({
  envoltura: { alignSelf: "stretch" },
  resaltado: { backgroundColor: colors.highlight },
  base: {
    alignSelf: "stretch",
    minHeight: sizes.button,
    paddingHorizontal: spacing.md,
    borderRadius: radius.md,
    alignItems: "center",
    justifyContent: "center",
  },
  primario: { backgroundColor: colors.primary },
  primarioPresionado: { backgroundColor: colors.primaryPressed },
  primarioDeshabilitado: { backgroundColor: colors.primaryDisabled },
  secundario: {
    backgroundColor: colors.surface,
    borderWidth: sizes.focusBorderWidth,
    borderColor: colors.primary,
  },
  terciario: { minHeight: sizes.buttonTertiary },
  google: {
    backgroundColor: colors.surface,
    borderWidth: sizes.borderWidth,
    borderColor: colors.border,
  },
  // "Cerrar sesión": como el secundario, con borde gris y texto de peligro.
  peligro: {
    backgroundColor: colors.surface,
    borderWidth: sizes.focusBorderWidth,
    borderColor: colors.border,
  },
  deshabilitado: { borderColor: colors.primaryDisabled },
  contenido: { flexDirection: "row", alignItems: "center", gap: spacing.sm },
});
