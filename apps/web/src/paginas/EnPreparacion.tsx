import { Encabezado, Tarjeta } from '../componentes';

// Lugar para los módulos que todavía no se construyen.
export function EnPreparacion({ titulo }: { titulo: string }) {
  return (
    <>
      <Encabezado titulo={titulo} subtitulo="Módulo en preparación" />
      <Tarjeta>
        <p className="subtitulo">Este módulo todavía no está disponible en el panel.</p>
      </Tarjeta>
    </>
  );
}
