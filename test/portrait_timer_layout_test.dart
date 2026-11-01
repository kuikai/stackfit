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

Future<void> _openPortrait(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({'stackfit_skin': 'chibi'});
  final prefs = await SharedPreferences.getInstance();
  final now = DateTime(2026, 10, 29);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        theme: AppTheme.light(AppSkin.chibi),
        home: ActiveTimerScreen(
          workout: Workout(
            id: 'w',
            name: 'Test',
            createdAt: now,
            updatedAt: now,
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
        ),
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
