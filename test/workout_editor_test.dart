import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stackfit/core/skins.dart';
import 'package:stackfit/core/theme.dart';
import 'package:stackfit/models/models.dart';
import 'package:stackfit/providers/app_providers.dart';
import 'package:stackfit/screens/workout_editor/workout_editor_screen.dart';
import 'package:stackfit/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('saving an exercise in a circuit writes the workout', (
    tester,
  ) async {
    final workout = Workout(
      id: 'w1',
      name: 'Workout A',
      createdAt: DateTime.utc(2026, 10, 1),
      updatedAt: DateTime.utc(2026, 10, 1),
      blocks: [
        CircuitBlock(
          Circuit(
            id: 'c1',
            rounds: 3,
            restBetweenRoundsSeconds: 60,
            exercises: [
              Exercise.sets(
                id: 'e1',
                name: 'Bench Press',
                sets: 3,
                reps: 8,
                restSeconds: 60,
              ),
            ],
          ),
        ),
      ],
    );
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await StorageService(prefs).saveWorkouts([workout]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: AppTheme.dark(AppSkin.classic),
          home: const WorkoutEditorScreen(workoutId: 'w1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Bench Press'));
    await tester.tap(find.text('Bench Press'));
    await tester.pumpAndSettle();

    await tester.enterText(_restField, '45');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    final saved = StorageService(prefs).loadWorkouts().single;
    final station = saved.blocks.whereType<CircuitBlock>().single;
    expect(station.circuit.exercises.single.restSeconds, 45);
  });
}

final Finder _restField = find.byWidgetPredicate(
  (widget) =>
      widget is TextField &&
      widget.decoration?.labelText == 'Rest before next station (seconds)',
);
