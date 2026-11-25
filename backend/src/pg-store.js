const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');

function sslFor(connectionString) {
  if (!connectionString) return false;
  if (/localhost|127\.0\.0\.1|railway\.internal/.test(connectionString)) return false;
  return { rejectUnauthorized: false };
}

class PgStore {
  constructor(pool) {
    this.pool = pool;
  }

  static fromEnv() {
    const connectionString = process.env.DATABASE_URL;
    if (!connectionString) return null;
    const pool = new Pool({ connectionString, ssl: sslFor(connectionString) });
    return new PgStore(pool);
  }

  async migrate() {
    const schema = fs.readFileSync(path.join(__dirname, '..', 'schema.sql'), 'utf8');
    await this.pool.query(schema);
  }

  async transaction(fn) {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');
      const result = await fn(new PgTx(client));
      await client.query('COMMIT');
      return result;
    } catch (error) {
      try { await client.query('ROLLBACK'); } catch { /* already aborted */ }
      throw error;
    } finally {
      client.release();
    }
  }

  async createUser({ email, passwordHash }) {
    const result = await this.pool.query(
      'INSERT INTO users (email, password_hash) VALUES ($1, $2) RETURNING id, email, password_hash AS "passwordHash"',
      [email, passwordHash]
    );
    return result.rows[0];
  }

  async findUserByEmail(email) {
    const result = await this.pool.query(
      'SELECT id, email, password_hash AS "passwordHash" FROM users WHERE email = $1',
      [email]
    );
    return result.rows[0] || null;
  }

  async findUserById(id) {
    const result = await this.pool.query(
      'SELECT id, email, password_hash AS "passwordHash" FROM users WHERE id = $1',
      [id]
    );
    return result.rows[0] || null;
  }

  async updatePassword(id, passwordHash) {
    await this.pool.query('UPDATE users SET password_hash = $1, updated_at = NOW() WHERE id = $2', [passwordHash, id]);
  }

  async saveReset({ userId, codeHash, expiresAt }) {
    await this.pool.query('DELETE FROM password_reset_tokens WHERE user_id = $1', [userId]);
    await this.pool.query(
      'INSERT INTO password_reset_tokens (user_id, code_hash, expires_at) VALUES ($1, $2, $3)',
      [userId, codeHash, expiresAt]
    );
  }

  async latestReset(userId) {
    const result = await this.pool.query(
      `SELECT id, user_id AS "userId", code_hash AS "codeHash", expires_at AS "expiresAt", used, attempts
       FROM password_reset_tokens WHERE user_id = $1 ORDER BY expires_at DESC LIMIT 1`,
      [userId]
    );
    return result.rows[0] || null;
  }

  async markResetUsed(id) {
    await this.pool.query('UPDATE password_reset_tokens SET used = TRUE WHERE id = $1', [id]);
  }

  async bumpResetAttempts(id) {
    const result = await this.pool.query(
      `UPDATE password_reset_tokens
       SET attempts = attempts + 1,
           used = CASE WHEN attempts + 1 >= 5 THEN TRUE ELSE used END
       WHERE id = $1 RETURNING attempts`,
      [id]
    );
    return result.rows[0] ? result.rows[0].attempts : 0;
  }

  async shareToken(userId, { regenerate = false } = {}) {
    if (regenerate) {
      const result = await this.pool.query(
        `INSERT INTO share_tokens (user_id, token) VALUES ($1, gen_random_uuid())
         ON CONFLICT (user_id) DO UPDATE SET token = gen_random_uuid(), created_at = NOW()
         RETURNING token`,
        [userId]
      );
      return result.rows[0].token;
    }
    const result = await this.pool.query(
      `INSERT INTO share_tokens (user_id, token) VALUES ($1, gen_random_uuid())
       ON CONFLICT (user_id) DO UPDATE SET token = share_tokens.token
       RETURNING token`,
      [userId]
    );
    return result.rows[0].token;
  }

  async userIdForShare(token) {
    const result = await this.pool.query('SELECT user_id FROM share_tokens WHERE token = $1', [token]);
    return result.rows[0] ? result.rows[0].user_id : null;
  }
}

class PgTx {
  constructor(client) {
    this.client = client;
  }

  async ensureVersion(userId) {
    await this.client.query(
      'INSERT INTO user_versions (user_id, version) VALUES ($1, 0) ON CONFLICT (user_id) DO NOTHING',
      [userId]
    );
    await this.client.query('SELECT version FROM user_versions WHERE user_id = $1 FOR UPDATE', [userId]);
  }

  async getVersion(userId) {
    const result = await this.client.query('SELECT version FROM user_versions WHERE user_id = $1', [userId]);
    return result.rows[0] ? Number(result.rows[0].version) : 0;
  }

  async setVersion(userId, version) {
    await this.client.query('UPDATE user_versions SET version = $2 WHERE user_id = $1', [userId, version]);
  }

  async ensureClient(userId, clientId) {
    await this.client.query(
      `INSERT INTO sync_clients (user_id, client_id, last_mutation_id) VALUES ($1, $2, 0)
       ON CONFLICT (user_id, client_id) DO NOTHING`,
      [userId, clientId]
    );
  }

  async getLastMutation(userId, clientId) {
    await this.ensureClient(userId, clientId);
    const result = await this.client.query(
      'SELECT last_mutation_id FROM sync_clients WHERE user_id = $1 AND client_id = $2',
      [userId, clientId]
    );
    return result.rows[0] ? Number(result.rows[0].last_mutation_id) : 0;
  }

  async setLastMutation(userId, clientId, id) {
    await this.client.query(
      `INSERT INTO sync_clients (user_id, client_id, last_mutation_id) VALUES ($1, $2, $3)
       ON CONFLICT (user_id, client_id) DO UPDATE SET last_mutation_id = EXCLUDED.last_mutation_id`,
      [userId, clientId, id]
    );
  }

  async clientMap(userId) {
    const result = await this.client.query(
      'SELECT client_id, last_mutation_id FROM sync_clients WHERE user_id = $1',
      [userId]
    );
    const out = {};
    for (const row of result.rows) out[row.client_id] = Number(row.last_mutation_id);
    return out;
  }

  async putDoc(userId, key, value, deleted, version) {
    await this.client.query(
      `INSERT INTO documents (user_id, key, value, deleted, version) VALUES ($1, $2, $3, $4, $5)
       ON CONFLICT (user_id, key) DO UPDATE SET value = EXCLUDED.value, deleted = EXCLUDED.deleted, version = EXCLUDED.version`,
      [userId, key, value == null ? null : JSON.stringify(value), deleted, version]
    );
  }

  async addChange(userId, version, key, value, deleted) {
    await this.client.query(
      'INSERT INTO document_changes (user_id, version, key, value, deleted) VALUES ($1, $2, $3, $4, $5)',
      [userId, version, key, value == null ? null : JSON.stringify(value), deleted]
    );
  }

  async allDocs(userId) {
    const result = await this.client.query(
      'SELECT key, value, deleted, version FROM documents WHERE user_id = $1 ORDER BY version',
      [userId]
    );
    return result.rows.map(normalizeRow);
  }

  async changesSince(userId, cookie) {
    const result = await this.client.query(
      'SELECT key, value, deleted, version FROM document_changes WHERE user_id = $1 AND version > $2 ORDER BY version',
      [userId, cookie]
    );
    return result.rows.map(normalizeRow);
  }
}

function normalizeRow(row) {
  return {
    key: row.key,
    value: row.value,
    deleted: row.deleted,
    version: Number(row.version),
  };
}

module.exports = { PgStore, sslFor };
