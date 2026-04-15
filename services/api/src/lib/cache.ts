export interface CacheStore {
  get<T>(key: string): Promise<T | null>;
  set<T>(key: string, value: T, ttlSeconds: number): Promise<void>;
  invalidatePrefix(prefix: string): Promise<void>;
}

type CacheRecord = {
  expiresAt: number;
  value: unknown;
};

export class InMemoryCacheStore implements CacheStore {
  private readonly records = new Map<string, CacheRecord>();

  async get<T>(key: string): Promise<T | null> {
    const record = this.records.get(key);
    if (!record) {
      return null;
    }

    if (Date.now() > record.expiresAt) {
      this.records.delete(key);
      return null;
    }

    return record.value as T;
  }

  async set<T>(key: string, value: T, ttlSeconds: number): Promise<void> {
    this.records.set(key, {
      value,
      expiresAt: Date.now() + ttlSeconds * 1000,
    });
  }

  async invalidatePrefix(prefix: string): Promise<void> {
    for (const key of this.records.keys()) {
      if (key.startsWith(prefix)) {
        this.records.delete(key);
      }
    }
  }
}
