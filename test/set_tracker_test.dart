import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackfit/models/models.dart';
import 'package:stackfit/widgets/set_tracker.dart';

void main() {
  testWidgets('a set that is not logged yet shows last time only', (
    tester,
  ) async {
    await _pump(
      tester,
      logs: const [],
      previousLogs: const [
        SetLog(
          exerciseId: 'bench',
          exerciseName: 'Bench Press',
          setNumber: 1,
          reps: 8,
          weightKg: 60,
        ),
      ],
    );

    expect(find.text('Last 8 × 60 kg'), findsOneWidget);
    expect(find.text('Set 2'), findsOneWidget);
    expect(find.textContaining('Last'), findsOneWidget);
  });

  testWidgets('a logged set keeps today and shows last time under it', (
    tester,
  ) async {
    await _pump(
      tester,
      isResting: true,
      logs: const [
        SetLog(
          exerciseId: 'bench',
          exerciseName: 'Bench Press',
          setNumber: 1,
          reps: 5,
          weightKg: 62.5,
        ),
      ],
      previousLogs: const [
        SetLog(
          exerciseId: 'bench',
          exerciseName: 'Bench Press',
          setNumber: 1,
          reps: 12,
        ),
      ],
    );

    expect(find.text('5 × 62.5 kg'), findsOneWidget);
    expect(find.text('Last 12 reps'), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required List<SetLog> logs,
  required List<SetLog> previousLogs,
  bool isResting = false,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 360,
          height: 480,
          child: SetTracker(
            exercise: Exercise.sets(
              id: 'bench',
              name: 'Bench Press',
              sets: 2,
              reps: 8,
              restSeconds: 60,
            ),
            logs: logs,
            previousLogs: previousLogs,
            activeSetNumber: 1,
            activeEntry: const ActiveSetEntry(reps: 8, weightKg: 0),
            isResting: isResting,
            onActiveEntryChanged: (_) {},
            onLoggedSetChanged: (_, {reps, weightKg}) {},
          ),
        ),
      ),
    ),
  );
}
