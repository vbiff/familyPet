-- Enable necessary extensions
create extension if not exists "uuid-ossp";

-- Create enum types
create type user_role as enum ('parent', 'child');
create type task_status as enum ('pending', 'completed', 'approved', 'rejected');
create type task_frequency as enum ('once', 'daily', 'weekly', 'monthly');
create type pet_mood as enum ('happy', 'neutral', 'sad');
create type pet_stage as enum ('egg', 'baby', 'child', 'teen', 'adult');

-- Create auth schema
create schema if not exists auth;

-- Enable RLS
alter table auth.users enable row level security;

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

-- Enable Row Level Security
alter table profiles enable row level security;
alter table families enable row level security;
alter table tasks enable row level security;
alter table pets enable row level security;

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

-- Tasks policies
create policy "Tasks are viewable by family members"
  on tasks for select
  using (
    family_id in (
      select family_id from profiles where id = auth.uid()
    )
  );

create policy "Parents can create tasks"
  on tasks for insert
  with check (
    exists (
      select 1 from profiles
      where id = auth.uid()
      and role = 'parent'
      and family_id = tasks.family_id
    )
  );

create policy "Parents can update tasks"
  on tasks for update
  using (
    exists (
      select 1 from profiles
      where id = auth.uid()
      and role = 'parent'
      and family_id = tasks.family_id
    )
  );

create policy "Children can update their assigned tasks"
  on tasks for update
  using (
    assigned_to_id = auth.uid()
    and status in ('pending', 'completed')
  )
  with check (
    assigned_to_id = auth.uid()
    and status in ('pending', 'completed')
  );

-- Pets policies
create policy "Pets are viewable by family members"
  on pets for select
  using (
    family_id in (
      select family_id from profiles where id = auth.uid()
    )
  );

create policy "Children can create one pet"
  on pets for insert
  with check (
    exists (
      select 1 from profiles
      where id = auth.uid()
      and role = 'child'
    )
    and not exists (
      select 1 from pets where owner_id = auth.uid()
    )
  );

create policy "Children can update their own pet"
  on pets for update
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

-- Create storage buckets
insert into storage.buckets (id, name)
values 
  ('task_images', 'Task Images'),
  ('profile_images', 'Profile Images');

-- Set up storage policies
create policy "Task images are viewable by family members"
  on storage.objects for select
  using (
    bucket_id = 'task_images'
    and (
      auth.uid() in (
        select profiles.id
        from storage.objects
        join tasks on tasks.image_url = storage.objects.name
        join profiles on profiles.family_id = tasks.family_id
        where storage.objects.id = objects.id
      )
    )
  );

create policy "Users can upload task images"
  on storage.objects for insert
  with check (
    bucket_id = 'task_images'
  );

create policy "Profile images are publicly accessible"
  on storage.objects for select
  using (bucket_id = 'profile_images');

create policy "Users can upload their profile image"
  on storage.objects for insert
  with check (
    bucket_id = 'profile_images'
  );

-- Set up realtime replication
begin;
  drop publication if exists supabase_realtime;
  create publication supabase_realtime;
commit;

alter publication supabase_realtime add table tasks;
alter publication supabase_realtime add table pets;

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