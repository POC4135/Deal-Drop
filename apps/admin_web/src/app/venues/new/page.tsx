import { redirect } from 'next/navigation';

import { AdminShell } from '../../../components/admin-shell';
import { adminApi } from '../../../lib/api';

async function createVenue(formData: FormData) {
  'use server';
  const venue = await adminApi.createVenue({
    name: String(formData.get('name') ?? ''),
    neighborhood: String(formData.get('neighborhood') ?? ''),
    address: String(formData.get('address') ?? ''),
    latitude: Number(formData.get('latitude')),
    longitude: Number(formData.get('longitude')),
  });
  redirect(`/venues/${venue.id}`);
}

export default function NewVenuePage() {
  return (
    <AdminShell eyebrow="Catalog" title="Create venue">
      <form action={createVenue} className="panel max-w-3xl p-8">
        <div className="grid gap-4 md:grid-cols-2">
          <Field name="name" label="Venue name" />
          <Field name="neighborhood" label="Neighborhood" />
          <Field name="address" label="Address" />
          <Field name="latitude" label="Latitude" type="number" />
          <Field name="longitude" label="Longitude" type="number" />
        </div>
        <button className="mt-6 rounded-full bg-amber-600 px-5 py-3 text-sm font-semibold text-white">Save venue</button>
      </form>
    </AdminShell>
  );
}

function Field({ name, label, type = 'text' }: { name: string; label: string; type?: string }) {
  return (
    <label className="block">
      <span className="mb-2 block text-sm font-semibold text-[var(--body)]">{label}</span>
      <input name={name} required type={type} step={type === 'number' ? 'any' : undefined} className="w-full rounded-[20px] border border-[var(--line)] bg-white px-4 py-3" />
    </label>
  );
}
