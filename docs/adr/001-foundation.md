# ADR 001: DealDrop Foundation

## Status

Accepted

## Decision

- Use a monorepo structure from the outset.
- Keep the backend as a modular monolith plus async workers.
- Treat citywide DealDrop PNGs as the binding mobile visual system.
- Use Flutter with Riverpod and go_router for the mobile client.
- Use `Deals / Map / Post / Karma` as the primary navigation shell.
- Keep `Profile`, `Saved`, and `Notifications` in a secondary account stack.

## Rationale

- The repo was nearly empty, so restructuring now is cheaper than migrating later.
- A modular monolith keeps product velocity high while preserving clean split points for scaling.
- The provided PNGs conflict across multiple visual systems; binding one canonical family prevents design drift.
- The selected 4-tab IA requires account routes to move off the bottom nav without losing discoverability.

## Consequences

- Some visual refinements still rely on inferred extensions until the final brand asset pack arrives.
- The mobile app now ships with live read paths and offline-aware write flows, but release hardening still depends on secure token storage and native push completion.
- The service, workers, admin console, and IaC now exist as implementation foundations, but full platform validation still depends on installing the Node.js and Terraform toolchains.
