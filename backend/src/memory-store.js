const { randomUUID } = require('crypto');

class MemoryStore {
  constructor() {
    this.chain = Promise.resolve();
    this.users = new Map();
    this.resets = [];
    this.shares = new Map();
    this.versions = new Map();
    this.clients = new Map();
    this.docs = new Map();
    this.changes = new Map();
  }

  transaction(fn) {
    const run = this.chain.then(() => fn(this.tx()));
    this.chain = run.then(() => undefined, () => undefined);
    return run;
  }

  tx() {
    const self = this;
    return {
      async ensureVersion(userId) {
        if (!self.versions.has(userId)) self.versions.set(userId, 0);
      },
      async getVersion(userId) {
        return self.versions.get(userId) || 0;
      },
      async setVersion(userId, version) {
        self.versions.set(userId, version);
      },
      async ensureClient(userId, clientId) {
        const key = `${userId}|${clientId}`;
        if (!self.clients.has(key)) self.clients.set(key, 0);
      },
      async getLastMutation(userId, clientId) {
        return self.clients.get(`${userId}|${clientId}`) || 0;
      },
      async setLastMutation(userId, clientId, id) {
        self.clients.set(`${userId}|${clientId}`, id);
      },
      async clientMap(userId) {
        const out = {};
        for (const [key, id] of self.clients) {
          if (key.startsWith(`${userId}|`)) out[key.slice(userId.length + 1)] = id;
        }
        return out;
      },
      async putDoc(userId, key, value, deleted, version) {
        if (!self.docs.has(userId)) self.docs.set(userId, new Map());
        self.docs.get(userId).set(key, { key, value, deleted, version });
      },
      async addChange(userId, version, key, value, deleted) {
        if (!self.changes.has(userId)) self.changes.set(userId, []);
        self.changes.get(userId).push({ key, value, deleted, version });
      },
      async allDocs(userId) {
        return [...(self.docs.get(userId)?.values() || [])];
      },
      async changesSince(userId, cookie) {
        return (self.changes.get(userId) || []).filter((row) => row.version > cookie);
      },
    };
  }

  async createUser({ email, passwordHash }) {
    const existing = [...this.users.values()].find((user) => user.email === email);
    if (existing) {
      const error = new Error('duplicate');
      error.code = '23505';
      throw error;
    }
    const user = { id: randomUUID(), email, passwordHash };
    this.users.set(user.id, user);
    return user;
  }

  async findUserByEmail(email) {
    return [...this.users.values()].find((user) => user.email === email) || null;
  }

  async findUserById(id) {
    return this.users.get(id) || null;
  }

  async updatePassword(id, passwordHash) {
    const user = this.users.get(id);
    if (user) user.passwordHash = passwordHash;
  }

  async saveReset({ userId, codeHash, expiresAt }) {
    this.resets = this.resets.filter((row) => row.userId !== userId);
    this.resets.push({
      id: randomUUID(), userId, codeHash, expiresAt, used: false, attempts: 0,
    });
  }

  async latestReset(userId) {
    return [...this.resets].reverse().find((row) => row.userId === userId) || null;
  }

  async markResetUsed(id) {
    const row = this.resets.find((item) => item.id === id);
    if (row) row.used = true;
  }

  async bumpResetAttempts(id) {
    const row = this.resets.find((item) => item.id === id);
    if (!row) return 0;
    row.attempts += 1;
    if (row.attempts >= 5) row.used = true;
    return row.attempts;
  }

  async shareToken(userId, { regenerate = false } = {}) {
    const current = this.shares.get(userId);
    if (current && !regenerate) return current;
    const token = randomUUID();
    this.shares.set(userId, token);
    return token;
  }

  async userIdForShare(token) {
    for (const [userId, value] of this.shares) {
      if (value === token) return userId;
    }
    return null;
  }
}

module.exports = { MemoryStore };
