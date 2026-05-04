import { AdminShell } from '../../components/admin-shell';

export default function LoginPage() {
  return (
    <AdminShell eyebrow="Auth" title="Operator login">
      <section className="panel mx-auto max-w-xl p-8">
        <p className="text-sm leading-6 text-[var(--body)]">
          Production auth is backed by Supabase sessions and DealDrop database roles. The current admin bridge uses a
          server-side API token when configured, while local development can continue with dev claims.
        </p>
        <form className="mt-8 space-y-4">
          {['Email address', 'Password'].map((label) => (
            <label key={label} className="block">
              <span className="mb-2 block text-sm font-semibold text-[var(--body)]">{label}</span>
              <input
                className="w-full rounded-[20px] border border-[var(--line)] bg-white px-4 py-3 outline-none"
                placeholder={label}
                type={label === 'Password' ? 'password' : 'email'}
              />
            </label>
          ))}
          <button className="rounded-full bg-amber-600 px-5 py-3 text-sm font-semibold text-white">Enter admin</button>
        </form>
      </section>
    </AdminShell>
  );
}
