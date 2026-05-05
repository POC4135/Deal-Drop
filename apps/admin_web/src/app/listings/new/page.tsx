import { redirect } from 'next/navigation';

import { AdminShell } from '../../../components/admin-shell';
import { adminApi } from '../../../lib/api';

async function createListing(formData: FormData) {
  'use server';
  const listing = await adminApi.createListing({
    title: String(formData.get('title') ?? ''),
    venueId: String(formData.get('venueId') ?? ''),
    neighborhood: String(formData.get('neighborhood') ?? ''),
    categoryLabel: String(formData.get('categoryLabel') ?? ''),
    scheduleLabel: String(formData.get('scheduleLabel') ?? ''),
    cuisine: String(formData.get('cuisine') ?? ''),
    conditions: String(formData.get('conditions') ?? ''),
  });
  redirect(`/listings/${listing.id}`);
}

export default function NewListingPage() {
  return (
    <AdminShell eyebrow="Catalog" title="Create listing">
      <form action={createListing} className="panel max-w-4xl p-8">
        <div className="grid gap-4 md:grid-cols-2">
          <Field name="title" label="Title" />
          <Field name="venueId" label="Venue ID" />
          <Field name="neighborhood" label="Neighborhood" />
          <Field name="categoryLabel" label="Category label" />
          <Field name="scheduleLabel" label="Schedule label" />
          <Field name="cuisine" label="Cuisine" />
        </div>
        <label className="mt-4 block">
          <span className="mb-2 block text-sm font-semibold text-[var(--body)]">Conditions</span>
          <textarea name="conditions" className="min-h-32 w-full rounded-lg border border-[var(--line)] bg-white px-4 py-3" />
        </label>
        <button className="mt-6 rounded-full bg-[var(--accent)] px-5 py-3 text-sm font-semibold text-white shadow-sm hover:bg-[var(--accent-strong)]">Save listing</button>
      </form>
    </AdminShell>
  );
}

function Field({ name, label }: { name: string; label: string }) {
  return (
    <label className="block">
      <span className="mb-2 block text-sm font-semibold text-[var(--body)]">{label}</span>
      <input name={name} required className="w-full rounded-lg border border-[var(--line)] bg-white px-4 py-3" />
    </label>
  );
}
