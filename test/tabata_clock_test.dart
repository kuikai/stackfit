import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stackfit/main.dart';
import 'package:stackfit/models/models.dart';
import 'package:stackfit/providers/app_providers.dart';

void main() {
  test('classic tabata is 20 seconds on, 10 off, 8 rounds', () {
    final workout = TabataClock.build();
    final exercise = workout.exercises.single;

    expect(workout.id, TabataClock.workoutId);
    expect(workout.name, 'Tabata');
    expect(exercise.type, ExerciseType.timer);
    expect(exercise.workSeconds, 20);
    expect(exercise.restSeconds, 10);
    expect(exercise.sets, 8);
  });

  test('custom numbers stay on the one timer exercise', () {
    final workout = TabataClock.build(
      workSeconds: 30,
      restSeconds: 15,
      rounds: 4,
    );
    final exercise = workout.exercises.single;

    expect(exercise.type, ExerciseType.timer);
    expect(exercise.workSeconds, 30);
    expect(exercise.restSeconds, 15);
    expect(exercise.sets, 4);
  });

  test('work, rest, and rounds stay inside the clock limits', () {
    final workout = TabataClock.build(
      workSeconds: 0,
      restSeconds: 9999,
      rounds: 200,
    );
    final exercise = workout.exercises.single;

    expect(exercise.workSeconds, TabataClock.minWorkSeconds);
    expect(exercise.restSeconds, TabataClock.maxRestSeconds);
    expect(exercise.sets, TabataClock.maxRounds);
  });

  testWidgets('Home opens the Tabata clock on round 1', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const StackFitApp(),
      ),
    );

    expect(find.byTooltip('Tabata'), findsOneWidget);
    await tester.tap(find.byTooltip('Tabata'));
    await tester.pumpAndSettle();

    expect(find.text('0:20'), findsOneWidget);
    expect(find.text('Round 1 of 8'), findsOneWidget);
    expect(find.text('WORK'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);

    await tester.tap(find.text('Start'));
    await tester.pump();
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Pause'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Tabata'), findsOneWidget);
    expect(find.text('In progress'), findsNothing);
    expect(find.text('Continue'), findsNothing);
  });
}
