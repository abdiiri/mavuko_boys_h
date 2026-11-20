-- Run once in Supabase SQL Editor: lets the app update live without refreshing
alter publication supabase_realtime add table public.students;
alter publication supabase_realtime add table public.attendance;
alter publication supabase_realtime add table public.fees;
alter publication supabase_realtime add table public.announcements;
