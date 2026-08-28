# Vestaboard Smart Home Display

[![CI](https://github.com/OWNER/REPO/actions/workflows/ci.yml/badge.svg)](https://github.com/OWNER/REPO/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A self-updating [Vestaboard Note](https://www.vestaboard.com/) display for the kitchen. A single Node.js process decides what to show based on the time of day and your calendar — no manual switching required.

- **Upcoming events** — when a calendar event starts within the next hour, the board shows the start time and an AI-shortened event name.
- **Morning weather** — between 7–8 AM, the board shows your local temperature and conditions.
- **Idle / default** — the rest of the day it shows a friendly message with the weekday and date.

```
   KITCHEN IS THE
   ♥ OF THE HOME
   THU 08/28/2026
```

## How it works

`board.js` runs a one-minute loop that selects a board by priority:

| Priority | Mode    | Condition                                      | Shows                              |
| -------- | ------- | ---------------------------------------------- | ---------------------------------- |
| 1        | Event   | A calendar event starts within the next 60 min | Start time + shortened event name  |
| 2        | Weather | Local time is between 7:00 and 8:00 AM         | City, temperature, conditions      |
| 3        | Default | Otherwise                                      | Kitchen message + weekday and date |

The board is only pushed when the layout actually changes, so the Vestaboard API is never spammed.

Two small Swift helpers provide native macOS integration:

- **`get-events`** reads upcoming events from the macOS Calendar via EventKit.
- **`summarize`** uses Apple's on-device Foundation Models to shorten event names to the 9-character display (e.g. `"Om Taekwondo"` → `TAEKWONDO`). If the model is unavailable, it falls back to truncation.

## Requirements

- macOS 14+ (Sonoma or later) — required for EventKit full access and, for event summarization, Apple Foundation Models (macOS 15.1+ on Apple Silicon).
- [Node.js](https://nodejs.org/) 22+ (LTS; uses the built-in `fetch`).
- Xcode command line tools (`swiftc`, `codesign`) — to build the Swift helpers.
- A Vestaboard with a [Cloud API token](https://docs.vestaboard.com/).

## Setup

1. **Clone and install dependencies:**

   ```sh
   git clone <your-repo-url>
   cd vestaboard
   npm install
   ```

2. **Configure environment variables:**

   ```sh
   cp .env.example .env
   ```

   Edit `.env`:

   | Variable           | Required | Description                                                              |
   | ------------------ | -------- | ------------------------------------------------------------------------ |
   | `VESTABOARD_TOKEN` | Yes      | Vestaboard Cloud API token (Settings in the mobile app or web app).      |
   | `ZIP_CODE`         | No\*     | US ZIP code used for the weather location.                               |
   | `CITY`             | No\*     | City name used for the weather location (alternative to `ZIP_CODE`).     |
   | `CALENDAR_NAME`    | No       | Calendar name(s) to read events from. Comma-separated. Default `Family`. |

   \*If neither `ZIP_CODE` nor `CITY` is set, weather mode is skipped and the default display is shown instead.

3. **Build the Swift helpers:**

   ```sh
   npm run build:native
   ```

   This compiles `native/get-events` and `native/summarize`, and code-signs `get-events` with the Calendar entitlement.

4. **Grant Calendar access.** The first time `get-events` runs, macOS prompts for Calendar access for your terminal app. Approve it (or enable it under **System Settings → Privacy & Security → Calendars**).

## Usage

Run the display:

```sh
npm start
```

The process updates the board immediately, then re-evaluates every minute. Press `Ctrl+C` to stop.

### Run continuously

To keep the display running in the background, use a process manager such as [`pm2`](https://pm2.keymetrics.io/):

```sh
npm install -g pm2
pm2 start board.js --name vestaboard
pm2 save
pm2 startup   # follow the printed instructions to start on boot
```

## Configuration

Behavior is tuned via constants in [`src/config.js`](src/config.js):

| Constant               | Default  | Description                                             |
| ---------------------- | -------- | ------------------------------------------------------- |
| `EVENT_WINDOW_MINUTES` | `60`     | How soon an event must start to take over the board.    |
| `WEATHER_HOUR_START`   | `7`      | Hour (24h) when the weather window begins.              |
| `WEATHER_HOUR_END`     | `8`      | Hour (24h) when the weather window ends.                |
| `WEATHER_CACHE_MS`     | `30 min` | How long fetched weather stays fresh before refetching. |
| `UPDATE_INTERVAL_MS`   | `60 s`   | How often the board is re-evaluated.                    |

## Project structure

```
board.js              Main loop — selects and pushes a board each minute
src/
  config.js           Environment configuration and behavior constants
  display.js          Character encoding, row helpers, Vestaboard API client
  clock.js            Default idle board (message + weekday/date)
  weather.js          Weather board (Open-Meteo, with caching)
  calendar.js         Event board (EventKit + Foundation Models helpers)
native/
  get-events.swift    EventKit helper — reads upcoming calendar events
  summarize.swift     Foundation Models helper — shortens event names
  entitlements.plist  Calendar entitlement for the signed get-events binary
```

## Data sources

- **Weather** — [Open-Meteo](https://open-meteo.com/) (free, no API key required).
- **Calendar** — macOS Calendar via [EventKit](https://developer.apple.com/documentation/eventkit).
- **Event summaries** — Apple [Foundation Models](https://developer.apple.com/documentation/foundationmodels) (on-device).

## Development

The platform-independent logic lives in `src/` and is covered by unit tests that
run anywhere (no macOS or Vestaboard required).

```sh
npm test            # run the test suite (node --test)
npm run lint        # ESLint
npm run format      # Prettier (write)
npm run format:check
```

Continuous integration runs lint, format check, and tests on every push and pull
request across the supported Node.js LTS releases (22, 24) and the latest release
(see [`.github/workflows/ci.yml`](.github/workflows/ci.yml)).

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full workflow.

## Troubleshooting

- **`Calendar access denied`** — grant access under System Settings → Privacy & Security → Calendars, then rerun.
- **`No matching calendars found`** — ensure `CALENDAR_NAME` exactly matches a calendar title in the Calendar app.
- **Weather not showing at 7 AM** — confirm `ZIP_CODE` or `CITY` is set and that the location resolves.
- **Event names truncated instead of summarized** — the Foundation Models runtime may be unavailable; the helper falls back to truncation automatically.

## License

MIT
