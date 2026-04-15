import { AdminShell } from '../../../components/admin-shell';

export default function NewVenuePage() {
  return (
    <AdminShell eyebrow="Catalog" title="Create venue">
      <section className="panel max-w-3xl p-8">
        <div className="grid gap-4 md:grid-cols-2">
          {['Venue name', 'Neighborhood', 'Address', 'Latitude', 'Longitude'].map((field) => (
            <label key={field} className="block">
              <span className="mb-2 block text-sm font-semibold text-[var(--body)]">{field}</span>
              <input className="w-full rounded-[20px] border border-[var(--line)] bg-white px-4 py-3" />
            </label>
          ))}
        </div>
        <button className="mt-6 rounded-full bg-amber-600 px-5 py-3 text-sm font-semibold text-white">Save venue</button>
      </section>
    </AdminShell>
  );
}
