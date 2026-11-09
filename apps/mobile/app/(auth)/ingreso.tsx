import { colors, radius, sizes, spacing } from '@almira/shared';
import { MaterialIcons } from '@expo/vector-icons';
import { router } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { useEffect, useRef, useState } from 'react';
import {
  Animated,
  Easing,
  KeyboardAvoidingView,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  View,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useAuth } from '@/auth';
import { Nota } from '@/components/Bloques';
import { Boton } from '@/components/Boton';
import { Campo } from '@/components/Campo';
import { Logo } from '@/components/Logo';
import { Texto } from '@/components/Texto';
import { useSesion } from '@/sesion';
import { supabaseConfigurado } from '@/supabase';

const CLAVE_MINIMA = 8;
const celularValido = (valor: string) => /^9\d{8}$/.test(valor);
const correoValido = (valor: string) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(valor.trim());

// Primera pantalla: Google arriba y, debajo, ingreso clásico con correo y contraseña.
// Sin Supabase configurado, Google sigue la simulación anterior.
export default function Ingreso() {
  const { iniciarConGoogle: googleSimulado } = useSesion();
  const {
    sesion,
    iniciarConGoogle,
    iniciarConCorreo,
    crearCuenta,
    enviarCodigoSms,
    verificarCodigoSms,
  } = useAuth();
  const { top, bottom } = useSafeAreaInsets();
  const [metodo, setMetodo] = useState<'correo' | 'celular'>('correo');
  const [celular, setCelular] = useState('');
  const [codigo, setCodigo] = useState('');
  const [codigoEnviado, setCodigoEnviado] = useState(false);
  const [registro, setRegistro] = useState(false);
  const [correo, setCorreo] = useState('');
  const [clave, setClave] = useState('');
  const [verClave, setVerClave] = useState(false);
  const [mensaje, setMensaje] = useState<string | null>(null);
  const [ocupado, setOcupado] = useState(false);

  // Entrada animada: la hoja blanca sube y aparece.
  const aparece = useRef(new Animated.Value(0)).current;
  useEffect(() => {
    Animated.timing(aparece, {
      toValue: 1,
      duration: 450,
      easing: Easing.out(Easing.cubic),
      useNativeDriver: true,
    }).start();
  }, [aparece]);

  useEffect(() => {
    if (supabaseConfigurado && sesion) router.replace('/inicio');
  }, [sesion]);

  const ejecutar = async (accion: () => Promise<string | null>) => {
    setMensaje(null);
    setOcupado(true);
    try {
      setMensaje(await accion());
    } finally {
      setOcupado(false);
    }
  };

  const conGoogle = () =>
    ejecutar(async () => {
      if (supabaseConfigurado) return iniciarConGoogle();
      await googleSimulado();
      router.replace('/inicio');
      return null;
    });

  const pedirCodigo = () =>
    ejecutar(async () => {
      const error = await enviarCodigoSms(celular);
      if (!error) setCodigoEnviado(true);
      return error;
    });
  const verificar = () => ejecutar(() => verificarCodigoSms(celular, codigo));

  const listo = correoValido(correo) && clave.length >= CLAVE_MINIMA;
  const enviar = () =>
    ejecutar(() => (registro ? crearCuenta(correo, clave) : iniciarConCorreo(correo, clave)));

  return (
    <KeyboardAvoidingView
      style={estilos.raiz}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
    >
      <StatusBar style="light" />
      <View style={[estilos.cabecera, { paddingTop: top + spacing.xl }]}>
        <Logo grande />
        <Texto variante="brand" color={colors.onPrimary} accessibilityRole="header">
          Almira
        </Texto>
        <Texto variante="bodyLg" color={colors.onPrimary} alineacion="center">
          Paga con claridad. Reclama con evidencia.
        </Texto>
      </View>

      <Animated.View
        style={[
          estilos.hoja,
          {
            opacity: aparece,
            transform: [
              {
                translateY: aparece.interpolate({
                  inputRange: [0, 1],
                  outputRange: [32, 0],
                }),
              },
            ],
          },
        ]}
      >
        <ScrollView
          keyboardShouldPersistTaps="handled"
          contentContainerStyle={[estilos.contenido, { paddingBottom: spacing.lg + bottom }]}
        >
          <Texto variante="headlineLg" accessibilityRole="header">
            {registro ? 'Crea tu cuenta' : 'Ingresa a tu cuenta'}
          </Texto>

          <Boton
            tipo="google"
            titulo="Continuar con Google"
            onPress={conGoogle}
            deshabilitado={ocupado}
          />

          <View style={estilos.divisor}>
            <View style={estilos.linea} />
            <Texto variante="bodyMd" color={colors.textSecondary}>
              o con tu {metodo === 'correo' ? 'correo' : 'celular'}
            </Texto>
            <View style={estilos.linea} />
          </View>

          <View style={estilos.metodos}>
            {(['correo', 'celular'] as const).map((m) => (
              <Pressable
                key={m}
                accessibilityRole="tab"
                accessibilityState={{ selected: metodo === m }}
                onPress={() => {
                  setMetodo(m);
                  setMensaje(null);
                }}
                style={[estilos.metodo, metodo === m && estilos.metodoActivo]}
              >
                <Texto
                  variante="bodyLgMedium"
                  color={metodo === m ? colors.onPrimary : colors.primary}
                  alineacion="center"
                >
                  {m === 'correo' ? 'Correo' : 'Celular'}
                </Texto>
              </Pressable>
            ))}
          </View>

          {metodo === 'celular' ? (
            <>
              <Campo
                etiqueta="Celular (+51)"
                placeholder="9 dígitos"
                keyboardType="number-pad"
                maxLength={9}
                autoComplete="tel"
                value={celular}
                onChangeText={(t) => {
                  setCelular(t.replace(/\D/g, ''));
                  setCodigoEnviado(false);
                }}
              />
              {codigoEnviado ? (
                <Campo
                  etiqueta="Código de 6 dígitos"
                  placeholder="Código que te llegó por SMS"
                  keyboardType="number-pad"
                  maxLength={6}
                  autoComplete="sms-otp"
                  value={codigo}
                  onChangeText={(t) => setCodigo(t.replace(/\D/g, ''))}
                />
              ) : null}
              {mensaje ? <Nota texto={mensaje} /> : null}
              <Boton
                titulo={codigoEnviado ? 'Verificar código' : 'Enviar código por SMS'}
                icono={codigoEnviado ? undefined : 'sms'}
                deshabilitado={
                  ocupado || !celularValido(celular) || (codigoEnviado && codigo.length !== 6)
                }
                onPress={codigoEnviado ? verificar : pedirCodigo}
              />
            </>
          ) : (
            <>
              <Campo
                etiqueta="Correo"
                placeholder="nombre@correo.com"
                keyboardType="email-address"
                autoCapitalize="none"
                autoComplete="email"
                autoCorrect={false}
                value={correo}
                onChangeText={setCorreo}
              />
              <View>
                <Campo
                  etiqueta="Contraseña"
                  placeholder={`Mínimo ${CLAVE_MINIMA} caracteres`}
                  secureTextEntry={!verClave}
                  autoCapitalize="none"
                  autoComplete={registro ? 'new-password' : 'current-password'}
                  value={clave}
                  onChangeText={setClave}
                  onSubmitEditing={listo ? enviar : undefined}
                />
                <Pressable
                  accessibilityRole="button"
                  accessibilityLabel={verClave ? 'Ocultar contraseña' : 'Mostrar contraseña'}
                  onPress={() => setVerClave((v) => !v)}
                  hitSlop={8}
                  style={estilos.ojo}
                >
                  <MaterialIcons
                    name={verClave ? 'visibility-off' : 'visibility'}
                    size={sizes.iconSm}
                    color={colors.textSecondary}
                  />
                </Pressable>
              </View>

              {mensaje ? <Nota texto={mensaje} /> : null}

              <Boton
                titulo={registro ? 'Crear cuenta' : 'Ingresar'}
                deshabilitado={!listo || ocupado}
                onPress={enviar}
              />

              <Pressable
                accessibilityRole="button"
                onPress={() => {
                  setRegistro((v) => !v);
                  setMensaje(null);
                }}
                style={estilos.cambiar}
              >
                <Texto variante="bodyLgMedium" color={colors.primary} alineacion="center">
                  {registro ? '¿Ya tienes cuenta? Ingresa' : '¿No tienes cuenta? Créala'}
                </Texto>
              </Pressable>
            </>
          )}

          <Texto variante="caption" color={colors.textSecondary} alineacion="center">
            Al continuar, aceptas los términos de servicio y la política de privacidad.
          </Texto>
        </ScrollView>
      </Animated.View>
    </KeyboardAvoidingView>
  );
}

const estilos = StyleSheet.create({
  raiz: { flex: 1, backgroundColor: colors.primary },
  cabecera: {
    alignItems: 'center',
    gap: spacing.sm,
    paddingHorizontal: spacing.margin,
    paddingBottom: spacing.xl,
  },
  hoja: {
    flex: 1,
    backgroundColor: colors.background,
    borderTopLeftRadius: radius.lg,
    borderTopRightRadius: radius.lg,
  },
  contenido: { padding: spacing.margin, gap: spacing.md },
  divisor: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.blockDense,
  },
  linea: { flex: 1, height: sizes.borderWidth, backgroundColor: colors.border },
  ojo: {
    position: 'absolute',
    right: spacing.md,
    bottom: 0,
    height: sizes.input,
    justifyContent: 'center',
  },
  metodos: { flexDirection: 'row', gap: spacing.sm },
  metodo: {
    flex: 1,
    minHeight: sizes.buttonTertiary,
    justifyContent: 'center',
    borderRadius: radius.md,
    borderWidth: sizes.borderWidth,
    borderColor: colors.primary,
  },
  metodoActivo: { backgroundColor: colors.primary },
  cambiar: { minHeight: sizes.buttonTertiary, justifyContent: 'center' },
});
