import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackfit/core/skins.dart';
import 'package:stackfit/core/theme.dart';
import 'package:stackfit/models/models.dart';
import 'package:stackfit/widgets/set_log_list.dart';

SetLog _set({
  required String exerciseId,
  required String exerciseName,
  required int setNumber,
  required int reps,
  double? weightKg,
}) {
  return SetLog(
    exerciseId: exerciseId,
    exerciseName: exerciseName,
    setNumber: setNumber,
    reps: reps,
    weightKg: weightKg,
  );
}

void main() {
  testWidgets('a long reps and kg line stays inside the card', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 280,
              child: SetLogList(
                logs: [
                  _set(
                    exerciseId: 'press',
                    exerciseName: 'Overhead Press',
                    setNumber: 1,
                    reps: 5,
                  ),
                  _set(
                    exerciseId: 'press',
                    exerciseName: 'Overhead Press',
                    setNumber: 2,
                    reps: 8,
                    weightKg: 22.5,
                  ),
                  _set(
                    exerciseId: 'press',
                    exerciseName: 'Overhead Press',
                    setNumber: 3,
                    reps: 5,
                    weightKg: 22.5,
                  ),
                  _set(
                    exerciseId: 'press',
                    exerciseName: 'Overhead Press',
                    setNumber: 4,
                    reps: 5,
                    weightKg: 22.5,
                  ),
                  _set(
                    exerciseId: 'press',
                    exerciseName: 'Overhead Press',
                    setNumber: 5,
                    reps: 5,
                    weightKg: 22.5,
                  ),
                  _set(
                    exerciseId: 'bench',
                    exerciseName: 'Bench Press',
                    setNumber: 1,
                    reps: 5,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Overhead Press'), findsOneWidget);
    expect(find.text('Bench Press'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('finish screen keeps a long set line inside the card', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final logs = [
      _set(
        exerciseId: 'press',
        exerciseName: 'Overhead Press',
        setNumber: 1,
        reps: 5,
      ),
      _set(
        exerciseId: 'press',
        exerciseName: 'Overhead Press',
        setNumber: 2,
        reps: 8,
        weightKg: 22.5,
      ),
      for (var setNumber = 3; setNumber <= 5; setNumber++)
        _set(
          exerciseId: 'press',
          exerciseName: 'Overhead Press',
          setNumber: setNumber,
          reps: 5,
          weightKg: 22.5,
        ),
      for (var setNumber = 1; setNumber <= 4; setNumber++)
        _set(
          exerciseId: 'bench',
          exerciseName: 'Bench Press',
          setNumber: setNumber,
          reps: 5,
        ),
      for (var setNumber = 1; setNumber <= 4; setNumber++)
        _set(
          exerciseId: 'row',
          exerciseName: 'Barbell Row',
          setNumber: setNumber,
          reps: 5,
        ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(AppSkin.cyberpunk),
        home: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),
                  const Text('Workout complete'),
                  const SizedBox(height: 160),
                  Flexible(flex: 3, child: SetLogList(logs: logs)),
                  const SizedBox(height: 120),
                  const FilledButton(onPressed: null, child: Text('Done')),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Overhead Press'), findsOneWidget);
    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('Barbell Row'), findsOneWidget);
    expect(
      find.text('5 · 8×22.5 · 5×22.5 · 5×22.5 · 5×22.5 kg'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
