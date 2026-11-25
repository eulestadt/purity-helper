/**
 * Purity Help day rules, version 1.
 * Samples are the source of truth. Streaks and rings are derived.
 * The Swift port lives in PurityHelp/Domain/DayDomain.swift and must match.
 */

const TREE = [
  { min: 90, id: 'mature', name: 'Mature tree' },
  { min: 30, id: 'young', name: 'Young tree' },
  { min: 14, id: 'sapling', name: 'Sapling' },
  { min: 7, id: 'sprout', name: 'Sprout' },
  { min: 1, id: 'seedling', name: 'Seedling' },
  { min: 0, id: 'seed', name: 'Seed' },
];

const MILESTONES = [1, 3, 7, 14, 30, 60, 90];

function parseDay(day) {
  if (typeof day !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(day)) return null;
  const [y, m, d] = day.split('-').map(Number);
  const utc = Date.UTC(y, m - 1, d);
  const check = new Date(utc);
  if (check.getUTCFullYear() !== y || check.getUTCMonth() !== m - 1 || check.getUTCDate() !== d) return null;
  return utc;
}

function addDays(day, n) {
  const utc = parseDay(day);
  if (utc == null) return null;
  return new Date(utc + n * 86400000).toISOString().slice(0, 10);
}

function daysBetween(a, b) {
  const left = parseDay(a);
  const right = parseDay(b);
  if (left == null || right == null) return null;
  return Math.round((right - left) / 86400000);
}

function isObject(value) {
  return value != null && typeof value === 'object' && !Array.isArray(value);
}

function eventsFrom(documents) {
  const events = [];
  for (const doc of documents) {
    if (!doc || doc.deleted) continue;
    if (typeof doc.key !== 'string' || !doc.key.startsWith('event/')) continue;
    if (!isObject(doc.value) || typeof doc.value.kind !== 'string') continue;
    if (parseDay(doc.value.day) == null) continue;
    events.push(doc.value);
  }
  return events;
}

function profileFrom(documents) {
  const doc = documents.find((d) => d && !d.deleted && d.key === 'profile' && isObject(d.value));
  return doc ? doc.value : {};
}

function plansFrom(documents) {
  return documents
    .filter((d) => d && !d.deleted && typeof d.key === 'string' && d.key.startsWith('plan/') && isObject(d.value))
    .map((d) => ({ id: d.key.slice('plan/'.length), ...d.value }))
    .sort((a, b) => String(a.trigger || '').localeCompare(String(b.trigger || '')));
}

function streakAsOf(relapseDays, today, journeyStart) {
  if (parseDay(today) == null) return 0;
  const relapses = [...new Set(relapseDays.filter((d) => parseDay(d) != null && d <= today))].sort();
  const last = relapses.length ? relapses[relapses.length - 1] : null;
  if (last === today) return 0;
  let start = null;
  if (last) start = addDays(last, 1);
  else if (typeof journeyStart === 'string' && parseDay(journeyStart) != null && journeyStart <= today) start = journeyStart;
  if (!start || start > today) return 0;
  return daysBetween(start, today) + 1;
}

function treeStage(days) {
  return TREE.find((stage) => days >= stage.min) || TREE[TREE.length - 1];
}

function ringsFor(eventsToday) {
  const bodyRelapse = eventsToday.some((e) => e.kind === 'relapse' && (e.type === 'pornography' || e.type === 'masturbation'));
  const thoughtRelapse = eventsToday.some((e) => e.kind === 'relapse' && e.type === 'thought');
  const surfed = eventsToday.some((e) => e.kind === 'urge' && e.outcome === 'surfed');
  const watchMark = eventsToday.some((e) => e.kind === 'prayer' && (e.form === 'vigil' || e.form === 'watch'));
  const intention = eventsToday.some((e) => e.kind === 'prayer' && e.form === 'intention');
  const otherPrayer = eventsToday.some((e) => e.kind === 'prayer' && e.form !== 'intention');
  const examen = eventsToday.some((e) => e.kind === 'examen');
  const scripture = eventsToday.some((e) => e.kind === 'scripture');
  const verse = eventsToday.some((e) => e.kind === 'verse');

  let prayer = 0;
  if (examen) prayer = 1;
  else {
    if (intention) prayer += 0.4;
    if (otherPrayer) prayer += 0.6;
    prayer = Math.min(1, prayer);
  }

  let watch = 0;
  if (!thoughtRelapse && (surfed || watchMark)) watch = 1;

  return {
    clear: bodyRelapse ? 0 : 1,
    watch,
    prayer,
    word: Math.min(1, (scripture ? 0.7 : 0) + (verse ? 0.3 : 0)),
  };
}

function recent(events, kind, map, limit = 10) {
  return events
    .filter((e) => e.kind === kind)
    .slice()
    .sort((a, b) => String(b.at || '').localeCompare(String(a.at || '')))
    .slice(0, limit)
    .map(map);
}

