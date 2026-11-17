-- Restaurant Control: Supabase SQL Editor-də bütöv şəkildə icra edin.
-- Bu sxem bir restoran üçün nəzərdə tutulub.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  role text not null default 'manager' check (role in ('admin','owner','manager')),
  created_at timestamptz not null default now()
);

create table if not exists public.issues (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  category text not null default 'Digər',
  priority text not null default 'medium' check (priority in ('high','medium','low')),
  status text not null default 'open' check (status in ('open','progress','done')),
  author_name text,
  description text,
  photo_url text,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, role)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name',''), 'manager')
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.issues enable row level security;

create or replace function public.current_role()
returns text language sql stable security definer set search_path = public
as $$
  select role from public.profiles where id = auth.uid()
$$;

drop policy if exists "Users read own profile or privileged profiles" on public.profiles;
create policy "Users read own profile or privileged profiles" on public.profiles
for select to authenticated
using (id = auth.uid() or public.current_role() in ('admin','owner'));

drop policy if exists "Privileged users update profiles" on public.profiles;
create policy "Privileged users update profiles" on public.profiles
for update to authenticated
using (public.current_role() in ('admin','owner'))
with check (public.current_role() in ('admin','owner'));

drop policy if exists "Authenticated users read issues" on public.issues;
create policy "Authenticated users read issues" on public.issues
for select to authenticated using (true);

drop policy if exists "Authenticated users create issues" on public.issues;
create policy "Authenticated users create issues" on public.issues
for insert to authenticated with check (created_by = auth.uid());

drop policy if exists "Authenticated users update issues" on public.issues;
create policy "Authenticated users update issues" on public.issues
for update to authenticated using (true) with check (true);

drop policy if exists "Privileged users delete issues" on public.issues;
create policy "Privileged users delete issues" on public.issues
for delete to authenticated using (public.current_role() in ('admin','owner'));

-- Fotoşəkillər üçün public oxunan bucket. Yazmaq yalnız daxil olmuş istifadəçiyə açıqdır.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('issue-photos','issue-photos',true,5242880,array['image/jpeg','image/png','image/webp'])
on conflict (id) do nothing;

drop policy if exists "Authenticated upload issue photos" on storage.objects;
create policy "Authenticated upload issue photos" on storage.objects
for insert to authenticated with check (bucket_id = 'issue-photos');

drop policy if exists "Authenticated update own issue photos" on storage.objects;
create policy "Authenticated update own issue photos" on storage.objects
for update to authenticated using (bucket_id = 'issue-photos' and owner = auth.uid())
with check (bucket_id = 'issue-photos' and owner = auth.uid());

drop policy if exists "Authenticated delete own issue photos" on storage.objects;
create policy "Authenticated delete own issue photos" on storage.objects
for delete to authenticated using (bucket_id = 'issue-photos' and owner = auth.uid());

-- İstifadəçi yaratdıqdan sonra onun rolunu Supabase SQL Editor-dən dəyişin:
-- update public.profiles set role='admin', full_name='Administrator' where id=(select id from auth.users where email='SIZIN_EMAIL');
-- update public.profiles set role='owner', full_name='Restoran sahibi' where id=(select id from auth.users where email='SAHIB_EMAIL');
