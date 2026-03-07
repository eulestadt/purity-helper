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
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const sgMail = require('@sendgrid/mail');

sgMail.setApiKey(process.env.SENDGRID_API_KEY || '');
const SENDER_EMAIL = 'account@phoenix.boston';

const app = express();
const PORT = process.env.PORT || 10000;
const API_SECRET = process.env.API_SECRET || 'change-me-in-production';

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.DATABASE_URL?.startsWith('postgres://') ? { rejectUnauthorized: false } : false,
});

app.use(express.json({ limit: '256kb' }));
app.use(express.static(path.join(__dirname, 'public')));

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

// GET /auth/me — returns current user email
app.get('/auth/me', requireAuth, async (req, res) => {
  const r = await pool.query('SELECT email FROM users WHERE id = $1', [req.userId]);
  if (r.rows.length === 0) return res.status(404).json({ error: 'User not found' });
  return res.json({ email: r.rows[0].email });
});

// POST /auth/request-reset — send 6-digit OTP to user's email (requires Bearer)
app.post('/auth/request-reset', requireAuth, async (req, res) => {
  const r = await pool.query('SELECT email FROM users WHERE id = $1', [req.userId]);
  if (r.rows.length === 0) return res.status(404).json({ error: 'User not found' });
  const email = r.rows[0].email;
  if (!email) return res.status(400).json({ error: 'No email on this account' });

  // Generate a 6-digit code, store its bcrypt hash
  const code = String(Math.floor(100000 + crypto.randomInt(900000)));
  const codeHash = await bcrypt.hash(code, 10);
  const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

  // Invalidate any existing codes for this user and insert the new one
  await pool.query('DELETE FROM password_reset_tokens WHERE user_id = $1', [req.userId]);
  await pool.query(
    'INSERT INTO password_reset_tokens (user_id, code_hash, expires_at) VALUES ($1, $2, $3)',
    [req.userId, codeHash, expiresAt]
  );

  // Send the email via SendGrid
  try {
    await sgMail.send({
      to: email,
      from: { email: SENDER_EMAIL, name: 'Purity Help' },
      subject: 'Your password reset code',
      text: `Your Purity Help password reset code is: ${code}\n\nThis code expires in 10 minutes. If you didn't request this, you can ignore this email.`,
      html: `
        <div style="font-family:-apple-system,sans-serif;max-width:480px;margin:auto;padding:32px 24px">
          <h2 style="margin:0 0 8px">Password Reset</h2>
          <p style="color:#6b7280;margin:0 0 24px">Enter the code below in the Purity Help app to set a new password.</p>
          <div style="background:#f3f4f6;border-radius:12px;padding:24px;text-align:center;font-size:36px;font-weight:700;letter-spacing:8px">${code}</div>
          <p style="color:#9ca3af;font-size:13px;margin:24px 0 0">Expires in 10 minutes. If you didn't request this, ignore this email.</p>
        </div>
      `,
    });
  } catch (e) {
    console.error('SendGrid error:', e?.response?.body || e.message);
    return res.status(502).json({ error: 'Failed to send email. Try again.' });
  }

  return res.json({ ok: true });
});

// POST /auth/confirm-reset — validate OTP and set new password (requires Bearer)
app.post('/auth/confirm-reset', requireAuth, async (req, res) => {
  const { code, newPassword } = req.body;
  if (!code || !newPassword || newPassword.length < 8) {
    return res.status(400).json({ error: 'Code and new password (min 8 chars) required' });
  }

  const r = await pool.query(
    'SELECT id, code_hash, expires_at, used FROM password_reset_tokens WHERE user_id = $1 ORDER BY expires_at DESC LIMIT 1',
    [req.userId]
  );
  if (r.rows.length === 0) return res.status(401).json({ error: 'No reset code found. Request a new one.' });

  const { id: tokenId, code_hash: codeHash, expires_at: expiresAt, used } = r.rows[0];
  if (used) return res.status(401).json({ error: 'Code already used. Request a new one.' });
  if (new Date() > new Date(expiresAt)) return res.status(401).json({ error: 'Code expired. Request a new one.' });

  const matches = await bcrypt.compare(code, codeHash);
  if (!matches) return res.status(401).json({ error: 'Incorrect code.' });

  // Mark token used and update password atomically
  await pool.query('UPDATE password_reset_tokens SET used = TRUE WHERE id = $1', [tokenId]);
  const newHash = await bcrypt.hash(newPassword, 10);
  await pool.query('UPDATE users SET password_hash = $1 WHERE id = $2', [newHash, req.userId]);

  return res.json({ ok: true });
});

