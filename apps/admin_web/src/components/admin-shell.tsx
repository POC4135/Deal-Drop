import Link from 'next/link';
import type { ReactNode } from 'react';

const navGroups = [
  {
    label: 'Overview',
    items: [
      { href: '/', label: 'Dashboard' },
      { href: '/login', label: 'Login shell' },
    ],
  },
  {
    label: 'Catalog',
    items: [
      { href: '/venues', label: 'Venues' },
      { href: '/listings', label: 'Listings' },
    ],
  },
  {
    label: 'Queues',
    items: [
      { href: '/moderation', label: 'Moderation' },
      { href: '/reports', label: 'Reports' },
      { href: '/stale', label: 'Stale listings' },
    ],
  },
  {
    label: 'Trust',
    items: [
      { href: '/contributors/usr_alex', label: 'Contributor review' },
      { href: '/audit', label: 'Audit log' },
    ],
  },
];

export function AdminShell({
  title,
  eyebrow,
  children,
}: {
  title: string;
  eyebrow: string;
  children: ReactNode;
}) {
  return (
    <div className="admin-shell">
      <aside className="admin-sidebar">
        <div className="space-y-2">
          <p className="text-xs font-bold uppercase tracking-[0.28em] text-amber-800">DealDrop Admin</p>
          <h1 className="text-2xl font-semibold tracking-tight text-stone-900">Platform operations</h1>
          <p className="text-sm leading-6 text-[var(--body)]">
            Atlanta launch market control plane for moderation, trust, and freshness.
          </p>
        </div>

        <nav className="mt-10 space-y-8">
          {navGroups.map((group) => (
            <div key={group.label}>
              <p className="text-xs font-semibold uppercase tracking-[0.18em] text-[var(--muted)]">{group.label}</p>
              <div className="mt-3 space-y-2">
                {group.items.map((item) => (
                  <Link
                    key={item.href}
                    href={item.href}
                    className="block rounded-2xl px-4 py-3 text-sm font-medium text-stone-800 transition hover:bg-white"
                  >
                    {item.label}
                  </Link>
                ))}
              </div>
            </div>
          ))}
        </nav>
      </aside>

      <main className="admin-main">
        <header className="mb-8 flex items-end justify-between gap-6">
          <div>
            <p className="text-sm font-semibold uppercase tracking-[0.22em] text-amber-700">{eyebrow}</p>
            <h2 className="mt-3 text-4xl font-semibold tracking-tight">{title}</h2>
          </div>
          <div className="pill">Atlanta launch market</div>
        </header>
        {children}
      </main>
    </div>
  );
}
