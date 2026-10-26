# StackFit – Next Version

**App name:** StackFit  
**Today:** Offline Flutter app. Workouts, history, theme, skin, and Pro live only on the device (`shared_preferences`).  
**Next version:** A user can create an account and keep that same data with them.  
**Later:** Sharing a workout or a progress summary from the account.

The timer, catalog, workout builder, Free/Pro limits, and offline use stay as they are. This version adds identity and storage. It does not add social feeds, video, wearables, charts, or subscriptions.

**Current build:** the app and the website in `website/` use the local server in `server/`. Start the server, then open `http://127.0.0.1:8787`. Reset codes print in that server window until email delivery is connected. A signed-in person can share one workout, or a chosen set of sessions, by link. Someone else can open that link without an account and save a copy of the workout. The phone shows account changes the next time it syncs.

---

## 1. What this version is for

Someone builds workouts and finishes sessions on a phone. If they reinstall, switch phones, or later open a website, that work should still be there.

Two stages:

| Stage | What the person can do |
|-------|------------------------|
| **Next version (app)** | Create an account. Sign in. Workouts, history, and appearance save to that account and come back on another signed-in device. |
| **Later (website)** | Open StackFit in a browser with the same account. Add workouts and completed sessions. Share a workout or a progress summary with someone else. |

The app must keep working with no account. Sign-in is how progress leaves the device. It is not a gate on the timer.

---

## 2. Account

### Create and sign in

- Create an account with email and password.
- Sign in and sign out.
- Reset a forgotten password by email.
- Show the signed-in email in Settings.
- One account can be used on more than one device, and later on the website.

Apple and Google sign-in can wait. Email and password is enough for this version.

### No account yet

- The app still opens straight to Home.
- Creating workouts, running them, and saving history on the device stays available.
- Settings explains that an account keeps workouts and history if the phone is replaced.

### First sign-in on a device that already has data

- Offer to move the device’s workouts and history onto the account.
- If the person skips that, the account starts from whatever is already saved in the cloud (or empty).
- Device-only data is not deleted until the move succeeds.

### Sign out

- Local copy can stay on the device so the app still works offline after sign-out.
- The next sign-in on that device uses the account’s saved data.
- Signing out does not delete the account.

---

## 3. What gets saved

Saved per account:

| Data | Already in the app | Notes |
|------|--------------------|--------|
| Workouts | Yes — name, exercises, timer/sets, created and updated times | The main thing to keep |
| Completed sessions | Yes — workout, date, duration, exercise count | History / “progress” |
| Theme and skin | Yes | Follows the account |
| Display name | New, optional | Used later when something is shared |

Not stored as a fake cloud flag:

- **Pro** stays a store purchase (RevenueCat), restored with “Restore Purchase”. The account can remember which store user unlocked Pro, but a cloud boolean alone must not unlock Pro.

Stays on the device, not in the account:

- Exercise catalog (still shipped inside the app)
- An in-progress workout (saved on the phone so it can be continued; not part of the account)

A completed workout still writes a history session, the same as today. That session is what syncs.

---

## 4. How save works

The app stays offline-first.

1. Every change is written on the device first, as it is now.
2. When the person is signed in and online, those changes upload.
3. When they open the app online, newer account data downloads.
4. If they are offline, the app uses the last saved copy and uploads when the network returns.

Rules when two devices change the same thing:

- **Workouts:** the copy with the newer `updatedAt` wins.
- **History:** sessions are added, not overwritten. The same session id is never stored twice.
- **Theme and skin:** the most recent change wins.

The UI should show a simple state in Settings: saved, saving, or offline (will save when online). Failures get a short message and a retry. They must not block starting a workout.

---

## 5. App changes

### Settings

- **Create account** / **Sign in** when signed out.
- Email, **Sign out**, and save status when signed in.
- **Move this device’s workouts to my account** only when local data has not been moved yet.

### Home, editor, timer, history

- Same screens and rules as the current app.
- Free still caps custom workouts at 3 and history at the last 10 sessions.
- Pro still unlocks unlimited workouts, full history, and duplicate.
- Limits count the account’s data when signed in, and the device’s data when not.

### Empty and error cases

- No network on first launch: app works locally; account actions explain that a connection is required to sign in.
- Wrong email or password: inline error, no crash.
- Upload fails: local data remains; status shows that it is not saved to the account yet.

---

## 6. Later: website

Build this only after accounts and save work in the app. Same account, same workouts, same history.

People can:

- Sign in on the site.
- See their workouts and history.
- Create and edit a workout (same timer and set fields as the app).
- Add a completed session (progress) by hand: which workout, when, duration.
- Sign out.

The phone app and the site read and write the same saved data. A workout edited on the site shows up in the app after sync, and the other way around.

The Tabata page runs a work and rest countdown in the browser. A signed-in person can save that workout and the finished session to the account.

---

## 7. Later: sharing

Sharing is opt-in. Everything is private until the owner shares it.

An owner can create a link for:

- **One workout** — name and exercises, so someone else can open it and add it to their own account.
- **A progress summary** — chosen sessions (dates, workout names, durations), without the rest of the account.

People with the link can open it without an account and read it. Adding that workout to their own list requires their own account (on the site or in the app).

The owner can turn a link off. After that, the link no longer opens. Shared pages never include email, password, or Pro status.

There is no feed, no followers, and no public profile in this step. A link is the whole sharing model.

---

## 8. Acceptance criteria

### Next version — account and save

- [x] Create an account with email and password
- [x] Sign in and sign out
- [x] Reset password with a code printed by the local server (email delivery is not connected yet)
- [x] Use the app fully with no account (device storage only)
- [x] On first sign-in, offer to move existing device workouts and history to the account
- [x] Workouts saved on the account appear on a second signed-in device that uses the same server
- [x] Completed sessions saved on the account appear on a second signed-in device that uses the same server
- [x] Theme and skin follow the account
- [x] Offline edits sync after the account server is reachable again
- [x] Duplicate session ids are not stored twice
- [x] Newer workout `updatedAt` wins if two devices edit the same workout
- [x] Pro still comes from the store / Restore Purchase
- [x] Free limits still apply (3 workouts, last 10 sessions)
- [x] Settings shows who is signed in and whether data is saved, saving, or waiting for network

### Website

- [x] Sign in with the same account
- [x] See the same workouts and history as the app
- [x] Create and edit a workout on the site
- [x] Add a completed session on the site
- [x] Changes show up in the app after sync (`AccountSnapshot.fromJson` reads the site’s workout and session shape)

### Share

- [x] Owner can share one workout by link
- [x] Owner can share a progress summary by link
- [x] Visitor can open a link without an account
- [x] Visitor can copy a shared workout into their own account
- [x] Owner can turn a link off
- [x] Shared pages do not show email or other private account data

---

## 9. Out of scope

- Social feed, followers, comments, likes
- Public profiles
- Live multiplayer workouts
- Video demos
- Apple Watch / Wear OS
- Charts and advanced stats
- Subscriptions (Pro stays a one-time purchase)
- Replacing on-device storage (the device remains the offline copy)

---

## 10. Done when

A person can create an account, build a workout, finish it, and see that workout and that session on another signed-in device after a reinstall. The same account works on the website, including a link to share one workout or a progress summary. The app still runs a workout with no account and no network.
