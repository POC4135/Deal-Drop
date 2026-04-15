import { AdminShell } from '../../../components/admin-shell';

export default function NewListingPage() {
  return (
    <AdminShell eyebrow="Catalog" title="Create listing">
      <section className="panel max-w-4xl p-8">
        <div className="grid gap-4 md:grid-cols-2">
          {['Title', 'Venue ID', 'Neighborhood', 'Category label', 'Schedule label', 'Cuisine'].map((field) => (
            <label key={field} className="block">
              <span className="mb-2 block text-sm font-semibold text-[var(--body)]">{field}</span>
              <input className="w-full rounded-[20px] border border-[var(--line)] bg-white px-4 py-3" />
            </label>
          ))}
        </div>
        <label className="mt-4 block">
          <span className="mb-2 block text-sm font-semibold text-[var(--body)]">Conditions</span>
          <textarea className="min-h-32 w-full rounded-[20px] border border-[var(--line)] bg-white px-4 py-3" />
        </label>
        <button className="mt-6 rounded-full bg-amber-600 px-5 py-3 text-sm font-semibold text-white">Save listing</button>
      </section>
    </AdminShell>
  );
}
