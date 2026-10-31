-- Esquema multi-municipalidad de Almira.
-- Toda tabla de datos lleva municipalidad_id. Las llaves foráneas compuestas
-- (municipalidad_id, id) impiden enlazar filas de municipalidades distintas.

create table public.municipalidades (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  nombre text not null,
  zona text not null check (zona in ('Lima Centro', 'Lima Sur', 'Lima Este', 'Lima Norte')),
  telefono_ayuda text,
  aviso_destacado text,
  activa boolean not null default true,
  creado_en timestamptz not null default now()
);

create table public.personal (
  id uuid primary key default gen_random_uuid(),
  municipalidad_id uuid not null references public.municipalidades (id) on delete restrict,
  user_id uuid not null references auth.users (id) on delete cascade,
  nombre text not null,
  rol text not null default 'operador' check (rol in ('administrador', 'operador')),
  creado_en timestamptz not null default now(),
  unique (municipalidad_id, user_id)
);

-- Una persona tiene una fila por cada municipalidad donde tributa.
-- user_id queda vacío hasta que el vecino vincula su DNI.
create table public.vecinos (
  id uuid primary key default gen_random_uuid(),
  municipalidad_id uuid not null references public.municipalidades (id) on delete restrict,
  user_id uuid references auth.users (id) on delete set null,
  dni char(8) not null check (dni ~ '^[0-9]{8}$'),
  nombre text not null,
  telefono text,
  canal_preferido text not null default 'whatsapp'
    check (canal_preferido in ('whatsapp', 'sms', 'app')),
  creado_en timestamptz not null default now(),
  unique (municipalidad_id, id),
  unique (municipalidad_id, dni),
  unique (municipalidad_id, user_id)
);

create table public.predios (
  id uuid primary key default gen_random_uuid(),
  municipalidad_id uuid not null references public.municipalidades (id) on delete restrict,
  vecino_id uuid not null,
  codigo text not null,
  direccion text not null,
  creado_en timestamptz not null default now(),
  unique (municipalidad_id, id),
  unique (municipalidad_id, codigo),
  foreign key (municipalidad_id, vecino_id)
    references public.vecinos (municipalidad_id, id) on delete restrict
);

create table public.deudas (
  id uuid primary key default gen_random_uuid(),
  municipalidad_id uuid not null references public.municipalidades (id) on delete restrict,
  vecino_id uuid not null,
  predio_id uuid,
  tipo text not null check (tipo in ('predial', 'arbitrios')),
  concepto text not null,
  periodo text not null,
  monto_insoluto numeric(12, 2) not null check (monto_insoluto >= 0),
  interes_moratorio numeric(12, 2) not null default 0 check (interes_moratorio >= 0),
  total numeric(12, 2) generated always as (monto_insoluto + interes_moratorio) stored,
  vencimiento date not null,
  estado text not null default 'vigente' check (estado in ('vigente', 'vencida', 'pagada')),
  creado_en timestamptz not null default now(),
  unique (municipalidad_id, id),
  foreign key (municipalidad_id, vecino_id)
    references public.vecinos (municipalidad_id, id) on delete restrict,
  foreign key (municipalidad_id, predio_id)
    references public.predios (municipalidad_id, id) on delete restrict
);

create table public.pagos (
  id uuid primary key default gen_random_uuid(),
  municipalidad_id uuid not null references public.municipalidades (id) on delete restrict,
  vecino_id uuid not null,
  deuda_id uuid not null,
  monto numeric(12, 2) not null check (monto > 0),
  medio text not null check (medio in ('billetera', 'tarjeta', 'pagoefectivo')),
  estado text not null default 'pendiente'
    check (estado in ('pendiente', 'confirmado', 'rechazado')),
  referencia text,
  creado_en timestamptz not null default now(),
  foreign key (municipalidad_id, vecino_id)
    references public.vecinos (municipalidad_id, id) on delete restrict,
  foreign key (municipalidad_id, deuda_id)
    references public.deudas (municipalidad_id, id) on delete restrict
);

create table public.recordatorios (
  id uuid primary key default gen_random_uuid(),
  municipalidad_id uuid not null references public.municipalidades (id) on delete restrict,
  vecino_id uuid not null,
  deuda_id uuid not null,
  codigo text not null,
  tipo text not null check (tipo in ('preventivo', 'mora', 'previo_coactiva')),
  canal text not null check (canal in ('whatsapp', 'sms', 'app')),
  estado text not null default 'programado'
    check (estado in ('programado', 'enviado', 'entregado', 'fallido')),
  programado_para timestamptz not null,
  entregado_en timestamptz,
  creado_en timestamptz not null default now(),
  unique (municipalidad_id, codigo),
  foreign key (municipalidad_id, vecino_id)
    references public.vecinos (municipalidad_id, id) on delete restrict,
  foreign key (municipalidad_id, deuda_id)
    references public.deudas (municipalidad_id, id) on delete restrict
);

-- foto_ruta apunta al bucket "evidencias" y debe estar en la carpeta de su municipalidad.
create table public.reclamos (
  id uuid primary key default gen_random_uuid(),
  municipalidad_id uuid not null references public.municipalidades (id) on delete restrict,
  vecino_id uuid not null,
  codigo text not null
    default 'REC-' || to_char(now(), 'YYYY') || '-' || substr(gen_random_uuid()::text, 1, 8),
  tipo text not null check (tipo in ('basura', 'bache', 'luminaria')),
  titulo text not null,
  descripcion text,
  estado text not null default 'en_atencion'
    check (estado in ('en_atencion', 'derivado', 'resuelto')),
  area text,
  plazo text,
  foto_ruta text not null check (split_part(foto_ruta, '/', 1) = municipalidad_id::text),
  latitud double precision check (latitud between -90 and 90),
  longitud double precision check (longitud between -180 and 180),
  creado_en timestamptz not null default now(),
  unique (municipalidad_id, codigo),
  foreign key (municipalidad_id, vecino_id)
    references public.vecinos (municipalidad_id, id) on delete restrict
);

create table public.obras (
  id uuid primary key default gen_random_uuid(),
  municipalidad_id uuid not null references public.municipalidades (id) on delete restrict,
  nombre text not null,
  ubicacion text not null,
  estado text not null default 'en_ejecucion' check (estado in ('en_ejecucion', 'finalizada')),
  avance_pct numeric(5, 2) not null default 0 check (avance_pct between 0 and 100),
  meta text not null,
  monto_asignado numeric(14, 2) not null check (monto_asignado >= 0),
  monto_ejecutado numeric(14, 2) not null default 0 check (monto_ejecutado >= 0),
  fotos integer not null default 0 check (fotos >= 0),
  creado_en timestamptz not null default now()
);

create index on public.personal (user_id);
create index on public.vecinos (user_id);
create index on public.predios (municipalidad_id, vecino_id);
create index on public.deudas (municipalidad_id, vecino_id);
create index on public.pagos (municipalidad_id, vecino_id);
create index on public.recordatorios (municipalidad_id, vecino_id);
create index on public.recordatorios (estado, programado_para);
create index on public.reclamos (municipalidad_id, vecino_id);
create index on public.obras (municipalidad_id);
