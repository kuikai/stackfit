import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stackfit/core/skins.dart';
import 'package:stackfit/core/theme.dart';
import 'package:stackfit/models/models.dart';
import 'package:stackfit/providers/app_providers.dart';
import 'package:stackfit/providers/completed_sessions_provider.dart';
import 'package:stackfit/screens/history/history_screen.dart';
import 'package:stackfit/screens/history/workout_history_screen.dart';
import 'package:stackfit/services/account/account_storage.dart';
import 'package:stackfit/services/storage_service.dart';
import 'package:stackfit/widgets/log_row_swipe.dart';

CompletedSession _session(
  String id, {
  String name = 'Push',
  String workoutId = 'workout',
  DateTime? completedAt,
}) {
  return CompletedSession(
    id: id,
    workoutId: workoutId,
    workoutName: name,
    completedAt: completedAt ?? DateTime.utc(2026, 1, 1),
    durationSeconds: 60,
    totalExercises: 1,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('deleteSession drops the row and records a tombstone', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);
    await storage.saveCompletedSessions([_session('s1')]);
    final notifier = CompletedSessionsNotifier(storage, AccountStorage(prefs));

    await notifier.deleteSession('s1');

    expect(notifier.state, isEmpty);
    expect(AccountStorage(prefs).loadSessionDeletions().single.id, 's1');
    expect(storage.loadCompletedSessions(), isEmpty);
  });

  test('deleteSessionsForWorkout drops that workout and leaves the rest', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);
    await storage.saveCompletedSessions([
      _session('s1', workoutId: 'push', name: 'Push'),
      _session('s2', workoutId: 'push', name: 'Push'),
      _session('s3', workoutId: 'pull', name: 'Pull'),
    ]);
    final notifier = CompletedSessionsNotifier(storage, AccountStorage(prefs));

    await notifier.deleteSessionsForWorkout('missing');
    expect(notifier.state, hasLength(3));
    expect(AccountStorage(prefs).loadSessionDeletions(), isEmpty);

    await notifier.deleteSessionsForWorkout('push');

    expect(notifier.state.map((session) => session.id), ['s3']);
    expect(
      AccountStorage(prefs).loadSessionDeletions().map((item) => item.id),
      containsAll(['s1', 's2']),
    );
    expect(storage.loadCompletedSessions().map((session) => session.id), ['s3']);
  });

  test('clearAll tombstones every session on this device', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);
    await storage.saveCompletedSessions([
      _session('s1'),
      _session('s2', name: 'Pull'),
    ]);
    final notifier = CompletedSessionsNotifier(storage, AccountStorage(prefs));

    await notifier.clearAll();

    expect(notifier.state, isEmpty);
    expect(
      AccountStorage(prefs).loadSessionDeletions().map((item) => item.id),
      containsAll(['s1', 's2']),
    );
  });

  testWidgets('swiping a history row asks before deleting', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await StorageService(prefs).saveCompletedSessions([_session('s1')]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: AppTheme.dark(AppSkin.classic),
          home: const HistoryScreen(),
        ),
      ),
    );

    expect(find.text('Push'), findsOneWidget);
    await tester.drag(find.byType(LogRowSwipe), const Offset(-90, 0));
    await tester.pumpAndSettle();

    expect(find.text('Delete this session?'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Push'), findsNothing);
    expect(find.text('No sessions yet'), findsOneWidget);
    expect(AccountStorage(prefs).loadSessionDeletions().single.id, 's1');
  });

  testWidgets('Clear asks then wipes history', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await StorageService(prefs).saveCompletedSessions([
      _session('s1'),
      _session('s2', name: 'Pull'),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: AppTheme.dark(AppSkin.classic),
          home: const HistoryScreen(),
        ),
      ),
    );

    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(find.text('Delete all history?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Clear'));
    await tester.pumpAndSettle();

    expect(find.text('No sessions yet'), findsOneWidget);
    expect(
      AccountStorage(prefs).loadSessionDeletions().map((item) => item.id),
      containsAll(['s1', 's2']),
    );
  });

  testWidgets('trash icon deletes every log of that workout', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await StorageService(prefs).saveCompletedSessions([
      _session('s1', name: 'Push', workoutId: 'push'),
      _session(
        's2',
        name: 'Push',
        workoutId: 'push',
        completedAt: DateTime.utc(2026, 1, 2),
      ),
      _session('s3', name: 'Pull', workoutId: 'pull'),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: AppTheme.dark(AppSkin.classic),
          home: const HistoryScreen(),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('delete-workout-logs-push')));
    await tester.pumpAndSettle();
    expect(find.text('Delete all logs?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Push'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('delete-workout-logs-push')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Push'), findsNothing);
    expect(find.text('Pull'), findsOneWidget);
    expect(
      AccountStorage(prefs).loadSessionDeletions().map((item) => item.id),
      containsAll(['s1', 's2']),
    );
    expect(
      AccountStorage(prefs).loadSessionDeletions().map((item) => item.id),
      isNot(contains('s3')),
    );
  });

  testWidgets('workout history trash icon deletes that workout', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await StorageService(prefs).saveCompletedSessions([
      _session('s1', name: 'Push', workoutId: 'push'),
      _session('s3', name: 'Pull', workoutId: 'pull'),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: AppTheme.dark(AppSkin.classic),
          home: const WorkoutHistoryScreen(
            workoutId: 'push',
            workoutName: 'Push',
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('delete-workout-logs-push')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Not done yet'), findsOneWidget);
    expect(
      StorageService(prefs).loadCompletedSessions().map((session) => session.id),
      ['s3'],
    );
  });
}
