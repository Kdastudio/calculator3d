-- KDA3D Calculator - Schema inicial
-- Execute no SQL Editor do Supabase ou via CLI: supabase db push

-- Perfil do usuário (empresa / preferências)
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text,
  company_name text default '',
  company_email text default '',
  company_phone text default '',
  company_slogan text default 'Soluções em Manufatura Aditiva',
  logo_path text,
  currency_code text default 'BRL',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Cálculos salvos
create table if not exists public.calculations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null default 'Novo cálculo',
  cost_inputs jsonb not null default '{}',
  tax_inputs jsonb not null default '{}',
  currency_code text not null default 'BRL',
  results jsonb,
  gcode_path text,
  gcode_filename text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Orçamentos salvos
create table if not exists public.quotes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  quote_number text not null,
  client_name text default '',
  contact text default '',
  quote_date date not null default current_date,
  items jsonb not null default '[]',
  discount_percent numeric(5,2) default 0,
  shipping_cost numeric(12,2) default 0,
  observations text default '',
  company_name text default '',
  company_email text default '',
  company_phone text default '',
  company_slogan text default '',
  logo_path text,
  currency_code text default 'BRL',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Índices
create index if not exists idx_calculations_user_id on public.calculations (user_id);
create index if not exists idx_calculations_updated_at on public.calculations (updated_at desc);
create index if not exists idx_quotes_user_id on public.quotes (user_id);
create index if not exists idx_quotes_updated_at on public.quotes (updated_at desc);

-- Trigger: criar perfil ao registrar
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email);
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Trigger: updated_at automático
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_updated_at on public.profiles;
create trigger profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

drop trigger if exists calculations_updated_at on public.calculations;
create trigger calculations_updated_at
  before update on public.calculations
  for each row execute function public.set_updated_at();

drop trigger if exists quotes_updated_at on public.quotes;
create trigger quotes_updated_at
  before update on public.quotes
  for each row execute function public.set_updated_at();

-- RLS
alter table public.profiles enable row level security;
alter table public.calculations enable row level security;
alter table public.quotes enable row level security;

-- Profiles
create policy "Usuário lê próprio perfil"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Usuário atualiza próprio perfil"
  on public.profiles for update
  using (auth.uid() = id);

create policy "Usuário insere próprio perfil"
  on public.profiles for insert
  with check (auth.uid() = id);

-- Calculations
create policy "Usuário lê próprios cálculos"
  on public.calculations for select
  using (auth.uid() = user_id);

create policy "Usuário insere próprios cálculos"
  on public.calculations for insert
  with check (auth.uid() = user_id);

create policy "Usuário atualiza próprios cálculos"
  on public.calculations for update
  using (auth.uid() = user_id);

create policy "Usuário deleta próprios cálculos"
  on public.calculations for delete
  using (auth.uid() = user_id);

-- Quotes
create policy "Usuário lê próprios orçamentos"
  on public.quotes for select
  using (auth.uid() = user_id);

create policy "Usuário insere próprios orçamentos"
  on public.quotes for insert
  with check (auth.uid() = user_id);

create policy "Usuário atualiza próprios orçamentos"
  on public.quotes for update
  using (auth.uid() = user_id);

create policy "Usuário deleta próprios orçamentos"
  on public.quotes for delete
  using (auth.uid() = user_id);

-- Storage buckets
insert into storage.buckets (id, name, public)
values
  ('logos', 'logos', false),
  ('gcodes', 'gcodes', false)
on conflict (id) do nothing;

-- Storage RLS: logos
create policy "Usuário lê próprios logos"
  on storage.objects for select
  using (bucket_id = 'logos' and auth.uid()::text = (storage.foldername(name))[1]);

create policy "Usuário envia próprios logos"
  on storage.objects for insert
  with check (bucket_id = 'logos' and auth.uid()::text = (storage.foldername(name))[1]);

create policy "Usuário atualiza próprios logos"
  on storage.objects for update
  using (bucket_id = 'logos' and auth.uid()::text = (storage.foldername(name))[1]);

create policy "Usuário deleta próprios logos"
  on storage.objects for delete
  using (bucket_id = 'logos' and auth.uid()::text = (storage.foldername(name))[1]);

-- Storage RLS: gcodes
create policy "Usuário lê próprios gcodes"
  on storage.objects for select
  using (bucket_id = 'gcodes' and auth.uid()::text = (storage.foldername(name))[1]);

create policy "Usuário envia próprios gcodes"
  on storage.objects for insert
  with check (bucket_id = 'gcodes' and auth.uid()::text = (storage.foldername(name))[1]);

create policy "Usuário deleta próprios gcodes"
  on storage.objects for delete
  using (bucket_id = 'gcodes' and auth.uid()::text = (storage.foldername(name))[1]);
