import type { FastifyInstance } from 'fastify';
import { z } from 'zod';

const bodySchema = z.object({
  title: z.string().min(1).max(200),
  description: z.string().max(2000).default(''),
});

export async function registerFeedbackRoutes(app: FastifyInstance): Promise<void> {
  app.post('/v1/feedback', async (request, reply) => {
    const webhookUrl = process.env.SLACK_FEEDBACK_WEBHOOK_URL;
    if (!webhookUrl) {
      return reply.status(503).send({ error: 'Feedback reporting is not configured.' });
    }

    const { title, description } = bodySchema.parse(request.body);

    const lines = [
      '*🐛 Bug Report*',
      `*Title:* ${title}`,
      ...(description ? [`*Details:* ${description}`] : []),
      `*Platform:* web  |  ${new Date().toUTCString()}`,
    ];

    await fetch(webhookUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ text: lines.join('\n') }),
    });

    return reply.status(204).send();
  });
}
