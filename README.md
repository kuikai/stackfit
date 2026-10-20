# StackFit

**Custom workouts. Clean timers.**

StackFit is an offline-first Flutter app for building and running mixed workout timers — timer rounds (work/rest) and set-based exercises in one flow.

## Features

- **Exercise catalog** — Strength, Bodyweight, Core, and Cardio with search and category filters
- **Workout builder** — Create, edit, reorder, and customize exercises (timer or sets)
- **Plan library** — Ready-made plans to start from: gym splits (5x5, Push/Pull/Legs, Upper/Lower, Bro Split), home HIIT, core, kettlebell, calisthenics, Couch to 5K, running speed work, swimming, cycling, rowing, boxing, jump rope, soccer conditioning, a triathlon brick, and mobility. Browsing is free; starting a plan session or adding a plan to your workouts is Pro
- **Active timer** — Work/rest countdowns, set tracking, pause, skip, reset; screen stays awake
- **History** — Completed sessions with date, duration, and exercise count
- **Themes & skins** — Light / Dark / System plus skins (Classic, Midnight, Forest, Sunset, Minimal, Synthwave, Bold Sports, Chibi, Cyberpunk, Dumbbell)
- **Free & Pro** — Free tier: 3 workouts and recent history; Pro unlocks unlimited workouts, full history, duplicate, and the plan library (in-app purchase wiring coming soon)

## Screenshots

*Coming soon — run the app locally to try it.*

## Requirements

- [Flutter](https://docs.flutter.dev/get-started/install) (stable; Dart SDK `^3.12.2`)
- Android Studio / Xcode (or Windows desktop) for your target platform

## Getting started

```bash
flutter pub get
flutter run
```

Workouts, history, and appearance are stored on the device with `shared_preferences`. The app works with no account.

To keep that data on an account (and open it on another device pointed at the same server), start the local account server first:

```bash
cd server
dart pub get
dart run bin/server.dart
```

Then create an account or sign in from Settings, or open the website at `http://127.0.0.1:8787`. The server listens on that address. Password reset codes print in the server window. Email delivery is not connected yet.

The website uses the same account. You can sign in, edit workouts, log a finished session, and share a workout or a progress summary by link. Someone with the link can open it without an account and save a copy of the workout. The app picks up those changes the next time it syncs.

Another device on the same network can use `--dart-define=STACKFIT_ACCOUNT_URL=http://YOUR_PC_IP:8787`.

## Tech stack

| Layer | Choice |
|-------|--------|
| Framework | Flutter / Dart |
| State | Riverpod |
| Storage | shared_preferences, local account server |
| Fonts | Google Fonts (Plus Jakarta Sans) |
| Other | wakelock_plus |

## Project layout

```
lib/           # Flutter app (workouts, timer, account sync)
server/        # account API used by the app and the website
website/       # browser site served by the account server
```

[GUIDE.md](GUIDE.md) has diagrams of how the three parts talk to each other and a one-line description of every file.

## License

MIT — see [LICENSE](LICENSE).
