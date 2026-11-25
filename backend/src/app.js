const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const path = require('path');
const { push, pull } = require('./sync');
const { derive, projectPublic, parseDay } = require('./domain');
const { HttpError } = require('./errors');
const { renderShare } = require('./share-page');
const { sendResetCode } = require('./mailer');

function todayOr(value) {
  if (typeof value === 'string' && parseDay(value)) return value;
  return new Date().toISOString().slice(0, 10);
}

function createApp(store, options = {}) {
  const secret = options.secret || process.env.API_SECRET || 'change-me-in-production';
  const mail = options.mailer || sendResetCode;
  const baseUrl = () => options.baseUrl || process.env.BASE_URL || '';
  const app = express();
  app.disable('x-powered-by');
  app.use(express.json({ limit: '1mb' }));

  function sign(userId) {
    return jwt.sign({ userId }, secret, { expiresIn: '180d' });
  }

  function requireAuth(req, res, next) {
    const header = req.headers.authorization || '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : '';
    if (!token) return next(new HttpError(401, 'Missing authorization'));
    try {
      req.userId = jwt.verify(token, secret).userId;
      return next();
    } catch {
      return next(new HttpError(401, 'Invalid or expired token'));
    }
  }

  async function userDocs(userId) {
    const rows = await store.transaction(async (tx) => tx.allDocs(userId));
    return rows.map((row) => ({ key: row.key, value: row.value, deleted: row.deleted }));
  }

  app.get('/health', (_req, res) => {
    res.json({ ok: true, sync: 'events-v1', mail: process.env.SMTP_HOST ? 'smtp' : 'log' });
  });

  app.post('/auth/signup', async (req, res, next) => {
    try {
      const email = typeof req.body?.email === 'string' ? req.body.email.trim().toLowerCase() : '';
      const password = req.body?.password;
      if (!email.includes('@') || email.length > 200 || typeof password !== 'string' || password.length < 8 || password.length > 200) {
        throw new HttpError(400, 'Email and password (8–200 characters) required');
      }
      const passwordHash = await bcrypt.hash(password, 10);
      try {
        const user = await store.createUser({ email, passwordHash });
        res.json({ token: sign(user.id), userId: user.id, email });
      } catch (error) {
        if (error.code === '23505') throw new HttpError(409, 'Email already registered');
        throw error;
      }
    } catch (error) { next(error); }
  });

  app.post('/auth/login', async (req, res, next) => {
    try {
      const email = typeof req.body?.email === 'string' ? req.body.email.trim().toLowerCase() : '';
      const password = req.body?.password;
      if (!email || typeof password !== 'string') throw new HttpError(400, 'Email and password required');
      const user = await store.findUserByEmail(email);
      const ok = user && await bcrypt.compare(password, user.passwordHash);
      if (!ok) throw new HttpError(401, 'Invalid email or password');
      res.json({ token: sign(user.id), userId: user.id, email });
    } catch (error) { next(error); }
  });

  app.get('/auth/me', requireAuth, async (req, res, next) => {
    try {
      const user = await store.findUserById(req.userId);
      if (!user) throw new HttpError(404, 'User not found');
      res.json({ email: user.email, userId: user.id });
    } catch (error) { next(error); }
  });

  app.post('/auth/forgot-password', async (req, res, next) => {
    try {
      const email = typeof req.body?.email === 'string' ? req.body.email.trim().toLowerCase() : '';
      if (!email) throw new HttpError(400, 'Email required');
      const user = await store.findUserByEmail(email);
      if (user) {
        const code = String(crypto.randomInt(100000, 1000000));
        const codeHash = await bcrypt.hash(code, 10);
        await store.saveReset({
          userId: user.id,
          codeHash,
          expiresAt: new Date(Date.now() + 10 * 60 * 1000),
        });
        try {
          await mail({ to: email, code });
        } catch (error) {
          console.error('Mail send failed:', error.message);
        }
      }
      res.json({ ok: true });
    } catch (error) { next(error); }
  });

  app.post('/auth/forgot-password-confirm', async (req, res, next) => {
    try {
      const email = typeof req.body?.email === 'string' ? req.body.email.trim().toLowerCase() : '';
      const code = typeof req.body?.code === 'string' ? req.body.code.trim() : '';
      const newPassword = req.body?.newPassword;
      if (!email || !code || typeof newPassword !== 'string' || newPassword.length < 8 || newPassword.length > 200) {
        throw new HttpError(400, 'Email, code, and a new password (8–200 characters) required');
      }
      const user = await store.findUserByEmail(email);
      if (!user) throw new HttpError(401, 'Invalid code');
      const reset = await store.latestReset(user.id);
      if (!reset || reset.used) throw new HttpError(401, 'Invalid code');
      if (new Date() > new Date(reset.expiresAt)) throw new HttpError(401, 'Code expired');
      const matches = await bcrypt.compare(code, reset.codeHash);
      if (!matches) {
        await store.bumpResetAttempts(reset.id);
        throw new HttpError(401, 'Invalid code');
      }
      await store.markResetUsed(reset.id);
      await store.updatePassword(user.id, await bcrypt.hash(newPassword, 10));
      res.json({ ok: true });
    } catch (error) { next(error); }
  });

  app.post('/sync/push', requireAuth, async (req, res, next) => {
    try {
      const result = await push(store, req.userId, req.body?.clientId, req.body?.mutations || []);
      res.json(result);
    } catch (error) { next(error); }
  });

  app.post('/sync/pull', requireAuth, async (req, res, next) => {
    try {
      const result = await pull(store, req.userId, req.body?.clientId, req.body?.cookie || 0);
      res.json(result);
    } catch (error) { next(error); }
  });

  app.get('/summary', requireAuth, async (req, res, next) => {
    try {
      const today = todayOr(req.query.today);
      const derived = derive(await userDocs(req.userId), { today });
      res.json(derived);
    } catch (error) { next(error); }
  });

  app.post('/share', requireAuth, async (req, res, next) => {
    try {
      const token = await store.shareToken(req.userId, { regenerate: req.body?.regenerate === true });
      const root = (baseUrl() || `${req.protocol}://${req.get('host')}`).replace(/\/$/, '');
      res.json({ token, link: `${root}/share/${token}` });
    } catch (error) { next(error); }
  });

  app.get('/share/:token', async (req, res, next) => {
    try {
      const token = req.params.token;
      if (!/^[0-9a-f-]{36}$/i.test(token)) throw new HttpError(404, 'Not found');
      const userId = await store.userIdForShare(token);
      if (!userId) throw new HttpError(404, 'Not found');
      const today = todayOr(req.query.today);
      const summary = projectPublic(derive(await userDocs(userId), { today }));
      if (req.query.format === 'json' || (req.headers.accept || '').includes('application/json')) {
        return res.json(summary);
      }
      return res.type('html').send(renderShare(summary));
    } catch (error) { next(error); }
  });

  app.use(express.static(path.join(__dirname, '..', 'public')));

  app.use((error, _req, res, _next) => {
    const status = error.status || 500;
    if (status >= 500) console.error(error);
    res.status(status).json({ error: status >= 500 ? 'Server error' : error.message, ...error.extra });
  });

  return app;
}

module.exports = { createApp };
