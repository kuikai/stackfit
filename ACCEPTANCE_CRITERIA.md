# StackFit – Acceptance Criteria (MVP)

**App name:** StackFit  
**Package:** `com.yourname.stackfit`  
**Platform:** Android + iOS (+ Windows for local testing)  
**Monetization:** Free limited + $1.99 one-time Pro (RevenueCat — pending)  
**Style:** Clean, minimal Material 3, offline-first

---

## 1. Exercise Catalog

- [x] Pre-loaded offline catalog (Strength, Bodyweight, Core, Cardio)
- [x] Searchable
- [x] Category filter chips
- [x] Add catalog exercise into a workout (then configure timer/sets)
- [x] Create fully custom exercises (not from catalog)

## 2. Creating / Editing a Workout

- [x] Name the workout
- [x] Add exercises from catalog or custom
- [x] Reorder exercises (drag & drop)
- [x] Edit / delete exercises
- [x] Large bottom actions: **Add exercise** + **Save workout**
- [x] **Cannot save a workout with 0 exercises** (shows a simple message)

### Timer exercise
- [x] Name
- [x] Work time (seconds)
- [x] Rest time (seconds)
- [x] **Sets / rounds** (how many work→rest cycles)
- [x] Large bottom **Add exercise** / **Save** button on the exercise editor

### Set exercise
- [x] Name
- [x] Number of sets (required)
- [x] Reps (optional)
- [x] Rest between sets (seconds)

## 3. Running a Workout

- [x] Header: workout name + “Exercise X of Y”
- [x] Tap workout on Home to **Start**; Edit via menu
- [x] **Keep screen awake** while a workout is running

### Timer flow
- [x] Big countdown for WORK, then REST
- [x] Clear WORK / REST labels
- [x] If multiple rounds: show “Set X of Y” and repeat work→rest
- [x] No rest after the final round; then next exercise

### Set flow
- [x] “Set X of Y” + reps (if set)
- [x] Big **Done / Next Set** button
- [x] After set → rest timer (when rest > 0)

### Rest
- [x] **Skip rest** button (immediate — no popup)
- [x] If not skipped → sound + haptic when rest finishes

### Feedback
- [x] Sound + haptic when **work** interval ends
- [x] Sound + haptic when **rest** interval ends
- [x] Sound + haptic when **full workout** completes

### Global controls (immediate — no confirm popups)
- [x] Pause / Resume
- [x] Skip current interval or set
- [x] **Reset** — restarts the whole run from the first exercise
- [x] **Stop** — exits the run immediately (no save)
- [x] Avoid interruptive dialogs during the active timer flow

### Complete
- [x] Workout Complete screen (duration + exercise count)
- [x] Saves a history session

## 4. Home / Quality

- [x] Empty state when no workouts (“No workouts yet” + Create Workout)
- [x] Confirmation dialog when **deleting** a workout
- [x] Free limit banner on Home

## 5. Free vs Pro

### Free
- [x] Max **3** custom workouts
- [x] Basic history (last **10** sessions)

### Pro ($1.99 one-time)
- [x] Unlimited workouts (gated in UI; purchase wiring pending RevenueCat)
- [x] Full history
- [x] Duplicate workout (Pro only)
- [x] Restore Purchase always visible in Settings (stub until RevenueCat)

## 6. Other

- [x] Offline-first (`shared_preferences`)
- [x] Light / Dark / System theme (persisted)
- [x] **App skins** (Classic, Midnight, Forest, Sunset, Minimal, Synthwave) — selectable in Settings, persisted, apply instantly
- [x] History screen (date + duration + exercise count)
- [x] Settings screen (theme + skins + Pro copy + Restore Purchase)
- [x] Debug-only Unlock/Reset Pro (for testing)
- [x] Architecture: Riverpod + `core / models / providers / services / screens / widgets`

## 7. Still pending

- [ ] RevenueCat / `purchases_flutter` real purchase + restore
- [ ] Optional custom sound assets (currently system sounds + haptics)
- [ ] `flutter_local_notifications` (ready later)

## 8. Out of scope

- Cloud sync, social, video demos, Wear OS, advanced charts, subscriptions
