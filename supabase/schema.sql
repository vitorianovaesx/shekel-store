-- ============================================================
-- ShekelStore - Schema Supabase
-- ============================================================

-- Tabela de perfis (estende auth.users)
create table public.profiles (
  id uuid references auth.users(id) on delete cascade primary key,
  username text unique not null,
  display_name text not null,
  avatar_url text,
  shekel_balance bigint default 1000 not null check (shekel_balance >= 0),
  total_won bigint default 0 not null,
  total_lost bigint default 0 not null,
  created_at timestamptz default now() not null
);

-- Tabela de itens da loja
create table public.items (
  id serial primary key,
  name text not null,
  description text not null,
  emoji text not null,
  price integer not null check (price > 0),
  category text not null,
  rarity text not null default 'comum',
  is_available boolean default true not null,
  created_at timestamptz default now() not null
);

-- Inventário do usuário
create table public.user_items (
  id serial primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  item_id integer references public.items(id) not null,
  purchased_at timestamptz default now() not null,
  unique(user_id, item_id)
);

-- Histórico de apostas
create table public.bets (
  id serial primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  game_type text not null,
  amount bigint not null check (amount > 0),
  outcome text not null check (outcome in ('win', 'loss')),
  payout bigint not null check (payout >= 0),
  details jsonb,
  created_at timestamptz default now() not null
);

-- Histórico de transações
create table public.transactions (
  id serial primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  type text not null,
  amount bigint not null,
  description text,
  created_at timestamptz default now() not null
);

-- ============================================================
-- Row Level Security
-- ============================================================

alter table public.profiles enable row level security;
alter table public.items enable row level security;
alter table public.user_items enable row level security;
alter table public.bets enable row level security;
alter table public.transactions enable row level security;

-- Profiles
create policy "Qualquer usuário autenticado pode ver perfis"
  on public.profiles for select to authenticated using (true);

create policy "Usuários criam o próprio perfil"
  on public.profiles for insert to authenticated with check (auth.uid() = id);

create policy "Usuários atualizam o próprio perfil"
  on public.profiles for update to authenticated using (auth.uid() = id);

-- Items
create policy "Itens são visíveis por todos"
  on public.items for select to authenticated using (true);

-- User items
create policy "Usuários veem o próprio inventário"
  on public.user_items for select to authenticated using (auth.uid() = user_id);

create policy "Usuários compram itens"
  on public.user_items for insert to authenticated with check (auth.uid() = user_id);

-- Bets
create policy "Usuários veem o próprio histórico de apostas"
  on public.bets for select to authenticated using (auth.uid() = user_id);

create policy "Usuários registram apostas"
  on public.bets for insert to authenticated with check (auth.uid() = user_id);

-- Transactions
create policy "Usuários veem o próprio histórico de transações"
  on public.transactions for select to authenticated using (auth.uid() = user_id);

create policy "Usuários registram transações"
  on public.transactions for insert to authenticated with check (auth.uid() = user_id);

-- ============================================================
-- Funções RPC
-- ============================================================

-- Ajusta saldo do usuário (pode ser positivo ou negativo)
create or replace function public.adjust_balance(uid uuid, delta bigint)
returns void as $$
begin
  update public.profiles
  set shekel_balance = shekel_balance + delta
  where id = uid;
end;
$$ language plpgsql security definer;

-- Incrementa total_won
create or replace function public.increment_won(uid uuid, amount bigint)
returns void as $$
begin
  update public.profiles
  set total_won = total_won + amount
  where id = uid;
end;
$$ language plpgsql security definer;

-- Incrementa total_lost
create or replace function public.increment_lost(uid uuid, amount bigint)
returns void as $$
begin
  update public.profiles
  set total_lost = total_lost + amount
  where id = uid;
end;
$$ language plpgsql security definer;

-- ============================================================
-- Trigger: cria perfil e bônus de registro automaticamente
-- ============================================================

create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, username, display_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1))
  );

  insert into public.transactions (user_id, type, amount, description)
  values (new.id, 'registration', 1000, 'Bônus de registro - bem-vindo à ShekelStore!');

  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ============================================================
-- Storage bucket para avatares
-- ============================================================

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict do nothing;

create policy "Avatares são públicos"
  on storage.objects for select
  using (bucket_id = 'avatars');

create policy "Usuários fazem upload do próprio avatar"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "Usuários atualizam o próprio avatar"
  on storage.objects for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

-- ============================================================
-- Seed: itens da loja
-- ============================================================

insert into public.items (name, description, emoji, price, category, rarity) values
  ('Coroa Dourada', 'Uma coroa majestosa banhada em ouro puro de Salomão', '👑', 500, 'acessório', 'raro'),
  ('Diamante Azul', 'Um diamante precioso de cor azul profundo, achado no deserto', '💎', 1000, 'joia', 'épico'),
  ('Estrela Brilhante', 'Uma estrela que nunca se apaga, símbolo de vitória', '⭐', 200, 'colecionável', 'comum'),
  ('Troféu de Ouro', 'Para os maiores vencedores do cassino', '🏆', 2000, 'conquista', 'lendário'),
  ('Chama Eterna', 'Uma chama que queima por toda a eternidade', '🔥', 300, 'colecionável', 'incomum'),
  ('Foguete Espacial', 'Vá além das estrelas e das apostas', '🚀', 800, 'veículo', 'raro'),
  ('Escudo Protetor', 'Proteja seus shekels com este escudo mágico', '🛡️', 600, 'proteção', 'incomum'),
  ('Varinha Mágica', 'Talvez ela traga sorte nas apostas', '🪄', 750, 'especial', 'raro'),
  ('Bolsa de Moedas', 'Mais espaço para guardar seus shekels', '👜', 400, 'utilitário', 'comum'),
  ('Cristal Místico', 'Um cristal com poderes divinatórios misteriosos', '🔮', 1500, 'mágico', 'épico'),
  ('Espada Sagrada', 'A espada dos guerreiros do templo de Jerusalém', '⚔️', 900, 'arma', 'raro'),
  ('Livro Antigo', 'Contém os segredos dos antigos apostadores', '📜', 350, 'conhecimento', 'incomum');
