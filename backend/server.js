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
const fs = require('fs');
const path = require('path');

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

function escapeHtml(unsafe) {
  if (unsafe == null) return '';
  return String(unsafe)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
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
     LEFT JOIN sync_data sd ON sd.user_id = st.user_id
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
  const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Purity Help – Partner Progress</title>
  <style>
    :root {
      --bg: #000000;
      --card-bg: #1c1c1e;
      --text: #ffffff;
      --secondary-text: #a1a1a6;
      --accent: #0a84ff;
      --danger: #ff453a;
      --success: #32d74b;
    }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      background-color: var(--bg);
      color: var(--text);
      margin: 0;
      padding: 0;
      display: flex;
      justify-content: center;
      min-height: 100vh;
    }
    .container {
      max-width: 500px;
      width: 100%;
      padding: 40px 20px;
      box-sizing: border-box;
    }
    .header {
      text-align: center;
      margin-bottom: 40px;
    }
    .header h1 {
      font-size: 32px;
      font-weight: 700;
      margin: 0;
      background: linear-gradient(135deg, #ffffff, #a1a1a6);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }
    .header p {
      color: var(--secondary-text);
      font-size: 15px;
      margin-top: 8px;
    }
    .grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 16px;
      margin-bottom: 30px;
    }
    .card {
      background-color: var(--card-bg);
      border-radius: 16px;
      padding: 24px 16px;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      text-align: center;
      box-shadow: 0 4px 20px rgba(0,0,0,0.3);
    }
    .card-wide {
      grid-column: 1 / -1;
    }
    .stat-value {
      font-size: 40px;
      font-weight: 700;
      margin-bottom: 6px;
    }
    .stat-label {
      font-size: 13px;
      font-weight: 600;
      color: var(--secondary-text);
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
    .text-success { color: var(--success); }
    .text-danger { color: var(--danger); }
    .text-accent { color: var(--accent); }
    .footer {
      text-align: center;
      color: var(--secondary-text);
      font-size: 13px;
      margin-top: 40px;
      opacity: 0.6;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Purity Progress</h1>
      <p>Partner Accountability Dashboard</p>
    </div>
    
    <div class="grid">
      <div class="card card-wide">
        <div class="stat-value text-success">${escapeHtml(payload.pornographyDays) || '0'}</div>
        <div class="stat-label">Days Pure (Pornography)</div>
      </div>
      
      <div class="card">
        <div class="stat-value">${escapeHtml(payload.masturbationDays) || '0'}</div>
        <div class="stat-label">Days Pure<br>(Masturbation)</div>
      </div>
      
      <div class="card">
        <div class="stat-value text-danger">${escapeHtml(payload.urgeMomentsCount) || '0'}</div>
        <div class="stat-label">Urges<br>Defeated</div>
      </div>
      
      ${payload.pureThoughtsDays != null ? `
      <div class="card card-wide">
        <div class="stat-value text-accent">${escapeHtml(payload.pureThoughtsDays)}</div>
        <div class="stat-label">Days Guarding Thoughts</div>
      </div>
      ` : ''}
      
      ${payload.hoursReclaimed > 0 ? `
      <div class="card card-wide">
        <div class="stat-value">${escapeHtml(payload.hoursReclaimed)}</div>
        <div class="stat-label">Hours Reclaimed</div>
      </div>
      ` : ''}
    </div>
    
    <div class="footer">
      Last synced: ${escapeHtml(payload.lastUpdated) || 'Never'}
    </div>
  </div>
</body>
</html>`;
  return res.type('html').send(html);
});

app.get('/health', (_, res) => res.json({ ok: true }));

async function init() {
  try {
    // Check if the users table exists. If not, auto-run the schema.
    const checkRes = await pool.query(`
      SELECT EXISTS(
    SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'users'
  );
  `);

    if (!checkRes.rows[0].exists) {
      console.log('Database tables not found. Initializing schema...');
      const schemaPath = path.join(__dirname, 'schema.sql');
      const schemaSql = fs.readFileSync(schemaPath, 'utf8');
      await pool.query(schemaSql);
      console.log('Schema initialized successfully.');
    } else {
      console.log('Database tables found. Skipping schema initialization.');
    }
  } catch (e) {
    console.error('DB connection or schema initialization failed:', e.message);
  }
  app.listen(PORT, () => console.log(`Purity Help API listening on port ${PORT} `));
}

init();
