# Trust Worker

Consumes immutable trust-affecting events and updates listing trust snapshots, freshness bands, and recheck scheduling.

Runtime entrypoint lives in `src/index.ts` and delegates to the API worker contract.
