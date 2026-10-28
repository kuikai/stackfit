# StackFit Themes

Four Pro anime themes for the StackFit fitness app. Every theme follows the
same Cyberpunk-shaped layout so Home, the timer, and workout-complete share
one recipe.

## Recipe (per theme folder)

```
<theme-id>/
  README.md
  background.jpg              Empty gym behind dark screens (not Home)
  girl-standing.jpg           Full Home hero (girl + scene)
  icons/
    banner.jpg                Settings card preview
    icon.jpg                  Portrait on the Settings card (optional)
  mascots/
    mascot-<name>.png         Standing cut-out on Home
    mascot-<name>-sit.png     Sitting on Done / Next Set
    mascot-<name>-rest.png    Lying on Skip rest
    animation/running/
      mascot-<name>-run-1.png … run-N.png   Workout-complete run cycle
```

Wire each path in `lib/core/skins.dart` and list it under `flutter: assets:`
in `pubspec.yaml`. Glass cards use a low `cardOpacity` in `skin_looks.dart`.

## Themes

- **bold-sports/** — High-energy neon pink sports anime (`mascot-power`)
- **chibi/** — Soft pastel oversized-head cute (`mascot-pastel`)
- **cyberpunk/** — Neon cyan/magenta night city gym (`mascot-chibi`)
- **dumbbell/** — Bright warm Doga Kobo–inspired gym (`mascot-companion`)
