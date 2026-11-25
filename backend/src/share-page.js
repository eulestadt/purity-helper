function escapeHtml(unsafe) {
  if (unsafe == null) return '';
  return String(unsafe)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

function ring(label, value) {
  const amount = Math.max(0, Math.min(1, Number(value) || 0));
  return `<div class="ring" style="--p:${amount}">
    <div class="ring-hole"><b>${Math.round(amount * 100)}</b><span>${escapeHtml(label)}</span></div>
  </div>`;
}

function list(title, rows, render) {
  if (!rows || !rows.length) return '';
  return `<section><h2>${escapeHtml(title)}</h2>${rows.map(render).join('')}</section>`;
}

function renderShare(summary) {
  const streaks = summary.streaks || {};
  const rings = summary.rings;
  const tree = summary.tree || { name: 'Seed', days: 0 };
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>A shared walk</title>
  <link rel="stylesheet" href="/style.css">
</head>
<body>
  <main class="wrap">
    <header class="mast">
      <p class="eyebrow">Purity Help</p>
      <h1>A shared walk</h1>
      <p class="lede">Read-only. Blessed are the pure in heart, for they shall see God.</p>
    </header>
    <section class="glass hero">
      <p class="eyebrow">${escapeHtml(tree.name)}</p>
      <p class="display">${escapeHtml(tree.days)} <span>clear days</span></p>
      ${summary.mission ? `<p class="mission">“${escapeHtml(summary.mission)}”</p>` : ''}
    </section>
    ${rings ? `<section class="rings">${ring('Clear', rings.clear)}${ring('Watch', rings.watch)}${ring('Prayer', rings.prayer)}${ring('Word', rings.word)}</section>` : ''}
    ${summary.streaks ? `<section class="stats">
      <article class="glass"><b>${escapeHtml(streaks.pornography ?? 0)}</b><span>Days without pornography</span></article>
      <article class="glass"><b>${escapeHtml(streaks.masturbation ?? 0)}</b><span>Days without masturbation</span></article>
      <article class="glass"><b>${escapeHtml(streaks.watch ?? 0)}</b><span>Days guarding thoughts</span></article>
      <article class="glass"><b>${escapeHtml(summary.hoursReclaimed ?? 0)}</b><span>Hours reclaimed</span></article>
    </section>` : ''}
    ${list('Begin again', summary.relapses, (row) => `<article class="glass item"><p class="meta">${escapeHtml(row.day)} · ${escapeHtml(row.type || '')}</p><p>${escapeHtml(row.trigger || '')}</p><p>${escapeHtml(row.note || '')}</p></article>`)}
    ${list('Urges', summary.urges, (row) => `<article class="glass item"><p class="meta">${escapeHtml(row.day)} · ${escapeHtml(row.outcome || '')}</p><p>${escapeHtml(row.activity || row.note || '')}</p></article>`)}
    ${list('Examens', summary.examens, (row) => `<article class="glass item"><p class="meta">${escapeHtml(row.day)}</p><p>${escapeHtml(row.how || '')}</p><p>${escapeHtml(row.resolve || '')}</p></article>`)}
    <p class="foot">Today on their calendar: ${escapeHtml(summary.today || '')}. Details appear only when they choose to share them.</p>
  </main>
</body>
</html>`;
}

module.exports = { renderShare, escapeHtml };
