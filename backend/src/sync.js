const { HttpError } = require('./errors');

const KEY_RE = /^(profile|event\/[A-Za-z0-9_-]{8,80}|plan\/[A-Za-z0-9_-]{8,80}|verse\/[A-Za-z0-9_-]{8,80})$/;
const CLIENT_RE = /^[A-Za-z0-9_-]{8,80}$/;

function cleanValue(value) {
  if (value == null || typeof value !== 'object' || Array.isArray(value)) {
    throw new HttpError(400, 'Document value must be an object');
  }
  let cloned;
  try {
    cloned = JSON.parse(JSON.stringify(value));
  } catch {
    throw new HttpError(400, 'Document value is not JSON');
  }
  if (cloned == null || typeof cloned !== 'object' || Array.isArray(cloned)) {
    throw new HttpError(400, 'Document value must be an object');
  }
  if (JSON.stringify(cloned).length > 20000) throw new HttpError(413, 'Document too large');
  return cloned;
}

async function push(store, userId, clientId, mutations) {
  if (!CLIENT_RE.test(clientId || '')) throw new HttpError(400, 'Invalid client id');
  if (!Array.isArray(mutations) || mutations.length > 100) {
    throw new HttpError(400, 'Mutations must be an array of at most 100');
  }

  return store.transaction(async (tx) => {
    await tx.ensureVersion(userId);
    let last = await tx.getLastMutation(userId, clientId);
    let version = await tx.getVersion(userId);

    for (const mutation of mutations) {
      const id = mutation && mutation.id;
      if (!Number.isInteger(id) || id <= 0) throw new HttpError(400, 'Mutation id must be a positive integer');
      if (id <= last) continue;
      if (id !== last + 1) {
        throw new HttpError(409, 'Mutation id gap', { expected: last + 1 });
      }
      const name = mutation.name;
      const args = mutation.args || {};
      if (name !== 'put' && name !== 'del') throw new HttpError(400, 'Unknown mutation');
      const key = args.key;
      if (typeof key !== 'string' || !KEY_RE.test(key)) throw new HttpError(400, 'Invalid document key');

      version += 1;
      if (name === 'del') {
        await tx.putDoc(userId, key, null, true, version);
        await tx.addChange(userId, version, key, null, true);
      } else {
        const value = cleanValue(args.value);
        await tx.putDoc(userId, key, value, false, version);
        await tx.addChange(userId, version, key, value, false);
      }
      last = id;
    }

    await tx.setLastMutation(userId, clientId, last);
    await tx.setVersion(userId, version);
    return { lastMutationId: last, cookie: version };
  });
}

async function pull(store, userId, clientId, cookie) {
  if (!CLIENT_RE.test(clientId || '')) throw new HttpError(400, 'Invalid client id');
  const since = Number(cookie);
  return store.transaction(async (tx) => {
    await tx.ensureVersion(userId);
    await tx.ensureClient(userId, clientId);
    const version = await tx.getVersion(userId);
    const rows = !Number.isFinite(since) || since <= 0
      ? await tx.allDocs(userId)
      : await tx.changesSince(userId, since);
    const patch = rows.map((row) => (
      row.deleted
        ? { op: 'del', key: row.key }
        : { op: 'put', key: row.key, value: row.value }
    ));
    const lastMutationIDs = await tx.clientMap(userId);
    return { cookie: version, lastMutationIDs, patch };
  });
}

module.exports = { push, pull, KEY_RE, CLIENT_RE };
