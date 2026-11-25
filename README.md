# Purity Help

A recovery companion for a pure heart (Matthew 5:8): zero pornography, zero masturbation, and a day that also includes watchfulness, prayer, and Scripture.

The phone is the journal. Clear days, rings, and hours are calculated from events, so two devices cannot overwrite each other's counters.

## A full day

Four rings on Today:

- **Clear** stays whole until a pornography or masturbation relapse is recorded. The tree grows from consecutive clear days.
- **Watch** closes when an urge is surfed or the heart is deliberately guarded. An entertained thought opens it again.
- **Prayer** fills with a morning offering and closes with the evening examen.
- **Word** fills by reading the day's verse and reviewing it from memory.

An urge opens a pause: breathe, name the trigger, wait, answer with Scripture, then either let it pass or begin again without destroying the history.

## Run the iOS app

1. Open `PurityHelp.xcodeproj` in Xcode 26.
2. Choose an iPhone simulator or a device.
3. Run.

The app works with no account. Settings → Sync takes the Railway URL when you want another device or a partner link.

Old on-device SwiftData from version 1 is left behind. Version 2 opens a new store named `PurityHelpV2`.

## API

```bash
npm test
npm start
```

`npm start` expects `DATABASE_URL`. For the account pages on this machine without Postgres:

```bash
node backend/dev-server.js
```

Hosting steps are in [docs/HOSTING_RAILWAY.md](docs/HOSTING_RAILWAY.md).

Sync is push and pull of idempotent mutations (`POST /sync/push`, `POST /sync/pull`). A relapse, an urge, an examen, and a verse review are separate events. Replaying a mutation does not apply it twice.

## Share links

Rings and streaks are visible to a partner. Mission, relapses, urges, and examens stay off the link until those toggles are turned on in Settings or on the account page.
