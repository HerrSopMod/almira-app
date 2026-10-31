import {
  colors,
  deudasPendientes,
  ETIQUETA_CANAL,
  ETIQUETA_ESTADO_DEUDA,
  ETIQUETA_TIPO_RECORDATORIO,
  formatearFecha,
  spacing,
  sumarDeudas,
  USUARIO_EJEMPLO,
  type Deuda,
} from '@almira/shared';
import { MaterialIcons } from '@expo/vector-icons';
import { router } from 'expo-router';
import { useState } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import {
  Destacado,
  Insignia,
  Monto,
  Separador,
  Tarjeta,
  Vacio,
} from '@/components/Bloques';
import { Boton } from '@/components/Boton';
import { Encabezado } from '@/components/Encabezado';
import { Opcion } from '@/components/Opcion';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';
import { municipalidadesDelVecino, useDatosMunicipales, useSesion } from '@/sesion';

export default function Inicio() {
  const { elegirMunicipalidad } = useSesion();
  const { municipalidad, deudas, recordatorios } = useDatosMunicipales();
  const [selectorAbierto, setSelectorAbierto] = useState(false);

  const pendientes = deudasPendientes(deudas);
  const total = sumarDeudas(pendientes);
  const proxima = pendientes
    .filter((deuda) => deuda.estado === 'vigente')
    .sort((a, b) => a.vencimiento.localeCompare(b.vencimiento))[0];

  const ultimoAviso = (deuda: Deuda) => {
    const entregados = recordatorios
      .filter((r) => r.deudaId === deuda.id && r.entregadoEn)
      .sort((a, b) => b.entregadoEn!.localeCompare(a.entregadoEn!));
    return entregados[0];
  };

  return (
    <Pantalla conPestanas encabezado={<Encabezado titulo="Inicio" conAvisos />}>
      <View style={estilos.grupo}>
        <Texto variante="headlineLg">Buenos días, {USUARIO_EJEMPLO.nombre}</Texto>
        <Pressable
          accessibilityRole="button"
          accessibilityState={{ expanded: selectorAbierto }}
          accessibilityLabel={`Municipalidad: ${municipalidad.nombre}. Cambiar`}
          onPress={() => setSelectorAbierto((abierto) => !abierto)}
          style={estilos.selector}
        >
          <MaterialIcons name="location-city" size={20} color={colors.primary} />
          <Texto variante="bodyLgMedium">{municipalidad.nombre}</Texto>
          <MaterialIcons name="arrow-drop-down" size={24} color={colors.text} />
        </Pressable>
        {selectorAbierto ? (
          <View style={estilos.grupo}>
            {municipalidadesDelVecino().map(({ municipalidad: opcion, cantidadPredios }) => (
              <Opcion
                key={opcion.id}
                titulo={opcion.nombre}
                detalle={`${cantidadPredios} ${cantidadPredios === 1 ? 'predio registrado' : 'predios registrados'}`}
                seleccionada={opcion.id === municipalidad.id}
                onPress={() => {
                  elegirMunicipalidad(opcion.id);
                  setSelectorAbierto(false);
                }}
              />
            ))}
            <Boton
              tipo="terciario"
              titulo="Ver todas las municipalidades"
              onPress={() => router.push('/municipalidad')}
            />
          </View>
        ) : null}
      </View>

      <Tarjeta>
        <Texto variante="bodyMd" color={colors.textSecondary}>
          Deuda total pendiente
        </Texto>
        <Monto valor={total} grande />
        {proxima ? (
          <Texto variante="bodyMd" color={colors.textSecondary}>
            Próximo vencimiento: {formatearFecha(proxima.vencimiento)}
          </Texto>
        ) : null}
      </Tarjeta>
      <Boton
        icono="payments"
        titulo="Pagar ahora"
        deshabilitado={pendientes.length === 0}
        onPress={() => router.push('/pagar')}
      />

      {municipalidad.avisoDestacado ? (
        <Destacado icono="savings" texto={municipalidad.avisoDestacado} />
      ) : null}

      <View style={estilos.grupo}>
        <Texto variante="headlineMd">Tributos registrados</Texto>
        {pendientes.length === 0 ? (
          <Vacio texto="No tienes tributos pendientes en esta municipalidad." />
        ) : (
          <Tarjeta>
            {pendientes.map((deuda, indice) => {
              const aviso = ultimoAviso(deuda);
              return (
                <View key={deuda.id} style={estilos.grupo}>
                  {indice > 0 ? <Separador /> : null}
                  <Pressable
                    accessibilityRole="button"
                    accessibilityLabel={`Ver detalle de ${deuda.concepto}`}
                    onPress={() => router.push(`/deuda/${deuda.id}`)}
                    style={estilos.grupo}
                  >
                    <View style={estilos.fila}>
                      <Texto variante="bodyLgMedium" style={estilos.flexible}>
                        {deuda.concepto}
                      </Texto>
                      <Monto valor={deuda.montoInsoluto + deuda.interesMoratorio} />
                    </View>
                    <Insignia
                      texto={ETIQUETA_ESTADO_DEUDA[deuda.estado]}
                      tono={deuda.estado === 'vencida' ? 'critico' : 'exito'}
                    />
                    {aviso ? (
                      <Texto variante="bodyMd" color={colors.textSecondary}>
                        Último aviso: {ETIQUETA_TIPO_RECORDATORIO[aviso.tipo]} por{' '}
                        {ETIQUETA_CANAL[aviso.canal]}
                      </Texto>
                    ) : null}
                  </Pressable>
                </View>
              );
            })}
          </Tarjeta>
        )}
      </View>

      <Boton
        tipo="secundario"
        titulo="Consultar al asistente"
        onPress={() => router.push('/asistente')}
      />
    </Pantalla>
  );
}

const estilos = StyleSheet.create({
  grupo: { gap: spacing.sm },
  selector: { flexDirection: 'row', alignItems: 'center', gap: spacing.sm, minHeight: 48 },
  fila: { flexDirection: 'row', gap: spacing.md },
  flexible: { flex: 1 },
});
