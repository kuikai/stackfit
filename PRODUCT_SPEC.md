# FitTimer / StackFit – Product Spec (MVP)

**App name:** StackFit  
**Package name:** `com.yourname.stackfit`  
**Platform:** Android + iOS (Flutter)  
**Monetization:** Free limited + $1.99 one-time Pro (RevenueCat)  
**Style:** Clean, minimal, Material 3, offline-first

---

## 1. Core Concept

A simple workout timer app where the user can create custom workouts that mix:

- **Timer-based** exercises (e.g. Plank 45s work / 15s rest × N rounds)
- **Set-based** exercises (e.g. Deadlift – 4 sets × 8 reps + rest)

The app also includes a built-in **Exercise Catalog** so users can quickly add common exercises instead of typing everything.

---

## 2. Acceptance Criteria

### 2.1 Exercise Catalog
- App ships with a pre-loaded catalog of common exercises
- Exercises are grouped by category (Strength, Bodyweight, Cardio, Core, etc.)
- User can search the catalog
- User can add any catalog exercise to a workout
- User can still create fully custom exercises (not from catalog)
- Catalog works fully offline

### 2.2 Creating / Editing a Workout
- User can create a new workout (give it a name)
- User can add exercises from catalog or create custom ones
- Large, easy-to-tap **Add exercise** and **Save workout** buttons (bottom of screen)
- Each exercise must be one of two types:

  **Timer Exercise**
  - Name
  - Work time (seconds)
  - Rest time (seconds)
  - **Sets / rounds** (number of work→rest cycles)

  **Set Exercise**
  - Name
  - Number of sets (required)
  - Reps (optional)
  - Rest between sets (seconds)

- User can reorder exercises
- User can delete exercises
- User can edit an existing workout

### 2.3 Running a Workout
- Clear header showing: Workout name + “Exercise X of Y”
- Tap a workout on Home to start; Edit via the workout menu
- **Timer exercise flow:**
  - Big countdown for work time
  - Automatically switches to rest countdown
  - Clear “WORK” / “REST” label
  - Supports multiple rounds (“Set X of Y”); repeats work→rest
  - No rest after the final round
- **Set exercise flow:**
  - Shows “Set 2 of 4” + reps (if set)
  - Big “Done / Next Set” button
  - After tapping → rest timer starts
- Rest timer behavior:
  - User can skip rest at any time (button, no popup)
  - If not skipped, timer runs and plays alarm/haptic when finished
- Global controls always available (**no confirmation popups** — keep the flow uninterrupted):
  - Pause / Resume
  - Skip current interval or set
  - **Reset** — restarts the whole workout from the first exercise
  - Stop entire workout (exits immediately)
- When last exercise finishes → “Workout Complete” screen + sound

### 2.4 Free vs Pro
**Free**
- Maximum 3 custom workouts
- Can run the 3 workouts unlimited times
- Basic history (last 10 sessions)

**Pro ($1.99 one-time)**
- Unlimited custom workouts
- Full history
- Duplicate workout
- Restore Purchase always available

### 2.5 Other Requirements
- Offline-first (all data in shared_preferences)
- Light + Dark + System theme
- Clean minimal Material 3 UI
- History screen (list of completed workouts with date + duration)
- Settings screen (theme toggle + Restore Purchase)
- Keep screen awake during active workout
- Sound + haptic when work ends, rest ends, and workout completes
- Cannot save a workout with 0 exercises
- Confirmation when deleting a workout
- Empty state on Home when no workouts
- Same architecture as other apps:
  - Riverpod
  - shared_preferences
  - purchases_flutter (RevenueCat)
  - flutter_local_notifications (ready for future)
  - Folder structure: `core / models / providers / services / screens / widgets`

---

## 3. Main Screens

1. Home (list of my workouts + “Create Workout” button)
2. Create / Edit Workout
3. Exercise Catalog (search + categories)
4. Active Timer screen
5. Workout Complete
6. History
7. Settings

---

## 4. Out of Scope for MVP
- Social features
- Video demonstrations
- Apple Watch / Wear OS
- Advanced statistics / charts
- Cloud sync
- Subscriptions

---

## 5. Success Criteria for MVP
- User can create a mixed timer + set workout in under 60 seconds
- User can run the full workout without confusion
- Rest timer can be skipped or used as an alarm
- Reset returns the run to the start without dialogs blocking the flow
- Free limit of 3 workouts is clear and fair
- App feels fast, clean and reliable offline
