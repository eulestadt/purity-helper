/**
 * Local account site with an in-memory journal. Not for production.
 * Usage: node dev-server.js
 */

const { createApp } = require('./src/app');
const { MemoryStore } = require('./src/memory-store');

const port = Number(process.env.PORT || 8787);
const app = createApp(new MemoryStore(), {
  secret: 'dev-only-secret',
  baseUrl: `http://127.0.0.1:${port}`,
});

app.listen(port, '127.0.0.1', () => {
  console.log(`Purity Help dev server at http://127.0.0.1:${port}`);
});
