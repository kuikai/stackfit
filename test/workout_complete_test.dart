import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stackfit/core/page_transition.dart';
import 'package:stackfit/core/skins.dart';
import 'package:stackfit/core/theme.dart';
import 'package:stackfit/models/models.dart';
import 'package:stackfit/providers/app_providers.dart';
import 'package:stackfit/screens/active_timer/workout_complete_screen.dart';
import 'package:stackfit/screens/home/home_screen.dart';

Workout _wristWorkout() {
  final now = DateTime(2026, 1, 1);
  return Workout(
    id: 'wrist',
    name: 'Wrist',
    createdAt: now,
    updatedAt: now,
    exercises: [
      Exercise(
        id: 'sup',
        name: 'Subernation',
        type: ExerciseType.sets,
        sets: 1,
        reps: 10,
      ),
      Exercise(
        id: 'pro',
        name: 'Pronation',
        type: ExerciseType.sets,
        sets: 1,
        reps: 10,
      ),
      Exercise(
        id: 'uln',
        name: 'Ulnadivation',
        type: ExerciseType.sets,
        sets: 1,
        reps: 50,
      ),
    ],
  );
}

List<SetLog> _logs() {
  return [
    SetLog(
      exerciseId: 'sup',
      exerciseName: 'Subernation',
      setNumber: 1,
      reps: 10,
      weightKg: 60,
    ),
    SetLog(
      exerciseId: 'pro',
      exerciseName: 'Pronation',
      setNumber: 1,
      reps: 10,
      weightKg: 30,
    ),
    SetLog(
      exerciseId: 'uln',
      exerciseName: 'Ulnadivation',
      setNumber: 1,
      reps: 50,
      weightKg: 1,
    ),
  ];
}

WorkoutCompleteScreen _completeScreen() {
  return WorkoutCompleteScreen(
    args: WorkoutCompleteArgs(
      workout: _wristWorkout(),
      durationSeconds: 985,
      setLogs: _logs(),
    ),
  );
}

ThemeData _theme() {
  return AppTheme.dark(AppSkin.cyberpunk).copyWith(
    pageTransitionsTheme: SoftPageTransitionsBuilder.theme,
  );
}

/// ChibiRun repeats forever, so pumpAndSettle never ends.
Future<void> _pumpFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('Done returns to the screen under the finish page', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: _theme(),
          themeMode: ThemeMode.dark,
          home: const Scaffold(body: Center(child: Text('Home video'))),
        ),
      ),
    );

    // pushReplacement of the timer leaves: [Home, Complete]
    final nav = Navigator.of(tester.element(find.text('Home video')));
    nav.push<void>(MaterialPageRoute<void>(builder: (_) => _completeScreen()));
    await _pumpFrames(tester);

    expect(find.text('Workout complete'), findsOneWidget);

    await tester.ensureVisible(find.text('Done'));
    await tester.tap(find.text('Done'));
    await _pumpFrames(tester);

    expect(find.text('Workout complete'), findsNothing);
    expect(find.text('Home video'), findsOneWidget);
  });

  testWidgets('Done still leaves when the finish page is the only route', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: _theme(),
          themeMode: ThemeMode.dark,
          home: _completeScreen(),
        ),
      ),
    );
    await _pumpFrames(tester);

    expect(find.text('Workout complete'), findsOneWidget);

    await tester.ensureVisible(find.text('Done'));
    await tester.tap(find.text('Done'));
    await _pumpFrames(tester);

    // Must not stay stuck on the finish page.
    expect(find.text('Workout complete'), findsNothing);
  });

  testWidgets('Done from a Home stack lands on a tappable Home', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: _theme(),
          themeMode: ThemeMode.dark,
          home: const HomeScreen(),
        ),
      ),
    );
    await _pumpFrames(tester);

    final nav = Navigator.of(tester.element(find.text('StackFit')));
    // Same stack shape as a finished workout: timer was replaced by complete.
    nav.push<void>(
      MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('Timer'))),
    );
    await _pumpFrames(tester);
    nav.pushReplacement(
      MaterialPageRoute<void>(builder: (_) => _completeScreen()),
    );
    await _pumpFrames(tester);

    await tester.ensureVisible(find.text('Done'));
    await tester.tap(find.text('Done'));
    // Let the soft page transition finish (420ms).
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Workout complete'), findsNothing);
    expect(find.text('StackFit'), findsOneWidget);

    // Home must accept taps — opacity 0 from the leave transition would block this.
    await tester.tap(find.byTooltip('Settings'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Settings'), findsWidgets);
  });
}
