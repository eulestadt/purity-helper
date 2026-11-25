const test = require('node:test');
const assert = require('node:assert/strict');
const { createApp } = require('../src/app');
const { MemoryStore } = require('../src/memory-store');
const { createLocal, put, ingestPull, documents } = require('../src/client-logic');

function listen(app) {
  return new Promise((resolve) => {
    const server = app.listen(0, '127.0.0.1', () => resolve(server));
  });
}

async function api(base, path, { token, body, method = 'GET' } = {}) {
  const response = await fetch(base + path, {
    method: body ? 'POST' : method,
    headers: {
      'content-type': 'application/json',
      ...(token ? { authorization: `Bearer ${token}` } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await response.text();
  let json = null;
  try { json = text ? JSON.parse(text) : null; } catch { json = { raw: text }; }
  return { status: response.status, json, text };
}

async function syncOnce(base, token, local) {
  let pulled = await api(base, '/sync/pull', { token, body: { clientId: local.clientId, cookie: local.cookie } });
  assert.equal(pulled.status, 200);
  ingestPull(local, pulled.json);
  if (!local.pending.length) return;
  const pushed = await api(base, '/sync/push', {
    token,
    body: { clientId: local.clientId, mutations: local.pending },
  });
  assert.equal(pushed.status, 200, pushed.text);
  pulled = await api(base, '/sync/pull', { token, body: { clientId: local.clientId, cookie: local.cookie } });
  assert.equal(pulled.status, 200);
  ingestPull(local, pulled.json);
  assert.equal(local.pending.length, 0);
}

test('two devices keep both relapses and converge', async () => {
  const mail = [];
  const app = createApp(new MemoryStore(), {
    secret: 'test-secret',
    baseUrl: 'http://share.test',
    mailer: async ({ to, code }) => { mail.push({ to, code }); },
  });
  const server = await listen(app);
  const base = `http://127.0.0.1:${server.address().port}`;
  try {
    const signup = await api(base, '/auth/signup', { body: { email: 'a@example.com', password: 'correct horse' } });
    assert.equal(signup.status, 200);
    const token = signup.json.token;
    const phone = createLocal('phone-client-1');
    const tablet = createLocal('tablet-client-2');

    put(phone, 'profile', {
      journeyStart: '2026-11-01',
      hoursPerDay: 1,
      mission: 'A pure heart',
      shareRelapses: false,
      shareMission: false,
    });
    put(phone, 'event/relapsephone0001', {
      kind: 'relapse', day: '2026-11-20', at: '2026-11-20T04:00:00Z', type: 'pornography', hour: 23, weekday: 5,
    });
    await syncOnce(base, token, phone);

    await syncOnce(base, token, tablet);
    put(tablet, 'event/relapsetablet0001', {
      kind: 'relapse', day: '2026-11-22', at: '2026-11-22T02:00:00Z', type: 'masturbation', hour: 2, weekday: 0, note: 'late',
    });
    put(tablet, 'plan/night-plan-001', { trigger: 'If I am alone after 11', action: 'I will walk outside and pray Psalm 51' });
    await syncOnce(base, token, tablet);
    await syncOnce(base, token, phone);

    const phoneKeys = documents(phone).filter((doc) => !doc.deleted).map((doc) => doc.key).sort();
    const tabletKeys = documents(tablet).filter((doc) => !doc.deleted).map((doc) => doc.key).sort();
    assert.deepEqual(phoneKeys, tabletKeys);
    assert.ok(phoneKeys.includes('event/relapsephone0001'));
    assert.ok(phoneKeys.includes('event/relapsetablet0001'));

    const summary = await api(base, '/summary?today=2026-11-24', { token, method: 'GET' });
    assert.equal(summary.status, 200);
    assert.equal(summary.json.streaks.clear, 2);
    assert.equal(summary.json.streaks.pornography, 4);
    assert.equal(summary.json.streaks.masturbation, 2);
    assert.equal(summary.json.plans.length, 1);

    const replay = await api(base, '/sync/push', {
      token,
      body: { clientId: phone.clientId, mutations: [{ id: 1, name: 'put', args: { key: 'profile', value: { wiped: true } } }] },
    });
    assert.equal(replay.status, 200);
    const still = await api(base, '/summary?today=2026-11-24', { token, method: 'GET' });
    assert.equal(still.json.profile.mission, 'A pure heart');

    const gap = await api(base, '/sync/push', {
      token,
      body: { clientId: 'fresh-client-9', mutations: [{ id: 2, name: 'put', args: { key: 'profile', value: { mission: 'no' } } }] },
    });
    assert.equal(gap.status, 409);
    assert.equal(gap.json.expected, 1);

    const share = await api(base, '/share', { token, body: {} });
    assert.equal(share.status, 200);
    assert.match(share.json.link, /^http:\/\/share\.test\/share\//);
    const page = await fetch(share.json.link.replace('http://share.test', base));
    const html = await page.text();
    assert.match(html, /clear days/i);
    assert.equal(html.includes('late'), false);
    assert.equal(html.includes('A pure heart'), false);

    const open = put(phone, 'profile', { ...phone.docs.get('profile').value, shareRelapses: true });
    assert.ok(open.id);
    await syncOnce(base, token, phone);
    const jsonShare = await fetch(`${share.json.link.replace('http://share.test', base)}?format=json&today=2026-11-24`);
    const shared = await jsonShare.json();
    assert.equal(shared.relapses.length, 2);

    const forgot = await api(base, '/auth/forgot-password', { body: { email: 'a@example.com' } });
    assert.equal(forgot.status, 200);
    assert.equal(mail.length, 1);
    const missing = await api(base, '/auth/forgot-password', { body: { email: 'missing@example.com' } });
    assert.equal(missing.status, 200);
    assert.equal(mail.length, 1);
    const confirm = await api(base, '/auth/forgot-password-confirm', {
      body: { email: 'a@example.com', code: mail[0].code, newPassword: 'another horse' },
    });
    assert.equal(confirm.status, 200);
    const relogin = await api(base, '/auth/login', { body: { email: 'a@example.com', password: 'another horse' } });
    assert.equal(relogin.status, 200);

    const anon = await api(base, '/sync/push', { body: { clientId: 'phone-client-1', mutations: [] } });
    assert.equal(anon.status, 401);
  } finally {
    server.close();
  }
});
