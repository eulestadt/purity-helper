/**
 * Purity Help optional backend.
 * REST API: auth, sync, share. Use with PostgreSQL on Render.
 * Env: DATABASE_URL, API_SECRET (JWT signing), PORT (default 10000).
 */

const express = require('express');
const { Pool } = require('pg');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');

const app = express();
const PORT = process.env.PORT || 10000;
const API_SECRET = process.env.API_SECRET || 'change-me-in-production';

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.DATABASE_URL?.startsWith('postgres://') ? { rejectUnauthorized: false } : false,
});

app.use(express.json({ limit: '256kb' }));

function requireAuth(req, res, next) {
  const auth = req.headers.authorization;
  const token = auth?.startsWith('Bearer ') ? auth.slice(7) : null;
  if (!token) {
    return res.status(401).json({ error: 'Missing or invalid authorization' });
  }
  try {
    const decoded = jwt.verify(token, API_SECRET);
    req.userId = decoded.userId;
    next();
  } catch {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}

function sanitizePayload(body) {
  const allowed = [
    'pornographyDays', 'masturbationDays', 'pureThoughtsDays',
    'urgeMomentsCount', 'hoursReclaimed', 'lastUpdated', 'models'
  ];
  const out = {};
  for (const key of allowed) {
    if (body[key] !== undefined) out[key] = body[key];
  }
  return out;
}

// POST /auth/signup — email + password; create user, return JWT
app.post('/auth/signup', async (req, res) => {
  const email = typeof req.body?.email === 'string' ? req.body.email.trim().toLowerCase() : '';
  const password = req.body?.password;
  if (!email || !password || password.length < 8) {
    return res.status(400).json({ error: 'Email and password (min 8 chars) required' });
  }
  const passwordHash = await bcrypt.hash(password, 10);
  try {
    const result = await pool.query(
      'INSERT INTO users (email, password_hash) VALUES ($1, $2) RETURNING id',
      [email, passwordHash]
    );
    const userId = result.rows[0].id;
    const token = jwt.sign({ userId }, API_SECRET, { expiresIn: '365d' });
    return res.json({ token, userId });
  } catch (e) {
    if (e.code === '23505') return res.status(409).json({ error: 'Email already registered' });
    throw e;
  }
});

// POST /auth/login — email + password; return JWT
app.post('/auth/login', async (req, res) => {
  const email = typeof req.body?.email === 'string' ? req.body.email.trim().toLowerCase() : '';
  const password = req.body?.password;
  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password required' });
  }
  const r = await pool.query('SELECT id, password_hash FROM users WHERE email = $1', [email]);
  if (r.rows.length === 0) {
    return res.status(401).json({ error: 'Invalid email or password' });
  }
  const { id: userId, password_hash: hash } = r.rows[0];
  const ok = await bcrypt.compare(password, hash);
  if (!ok) return res.status(401).json({ error: 'Invalid email or password' });
  const token = jwt.sign({ userId }, API_SECRET, { expiresIn: '365d' });
  return res.json({ token, userId });
});

// POST /sync — upsert sync data (auth by Bearer or anonymous deviceId in body)
app.post('/sync', async (req, res) => {
  const auth = req.headers.authorization;
  const token = auth?.startsWith('Bearer ') ? auth.slice(7) : null;
  const deviceId = typeof req.body?.deviceId === 'string' ? req.body.deviceId.trim() : null;
  const payload = sanitizePayload(req.body?.payload || req.body || {});

  let userId;
  if (token) {
    try {
      const decoded = jwt.verify(token, API_SECRET);
      userId = decoded.userId;
    } catch {
      return res.status(401).json({ error: 'Invalid or expired token' });
    }
  } else if (deviceId) {
    const r = await pool.query(
      'INSERT INTO users (device_id) VALUES ($1) ON CONFLICT (device_id) DO UPDATE SET updated_at = NOW() RETURNING id',
      [deviceId]
    );
    userId = r.rows[0].id;
  } else {
    return res.status(400).json({ error: 'Authorization Bearer token or body deviceId required' });
  }

  payload.lastUpdated = new Date().toISOString();
  await pool.query(
    `INSERT INTO sync_data (user_id, payload, updated_at) VALUES ($1, $2, NOW())
     ON CONFLICT (user_id) DO UPDATE SET payload = EXCLUDED.payload, updated_at = NOW()`,
    [userId, JSON.stringify(payload)]
  );
  return res.json({ ok: true });
});

