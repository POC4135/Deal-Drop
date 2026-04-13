# DealDrop

DealDrop is an Atlanta-first local value discovery platform built around three product invariants: freshness, trust, and speed.

This repository now uses a monorepo layout so the Flutter client, internal admin portal, backend contracts, seed data, and infrastructure can evolve together without forcing a premature microservice split.

## Repository Layout

- `apps/mobile`: Flutter consumer app.
- `apps/admin`: internal moderation and operations portal scaffold.
- `services/api`: TypeScript API scaffold and domain notes.
- `services/workers`: async worker scaffolds for read-model, trust, and karma pipelines.
- `packages/contracts`: API contracts and OpenAPI source of truth.
- `packages/design_tokens`: Flutter design-token package used by the mobile app.
- `docs/mockups`: PNG catalog, implementation notes, and deviation log.
- `docs/adr`: architecture decision records.
- `infra/terraform`: infrastructure placeholder for AWS provisioning.
- `seed/atlanta`: curated launch-market seed data.

## Current State

This implementation pass establishes:

- the monorepo reshape
- a production-oriented Flutter app shell aligned to the provided mockups
- route architecture for `Deals / Map / Post / Karma`
- profile, saved, and notifications account stack routes
- sample seed data for Atlanta neighborhoods
- contract, documentation, and service scaffolding for the AWS-backed platform

## What Still Needs Real Inputs

- canonical mobile PNGs for detail/search/saved/post-flow/notification states
- brand font files or explicit font-family choices
- production map SDK keys and tile strategy
- Node.js toolchain installation for running the admin and API packages locally
- AWS credentials and IaC execution environment
