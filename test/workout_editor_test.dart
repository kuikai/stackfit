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
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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

    await tester.ensureVisible(find.byTooltip('Edit'));
    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();

    await tester.enterText(_restField, '45');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    final saved = StorageService(prefs).loadWorkouts().single;
    final station = saved.blocks.whereType<CircuitBlock>().single;
    expect(station.circuit.exercises.single.restSeconds, 45);
  });

  testWidgets('moving an exercise writes the new order', (tester) async {
    final workout = Workout(
      id: 'w1',
      name: 'Workout A',
      createdAt: DateTime.utc(2026, 10, 1),
      updatedAt: DateTime.utc(2026, 10, 1),
      blocks: [
        ExerciseBlock(
          Exercise.sets(
            id: 'e1',
            name: 'Squats',
            sets: 3,
            reps: 8,
            restSeconds: 60,
          ),
        ),
        ExerciseBlock(
          Exercise.sets(
            id: 'e2',
            name: 'Lunges',
            sets: 3,
            reps: 10,
            restSeconds: 60,
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

    await tester.tap(find.byTooltip('Move down').first);
    await tester.pumpAndSettle();

    final saved = StorageService(prefs).loadWorkouts().single;
    expect(
      saved.blocks.whereType<ExerciseBlock>().map((block) => block.exercise.name),
      ['Lunges', 'Squats'],
    );
  });
}

final Finder _restField = find.byWidgetPredicate(
  (widget) =>
      widget is TextField &&
      widget.decoration?.labelText == 'Rest before next station (seconds)',
);
