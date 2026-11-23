// Coordenadas de las obras desde Infobras, para cargarlas en Almira con una migración.
//
// No usa ninguna dirección inventada: tú copias la petición que hace la ficha de Infobras
// para dibujar su mapa y el script la repite para cada obra.
//
// Cómo usarlo
// 1. Abre en Chrome la ficha de una obra en https://infobras.contraloria.gob.pe (por ejemplo,
//    la 552143) con DevTools → Network abierto y mira su mapa.
// 2. Busca la petición que trae el punto de la obra (su respuesta tiene números como -12.08 y
//    -77.03). Clic derecho → Copy → Copy as fetch.
// 3. Pega aquí abajo, en PETICION, la dirección y las opciones de ese fetch. Cambia el código de la
//    obra (552143) por {codigo} en la dirección y, si lo tiene, en el body.
// 4. Copia todo este archivo en la consola de esa misma pestaña de Infobras y pulsa Enter.
// 5. Descarga dos archivos: obras-coordenadas.csv (para revisar) y
//    20261123000005_obras_coordenadas.sql (la migración). Envíaselos a Claude o al equipo.
//
// Infobras entrega la latitud y la longitud invertidas en ese endpoint. El script no supone el
// orden: en Lima la latitud está cerca de -12 y la longitud cerca de -77, así que reconoce cada una
// por su rango y marca en la columna «invertido» cuáles venían al revés.
// Si una obra trae varios puntos (un tramo de calle), usa el primero y lo marca para revisar.

const PETICION = {
  url: 'PEGA_AQUI_LA_DIRECCION_CON_{codigo}',
  opciones: {
    // Pega aquí lo que venga en el segundo argumento de «Copy as fetch» (method, headers, body…).
    method: 'GET',
  },
};

// [slug de la municipalidad en Almira, código Infobras]
const OBRAS = [
  ...[552143, 512478, 524809, 514912, 140101, 140100, 167167, 174106, 160621, 141346, 156671, 156446,
    149331, 145347, 150453].map((c) => ['lince', c]),
  ...[559956, 557113, 555253, 549961, 538068, 544745, 540067, 518410, 525884, 522278, 520835, 536730,
    521023, 518937, 514939, 509645, 502874, 521481, 509650, 518707, 518708, 518366, 132624, 29777].map(
    (c) => ['lurin', c],
  ),
];

// Lima Metropolitana, con margen. Un punto fuera de aquí no se carga.
const esLatitud = (n) => n >= -12.6 && n <= -11.5;
const esLongitud = (n) => n >= -77.3 && n <= -76.5;

function puntosEn(texto) {
  const numeros = (texto.match(/-?\d{1,3}\.\d{4,}/g) || []).map(Number);
  const puntos = [];
  for (let i = 0; i + 1 < numeros.length; i++) {
    const [a, b] = [numeros[i], numeros[i + 1]];
    let punto = null;
    if (esLatitud(a) && esLongitud(b)) punto = { latitud: a, longitud: b, invertido: false };
    else if (esLongitud(a) && esLatitud(b)) punto = { latitud: b, longitud: a, invertido: true };
    if (punto) {
      puntos.push(punto);
      i++;
    }
  }
  return puntos;
}

const esperar = (ms) => new Promise((r) => setTimeout(r, ms));

function descargar(nombre, contenido) {
  const enlace = document.createElement('a');
  enlace.href = URL.createObjectURL(new Blob([contenido], { type: 'text/plain;charset=utf-8' }));
  enlace.download = nombre;
  enlace.click();
}

(async () => {
  if (PETICION.url.startsWith('PEGA_AQUI')) throw new Error('Primero pega la petición en PETICION.');
  const filas = [];
  for (const [slug, codigo] of OBRAS) {
    const poner = (s) => (typeof s === 'string' ? s.replaceAll('{codigo}', String(codigo)) : s);
    let fila = { slug, codigo, latitud: null, longitud: null, invertido: '', puntos: 0, nota: '' };
    try {
      const respuesta = await fetch(poner(PETICION.url), { ...PETICION.opciones, body: poner(PETICION.opciones.body) });
      const puntos = puntosEn(await respuesta.text());
      fila.puntos = puntos.length;
      if (!respuesta.ok) fila.nota = `HTTP ${respuesta.status}`;
      else if (puntos.length === 0) fila.nota = 'sin punto';
      else {
        Object.assign(fila, puntos[0], { invertido: puntos[0].invertido ? 'sí' : 'no' });
        if (puntos.length > 1) fila.nota = 'varios puntos: revisar';
      }
    } catch (error) {
      fila.nota = String(error.message || error);
    }
    filas.push(fila);
    await esperar(800); // una petición por vez, sin cargar el servidor
  }
  console.table(filas);

  const csv = ['slug,codigo,latitud,longitud,invertido,puntos,nota']
    .concat(filas.map((f) => [f.slug, f.codigo, f.latitud ?? '', f.longitud ?? '', f.invertido, f.puntos, f.nota].join(',')))
    .join('\n');
  descargar('obras-coordenadas.csv', csv);

  const conPunto = filas.filter((f) => f.latitud !== null);
  const valores = conPunto
    .map((f) => `  ('${f.slug}', ${f.codigo}, ${f.latitud}, ${f.longitud})`)
    .join(',\n');
  const sql = `-- Coordenadas de las obras tomadas del mapa de Infobras (Contraloría), consulta del ${new Date().toISOString().slice(0, 10)}.
-- Generada con supabase/scripts/infobras-coordenadas.js. Infobras entrega latitud y longitud
-- invertidas: el script reconoce cada una por su rango en Lima.
-- Solo llena obras sin coordenadas (no pisa una ubicación ya verificada) y descarta puntos fuera
-- de Lima Metropolitana. ${filas.length - conPunto.length} de ${filas.length} obras quedan sin punto.

update public.obras o
set latitud = v.latitud, longitud = v.longitud
from (values
${valores}
) as v (slug, codigo, latitud, longitud)
join public.municipalidades m on m.slug = v.slug
where o.municipalidad_id = m.id
  and o.codigo_infobras = v.codigo
  and o.latitud is null
  and o.longitud is null
  and v.latitud between -12.6 and -11.5
  and v.longitud between -77.3 and -76.5;
`;
  descargar('20261123000005_obras_coordenadas.sql', sql);
  console.log(`Listo: ${conPunto.length} de ${filas.length} obras con punto.`);
})();
