# StackFit

**Custom workouts. Clean timers.**

StackFit is an offline-first Flutter app for building and running mixed workout timers — timer rounds (work/rest) and set-based exercises in one flow.

## Features

- **Exercise catalog** — Strength, Bodyweight, Core, and Cardio with search and category filters
- **Workout builder** — Create, edit, reorder, and customize exercises (timer or sets)
- **Active timer** — Work/rest countdowns, set tracking, pause, skip, reset; screen stays awake
- **History** — Completed sessions with date, duration, and exercise count
- **Themes & skins** — Light / Dark / System plus skins (Classic, Midnight, Forest, Sunset, Minimal, Synthwave)
- **Free & Pro** — Free tier: 3 workouts and recent history; Pro unlocks unlimited workouts, full history, and duplicate (in-app purchase wiring coming soon)

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

No API keys or backend setup required — data is stored on-device with `shared_preferences`.

## Tech stack

| Layer | Choice |
|-------|--------|
| Framework | Flutter / Dart |
| State | Riverpod |
| Storage | shared_preferences |
| Fonts | Google Fonts (Plus Jakarta Sans) |
| Other | wakelock_plus |

## Project layout

```
lib/
  core/        # theme, skins, constants
  models/      # workouts, exercises, sessions, settings
  providers/   # Riverpod state
  services/    # storage, sound, session controller
  screens/     # home, editor, timer, history, settings
  widgets/     # shared UI pieces
```

## License

MIT — see [LICENSE](LICENSE).
