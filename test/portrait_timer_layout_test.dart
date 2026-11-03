import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stackfit/core/skins.dart';
import 'package:stackfit/core/theme.dart';
import 'package:stackfit/models/models.dart';
import 'package:stackfit/providers/app_providers.dart';
import 'package:stackfit/screens/active_timer/active_timer_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('portrait logging shows every set and keeps the mascot off it', (
    tester,
  ) async {
    await _openPortrait(tester);

    expect(find.text('Set 3').hitTestable(), findsOneWidget);
    expect(find.text('Reps').hitTestable(), findsOneWidget);
    final mascot = _rectOf(tester, Image);
    final done = _rect(tester, 'Done / Next Set');
    expect(_overlaps(_rect(tester, 'Reps'), mascot), isFalse);
    expect(mascot.top, lessThan(done.top));
    expect(mascot.bottom, greaterThan(done.top));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a timer exercise waits on Start', (tester) async {
    await _openTimer(tester);

    expect(find.text('READY'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('0:20'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    expect(find.text('0:20'), findsOneWidget);

    await tester.tap(find.text('Start'));
    await tester.pump();
    expect(find.text('WORK'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('0:19'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('portrait rest puts a short clock above the log', (tester) async {
    await _openPortrait(tester);

    await tester.tap(find.text('Done / Next Set'));
    await tester.pump();

    expect(find.text('Skip rest').hitTestable(), findsOneWidget);
    expect(find.text('1:00'), findsOneWidget);
    expect(find.text('Log').hitTestable(), findsOneWidget);
    final clock = _rect(tester, '1:00');
    final log = _rect(tester, 'Log');
    expect(clock.bottom, lessThan(log.top));
    expect(_overlaps(_rect(tester, 'Reps'), _rectOf(tester, Image)), isFalse);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Future<void> _openTimer(WidgetTester tester) async {
  await _pumpWorkout(
    tester,
    Workout(
      id: 'timed',
      name: 'Core',
      createdAt: DateTime(2026, 10, 29),
      updatedAt: DateTime(2026, 10, 29),
      exercises: [
        Exercise.timer(
          id: 'plank',
          name: 'Plank',
          workSeconds: 20,
          restSeconds: 5,
          sets: 2,
        ),
      ],
    ),
  );
}

Future<void> _openPortrait(WidgetTester tester) async {
  await _pumpWorkout(
    tester,
    Workout(
      id: 'w',
      name: 'Test',
      createdAt: DateTime(2026, 10, 29),
      updatedAt: DateTime(2026, 10, 29),
      exercises: [
        Exercise.sets(
          id: 'bench',
          name: 'Bench Press',
          sets: 3,
          reps: 8,
          restSeconds: 60,
        ),
      ],
    ),
  );
}

Future<void> _pumpWorkout(WidgetTester tester, Workout workout) async {
  tester.view.physicalSize = const Size(390, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({'stackfit_skin': 'chibi'});
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        theme: AppTheme.light(AppSkin.chibi),
        home: ActiveTimerScreen(workout: workout),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Rect _rect(WidgetTester tester, String text) {
  return tester.getRect(find.text(text));
}

Rect _rectOf(WidgetTester tester, Type type) {
  return tester.getRect(find.byType(type));
}

bool _overlaps(Rect first, Rect second) {
  return first.overlaps(second);
}
