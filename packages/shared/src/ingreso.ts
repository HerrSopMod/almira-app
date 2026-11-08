// Validaciones del ingreso (pantallas 02a a 02c). El ingreso todavía es simulado.

// DNI o carné de extranjería: de 8 a 12 letras o números, sin espacios ni signos.
export function documentoValido(texto: string): boolean {
  return /^[A-Za-z0-9]{8,12}$/.test(texto.trim());
}

// Código SMS de 6 dígitos.
export function codigoValido(texto: string): boolean {
  return /^\d{6}$/.test(texto);
}
