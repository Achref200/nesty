-- ============================================================================
-- Nesty — initial schema
-- Profiles, listings (rooms embedded as jsonb to match the mobile model),
-- reservations, saved listings, and the marketing waitlist. Row Level Security
-- is enabled on every table; policies scope each row to its owner.
-- Apply with the Supabase SQL editor or `supabase db push`.
-- ============================================================================

-- ---------------------------------------------------------------- profiles ---
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text,
  full_name text,
  role text not null default 'seeker' check (role in ('seeker', 'host')),
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "Profiles are viewable by everyone"
  on public.profiles for select using (true);
create policy "Users can insert their own profile"
  on public.profiles for insert with check (auth.uid() = id);
create policy "Users can update their own profile"
  on public.profiles for update using (auth.uid() = id);

-- ---------------------------------------------------------------- listings ---
create table if not exists public.listings (
  id uuid primary key default gen_random_uuid(),
  host_id uuid not null references public.profiles (id) on delete cascade,
  title text not null,
  city text not null,
  address text,
  price_per_month numeric not null default 0,
  currency text not null default 'TND',
  type text not null default 'entire_place'
    check (type in ('entire_place', 'private_room', 'shared_room')),
  bedrooms int not null default 0,
  bathrooms int not null default 0,
  area_sqm numeric not null default 0,
  cover_image text,
  gallery text[] not null default '{}',
  rooms jsonb not null default '[]',
  amenities text[] not null default '{}',
  rating numeric not null default 0,
  review_count int not null default 0,
  host_name text,
  description text,
  tour_3d_url text,
  is_superhost boolean not null default false,
  available_from text,
  bills_included boolean not null default false,
  flatmates int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.listings enable row level security;

create index if not exists listings_host_id_idx on public.listings (host_id);
create index if not exists listings_type_idx on public.listings (type);

create policy "Listings are viewable by everyone"
  on public.listings for select using (true);
create policy "Hosts can insert their own listings"
  on public.listings for insert with check (auth.uid() = host_id);
create policy "Hosts can update their own listings"
  on public.listings for update using (auth.uid() = host_id);
create policy "Hosts can delete their own listings"
  on public.listings for delete using (auth.uid() = host_id);

-- ------------------------------------------------------------ reservations ---
create table if not exists public.reservations (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.listings (id) on delete cascade,
  host_id uuid references public.profiles (id) on delete cascade,
  guest_id uuid not null references public.profiles (id) on delete cascade,
  guest_name text,
  type text not null check (type in ('visit', 'stay')),
  start_at timestamptz not null,
  end_at timestamptz,
  guests int not null default 1,
  status text not null default 'pending'
    check (status in ('pending', 'confirmed', 'cancelled', 'completed')),
  note text,
  estimated_total numeric,
  created_at timestamptz not null default now()
);

alter table public.reservations enable row level security;

create index if not exists reservations_host_id_idx on public.reservations (host_id);
create index if not exists reservations_guest_id_idx on public.reservations (guest_id);
create index if not exists reservations_listing_id_idx on public.reservations (listing_id);

create policy "Guests can create their own reservations"
  on public.reservations for insert with check (auth.uid() = guest_id);
create policy "Guest or host can view a reservation"
  on public.reservations for select
  using (auth.uid() = guest_id or auth.uid() = host_id);
create policy "Host can manage reservations on their listings"
  on public.reservations for update using (auth.uid() = host_id);
create policy "Guest can update their own reservation"
  on public.reservations for update using (auth.uid() = guest_id);

-- ------------------------------------------------------------ saved listings -
create table if not exists public.saved_listings (
  user_id uuid not null references public.profiles (id) on delete cascade,
  listing_id uuid not null references public.listings (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, listing_id)
);

alter table public.saved_listings enable row level security;

create policy "Users manage their own saved listings"
  on public.saved_listings for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ---------------------------------------------------------------- waitlist ---
create table if not exists public.waitlist (
  id uuid primary key default gen_random_uuid(),
  email text not null unique,
  source text,
  created_at timestamptz not null default now()
);

alter table public.waitlist enable row level security;

-- Anyone (including anonymous visitors) may join; reads are not exposed to the
-- anon/authenticated API — only the service role can list signups.
create policy "Anyone can join the waitlist"
  on public.waitlist for insert with check (true);

-- ------------------------------------------------------------------ triggers -
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at before update on public.profiles
  for each row execute function public.set_updated_at();

drop trigger if exists listings_set_updated_at on public.listings;
create trigger listings_set_updated_at before update on public.listings
  for each row execute function public.set_updated_at();

-- Denormalise the reservation's host from its listing so guests never have to
-- send it (and can't spoof it).
create or replace function public.set_reservation_host()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  select host_id into new.host_id from public.listings where id = new.listing_id;
  return new;
end;
$$;

drop trigger if exists reservations_set_host on public.reservations;
create trigger reservations_set_host before insert on public.reservations
  for each row execute function public.set_reservation_host();

-- Create a profile automatically for every new auth user, seeding role & name
-- from the sign-up metadata.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, email, full_name, role)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'full_name', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data ->> 'role', 'seeker')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
