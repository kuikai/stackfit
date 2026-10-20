# StackFit – Share routines and progress

**App name:** StackFit  
**Today:** Workouts and history live only on the device (`shared_preferences`).  
**Already planned:** An account that saves that same data, then a website on the account. See [NEXT_VERSION.md](NEXT_VERSION.md).  
**This plan:** People share a workout or a progress summary, and someone else can add that workout to their own account. A routine from another site can be added the same way when it is shared as a StackFit link or file.

The timer, catalog, Free/Pro limits, and offline use stay as they are.

---

## 1. Is this possible?

Yes. The app and the website talk to the same database. Each person has an account. Their workouts and completed sessions are stored on that account, with a copy kept on the phone so the timer still works offline.

Sharing does not give another person access to the whole account. The owner publishes one workout, or a short progress summary, as a link. The other person opens the link and, if they want the workout, copies it onto their own account.

An outside site (the example here is “fysterpyte”) cannot write straight into someone’s StackFit account. It can hand over a routine the same way a friend would: a link or a small file. The StackFit user then taps **Add to my account**. The routine becomes a normal StackFit workout they own.

---

## 2. What people can do

| Who | What they do |
|-----|----------------|
| Owner | Builds workouts and finishes sessions in the app, same as today. |
| Owner | Signs in. Data saves to their account and shows up on the website. |
| Owner | Shares one workout, or a progress summary, with a link. |
| Friend | Opens the link in a browser. Can read it with no account. |
| Friend | Signs in (app or site) and adds that workout to their own list. |
| Someone on another site | Gets a routine there. The site (or the person) shares a StackFit link or file. |
| StackFit user | Adds that shared routine to their account. It shows up on the phone after sync. |

A copied workout is a new workout. Later edits on one account do not change the other account. The other person’s completed sessions stay on their account. A progress link is for reading (dates, workout names, durations). It is not copied into the friend’s history.

After the friend adds the workout, they run it in StackFit. That run writes their own history entry, the same as any other workout.

---

## 3. What has to exist first

This sits on the account work in [NEXT_VERSION.md](NEXT_VERSION.md). Sharing is not the first build.

1. **Account** — email and password, sign in, sign out, reset password.
2. **Database** — one store for users, workouts, and completed sessions.
3. **App sync** — device saves first, then uploads when online. Downloads newer account data on open.
4. **Website** — same account, same workouts, same history. Create and edit workouts. Log a completed session by hand. No live countdown timer required on the site.

Suggested store: Postgres with email auth (Supabase is a fit: one project for the Flutter app and the website). Tables:

| Table | Holds |
|-------|--------|
| `profiles` | User id, email, optional display name |
| `workouts` | Account id, name, exercises, created and updated times |
| `sessions` | Account id, workout id, workout name, completed time, duration, exercise count |
| `shares` | Owner, kind (`workout` or `progress`), public token, snapshot, on/off |

Row access: a person can read and write only their own workouts and sessions. A share row is readable by anyone who has the token, and only while the owner left it on. Shared pages never include email, password, or Pro status.

Pro stays a store purchase. The database must not unlock Pro with a flag alone.

---

## 4. Share a StackFit workout

From the app or the website, on a workout the person owns:

- **Share workout** creates a link, for example `https://stackfit.app/s/abc123`.
- The link stores a snapshot: workout name and exercises, not a live pointer into the private list.
- The owner can turn the link off. After that, the page no longer opens.
- Turning it off does not remove copies people already added.

The snapshot uses the fields the app already has.

**Workout:** name.

**Timer exercise:** name, work seconds, rest seconds, rounds (`sets`).

**Set exercise:** name, sets, reps (optional), rest seconds.

The public page shows the name and the exercise list in plain language (“Plank · 45s work / 15s rest · 3 rounds”). It has one action: **Add to my account**.

Add flow:

1. If the visitor is not signed in, they create an account or sign in, then return to the same link.
2. StackFit creates a new workout on their account with new ids.
3. Free accounts still stop at 3 custom workouts. If they are already at the limit, the page says so and does not add a fourth.
4. The new workout syncs to the phone and appears on Home.

---

## 5. Share progress

From History (app or website):

- The owner picks sessions, or a date range, and creates a link.
- The page lists workout name, date, and duration for those sessions only.
- It does not list the rest of their history, their other workouts, or their email.
- There is no **Add to my account** for someone else’s sessions. Progress on the link is a view.