function derive(documents, options = {}) {
  const today = options.today;
  const docs = Array.isArray(documents) ? documents : [];
  const profile = profileFrom(docs);
  const events = eventsFrom(docs);
  const eventsToday = events.filter((e) => e.day === today);
  const journeyStart = typeof profile.journeyStart === 'string' ? profile.journeyStart : null;

  const pornDays = events.filter((e) => e.kind === 'relapse' && e.type === 'pornography').map((e) => e.day);
  const mastDays = events.filter((e) => e.kind === 'relapse' && e.type === 'masturbation').map((e) => e.day);
  const thoughtDays = events.filter((e) => e.kind === 'relapse' && e.type === 'thought').map((e) => e.day);
  const clearDays = events
    .filter((e) => e.kind === 'relapse' && (e.type === 'pornography' || e.type === 'masturbation'))
    .map((e) => e.day);

  const streaks = {
    clear: streakAsOf(clearDays, today, journeyStart),
    pornography: streakAsOf(pornDays, today, journeyStart),
    masturbation: streakAsOf(mastDays, today, journeyStart),
    watch: streakAsOf(thoughtDays, today, journeyStart),
  };

  const rings = ringsFor(eventsToday);
  const hoursPerDay = Number(profile.hoursPerDay);
  const perDay = Number.isFinite(hoursPerDay) ? hoursPerDay : 1;
  const hours = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
  const weekdays = [0, 0, 0, 0, 0, 0, 0];
  for (const event of events) {
    if (event.kind !== 'relapse' && event.kind !== 'urge') continue;
    const hour = Number(event.hour);
    const weekday = Number(event.weekday);
    if (Number.isInteger(hour) && hour >= 0 && hour <= 23) hours[hour] += 1;
    if (Number.isInteger(weekday) && weekday >= 0 && weekday <= 6) weekdays[weekday] += 1;
  }
  let busiestHour = null;
  let busiestCount = 0;
  hours.forEach((count, hour) => {
    if (count > busiestCount) {
      busiestCount = count;
      busiestHour = hour;
    }
  });

  const reached = MILESTONES.filter((day) => streaks.clear >= day);

  return {
    today,
    profile,
    plans: plansFrom(docs),
    streaks,
    rings,
    fullDay: rings.clear === 1 && rings.watch === 1 && rings.prayer === 1 && rings.word === 1,
    tree: { ...treeStage(streaks.clear), days: streaks.clear },
    hoursReclaimed: Math.round(streaks.clear * perDay * 10) / 10,
    milestones: reached,
    nextMilestone: MILESTONES.find((day) => day > streaks.clear) ?? null,
    danger: { hours, weekdays, busiestHour },
    recentRelapses: recent(events, 'relapse', (e) => ({
      day: e.day, at: e.at || null, type: e.type || null, trigger: e.trigger || null, note: e.note || null,
    })),
    recentUrges: recent(events, 'urge', (e) => ({
      day: e.day, at: e.at || null, outcome: e.outcome || null, note: e.note || null, activity: e.activity || null,
    })),
    recentExamens: recent(events, 'examen', (e) => ({
      day: e.day, at: e.at || null, how: e.how || null, resolve: e.resolve || null,
    })),
    todayPractice: {
      intention: eventsToday.some((e) => e.kind === 'prayer' && e.form === 'intention'),
      scripture: eventsToday.some((e) => e.kind === 'scripture'),
      examen: eventsToday.some((e) => e.kind === 'examen'),
      surfed: eventsToday.some((e) => e.kind === 'urge' && e.outcome === 'surfed'),
      vigil: eventsToday.some((e) => e.kind === 'prayer' && e.form === 'vigil'),
      relapse: eventsToday.some((e) => e.kind === 'relapse' && (e.type === 'pornography' || e.type === 'masturbation')),
    },
  };
}

function projectPublic(derived) {
  const profile = derived.profile || {};
  const out = {
    today: derived.today,
    tree: derived.tree,
  };
  if (profile.shareRings !== false) out.rings = derived.rings;
  if (profile.shareStreaks !== false) {
    out.streaks = derived.streaks;
    out.hoursReclaimed = derived.hoursReclaimed;
    out.milestones = derived.milestones;
  }
  if (profile.shareMission === true && profile.mission) out.mission = String(profile.mission);
  if (profile.shareRelapses === true) out.relapses = derived.recentRelapses;
  if (profile.shareUrges === true) out.urges = derived.recentUrges;
  if (profile.shareExamens === true) out.examens = derived.recentExamens;
  return out;
}

module.exports = {
  MILESTONES,
  parseDay,
  addDays,
  daysBetween,
  streakAsOf,
  ringsFor,
  treeStage,
  derive,
  projectPublic,
};
