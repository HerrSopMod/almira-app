import { codigoValido, colors, sizes, spacing, USUARIO_EJEMPLO } from '@almira/shared';
import { MaterialIcons } from '@expo/vector-icons';
import { router } from 'expo-router';
import { useEffect, useState } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { useAuth, type MetodoIngreso } from '@/auth';
import { Nota, PiePrototipo, TituloPantalla } from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Boton } from '@/components/Boton';
import { Campo } from '@/components/Campo';
import { Pantalla } from '@/components/Pantalla';
import { Segmentado } from '@/components/Segmentado';
import { Texto } from '@/components/Texto';
import { irTrasIngreso } from '@/recorrido';
import { useSesion } from '@/sesion';
import { supabaseConfigurado } from '@/supabase';

const CLAVE_MINIMA = 8;
const celularValido = (valor: string) => /^9\d{8}$/.test(valor);
const correoValido = (valor: string) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(valor.trim());

type Metodo = 'correo' | 'celular';

// Pantalla 02a (Stitch 1). Google, correo con contraseña o celular con código SMS, con
// Supabase Auth. Después sigue el recorrido de irTrasIngreso (02c, 02d, 03 e Inicio).
// Sin Supabase configurado, los tres métodos se simulan con los datos de ejemplo.
export default function Ingreso() {
  const { metodoIngreso, consentimientoAceptado, ingresarSimulado } = useSesion();
  const {
    sesion,
    iniciarConGoogle,
    iniciarConCorreo,
    crearCuenta,
    enviarCodigoSms,
    verificarCodigoSms,
  } = useAuth();
  const [metodo, setMetodo] = useState<Metodo>('correo');
  const [celular, setCelular] = useState('');
  const [codigo, setCodigo] = useState('');
  const [codigoEnviado, setCodigoEnviado] = useState(false);
  const [registro, setRegistro] = useState(false);
  const [correo, setCorreo] = useState('');
  const [clave, setClave] = useState('');
  const [verClave, setVerClave] = useState(false);
  const [mensaje, setMensaje] = useState<string | null>(null);
  const [ocupado, setOcupado] = useState(false);

  // Con Supabase, al aparecer la sesión (también al volver de Google en la web) sigue el recorrido.
  useEffect(() => {
    if (supabaseConfigurado && sesion) irTrasIngreso(metodoIngreso, consentimientoAceptado);
    // Solo cuando cambia la sesión: al volver atrás a esta pantalla no se adelanta sola.
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

  // Ingreso simulado: sin Supabase no se abre Google ni se envía nada.
  const simular = (metodoSimulado: MetodoIngreso) => {
    ingresarSimulado(metodoSimulado);
    irTrasIngreso(metodoSimulado, consentimientoAceptado);
  };

  const conGoogle = () =>
    supabaseConfigurado ? ejecutar(iniciarConGoogle) : simular('google');

  const pedirCodigo = () => {
    if (!supabaseConfigurado) {
      setCodigo(USUARIO_EJEMPLO.codigoSmsEjemplo);
      setCodigoEnviado(true);
      return;
    }
    void ejecutar(async () => {
      const error = await enviarCodigoSms(celular);
      if (!error) setCodigoEnviado(true);
      return error;
    });
  };
  const verificar = () =>
    supabaseConfigurado ? ejecutar(() => verificarCodigoSms(celular, codigo)) : simular('celular');

  const listo = correoValido(correo) && clave.length >= CLAVE_MINIMA;
  const enviar = () => {
    if (!supabaseConfigurado) {
      simular('correo');
      return;
    }
    void ejecutar(() => (registro ? crearCuenta(correo, clave) : iniciarConCorreo(correo, clave)));
  };

  const elegirMetodo = (nuevo: Metodo) => {
    setMetodo(nuevo);
    setMensaje(null);
  };

  return (
    <Pantalla
      encabezadoHastaArriba
      encabezado={<BarraSuperior titulo="Paso 1 de 5" conVolver={false} />}
    >
      <TituloPantalla
        titulo={registro && metodo === 'correo' ? 'Crea tu cuenta' : 'Ingresa a tu cuenta'}
        texto="Usa los datos con los que figuras en el padrón municipal."
      />

      <Boton tipo="google" titulo="Continuar con Google" onPress={conGoogle} deshabilitado={ocupado} />

      <View style={estilos.divisor}>
        <View style={estilos.linea} />
        <Texto variante="bodyMd" color={colors.textSecondary}>
          o con tu {metodo === 'correo' ? 'correo' : 'celular'}
        </Texto>
        <View style={estilos.linea} />
      </View>

      <Segmentado<Metodo>
        opciones={[
          { valor: 'correo', titulo: 'Correo' },
          { valor: 'celular', titulo: 'Celular' },
        ]}
        elegida={metodo}
        onElegir={elegirMetodo}
      />

      {metodo === 'celular' ? (
        <>
          <Campo
            etiqueta="Celular (+51)"
            placeholder="9 dígitos"
            keyboardType="number-pad"
            maxLength={9}
            autoComplete="tel"
            value={celular}
            onChangeText={(texto) => {
              setCelular(texto.replace(/\D/g, ''));
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
              onChangeText={(texto) => setCodigo(texto.replace(/\D/g, ''))}
            />
          ) : null}
          {codigoEnviado && !supabaseConfigurado ? (
            <Nota texto="Datos de ejemplo. Sirve cualquier código de 6 dígitos." />
          ) : null}
          {mensaje ? <Nota texto={mensaje} /> : null}
          <Boton
            titulo={codigoEnviado ? 'Verificar código' : 'Recibir código por SMS'}
            icono={codigoEnviado ? undefined : 'sms'}
            deshabilitado={
              ocupado || !celularValido(celular) || (codigoEnviado && !codigoValido(codigo))
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
              onPress={() => setVerClave((visible) => !visible)}
              hitSlop={spacing.sm}
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
          <Boton
            tipo="terciario"
            titulo={registro ? '¿Ya tienes cuenta? Ingresa' : '¿No tienes cuenta? Créala'}
            onPress={() => {
              setRegistro((valor) => !valor);
              setMensaje(null);
            }}
          />
        </>
      )}

      {supabaseConfigurado ? null : (
        <Nota texto="Datos de ejemplo. En este prototipo no se envía ni se guarda ninguna información." />
      )}
      <Texto variante="caption" color={colors.textSecondary} alineacion="center">
        Antes de entrar te pediremos tu consentimiento para usar tus datos.
      </Texto>
      <Boton
        tipo="terciario"
        titulo="No tengo cuenta ni smartphone propio"
        onPress={() => router.push('/sin-smartphone')}
      />
      <PiePrototipo />
    </Pantalla>
  );
}

const estilos = StyleSheet.create({
  divisor: { flexDirection: 'row', alignItems: 'center', gap: spacing.blockDense },
  linea: { flex: 1, height: sizes.borderWidth, backgroundColor: colors.border },
  ojo: {
    position: 'absolute',
    right: spacing.md,
    bottom: 0,
    height: sizes.input,
    justifyContent: 'center',
  },
});
