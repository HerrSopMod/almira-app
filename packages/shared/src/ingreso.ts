// Validaciones del ingreso (pantallas 02a a 02e).

// DNI o carné de extranjería: de 8 a 12 letras o números, sin espacios ni signos.
export function documentoValido(texto: string): boolean {
  return /^[A-Za-z0-9]{8,12}$/.test(texto.trim());
}

// Código SMS de 6 dígitos.
export function codigoValido(texto: string): boolean {
  return /^\d{6}$/.test(texto);
}

// Código de contribuyente o de predio: letras, números y guiones, de 4 a 20 caracteres.
export function codigoContribuyenteValido(texto: string): boolean {
  return /^[A-Za-z0-9-]{4,20}$/.test(texto.trim());
}

// Celular peruano: 9 dígitos que empiezan con 9.
export function celularValido(texto: string): boolean {
  return /^9\d{8}$/.test(texto);
}

const normalizarCodigo = (texto: string) => texto.trim().toUpperCase();

// Padrón simulado: el vínculo vale solo si el código (de contribuyente o de predio) y el DNI
// son de la misma persona en esa municipalidad. Devuelve el vecino, o null si no coinciden.
// Con Supabase esta misma regla corre en el servidor (vincular_contribuyente).
export function buscarVecinoPorCodigo<
  V extends { id: string; municipalidadId: string; dni: string; codigoContribuyente: string | null },
>(
  padron: V[],
  prediosPadron: { vecinoId: string; codigo: string }[],
  municipalidadId: string,
  codigo: string,
  dni: string,
): V | null {
  const buscado = normalizarCodigo(codigo);
  return (
    padron.find(
      (vecino) =>
        vecino.municipalidadId === municipalidadId &&
        vecino.dni.toUpperCase() === normalizarCodigo(dni) &&
        (vecino.codigoContribuyente?.toUpperCase() === buscado ||
          prediosPadron.some(
            (predio) => predio.vecinoId === vecino.id && predio.codigo.toUpperCase() === buscado,
          )),
    ) ?? null
  );
}
