-- KDA3D - Estoque por usuário
-- Execute após 002_supplies_and_energy.sql

create table if not exists public.stock_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  unit text not null default 'g',
  quantity_on_hand numeric(14,4) not null default 0,
  unit_cost numeric(14,4) not null default 0,
  supply_id uuid references public.supplies (id) on delete set null,
  notes text default '',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists idx_stock_items_user_id on public.stock_items (user_id);
create index if not exists idx_stock_items_supply_id on public.stock_items (supply_id);

drop trigger if exists stock_items_updated_at on public.stock_items;
create trigger stock_items_updated_at
  before update on public.stock_items
  for each row execute function public.set_updated_at();

alter table public.stock_items enable row level security;

create policy "Usuário lê próprio estoque"
  on public.stock_items for select using (auth.uid() = user_id);

create policy "Usuário insere próprio estoque"
  on public.stock_items for insert with check (auth.uid() = user_id);

create policy "Usuário atualiza próprio estoque"
  on public.stock_items for update using (auth.uid() = user_id);

create policy "Usuário deleta próprio estoque"
  on public.stock_items for delete using (auth.uid() = user_id);
