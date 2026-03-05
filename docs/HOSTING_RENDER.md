# How to set up the Purity Help server on Render

This guide walks through hosting the **optional** Purity Help backend on [Render](https://render.com). The iOS app works **fully offline** without any server. The backend is only used when users turn on **Sync to cloud** or use **Share with partner** in Settings.

---

## What you’ll have when done

- A **PostgreSQL** database on Render (stores users, sync payloads, share tokens).
- A **Web Service** (Node.js) that serves the API (auth, sync, share).
- A public HTTPS URL (e.g. `https://purity-helper-api.onrender.com`) that you enter in the app under **Settings → Cloud sync → API base URL**.

---

## Prerequisites

- A [Render](https://render.com) account (free tier is enough to start).
- This repo (or at least the `backend/` folder and `docs/` for the schema).
- Node.js 18+ (only if you want to run the backend locally for testing).

---

## Step 1: Create a PostgreSQL database on Render

1. Log in at [dashboard.render.com](https://dashboard.render.com).
2. Click **New +** → **PostgreSQL**.
3. Configure:
   - **Name**: e.g. `purity-help-db`.
   - **Region**: Choose one close to you (and to where you’ll deploy the API).
   - **PostgreSQL version**: Default is fine.
   - **Databases / User**: Default is fine.
4. Click **Create Database**.
5. Wait until the instance is **Available**.
6. Open the database and go to the **Info** tab.
7. Copy **Internal Database URL** (use this when the API runs on Render).  



   If you ever run the API outside Render, use **External Database URL** instead.  
   It looks like: `postgres://user:password@hostname/database?options`

Keep this URL secret; you’ll add it as `DATABASE_URL` in the next steps.

---

## Step 2: Run the database schema

**Great news!** You don't have to do anything for this step anymore. 

When you deploy the Web Service in Step 3, the server will automatically check if your database is empty. If it is, the server will automatically read the `backend/schema.sql` file and set up all the required tables (`users`, `sync_data`, `share_tokens`) for you on its first boot!

---

## Step 3: Create the Web Service (API) on Render

1. In the Render dashboard, click **New +** → **Web Service**.
2. **Connect repository**:
   - If the app repo is on GitHub/GitLab: connect the repo and select it.
   - Otherwise you’ll need to push the `backend/` code to a repo Render can access.
3. Configure the service:

   | Field | Value |
   |-------|--------|
   | **Name** | e.g. `purity-helper-api` |
   | **Region** | Same as (or near) your PostgreSQL for lower latency. |
   | **Root Directory** | `backend` — **important**: set this if your repo root is the iOS app. Leave blank if the repo root is already the backend. |
   | **Runtime** | Node |
   | **Build Command** | `npm install` |
   | **Start Command** | `npm start` |
   | **Instance Type** | Free (or paid if you want no cold starts). |

4. **Environment variables** (Add → Environment Variable):

   | Key | Value | Notes |
   |----|--------|--------|
   | `DATABASE_URL` | *(paste Internal Database URL from Step 1)* | Required. From PostgreSQL service → Info → Internal Database URL. |
   | `API_SECRET` | Long random string | Required. Use e.g. `openssl rand -hex 32` and paste the result. **Keep secret**; used to sign JWTs. |
   | `BASE_URL` | `https://YOUR-SERVICE-NAME.onrender.com` | Required for share links. Replace with your **actual** Web Service URL (no trailing slash). You can set this after first deploy (see below). |
   | `PORT` | *(leave empty)* | Render sets this automatically; the server uses `process.env.PORT` or 10000. |

5. Click **Create Web Service**. Render will clone the repo, run `npm install` in `backend/`, then `npm start`.

6. After the first deploy, note the service URL (e.g. `https://purity-helper-api.onrender.com`). If you didn’t set `BASE_URL` yet, go to **Environment** → edit `BASE_URL` → set it to that URL (no trailing slash) → Save. Redeploy if needed.

---

## Step 4: Check that the API is running

1. In the Web Service page, open the **Logs** tab and confirm the server started (e.g. “Listening on port 10000” or the port Render assigned).
2. Open in a browser or with `curl`:

   ```bash
   curl https://purity-helper-api.onrender.com/health
   ```

   You should see: `{"ok":true}`.

If you get 503 or connection errors, wait a minute (free tier may be spinning up) and check Logs for errors (e.g. missing `DATABASE_URL` or `API_SECRET`).

---

## Step 5: Configure the iOS app

1. On the device or simulator, open **Purity Help** → **Settings** → **Cloud sync (optional)**.
2. Turn **Sync to cloud** on.
3. In **API base URL**, enter your Web Service URL **with no trailing slash**, e.g.:
   - `https://purity-helper-api.onrender.com`
4. Save. The app will use `{baseUrl}/sync`, `{baseUrl}/me`, `{baseUrl}/share`, and the auth endpoints.

Users can optionally **Create account / Log in** so their data can be restored after reinstall via **GET /me**.

---

## API endpoints (reference)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | /health | — | Health check; returns `{ "ok": true }`. |
| POST | /auth/signup | — | Body: `{ "email", "password" }` (password min 8 chars). Returns `{ "token", "userId" }`. |
| POST | /auth/login | — | Body: `{ "email", "password" }`. Returns `{ "token", "userId" }`. |
| POST | /sync | Bearer token or body `deviceId` | Body: `{ "deviceId"? , "payload": { ... } }`. Upserts sync data for the user or device. |
| GET | /me | Bearer | Returns `{ "payload": { ... } }` for the current user (account recovery). |
| POST | /share | Bearer | Creates or refreshes share token; returns `{ "token", "link" }`. `BASE_URL` is used to build the link. |
| GET | /share/:token | — | Read-only summary. HTML in browser; JSON if `Accept: application/json` or `?format=json`. |

---

## Security notes

- **Secrets**: Never put `DATABASE_URL`, `API_SECRET`, or real passwords in the app binary or in git. Use Render environment variables only.
- **Passwords**: The server hashes passwords with bcrypt; it never stores or logs plaintext passwords.
- **Auth**: The app should send the JWT in `Authorization: Bearer <token>` and store the token in the **Keychain**, not UserDefaults.
- **Share links**: Long-lived UUID tokens; users can regenerate so old links stop working.
- **HTTPS**: Use Render’s default HTTPS URL as the API base in the app.

---

## Troubleshooting

- **“Sync failed” / 401 in app**  
  - Check **API base URL** (no trailing slash, correct host).  
  - If using an account, ensure the app stored the token and sends `Authorization: Bearer <token>`.

- **503 or “Service Unavailable”**  
  - Free tier services spin down after inactivity; first request may take 30–60 seconds.  
  - Check **Logs** for crashes (e.g. missing env vars, DB connection errors).

- **Database connection errors in Logs**  
  - Confirm `DATABASE_URL` is the **Internal** URL when the API runs on Render.  
  - Ensure the database string is correct. You do not need to apply the schema manually; check the Web Service logs to see if it says "Initializing schema..." during boot.

- **“Email already registered” (409)**  
  - Normal for signup with an existing email; use login instead.

- **Share link returns 404 or wrong host**  
  - Set `BASE_URL` to the exact Web Service URL (e.g. `https://purity-helper-api.onrender.com`) and redeploy.

---

## Summary checklist

- [ ] PostgreSQL created on Render; **Internal Database URL** copied.
- [ ] Web Service created; **Root Directory** = `backend` (if repo root is the app).
- [ ] Env vars set: `DATABASE_URL`, `API_SECRET`, `BASE_URL` (and optionally leave `PORT` unset).
- [ ] Deploy succeeded; verify server logs say "Schema initialized successfully" or "Skipping schema initialization".
- [ ] App **Settings → Cloud sync** has the correct **API base URL** (no trailing slash).

After that, users can enable sync and optionally create an account; data is stored in your Render PostgreSQL and can be shared via the share link.
