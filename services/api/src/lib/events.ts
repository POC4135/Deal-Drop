import { ulid } from 'ulid';

import type { DomainEvent } from '@dealdrop/shared-types';

export interface EventStore {
  append(event: Omit<DomainEvent, 'id'>): Promise<DomainEvent>;
  list(): Promise<DomainEvent[]>;
}

export class InMemoryEventStore implements EventStore {
  private readonly events: DomainEvent[] = [];

  async append(event: Omit<DomainEvent, 'id'>): Promise<DomainEvent> {
    const record: DomainEvent = {
      id: ulid(),
      ...event,
    };
    this.events.push(record);
    return record;
  }

  async list(): Promise<DomainEvent[]> {
    return [...this.events];
  }
}
