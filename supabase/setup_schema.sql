-- ===== 20260311070819_082d2037-c912-47e9-8772-a041c0dfa87b.sql =====

-- Create app_role enum
create type public.app_role as enum ('admin', 'manager', 'student');

-- Profiles table
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  email text not null,
  student_id text unique,
  class text,
  created_at timestamptz default now()
);
alter table public.profiles enable row level security;

-- User roles table
create table public.user_roles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  role app_role not null,
  unique (user_id, role)
);
alter table public.user_roles enable row level security;

-- Security definer function to check roles
create or replace function public.has_role(_user_id uuid, _role app_role)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.user_roles where user_id = _user_id and role = _role
  )
$$;

-- Get user role
create or replace function public.get_user_role(_user_id uuid)
returns app_role
language sql
stable
security definer
set search_path = public
as $$
  select role from public.user_roles where user_id = _user_id limit 1
$$;

-- Students table
create table public.students (
  id uuid primary key default gen_random_uuid(),
  student_id text unique not null,
  name text not null,
  email text not null,
  class text not null,
  user_id uuid references auth.users(id) on delete cascade,
  created_at timestamptz default now()
);
alter table public.students enable row level security;

-- Attendance table
create table public.attendance (
  id uuid primary key default gen_random_uuid(),
  student_id text not null references public.students(student_id) on delete cascade,
  date date not null default current_date,
  status text not null check (status in ('present', 'absent')),
  created_at timestamptz default now(),
  unique (student_id, date)
);
alter table public.attendance enable row level security;

-- Fees table
create table public.fees (
  id uuid primary key default gen_random_uuid(),
  student_id text unique not null references public.students(student_id) on delete cascade,
  amount_paid numeric not null default 0,
  total_amount numeric not null default 45000,
  payment_status text not null default 'pending' check (payment_status in ('paid', 'partial', 'pending')),
  date date,
  created_at timestamptz default now()
);
alter table public.fees enable row level security;

-- RLS Policies

-- Profiles
create policy "Users can read own profile" on public.profiles for select to authenticated using (id = auth.uid());
create policy "Admins can read all profiles" on public.profiles for select to authenticated using (public.has_role(auth.uid(), 'admin'));
create policy "Admins can insert profiles" on public.profiles for insert to authenticated with check (public.has_role(auth.uid(), 'admin'));
create policy "Admins can update profiles" on public.profiles for update to authenticated using (public.has_role(auth.uid(), 'admin'));

-- User roles
create policy "Users can read own role" on public.user_roles for select to authenticated using (user_id = auth.uid());
create policy "Admins can read all roles" on public.user_roles for select to authenticated using (public.has_role(auth.uid(), 'admin'));
create policy "Admins can insert roles" on public.user_roles for insert to authenticated with check (public.has_role(auth.uid(), 'admin'));

-- Students
create policy "Admins and managers can read all students" on public.students for select to authenticated using (public.has_role(auth.uid(), 'admin') or public.has_role(auth.uid(), 'manager'));
create policy "Students can read own record" on public.students for select to authenticated using (user_id = auth.uid());
create policy "Admins can insert students" on public.students for insert to authenticated with check (public.has_role(auth.uid(), 'admin'));
create policy "Admins can update students" on public.students for update to authenticated using (public.has_role(auth.uid(), 'admin'));
create policy "Admins can delete students" on public.students for delete to authenticated using (public.has_role(auth.uid(), 'admin'));

-- Attendance
create policy "Admins and managers can read all attendance" on public.attendance for select to authenticated using (public.has_role(auth.uid(), 'admin') or public.has_role(auth.uid(), 'manager'));
create policy "Students can read own attendance" on public.attendance for select to authenticated using (
  student_id in (select s.student_id from public.students s where s.user_id = auth.uid())
);
create policy "Admins can insert attendance" on public.attendance for insert to authenticated with check (public.has_role(auth.uid(), 'admin'));
create policy "Admins can update attendance" on public.attendance for update to authenticated using (public.has_role(auth.uid(), 'admin'));

-- Fees
create policy "Admins and managers can read all fees" on public.fees for select to authenticated using (public.has_role(auth.uid(), 'admin') or public.has_role(auth.uid(), 'manager'));
create policy "Students can read own fees" on public.fees for select to authenticated using (
  student_id in (select s.student_id from public.students s where s.user_id = auth.uid())
);
create policy "Admins can insert fees" on public.fees for insert to authenticated with check (public.has_role(auth.uid(), 'admin'));
create policy "Admins can update fees" on public.fees for update to authenticated using (public.has_role(auth.uid(), 'admin'));

-- Trigger to auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, name, email)
  values (new.id, coalesce(new.raw_user_meta_data->>'name', ''), new.email);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ===== 20260311071713_1123fa59-ffae-462c-83d5-b17e8a6f3ab8.sql =====

-- Allow admins to update and delete user_roles
create policy "Admins can update roles" on public.user_roles for update to authenticated using (public.has_role(auth.uid(), 'admin'));
create policy "Admins can delete roles" on public.user_roles for delete to authenticated using (public.has_role(auth.uid(), 'admin'));

-- Allow admins to read all profiles (for user management)
create policy "Admins can read all profiles for management" on public.profiles for select to authenticated using (public.has_role(auth.uid(), 'admin'));

-- ===== 20260311073154_5ee9fb0b-6384-46a2-af61-2d6e932e2b61.sql =====
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
-- ===== 20260311075528_266e59b8-fe9a-45f0-85ad-db692adb3db7.sql =====

CREATE TABLE public.announcements (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  created_by UUID NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;

-- Admins can do everything
CREATE POLICY "Admins can manage announcements"
  ON public.announcements FOR ALL
  TO authenticated
  USING (public.has_role(auth.uid(), 'admin'))
  WITH CHECK (public.has_role(auth.uid(), 'admin'));

-- Students can read announcements
CREATE POLICY "Students can read announcements"
  ON public.announcements FOR SELECT
  TO authenticated
  USING (public.has_role(auth.uid(), 'student'));

