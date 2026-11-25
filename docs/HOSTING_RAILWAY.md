# Host the Purity Help API on Railway

The iOS app keeps a full journal on the phone. Railway is only for sync, password reset, and the account and share pages.

## Services

1. A Postgres service. Railway injects `DATABASE_URL`.
2. This repo as a web service. The root `package.json` installs `backend/` and starts `node backend/server.js`. The schema is applied on boot.

## Variables

| Name | Purpose |
| --- | --- |
| `DATABASE_URL` | Provided by the Railway Postgres service. Use the private URL when both services are in the same project. |
| `API_SECRET` | Long random string used to sign login tokens. |
| `BASE_URL` | Public https origin of this service, with no trailing slash. Share links are built from it. |
| `MAIL_FROM` | From address, for example `Purity Help <you@your-domain>`. |
| `SMTP_HOST` | Your mailbox's SMTP host. Leave unset to write reset codes to the Railway logs instead of using a mail vendor. |
| `SMTP_PORT` | Usually `587`. |
| `SMTP_USER` / `SMTP_PASS` | SMTP submission credentials for a mailbox you control. |
| `SMTP_SECURE` | `true` only for port 465. |
| `MAIL_MODE` | `smtp` to send, or `log` to force the log fallback. |

SendGrid is not part of this service. If SMTP is unset, a reset code is printed in the service logs so the account can still be recovered.

## App setting

In the iOS app, Settings → Sync, set the base URL to `BASE_URL` and sign in with the same email as the website.
