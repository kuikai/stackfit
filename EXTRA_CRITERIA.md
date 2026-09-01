# StackFit – Extra Acceptance Criteria

Add these **after** Cursor finishes the first scaffolding + basic structure.

---

## High Priority (strongly recommended before release)

### 1. Keep screen awake during active workout
- While a workout is running, the screen must stay on
- Extremely important for timers so the phone doesn’t lock

### 2. Basic sound + haptic when work/rest ends
- Play a short sound + light haptic feedback when:
  - Work interval finishes
  - Rest interval finishes
  - Full workout completes
- Makes the app feel professional and usable without looking at the screen

### 3. Cannot save a workout with 0 exercises
- Prevent the user from saving an empty workout
- Show a simple message if they try

---

## Medium Priority (good to have)

### 4. Confirmation dialog when deleting a workout
- Ask “Delete this workout?” before actually deleting
- Avoids accidental deletes

### 5. Empty state on Home screen
- When the user has no workouts yet, show a clean empty state
- Example text: “No workouts yet” + a clear “Create Workout” button
- Better first impression

### 6. Ability to reorder exercises (drag & drop)
- User should be able to drag exercises up/down when creating or editing a workout
- Already mentioned in the main spec — just make sure it’s implemented

---

**Note:**  
These are additions to the main Product Spec.  
Core MVP criteria stay the same.
