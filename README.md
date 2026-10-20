# StackFit

**Custom workouts. Clean timers.**

StackFit is an offline-first Flutter app for building and running mixed workout timers — timer rounds (work/rest) and set-based exercises in one flow. An optional local server keeps that same data on an account, powers a website, and lets you share workouts by link.

## Features

### Phone app

- **Exercise catalog** — Strength, Bodyweight, Core, and Cardio with search and category filters
- **Workout builder** — Create, edit, reorder, and customize exercises (timer or sets)
- **Plan library** — Ready-made plans: gym splits (5x5, Push/Pull/Legs, Upper/Lower, Bro Split), home HIIT, core, kettlebell, calisthenics, Couch to 5K, running speed work, swimming, cycling, rowing, boxing, jump rope, soccer conditioning, a triathlon brick, and mobility. Browsing is free; starting a plan or adding it to your workouts is Pro
- **Active timer** — Work/rest countdowns, set tracking, pause, skip, reset; screen stays awake
- **History** — Completed sessions with date, duration, and exercise count
- **Themes & skins** — Light / Dark / System. Everyday skins: Classic, Midnight, Forest, Sunset, Minimal, Synthwave. Pro skins: Bold Sports, Chibi, Cyberpunk, Dumbbell
- **Free & Pro** — Free: 3 workouts and recent history. Pro: unlimited workouts, full history, duplicate, plan library, and Pro skins (store purchase wiring coming soon)

### Account, sync, and sharing

- **Optional account** — Sign up, sign in, sign out, and reset password from Settings. The timer still works with no account
- **Sync** — Workouts, history, theme, and skin save to the account and merge across devices pointed at the same server
- **Move device data** — On first sign-in, offer to move workouts already on the phone onto the account
- **Share by link** — Publish one workout or a progress summary. Anyone with the link can open it; signed-in users can add the workout to their own list

### Website

Served by the same local server (`http://127.0.0.1:8787`):

- Sign in with the same account as the phone
- Edit workouts and log a finished session by hand
- Run a workout or open the standalone Tabata timer (`/tabata`)
- Create and open share links (`/s/…`)

Phone and website stay in sync the next time the app uploads or downloads.

## Requirements

- [Flutter](https://docs.flutter.dev/get-started/install) (stable; Dart SDK `^3.12.2`)
- Android Studio / Xcode (or Windows desktop) for your target platform
- [Dart](https://dart.dev/get-dart) on the PATH if you run the account server

## Getting started

### App only (offline)

```bash
flutter pub get
flutter run
```

Workouts, history, and appearance are stored on the device with `shared_preferences`. No server required.

### App + account server + website

```bash
cd server
dart pub get
dart run bin/server.dart
```

Then:

1. Create an account or sign in from **Settings** in the app, **or** open `http://127.0.0.1:8787` in a browser
2. Password reset codes print in the server window (email delivery is not connected yet)
3. Point another device on the same network at your PC with:

```bash
flutter run --dart-define=STACKFIT_ACCOUNT_URL=http://YOUR_PC_IP:8787
```

## Tests

```bash
# phone app
flutter test

# account server + share routes + website serving
cd server
dart test
```

## Tech stack

| Layer | Choice |
|-------|--------|
| Phone app | Flutter / Dart, Riverpod |
| Storage (device) | shared_preferences |
| Account API | Dart (shelf), JSON files on disk |
| Website | Plain HTML + JavaScript |
| Fonts | Google Fonts (Plus Jakarta Sans) |
| Other | wakelock_plus, http |

## Project layout

```
lib/           # Flutter phone app (screens → providers → services → models)
server/        # Account + share API; also serves the website on :8787
website/       # Browser UI (library, editor, run, Tabata, share pages)
test/          # Flutter tests
GUIDE.md       # Diagrams and a one-line map of every file
NEXT_VERSION.md
SHARING_PLAN.md
```

[GUIDE.md](GUIDE.md) is the map of how the three parts talk to each other.

## License

MIT — see [LICENSE](LICENSE).