// GET /me — current user's synced data (requires Bearer)
app.get('/me', requireAuth, async (req, res) => {
  const r = await pool.query(
    'SELECT payload FROM sync_data WHERE user_id = $1',
    [req.userId]
  );
  if (r.rows.length === 0) {
    return res.json({ payload: {} });
  }
  return res.json({ payload: r.rows[0].payload });
});

// POST /share — create or refresh share token; return link (Bearer or body deviceId)
app.post('/share', async (req, res) => {
  const auth = req.headers.authorization;
  const token = auth?.startsWith('Bearer ') ? auth.slice(7) : null;
  const deviceId = typeof req.body?.deviceId === 'string' ? req.body.deviceId.trim() : null;

  let userId;
  if (token) {
    try {
      const decoded = jwt.verify(token, API_SECRET);
      userId = decoded.userId;
    } catch {
      return res.status(401).json({ error: 'Invalid or expired token' });
    }
  } else if (deviceId) {
    const r = await pool.query(
      'INSERT INTO users (device_id) VALUES ($1) ON CONFLICT (device_id) DO UPDATE SET updated_at = NOW() RETURNING id',
      [deviceId]
    );
    userId = r.rows[0].id;
  } else {
    return res.status(400).json({ error: 'Authorization Bearer token or body deviceId required' });
  }

  const r = await pool.query(
    `INSERT INTO share_tokens (user_id, token) VALUES ($1, gen_random_uuid())
     ON CONFLICT (user_id) DO UPDATE SET token = gen_random_uuid() RETURNING token`,
    [userId]
  );
  const shareToken = r.rows[0].token;
  const baseUrl = process.env.BASE_URL || `http://localhost:${PORT}`;
  return res.json({ token: shareToken, link: `${baseUrl}/share/${shareToken}` });
});

// GET /share/:token — read-only summary (HTML for browser, JSON for app)
app.get('/share/:token', async (req, res) => {
  const token = req.params.token;
  if (!/^[0-9a-f-]{36}$/i.test(token)) {
    return res.status(404).send('Not found');
  }
  const r = await pool.query(
    `SELECT sd.payload FROM share_tokens st
     JOIN sync_data sd ON sd.user_id = st.user_id
     WHERE st.token = $1`,
    [token]
  );
  if (r.rows.length === 0) {
    return res.status(404).send('Not found');
  }
  const payload = r.rows[0].payload || {};
  const wantsJson = req.headers.accept?.includes('application/json') || req.query.format === 'json';
  if (wantsJson) {
    return res.json(payload);
  }
  const html = `<!DOCTYPE html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Purity Help – Progress</title></head><body style="font-family:system-ui;max-width:480px;margin:1rem auto;padding:1rem;"><h1>Progress summary</h1><p>Days of purity (pornography): ${payload.pornographyDays ?? '—'}</p><p>Days of purity (masturbation): ${payload.masturbationDays ?? '—'}</p>${payload.pureThoughtsDays != null ? `<p>Days guarding thoughts: ${payload.pureThoughtsDays}</p>` : ''}<p>Urge moments logged: ${payload.urgeMomentsCount ?? '—'}</p>${payload.hoursReclaimed > 0 ? `<p>Hours reclaimed: ${payload.hoursReclaimed}</p>` : ''}<p><small>Last updated: ${payload.lastUpdated || '—'}</small></p></body></html>`;
  return res.type('html').send(html);
});

app.get('/health', (_, res) => res.json({ ok: true }));

async function init() {
  try {
    await pool.query('SELECT 1');
  } catch (e) {
    console.error('DB connection failed:', e.message);
  }
  app.listen(PORT, () => console.log(`Purity Help API listening on port ${PORT}`));
}

init();
