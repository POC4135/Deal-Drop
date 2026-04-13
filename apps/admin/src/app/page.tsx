const queues = [
  { label: 'Submission queue', value: '28 pending', note: '4 need duplicate merge review' },
  { label: 'Issue reports', value: '11 open', note: '2 are reducing trust on hot listings' },
  { label: 'Stale listings', value: '37 due', note: 'West Midtown and Ponce need rechecks first' },
];

const listings = [
  { venue: 'Taqueria del Sol', status: 'Founder verified', freshness: '42 mins ago' },
  { venue: 'Sakura Ramen House', status: 'User confirmed', freshness: '3 recent confirmations' },
  { venue: 'Bella Napoli', status: 'Needs recheck', freshness: 'Last verified yesterday' },
];

export default function AdminHomePage() {
  return (
    <main className="min-h-screen bg-stone-50 px-8 py-10 text-stone-900">
      <div className="mx-auto max-w-6xl space-y-8">
        <header className="flex items-center justify-between">
          <div>
            <p className="text-sm font-semibold uppercase tracking-[0.24em] text-amber-700">
              DealDrop Admin
            </p>
            <h1 className="mt-3 text-5xl font-semibold tracking-tight">Moderation overview</h1>
          </div>
          <div className="rounded-full bg-amber-100 px-4 py-2 text-sm font-semibold text-amber-900">
            Atlanta launch market
          </div>
        </header>

        <section className="grid gap-4 md:grid-cols-3">
          {queues.map((queue) => (
            <article key={queue.label} className="rounded-[28px] bg-white p-6 shadow-sm ring-1 ring-stone-200">
              <p className="text-sm font-semibold uppercase tracking-[0.18em] text-stone-500">
                {queue.label}
              </p>
              <p className="mt-3 text-3xl font-semibold">{queue.value}</p>
              <p className="mt-2 text-sm text-stone-600">{queue.note}</p>
            </article>
          ))}
        </section>

        <section className="grid gap-6 lg:grid-cols-[1.5fr_1fr]">
          <article className="rounded-[32px] bg-white p-6 shadow-sm ring-1 ring-stone-200">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-semibold uppercase tracking-[0.18em] text-stone-500">
                  High-impact listings
                </p>
                <h2 className="mt-2 text-2xl font-semibold">Trust and freshness watchlist</h2>
              </div>
              <button className="rounded-full bg-stone-100 px-4 py-2 text-sm font-semibold text-stone-700">
                Export queue
              </button>
            </div>
            <div className="mt-6 space-y-4">
              {listings.map((listing) => (
                <div
                  key={listing.venue}
                  className="flex items-center justify-between rounded-[24px] bg-stone-50 px-5 py-4"
                >
                  <div>
                    <p className="text-lg font-semibold">{listing.venue}</p>
                    <p className="mt-1 text-sm text-stone-600">{listing.status}</p>
                  </div>
                  <p className="text-sm font-semibold text-stone-500">{listing.freshness}</p>
                </div>
              ))}
            </div>
          </article>

          <article className="rounded-[32px] bg-amber-500 p-6 text-white shadow-sm">
            <p className="text-sm font-semibold uppercase tracking-[0.18em] text-amber-100">
              Contributor health
            </p>
            <h2 className="mt-2 text-3xl font-semibold">92% approval accuracy</h2>
            <p className="mt-3 text-sm leading-6 text-amber-50">
              Higher-trust contributors are currently carrying 61% of successful freshness confirmations.
            </p>
            <div className="mt-8 rounded-[24px] bg-white/15 p-5">
              <p className="text-sm font-semibold uppercase tracking-[0.18em] text-amber-100">
                Queue SLA
              </p>
              <p className="mt-2 text-2xl font-semibold">12m median review time</p>
            </div>
          </article>
        </section>
      </div>
    </main>
  );
}
