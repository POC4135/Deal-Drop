/**
 * Resilience tier — behavior when an external dependency is unconfigured, down,
 * slow, or returns garbage. Exercised via the feedback route, the only path that
 * makes a live outbound call (Slack webhook). The outbound boundary is mocked;
 * internal logic is real.
 */
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

import { buildSeedApp } from '../support/app.js';

let app: Awaited<ReturnType<typeof buildSeedApp>>;
const ENV_KEY = 'SLACK_FEEDBACK_WEBHOOK_URL';
let priorWebhook: string | undefined;

beforeEach(async () => {
  priorWebhook = process.env[ENV_KEY];
  app = await buildSeedApp();
  await app.ready();
});

afterEach(async () => {
  await app.close();
  vi.unstubAllGlobals();
  if (priorWebhook === undefined) {
    delete process.env[ENV_KEY];
  } else {
    process.env[ENV_KEY] = priorWebhook;
  }
});

const feedback = (app: Awaited<ReturnType<typeof buildSeedApp>>) =>
  app.inject({
    method: 'POST',
    url: '/v1/feedback',
    payload: { title: 'Bug', description: 'It broke', metadata: { type: 'bug' } },
  });

describe('feedback → Slack webhook resilience', () => {
  it('degrades gracefully to 503 when the integration is not configured', async () => {
    delete process.env[ENV_KEY];
    const res = await feedback(app);
    expect(res.statusCode).toBe(503);
    expect(res.json().error).toMatch(/not configured/i);
  });

  it('succeeds (204) when the webhook accepts the post', async () => {
    process.env[ENV_KEY] = 'https://hooks.slack.test/abc';
    const fetchMock = vi.fn(async (_url: string, _init?: unknown) => new Response(null, { status: 200 }));
    vi.stubGlobal('fetch', fetchMock);

    const res = await feedback(app);
    expect(res.statusCode).toBe(204);
    expect(fetchMock).toHaveBeenCalledOnce();
    // The outbound call targets the configured webhook, not an attacker-controlled URL.
    expect(fetchMock.mock.calls[0]?.[0]).toBe('https://hooks.slack.test/abc');
  });

  it('FINDING: a webhook failure is not caught and surfaces as 500 (no retry/circuit-breaker)', async () => {
    process.env[ENV_KEY] = 'https://hooks.slack.test/abc';
    vi.stubGlobal('fetch', vi.fn(async () => {
      throw new Error('ECONNRESET');
    }));

    const res = await feedback(app);
    // Pinned: the route awaits fetch with no error handling, so the rejection
    // propagates to the global handler. Documented in TESTING.md as a gap.
    expect(res.statusCode).toBe(500);
    expect(res.body).not.toMatch(/ECONNRESET.*at .*:\d+/); // message ok, but no stack frames
  });

  it('rejects malformed feedback payloads before any outbound call', async () => {
    process.env[ENV_KEY] = 'https://hooks.slack.test/abc';
    const fetchMock = vi.fn(async () => new Response(null, { status: 200 }));
    vi.stubGlobal('fetch', fetchMock);

    const res = await app.inject({ method: 'POST', url: '/v1/feedback', payload: { description: 123 } });
    expect(res.statusCode).toBeGreaterThanOrEqual(400);
    expect(fetchMock).not.toHaveBeenCalled();
  });
});
