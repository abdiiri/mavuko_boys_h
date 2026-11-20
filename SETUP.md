# Mavuko Boys – connect to YOUR Supabase (project tfmdgrverkyocbtpxelo)

Already done in this zip:
- `.env` and `supabase/config.toml` point to your Supabase project (Lovable's is no longer used).
- The project builds successfully.

## One-time setup (in order)

1. **Create the tables** – Supabase dashboard → SQL Editor → New query → paste
   `supabase/setup_schema.sql` → Run. (Run once only.)

2. **Deploy the edge functions** (needed to add/delete users from the app):
   ```
   npm i -g supabase
   supabase login
   supabase link --project-ref tfmdgrverkyocbtpxelo
   supabase functions deploy create-user
   supabase functions deploy delete-user
   supabase functions deploy seed-admin
   ```

3. **Create the admin + the 4 students** (Windows cmd, inside the `tools` folder):
   ```
   cd tools
   npm install
   set SUPABASE_URL=https://tfmdgrverkyocbtpxelo.supabase.co
   set SERVICE_ROLE_KEY=<service_role key from Project Settings > API Keys>
   set ADMIN_EMAIL=you@example.com
   set ADMIN_PASSWORD=<strong password>
   set ADMIN_NAME=Admin
   set STUDENT_PASSWORD=<temporary password for students>
   node seed.mjs
   ```
   Never commit or share the service_role key. Run this once only.

4. **Run locally**: `npm install` then `npm run dev`.
   Admin logs in with email; students log in with username (abdiiri, nuur, wehliye, othiambo).

5. **Vercel**: Settings → Environment Variables, add
   `VITE_SUPABASE_URL` = https://tfmdgrverkyocbtpxelo.supabase.co
   `VITE_SUPABASE_PUBLISHABLE_KEY` = your publishable key, then Redeploy.