// POST /auth/forgot-password — unauthenticated reset request
app.post('/auth/forgot-password', async (req, res) => {
  const email = typeof req.body?.email === 'string' ? req.body.email.trim().toLowerCase() : '';
  if (!email) return res.status(400).json({ error: 'Email required' });

  const r = await pool.query('SELECT id FROM users WHERE email = $1', [email]);
  // Always return success to prevent email enumeration
  if (r.rows.length === 0) return res.json({ ok: true });

  const userId = r.rows[0].id;
  const code = String(Math.floor(100000 + crypto.randomInt(900000)));
  const codeHash = await bcrypt.hash(code, 10);
  const expiresAt = new Date(Date.now() + 10 * 60 * 1000);

  await pool.query('DELETE FROM password_reset_tokens WHERE user_id = $1', [userId]);
  await pool.query(
    'INSERT INTO password_reset_tokens (user_id, code_hash, expires_at) VALUES ($1, $2, $3)',
    [userId, codeHash, expiresAt]
  );

  try {
    await sgMail.send({
      to: email,
      from: { email: SENDER_EMAIL, name: 'Purity Help' },
      subject: 'Your password reset code',
      text: `Your Purity Help password reset code is: ${code}\n\nThis code expires in 10 minutes. If you didn't request this, you can ignore this email.`,
      html: `
        <div style="font-family:-apple-system,sans-serif;max-width:480px;margin:auto;padding:32px 24px">
          <h2 style="margin:0 0 8px">Password Reset</h2>
          <p style="color:#6b7280;margin:0 0 24px">Enter the code below to set a new password.</p>
          <div style="background:#f3f4f6;border-radius:12px;padding:24px;text-align:center;font-size:36px;font-weight:700;letter-spacing:8px">${code}</div>
          <p style="color:#9ca3af;font-size:13px;margin:24px 0 0">Expires in 10 minutes. If you didn't request this, ignore this email.</p>
        </div>
      `,
    });
  } catch (e) {
    console.error('SendGrid error:', e?.response?.body || e.message);
    // Even if it fails, don't leak that the email exists
  }
  return res.json({ ok: true });
});

