-- Enable necessary extensions
create extension if not exists "uuid-ossp";

-- Create enum types (skip if they already exist)
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('parent', 'child');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE task_status AS ENUM ('pending', 'completed', 'approved', 'rejected');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE task_frequency AS ENUM ('once', 'daily', 'weekly', 'monthly');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE pet_mood AS ENUM ('happy', 'neutral', 'sad');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE pet_stage AS ENUM ('egg', 'baby', 'child', 'teen', 'adult');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Auth schema already exists in Supabase
-- Skipping auth schema creation and RLS on auth.users (managed by Supabase)

-- Create families table first (without parent_id constraint initially)
create table families (
  id uuid default uuid_generate_v4() primary key,
  name text not null,
  invite_code text unique not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Create profiles table
create table profiles (
  id uuid references auth.users on delete cascade primary key,
  email text not null unique,
  display_name text not null,
  avatar_url text,
  role user_role not null,
  family_id uuid references families(id),
  last_login_at timestamp with time zone default timezone('utc'::text, now()) not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Add parent_id to families table after profiles exists
alter table families add column parent_id uuid references profiles(id);

-- Enable Row Level Security (only on tables that exist so far)
alter table profiles enable row level security;
alter table families enable row level security;
-- tasks and pets tables will have RLS enabled when they are created in later migrations

-- Create RLS policies

-- Profiles policies
create policy "Enable read access for all users"
  on profiles for select
  using (true);

create policy "Enable insert for authenticated users only"
  on profiles for insert
  with check (auth.uid() = id);

create policy "Enable update for users based on id"
  on profiles for update
  using (auth.uid() = id);

-- Families policies
create policy "Families are viewable by members"
  on families for select
  using (
    id in (
      select family_id from profiles where id = auth.uid()
    )
  );

create policy "Parents can create families"
  on families for insert
  with check (
    exists (
      select 1 from profiles
      where id = auth.uid()
      and role = 'parent'
    )
  );

create policy "Parents can update their family"
  on families for update
  using (
    parent_id = auth.uid()
  )
  with check (
    parent_id = auth.uid()
  );

-- Tasks and Pets policies will be created when the tables are created in later migrations

-- Create storage buckets (skip if they already exist)
insert into storage.buckets (id, name)
values 
  ('task_images', 'Task Images'),
  ('profile_images', 'Profile Images')
on conflict (id) do nothing;

-- Storage policies will be created in later migrations when the necessary tables exist

-- Set up realtime replication
begin;
  drop publication if exists supabase_realtime;
  create publication supabase_realtime;
commit;

-- Tables will be added to realtime publication when they are created in later migrations

-- Create functions for updating timestamps
create or replace function update_updated_at_column()
returns trigger as $$
begin
  new.updated_at = timezone('utc'::text, now());
  return new;
end;
$$ language plpgsql;

-- Create triggers for updating timestamps
create trigger update_profiles_updated_at
  before update on profiles
  for each row
  execute function update_updated_at_column();

create trigger update_families_updated_at
  before update on families
  for each row
  execute function update_updated_at_column();

create trigger update_tasks_updated_at
  before update on tasks
  for each row
  execute function update_updated_at_column();

create trigger update_pets_updated_at
  before update on pets
  for each row
  execute function update_updated_at_column();

-- Create function to handle new user signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (
    id,
    email,
    display_name,
    role,
    created_at,
    updated_at,
    last_login_at
  )
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'display_name', new.email),
    (new.raw_user_meta_data->>'role')::user_role,
    timezone('utc'::text, now()),
    timezone('utc'::text, now()),
    timezone('utc'::text, now())
  );
  return new;
end;
$$;

-- Create trigger for new user signup
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user(); 