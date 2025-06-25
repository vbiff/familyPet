-- Enable necessary extensions
create extension if not exists "uuid-ossp";

-- Create enum types
create type user_role as enum ('parent', 'child');
create type task_status as enum ('pending', 'completed', 'approved', 'rejected');
create type task_frequency as enum ('once', 'daily', 'weekly', 'monthly');
create type pet_mood as enum ('happy', 'neutral', 'sad');
create type pet_stage as enum ('egg', 'baby', 'child', 'teen', 'adult');

-- Create profiles table
create table profiles (
  id uuid references auth.users primary key,
  email text not null unique,
  display_name text,
  avatar_url text,
  role user_role not null,
  family_id uuid references families(id),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Create families table
create table families (
  id uuid default uuid_generate_v4() primary key,
  name text not null,
  parent_id uuid references profiles(id) not null,
  invite_code text unique not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Create tasks table
create table tasks (
  id uuid default uuid_generate_v4() primary key,
  title text not null,
  description text not null,
  points integer not null check (points >= 0),
  family_id uuid references families(id) not null,
  assigned_to_id uuid references profiles(id) not null,
  created_by_id uuid references profiles(id) not null,
  status task_status not null default 'pending',
  frequency task_frequency not null,
  due_date timestamp with time zone not null,
  image_url text,
  completion_note text,
  completed_at timestamp with time zone,
  approved_at timestamp with time zone,
  is_archived boolean not null default false,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Create pets table
create table pets (
  id uuid default uuid_generate_v4() primary key,
  name text not null,
  owner_id uuid references profiles(id) not null,
  family_id uuid references families(id) not null,
  mood pet_mood not null default 'neutral',
  stage pet_stage not null default 'egg',
  experience integer not null default 0 check (experience >= 0),
  level integer not null default 1 check (level >= 1),
  happiness integer not null default 50 check (happiness >= 0 and happiness <= 100),
  energy integer not null default 100 check (energy >= 0 and energy <= 100),
  last_fed timestamp with time zone not null default timezone('utc'::text, now()),
  last_interaction timestamp with time zone not null default timezone('utc'::text, now()),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Create indexes
create index idx_profiles_family_id on profiles(family_id);
create index idx_tasks_family_id on tasks(family_id);
create index idx_tasks_assigned_to_id on tasks(assigned_to_id);
create index idx_tasks_created_by_id on tasks(created_by_id);
create index idx_tasks_due_date on tasks(due_date);
create index idx_pets_owner_id on pets(owner_id);
create index idx_pets_family_id on pets(family_id);

-- Enable Row Level Security
alter table profiles enable row level security;
alter table families enable row level security;
alter table tasks enable row level security;
alter table pets enable row level security;

-- Create RLS policies

-- Profiles policies
create policy "Profiles are viewable by family members"
  on profiles for select
  using (
    auth.uid() = id or
    family_id in (
      select family_id from profiles where id = auth.uid()
    )
  );

create policy "Users can update own profile"
  on profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

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