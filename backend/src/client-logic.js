/**
 * Device-side sync state. The server is authoritative.
 * Optimistic edits live in `pending` and are replayed after every pull.
 */

function clone(value) {
  return value == null ? value : JSON.parse(JSON.stringify(value));
}

function createLocal(clientId) {
  return {
    clientId,
    cookie: 0,
    nextId: 1,
    serverDocs: new Map(),
    docs: new Map(),
    pending: [],
  };
}

function applyMutation(docs, mutation) {
  if (mutation.name === 'put') {
    docs.set(mutation.args.key, { value: clone(mutation.args.value), deleted: false });
  } else if (mutation.name === 'del') {
    docs.set(mutation.args.key, { value: null, deleted: true });
  }
}

function rebuild(local) {
  local.docs = new Map(local.serverDocs);
  for (const mutation of local.pending) applyMutation(local.docs, mutation);
}

function put(local, key, value) {
  const mutation = { id: local.nextId++, name: 'put', args: { key, value: clone(value) } };
  local.pending.push(mutation);
  applyMutation(local.docs, mutation);
  return mutation;
}

function del(local, key) {
  const mutation = { id: local.nextId++, name: 'del', args: { key } };
  local.pending.push(mutation);
  applyMutation(local.docs, mutation);
  return mutation;
}

function ingestPull(local, pull) {
  const ids = pull.lastMutationIDs || {};
  const acked = Number(ids[local.clientId] || 0);
  local.pending = local.pending.filter((mutation) => mutation.id > acked);
  for (const op of pull.patch || []) {
    if (op.op === 'del') local.serverDocs.set(op.key, { value: null, deleted: true });
    else local.serverDocs.set(op.key, { value: clone(op.value), deleted: false });
  }
  local.cookie = Number(pull.cookie || 0);
  rebuild(local);
}

function documents(local) {
  return [...local.docs.entries()].map(([key, doc]) => ({
    key,
    value: doc.value,
    deleted: doc.deleted,
  }));
}

module.exports = { createLocal, put, del, ingestPull, documents, rebuild };
