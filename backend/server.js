/**
 * Purity Help API.
 * Event sync, account pages, and share links.
 * Env: DATABASE_URL, API_SECRET, BASE_URL, PORT,
 *      SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, MAIL_FROM, MAIL_MODE.
 */

const { createApp } = require('./src/app');
const { PgStore } = require('./src/pg-store');

async function main() {
  const store = PgStore.fromEnv();
  if (!store) {
    console.error('DATABASE_URL is required');
    process.exit(1);
  }
  try {
    await store.migrate();
    console.log('Schema ready');
  } catch (error) {
    console.error('Schema migration failed:', error.message);
    process.exit(1);
  }
  if (!process.env.API_SECRET) console.warn('API_SECRET is not set; set a long random value on Railway');
  const port = Number(process.env.PORT || 10000);
  const app = createApp(store);
  app.listen(port, () => console.log(`Purity Help API listening on ${port}`));
}

if (require.main === module) main();

module.exports = { main };
