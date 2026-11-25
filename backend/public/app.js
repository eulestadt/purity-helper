const state = {
  mode: 'login',
  token: localStorage.getItem('purity_token') || '',
  clientId: localStorage.getItem('purity_client') || '',
  cookie: Number(localStorage.getItem('purity_cookie') || 0),
  nextId: Number(localStorage.getItem('purity_next') || 1),
  summary: null,
  share: '',
};

if (!state.clientId) {
  state.clientId = crypto.randomUUID().replace(/-/g, '').slice(0, 24);
  localStorage.setItem('purity_client', state.clientId);
}

const $ = (id) => document.getElementById(id);

function today() {
  const now = new Date();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const day = String(now.getDate()).padStart(2, '0');
  return `${now.getFullYear()}-${month}-${day}`;
}

function alertBox(id, message, ok = false) {
  const node = $(id);
  node.textContent = message;
  node.className = ok ? 'alert ok' : 'alert';
}

async function request(path, { method = 'GET', body } = {}) {
  const response = await fetch(path, {
    method,
    headers: {
      'content-type': 'application/json',
      ...(state.token ? { authorization: `Bearer ${state.token}` } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const json = await response.json().catch(() => ({}));
  if (!response.ok) throw new Error(json.error || 'Request failed');
  return json;
}

function ring(label, value) {
  const amount = Math.max(0, Math.min(1, Number(value) || 0));
  return `<div class="ring" style="--p:${amount}"><div class="ring-hole"><b>${Math.round(amount * 100)}</b><span>${label}</span></div></div>`;
}

function render() {
  const signedIn = Boolean(state.token && state.summary);
  $('signed-out').classList.toggle('hidden', signedIn);
  $('signed-in').classList.toggle('hidden', !signedIn);
  if (!signedIn) return;
  const summary = state.summary;
  $('tree-name').textContent = summary.tree?.name || 'Seed';
  $('clear-days').innerHTML = `${summary.streaks?.clear ?? 0} <span>clear days</span>`;
  $('mission-line').textContent = summary.profile?.mission || 'Set a mission on the phone. It can stay off the share link.';
  $('rings').innerHTML = ['Clear', 'Watch', 'Prayer', 'Word']
    .map((label) => ring(label, summary.rings?.[label.toLowerCase()]))
    .join('');
  const streaks = summary.streaks || {};
  const cards = [
    [streaks.pornography ?? 0, 'Days without pornography'],
    [streaks.masturbation ?? 0, 'Days without masturbation'],
    [streaks.watch ?? 0, 'Days guarding thoughts'],
    [summary.hoursReclaimed ?? 0, 'Hours reclaimed'],
  ];
  $('stats').innerHTML = cards.map(([value, label]) => `<article class="glass"><b>${value}</b><span>${label}</span></article>`).join('');
  $('sync-line').textContent = summary.fullDay ? 'Today is a full day.' : 'Today is still open.';
  const profile = summary.profile || {};
  const toggles = [
    ['shareRings', 'Rings', profile.shareRings !== false],
    ['shareStreaks', 'Streaks and hours', profile.shareStreaks !== false],
    ['shareMission', 'Mission', profile.shareMission === true],
    ['shareRelapses', 'Relapses', profile.shareRelapses === true],
    ['shareUrges', 'Urges', profile.shareUrges === true],
    ['shareExamens', 'Examens', profile.shareExamens === true],
  ];
  $('toggles').innerHTML = toggles.map(([key, label, on]) => `
    <label class="check"><span>${label}</span>
      <input type="checkbox" data-key="${key}" ${on ? 'checked' : ''}>
    </label>`).join('');
  $('share-link').textContent = state.share || '';
  $('who').textContent = state.email || '';
}

async function refresh() {
  if (!state.token) { render(); return; }
  const me = await request('/auth/me');
  state.email = me.email;
  const pulled = await request('/sync/pull', { method: 'POST', body: { clientId: state.clientId, cookie: state.cookie } });
  state.cookie = pulled.cookie;
  localStorage.setItem('purity_cookie', String(state.cookie));
  const acked = Number(pulled.lastMutationIDs?.[state.clientId] || 0);
  if (acked + 1 > state.nextId) {
    state.nextId = acked + 1;
    localStorage.setItem('purity_next', String(state.nextId));
  }
  state.summary = await request(`/summary?today=${today()}`);
  if (!state.share) {
    const share = await request('/share', { method: 'POST', body: {} });
    state.share = share.link;
  }
  render();
}

let queue = Promise.resolve();

function enqueue(task) {
  const run = queue.then(task, task);
  queue = run.then(() => undefined, () => undefined);
  return run;
}

async function putProfile(patch) {
  const current = { ...(state.summary?.profile || {}), ...patch };
  const id = state.nextId;
  await request('/sync/push', {
    method: 'POST',
    body: { clientId: state.clientId, mutations: [{ id, name: 'put', args: { key: 'profile', value: current } }] },
  });
  state.nextId = id + 1;
  localStorage.setItem('purity_next', String(state.nextId));
  state.cookie = 0;
  localStorage.setItem('purity_cookie', '0');
  await refresh();
}

$('toggle-mode').addEventListener('click', () => {
  state.mode = state.mode === 'login' ? 'signup' : 'login';
  $('auth-title').textContent = state.mode === 'login' ? 'Log in' : 'Create an account';
  $('auth-submit').textContent = state.mode === 'login' ? 'Log in' : 'Create account';
  $('toggle-mode').textContent = state.mode === 'login' ? 'Create an account' : 'I already have an account';
});

$('auth-form').addEventListener('submit', async (event) => {
  event.preventDefault();
  try {
    const path = state.mode === 'login' ? '/auth/login' : '/auth/signup';
    const result = await request(path, {
      method: 'POST',
      body: { email: $('email').value, password: $('password').value },
    });
    state.token = result.token;
    localStorage.setItem('purity_token', state.token);
    state.cookie = 0;
    await refresh();
  } catch (error) {
    alertBox('auth-alert', error.message);
  }
});

$('show-forgot').addEventListener('click', () => $('forgot-form').classList.remove('hidden'));

$('forgot-form').addEventListener('submit', async (event) => {
  event.preventDefault();
  try {
    await request('/auth/forgot-password', { method: 'POST', body: { email: $('forgot-email').value } });
    alertBox('forgot-alert', 'If that account exists, a code is on its way.', true);
  } catch (error) {
    alertBox('forgot-alert', error.message);
  }
});

$('forgot-confirm').addEventListener('click', async () => {
  try {
    await request('/auth/forgot-password-confirm', {
      method: 'POST',
      body: {
        email: $('forgot-email').value,
        code: $('forgot-code').value,
        newPassword: $('forgot-password').value,
      },
    });
    alertBox('forgot-alert', 'Password updated. Log in with it.', true);
  } catch (error) {
    alertBox('forgot-alert', error.message);
  }
});

$('toggles').addEventListener('change', (event) => {
  const input = event.target;
  if (!input.dataset.key) return;
  enqueue(async () => {
    try {
      await putProfile({ [input.dataset.key]: input.checked });
    } catch (error) {
      $('sync-line').textContent = error.message;
      await refresh();
    }
  });
});

$('copy-link').addEventListener('click', async () => {
  if (state.share) await navigator.clipboard.writeText(state.share);
});

$('regen-link').addEventListener('click', async () => {
  const share = await request('/share', { method: 'POST', body: { regenerate: true } });
  state.share = share.link;
  render();
});

$('sign-out').addEventListener('click', () => {
  state.token = '';
  state.summary = null;
  state.share = '';
  localStorage.removeItem('purity_token');
  render();
});

refresh().catch((error) => {
  state.token = '';
  localStorage.removeItem('purity_token');
  alertBox('auth-alert', error.message);
  render();
});
