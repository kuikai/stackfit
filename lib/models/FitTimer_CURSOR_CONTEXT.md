# FitTimer – Cursor Context & Rules

You are helping build **FitTimer**, a simple Flutter fitness/workout timer app for Android + iOS.

Follow these rules strictly.

---

## 1. Project Overview

**FitTimer** lets users create custom workouts that mix two types of exercises:

- **Timer-based** (e.g. Plank 45s work / 15s rest)
- **Set-based** (e.g. Deadlift – 4 sets × 8 reps + rest between sets)

Features:
- Built-in offline Exercise Catalog
- Rest timer that can be skipped (but alarms if not skipped)
- Free: max 3 custom workouts
- Pro: $1.99 one-time unlock → unlimited workouts + full history + duplicate
- Offline-first
- Clean, minimal Material 3 UI
- Light + Dark mode

**Package name:** `com.yourname.fittimer`

---

## 2. Tech Stack (mandatory)

- Flutter + Material 3
- Riverpod (state management)
- shared_preferences (local storage)
- purchases_flutter (RevenueCat)
- flutter_local_notifications (ready for later)
- Offline-first

**Never** use subscriptions. Only one-time $1.99 purchase.

---

## 3. Folder Structure (mandatory)

```
lib/
├── core/               # constants, theme, utils, router
├── models/             # already created
├── providers/          # Riverpod providers
├── services/           # storage, revenuecat, notifications, sound
├── screens/
└── widgets/
```

---

## 4. Data Models (already exist)

Located in `lib/models/`:

- `ExerciseType` (enum: timer, sets)
- `Exercise` (supports both timer and sets, reps optional)
- `Workout`
- `CatalogExercise` + `ExerciseCatalog` (27 common exercises)
- `CompletedSession` (history)

Import with:
```dart
import 'package:fittimer/models/models.dart';
```

### Key model rules:
- Timer exercise → `workSeconds` + `restSeconds` + `sets` (rounds, default 1)
- Set exercise → `sets` (required) + `reps` (optional) + `restSeconds`
- All models are JSON serializable
- Use the factory constructors: `Exercise.timer(...)` and `Exercise.sets(...)`

---

## 5. Acceptance Criteria (must implement)

### Exercise Catalog
- Pre-loaded offline catalog with categories: Strength, Bodyweight, Core, Cardio
- Searchable
- User can add catalog exercises to a workout
- User can also create fully custom exercises

### Create / Edit Workout
- Name the workout
- Add exercises (from catalog or custom)
- Choose type: Timer or Sets
- Timer exercises include **sets/rounds**
- Large bottom **Add** / **Save** buttons (easy tap targets)
- Reorder exercises
- Delete exercises

### Running a Workout
- Show “Exercise X of Y”
- **Timer exercise**: automatic work countdown → rest countdown; multi-round support
- **Set exercise**: show “Set 2 of 4 – 8 reps” + big “Done / Next Set” button
- After set → rest timer starts
- User can **skip rest** at any time (no popup)
- If rest is not skipped → play alarm/sound when rest finishes
- Global controls: Pause / Resume / Skip / **Reset** (restart from beginning) / Stop
- **No confirmation popups** on Reset/Stop during an active run — keep flow uninterrupted
- Workout Complete screen when finished

### Free vs Pro
- Free: maximum **3** custom workouts
- Pro ($1.99 one-time): unlimited + full history + duplicate workout
- Restore Purchase must always be available in Settings

### Other
- Light + Dark + System theme
- History of completed sessions
- Everything works offline

---

## 6. Monetization Rules (strict)

- Free trial with hard limit of 3 workouts
- One-time unlock for $1.99 via RevenueCat
- No subscriptions ever
- Always show “Restore Purchase”

---

## 7. UI Style

- Extremely clean and minimal
- Big readable numbers on the timer screen
- Clear “WORK” / “REST” labels
- Material 3
- Prefer large tap targets
- Avoid clutter
- Prefer inline actions over interruptive dialogs in the active timer flow

---

## 8. Current Progress

- Product Spec + Acceptance Criteria updated for StackFit
- Models, storage, providers, Home, Editor, Catalog, Active Timer, Complete, History, Settings are in
- See project root: [`ACCEPTANCE_CRITERIA.md`](../../ACCEPTANCE_CRITERIA.md)
- Next recommended steps:
  1. Wire RevenueCat (`purchases_flutter`) for real Pro purchase + restore
  2. Optional custom sound assets

---

## 9. Coding Rules for Cursor

- Always use Riverpod
- Prefer `ConsumerWidget` / `ConsumerStatefulWidget`
- Keep business logic in providers/services, not in widgets
- Use the existing models – do not reinvent them
- Make everything offline-first
- Keep UI simple and consistent with Material 3
- When in doubt, choose the simpler solution

---

## 10. Out of Scope (do not build yet)

- Cloud sync
- Social features
- Video demos
- Apple Watch / Wear OS
- Advanced charts/stats
- Subscriptions
