// Seeds your NEW Supabase project with an admin + the 4 students.
// Run once:  node seed.mjs
// Needs env vars: SUPABASE_URL, SERVICE_ROLE_KEY, ADMIN_EMAIL, ADMIN_PASSWORD, ADMIN_NAME, STUDENT_PASSWORD
import { createClient } from '@supabase/supabase-js';

const need = ['SUPABASE_URL', 'SERVICE_ROLE_KEY', 'ADMIN_EMAIL', 'ADMIN_PASSWORD', 'STUDENT_PASSWORD'];
const missing = need.filter((k) => !process.env[k]);
if (missing.length) {
  console.error('Missing env vars:', missing.join(', '));
  process.exit(1);
}

const sb = createClient(process.env.SUPABASE_URL, process.env.SERVICE_ROLE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false },
});

const DOMAIN = 'students.pumwani.local'; // same as the app's login page

const students = [
  { studentId: '1',  name: 'Abdirizak Hassan', username: 'abdiiri',   class: 'Grade 6 A' },
  { studentId: '5',  name: 'Nuur Ali',         username: 'nuur',      class: 'Grade 7' },
  { studentId: '10', name: 'Wehliye Farah',    username: 'wehliye',   class: 'Class 8' },
  { studentId: '12', name: 'Othiambo Ojwang',  username: 'othiambo',  class: 'Class 7' },
];

async function createAccount({ email, password, name, role, studentId, studentClass }) {
  const { data, error } = await sb.auth.admin.createUser({
    email, password, email_confirm: true, user_metadata: { name },
  });
  if (error) { console.error(`✗ ${email}: ${error.message}`); return null; }
  const id = data.user.id;
  await new Promise((r) => setTimeout(r, 600)); // let the profile trigger run

  const prof = await sb.from('profiles').upsert({
    id, name, email, student_id: studentId ?? null, class: studentClass ?? null,
  });
  if (prof.error) console.error(`  profile: ${prof.error.message}`);

  const r = await sb.from('user_roles').insert({ user_id: id, role });
  if (r.error) console.error(`  role: ${r.error.message}`);

  if (role === 'student') {
    const s = await sb.from('students').insert({
      student_id: studentId, name, email, class: studentClass, user_id: id,
    });
    if (s.error) console.error(`  students: ${s.error.message}`);
    const f = await sb.from('fees').insert({
      student_id: studentId, amount_paid: 0, total_amount: 45000, payment_status: 'pending',
    });
    if (f.error) console.error(`  fees: ${f.error.message}`);
  }
  console.log(`✓ ${role}: ${name} (${email})`);
  return id;
}

await createAccount({
  email: process.env.ADMIN_EMAIL,
  password: process.env.ADMIN_PASSWORD,
  name: process.env.ADMIN_NAME || 'Admin',
  role: 'admin',
});

for (const s of students) {
  await createAccount({
    email: `${s.username}@${DOMAIN}`,
    password: process.env.STUDENT_PASSWORD,
    name: s.name, role: 'student', studentId: s.studentId, studentClass: s.class,
  });
}
console.log('Done. Check Table Editor → profiles, students, user_roles, fees.');
