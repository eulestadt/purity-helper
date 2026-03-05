# Purity Help

iOS 26 recovery app: zero pornography, zero masturbation, journey toward a pure heart (Mt 5:8).

## Requirements

- Xcode 26 (or later)
- iOS 26.0+ (Simulator or device)

## Build and run

1. Open `PurityHelp.xcodeproj` in Xcode.
2. Select an iOS Simulator (e.g. iPhone 17) or a device.
3. Run (⌘R).

To regenerate the Xcode project from the spec:

```bash
xcodegen generate
```

## Features (from plan)

- **Streak tracking**: Pornography, masturbation, optional pure thoughts ("days guarding thoughts") with compassionate reset and optional streak freeze.
- **Seedling → tree**: Growth visualization by days of purity (Seedling, Sprout, Sapling, Young tree, Mature tree).
- **Urge Moment**: Theosis framing, 4-4-8 breathing, 10-minute delay, urge surfing guide, replace activity, if-then plan reminder, Stories of Hope link.
- **Daily Examen**: 5-step Jesuit Examen with journaling.
- **Mission / Why**: Personal mission shown on Home and at top of Urge Moment.
- **Hours reclaimed**: Configurable daily estimate and running total.
- **If–Then plans**: Implementation intentions; reminder in Urge Moment.
- **Danger zone**: Pattern insights from reset history.
- **Spiritual**: Daily Scripture, Wisdom of the Ages (Kempis, Bunyan, Lewis, Augustine, Francis de Sales), sacrament reminder toggle.
- **Stories of Hope**: Curated recovery examples (historical and modern).
- **Shareable progress**: Read-only summary and export for accountability partner.
- **Liquid Glass**: `.glassEffect()` on key cards (iOS 26).
- **Milestone celebrations**: 3, 7, 14, 30, 90 days.

All data is stored locally (SwiftData). No account required.

## Optional backend (Render)

For **optional** cloud sync and shareable progress links (e.g. for accountability partners), a small Node.js + PostgreSQL API is included. The app works fully without it.

- **Backend**: `backend/` — Express server; endpoints: `POST /sync`, `GET /me`, `POST /share`, `GET /share/:token`, `POST /auth/signup`, `POST /auth/login`.
- **Hosting**: See [docs/HOSTING_RENDER.md](docs/HOSTING_RENDER.md) for creating a PostgreSQL database and Web Service on Render, setting `DATABASE_URL`, `API_SECRET`, and `BASE_URL`, and running the schema.
- **Security**: Passwords hashed with bcrypt; JWT for auth; store tokens in Keychain in the app; share links use UUID tokens with optional "Regenerate link."