The owner can turn this link off too.

---

## 6. Add a routine from another site

Example: someone builds a routine on another site, then wants it in StackFit.

StackFit accepts a routine in one published shape, the same fields as section 4. Two ways in:

| Way in | What the other site or the person does |
|--------|----------------------------------------|
| **Link** | Hosts a page or file StackFit can read, or uses a StackFit import link that already contains the routine. |
| **File** | Downloads a `.json` routine file. The user picks **Add from file** in the app or on the website. |

A cooperating site can add a button: **Add to StackFit**. That button opens StackFit’s website (or the app, via a link) with the routine attached. StackFit shows the exercise list and asks the signed-in user to confirm **Add to my account**. Nothing is saved until they confirm.

If the other site never adds that button, the person can still export or copy the routine into the StackFit file format and import it themselves.

Rules for a file or link from outside:

- Unknown fields are ignored.
- A workout with no name, or with no exercises, is rejected with a short message.
- Each exercise must be `timer` or `sets`, with the numbers that type needs (work/rest/rounds, or sets/rest).
- The import becomes a new workout on the signed-in account. It does not overwrite an existing one.
- The 3-workout Free limit applies here too.

StackFit does not log into the other site, and it does not read that site’s private database.

### Routine file (shape)

```json
{
  "name": "Push day",
  "exercises": [
    {
      "name": "Bench press",
      "type": "sets",
      "sets": 4,
      "reps": 8,
      "restSeconds": 90
    },
    {
      "name": "Plank",
      "type": "timer",
      "workSeconds": 45,
      "restSeconds": 15,
      "sets": 3
    }
  ]
}
```

`sets` on a timer exercise means rounds, matching the app today.

---

## 7. Where it shows up

**App**

- Settings: account, save status (saved / saving / offline).
- Workout menu: **Share**, and **Add from link** / **Add from file**.
- History: **Share progress**.
- Opening a share link on the phone can jump straight to the add screen.

**Website**

- Sign in, workout list, history.
- Share and turn off a link.
- Public page for a token, with **Add to my account**.
- Same add-from-file action.

---

## 8. Order to build

| Step | Build | Done when |
|------|--------|-----------|
| 1 | Account + database + app sync | A workout finished on one signed-in phone shows up on another. |
| 2 | Website on that account | Edit a workout on the site; it shows up in the app after sync. |
| 3 | Share link + add to my account | A friend opens a link and the workout lands on their account and their phone. |
| 4 | Progress link | A chosen slice of history opens in a browser, and private data stays hidden. |
| 5 | Import file / outside link | A routine file (or a link from another site) adds one workout after the user confirms. |

Steps 3–5 wait until step 1 is solid. The website can ship with step 2 before sharing exists.

---

## 9. Acceptance criteria

### Share a workout

- [ ] Owner can create a link for one workout from the app or the website
- [ ] Visitor can open the link without an account and read the name and exercises
- [ ] Visitor can add that workout to their own account
- [ ] The copy has new ids and does not change when the owner later edits the original
- [ ] Owner can turn the link off, and the page stops opening
- [ ] Copies already added stay on the other account
- [ ] Free limit of 3 workouts still blocks the add
- [ ] The new workout appears in the app after sync

### Share progress

- [ ] Owner can share chosen sessions by link
- [ ] The page shows date, workout name, and duration for those sessions only
- [ ] Email and the rest of the account are not on the page
- [ ] Owner can turn the link off

### Routine from another site

- [ ] A valid routine file adds one workout after the user confirms
- [ ] A link that carries the same routine shape does the same
- [ ] A file with no exercises is rejected
- [ ] An exercise that is not `timer` or `sets` is rejected
- [ ] Nothing is written before the user confirms

### Still true

- [ ] The app runs a workout with no account and no network
- [ ] Pro still comes from the store / Restore Purchase
- [ ] Shared pages do not show email, password, or Pro status

---

## 10. Out of scope

- A social feed, followers, comments, or likes
- Public profiles
- Copying another person’s session history into your account
- Logging into another site or reading its private database
- Live countdown timer on the website
- Charts, video demos, wearables, subscriptions

---

## 11. Done when

A person can sign in, keep workouts and history on their account, and open the same data on the website. They can send a friend a workout link. The friend adds it and sees it in the app. They can also take a routine shared from another site, confirm it, and have that workout on the account.