// POST /auth/forgot-password-confirm — unauthenticated confirm + set new password
app.post('/auth/forgot-password-confirm', async (req, res) => {
  const email = typeof req.body?.email === 'string' ? req.body.email.trim().toLowerCase() : '';
  const { code, newPassword } = req.body;

  if (!email || !code || !newPassword || newPassword.length < 8) {
    return res.status(400).json({ error: 'Valid email, code, and new password required' });
  }

  const u = await pool.query('SELECT id FROM users WHERE email = $1', [email]);
  if (u.rows.length === 0) return res.status(401).json({ error: 'Invalid request' });
  const userId = u.rows[0].id;

  const r = await pool.query(
    'SELECT id, code_hash, expires_at, used FROM password_reset_tokens WHERE user_id = $1 ORDER BY expires_at DESC LIMIT 1',
    [userId]
  );
  if (r.rows.length === 0) return res.status(401).json({ error: 'No reset code found.' });

  const { id: tokenId, code_hash: codeHash, expires_at: expiresAt, used } = r.rows[0];
  if (used) return res.status(401).json({ error: 'Code already used.' });
  if (new Date() > new Date(expiresAt)) return res.status(401).json({ error: 'Code expired.' });

  const matches = await bcrypt.compare(code, codeHash);
  if (!matches) return res.status(401).json({ error: 'Incorrect code.' });

  // Mark token used and update password
  await pool.query('UPDATE password_reset_tokens SET used = TRUE WHERE id = $1', [tokenId]);
  const newHash = await bcrypt.hash(newPassword, 10);
  await pool.query('UPDATE users SET password_hash = $1 WHERE id = $2', [newHash, userId]);

  return res.json({ ok: true });
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
    // DO UPDATE SET token = share_tokens.token is a no-op UPDATE that lets RETURNING
    // give us the existing token instead of always regenerating a new UUID.
    // This ensures all devices on the same account get the same stable share link.
    `INSERT INTO share_tokens (user_id, token) VALUES ($1, gen_random_uuid())
     ON CONFLICT (user_id) DO UPDATE SET token = share_tokens.token RETURNING token`,
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

  // Apply privacy preferences stored in the payload by the iOS app.
  // The app sets shareExamens/shareUrges/shareRelapses = false when the
  // user has turned those toggles off — strip those models here so the
  // share page never shows data the user chose to keep private.
  const filtered = { ...payload };
  const hasModels = filtered.models && typeof filtered.models === 'object';
  if (hasModels) {
    filtered.models = { ...filtered.models };
    if (filtered.shareExamens === false) {
      filtered.models.examenEntries = [];
    }
    if (filtered.shareUrges === false) {
      filtered.models.urgeLogs = [];
    }
    if (filtered.shareRelapses === false) {
      filtered.models.resetRecords = [];
    }
  }
  // Strip the internal prefs from what we expose publicly
  const { shareExamens: _se, shareUrges: _su, shareRelapses: _sr, ...publicPayload } = filtered;
  publicPayload.models = filtered.models;

  const wantsJson = req.headers.accept?.includes('application/json') || req.query.format === 'json';
  if (wantsJson) {
    return res.json(publicPayload);
  }
  const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <style>
    :root {
      --bg: #1a2639;
      --bg-bottom: #33261a;
      --card-bg: rgba(255, 255, 255, 0.05);
      --text: #ffffff;
      --secondary-text: #a1a1a6;
      --accent: #5e5ce6;
      --danger: #ff453a;
      --success: #30d158;
    }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol";
      background: linear-gradient(to bottom, var(--bg), var(--bg-bottom));
      background-attachment: fixed;
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
      backdrop-filter: blur(12px);
      border: 1px solid rgba(255, 255, 255, 0.1);
      border-radius: 16px;
      padding: 24px 16px;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      text-align: center;
      box-shadow: 0 8px 32px rgba(0,0,0,0.15);
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
    .list-section {
      margin-top: 40px;
    }
    .list-header {
      font-size: 20px;
      font-weight: 600;
      margin-bottom: 16px;
      color: var(--text);
      border-bottom: 1px solid rgba(255,255,255,0.1);
      padding-bottom: 8px;
    }
    .item-card {
      background-color: var(--card-bg);
      border-radius: 12px;
      padding: 16px;
      margin-bottom: 12px;
      border: 1px solid rgba(255,255,255,0.05);
      text-align: left;
    }
    .item-date {
      font-size: 12px;
      color: var(--secondary-text);
      margin-bottom: 6px;
      font-weight: 500;
    }
    .item-title {
      font-size: 15px;
      font-weight: 600;
      margin-bottom: 4px;
    }
    .item-body {
      font-size: 14px;
      color: rgba(255,255,255,0.85);
      line-height: 1.5;
      margin-top: 8px;
    }
    .badge {
      display: inline-block;
      padding: 4px 8px;
      border-radius: 6px;
      font-size: 11px;
      font-weight: 700;
      text-transform: uppercase;
    }
    .badge-success { background: rgba(50,215,75,0.2); color: var(--success); }
    .badge-danger { background: rgba(255,69,58,0.2); color: var(--danger); }
    .badge-accent { background: rgba(10,132,255,0.2); color: var(--accent); }
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

    ${payload.models?.resetRecords?.length > 0 ? `
    <div class="list-section">
      <div class="list-header">Timers Reset</div>
      ${payload.models.resetRecords
        .sort((a, b) => b.date - a.date)
        .slice(0, 10)
        .map(reset => {
          const d = new Date(reset.date * 1000).toLocaleString(undefined, { weekday: 'short', month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit' });
          let capType = reset.type ? reset.type.charAt(0).toUpperCase() + reset.type.slice(1) : 'Unknown';
          if (capType === 'PureThoughts') capType = 'Impure Thoughts';

          const relapsedBadge = '<span class="badge badge-danger">Relapsed</span>';

          return `
          <div class="item-card">
            <div class="item-date">${d}</div>
            <div class="item-title">Begin Again: ${escapeHtml(capType)} ${relapsedBadge}</div>
            <div class="item-body" style="opacity: 0.9;">
              ${reset.triggerTag ? `<strong>Autopsy:</strong> ${escapeHtml(reset.triggerTag)}<br>` : ''}
              ${reset.optionalNote ? `<strong>Confession:</strong> <em>"${escapeHtml(reset.optionalNote)}"</em>` : ''}
            </div>
          </div>
          `;
        }).join('')}
    </div>
    ` : ''}

    ${payload.models?.urgeLogs?.length > 0 ? `
    <div class="list-section">
      <div class="list-header">Recent Urge Data</div>
      ${payload.models.urgeLogs
        .sort((a, b) => b.date - a.date)
        .slice(0, 10)
        .map(log => {
          const d = new Date(log.date * 1000).toLocaleString(undefined, { weekday: 'short', month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit' });
          return `
          <div class="item-card">
            <div class="item-date">${d}</div>
            <div class="item-title">${escapeHtml(log.replaceActivityUsed || log.quickActionUsed || 'Fought Urge')}</div>
            ${log.optionalNote ? `<div class="item-body"><em>"${escapeHtml(log.optionalNote)}"</em></div>` : ''}
          </div>
          `;
        }).join('')}
    </div>
    ` : ''}

    ${payload.models?.examenEntries?.length > 0 ? `
    <div class="list-section">
      <div class="list-header">Daily Examens</div>
      ${payload.models.examenEntries
        .sort((a, b) => b.date - a.date)
        .slice(0, 7)
        .map(entry => {
          const d = new Date(entry.date * 1000).toLocaleString(undefined, { weekday: 'long', month: 'short', day: 'numeric' });
          let bodyHtml = '';
          if (entry.howWasToday) bodyHtml += `<strong>How was today?</strong><br>${escapeHtml(entry.howWasToday)}<br><br>`;
          if (entry.step1Thanks) bodyHtml += `<strong>Gratitude</strong><br>${escapeHtml(entry.step1Thanks)}<br><br>`;
          if (entry.step5Resolve) bodyHtml += `<strong>Resolve</strong><br>${escapeHtml(entry.step5Resolve)}`;

          return `
          <div class="item-card">
            <div class="item-date">${d}</div>
            <div class="item-body">${bodyHtml}</div>
          </div>
          `;
        }).join('')}
    </div>
    ` : ''}
    
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
    // Check if the users table exists. If not, auto-run the full schema.
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
      console.log('Database tables found. Skipping full schema initialization.');
      // Always ensure the password_reset_tokens table exists (idempotent migration)
      await pool.query(`
        CREATE TABLE IF NOT EXISTS password_reset_tokens (
          id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          code_hash  TEXT NOT NULL,
          expires_at TIMESTAMPTZ NOT NULL,
          used       BOOLEAN NOT NULL DEFAULT FALSE
        );
      `);
      await pool.query(`CREATE INDEX IF NOT EXISTS idx_prt_user_id ON password_reset_tokens(user_id);`);
    }
  } catch (e) {
    console.error('DB connection or schema initialization failed:', e.message);
  }
  app.listen(PORT, () => console.log(`Purity Help API listening on port ${PORT} `));
}

init();
