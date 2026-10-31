import {
  colors,
  ETIQUETA_ESTADO_OBRA,
  formatearSoles,
  spacing,
} from '@almira/shared';
import { router } from 'expo-router';
import { StyleSheet, View } from 'react-native';
import {
  Destacado,
  FilaDato,
  Insignia,
  Monto,
  Progreso,
  Tarjeta,
  Vacio,
} from '@/components/Bloques';
import { Boton } from '@/components/Boton';
import { Encabezado } from '@/components/Encabezado';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';
import { useDatosMunicipales } from '@/sesion';

export default function Obras() {
  const { municipalidad, obras } = useDatosMunicipales();
  const asignado = obras.reduce((suma, obra) => suma + obra.montoAsignado, 0);
  const ejecutado = obras.reduce((suma, obra) => suma + obra.montoEjecutado, 0);
  const ejecucion = asignado > 0 ? (ejecutado / asignado) * 100 : 0;

  return (
    <Pantalla conPestanas encabezado={<Encabezado titulo="Obras" conAvisos />}>
      <View style={estilos.grupo}>
        <Texto variante="headlineLg">Obras públicas distritales</Texto>
        <Texto color={colors.textSecondary}>{municipalidad.nombre}</Texto>
      </View>
      <Boton
        tipo="secundario"
        titulo="Cambiar municipalidad"
        onPress={() => router.push('/municipalidad')}
      />

      {obras.length === 0 ? (
        <Vacio texto="Esta municipalidad aún no tiene obras publicadas." />
      ) : (
        <>
          <Tarjeta>
            <Texto variante="bodyMd" color={colors.textSecondary}>
              Presupuesto de obras
            </Texto>
            <Monto valor={asignado} grande />
            <FilaDato etiqueta="Ejecución global" valor={`${ejecucion.toFixed(1)}%`} />
            <Progreso porcentaje={ejecucion} />
          </Tarjeta>

          {obras.map((obra) => (
            <Tarjeta key={obra.id}>
              <Insignia texto={ETIQUETA_ESTADO_OBRA[obra.estado]} tono="atencion" />
              <Texto variante="headlineSm">{obra.nombre}</Texto>
              <Texto variante="bodyMd" color={colors.textSecondary}>
                {obra.ubicacion} · {obra.fotos} fotos
              </Texto>
              <Progreso porcentaje={obra.avancePct} />
              <FilaDato etiqueta={`${obra.avancePct}% de avance físico`} valor={`Meta: ${obra.meta}`} />
              <FilaDato etiqueta="Monto asignado" valor={formatearSoles(obra.montoAsignado)} />
              <FilaDato etiqueta="Monto ejecutado" valor={formatearSoles(obra.montoEjecutado)} />
            </Tarjeta>
          ))}
        </>
      )}

      <Destacado
        icono="policy"
        titulo="Transparencia"
        texto="Los montos y avances se publican para consulta de los vecinos."
      />
    </Pantalla>
  );
}

const estilos = StyleSheet.create({
  grupo: { gap: spacing.sm },
});
