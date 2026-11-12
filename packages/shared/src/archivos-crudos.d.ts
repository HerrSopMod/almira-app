// Vite importa el contenido de un archivo como texto con el sufijo ?raw (lo usan las pruebas
// que revisan las migraciones SQL).
declare module '*?raw' {
  const contenido: string;
  export default contenido;
}
