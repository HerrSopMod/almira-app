/// Listas editables de etiquetas del modelo, en inglés y tal como las
/// nombra el modelo. La comparación no distingue mayúsculas.
library;

/// Etiquetas que indican un problema en la vía pública.
const etiquetasValidas = <String>[
  'Road',
  'Asphalt',
  'Bridge',
  'Building',
  'Wall',
  'Construction',
  'Infrastructure',
  'Junk',
  'Soil',
  'Park',
  'Handrail',
  'Tower',
  'Vehicle',
];

/// Etiquetas que indican que la foto no es de la vía pública.
const etiquetasNoValidas = <String>[
  'Selfie',
  'Screenshot',
  'Web page',
  'Food',
  'Pet',
  'Cat',
  'Dog',
  'Poster',
  'Bedroom',
  'Kitchen',
  'Couch',
  'Toy',
];

/// Confianza mínima de una etiqueta no válida para marcar la foto como no válida.
const umbralNoValida = 0.7;

/// Confianza mínima de una etiqueta válida para marcar la foto como válida.
const umbralValida = 0.6;

/// Confianza mínima que devuelve el modelo. Va por debajo de los dos umbrales
/// anteriores para no descartar etiquetas antes de aplicar la regla.
const umbralModelo = 0.5;
