-- KDA3D - Insumos e histórico de preços
-- Execute após 001_initial_schema.sql

create table if not exists public.supplies (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  type text not null default 'filament',
  brand text default '',
  supplier text default '',
  price_per_unit numeric(12,2) not null default 0,
  unit text not null default 'kg',
  color text,
  material text,
  density numeric(6,3) default 1.24,
  purchased_at timestamptz,
  is_active boolean default true,
  notes text default '',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.supply_price_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  supply_id uuid not null references public.supplies (id) on delete cascade,
  price numeric(12,2) not null,
  supplier text default '',
  recorded_at timestamptz not null default now()
);

create index if not exists idx_supplies_user_id on public.supplies (user_id);
create index if not exists idx_supply_history_user on public.supply_price_history (user_id);
create index if not exists idx_supply_history_supply on public.supply_price_history (supply_id);

drop trigger if exists supplies_updated_at on public.supplies;
create trigger supplies_updated_at
  before update on public.supplies
  for each row execute function public.set_updated_at();

alter table public.supplies enable row level security;
alter table public.supply_price_history enable row level security;

create policy "Usuário lê próprios insumos"
  on public.supplies for select using (auth.uid() = user_id);

create policy "Usuário insere próprios insumos"
  on public.supplies for insert with check (auth.uid() = user_id);

create policy "Usuário atualiza próprios insumos"
  on public.supplies for update using (auth.uid() = user_id);

create policy "Usuário deleta próprios insumos"
  on public.supplies for delete using (auth.uid() = user_id);

create policy "Usuário lê próprio histórico"
  on public.supply_price_history for select using (auth.uid() = user_id);

create policy "Usuário insere próprio histórico"
  on public.supply_price_history for insert with check (auth.uid() = user_id);

create policy "Usuário deleta próprio histórico"
  on public.supply_price_history for delete using (auth.uid() = user_id);

alter table public.profiles
  add column if not exists preferred_state text default 'São Paulo';
