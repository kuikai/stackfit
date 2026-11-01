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
import 'package:stackfit/services/account/account_storage.dart';
import 'package:stackfit/services/storage_service.dart';

CompletedSession _session(String id, {String name = 'Push'}) {
  return CompletedSession(
    id: id,
    workoutId: 'workout',
    workoutName: name,
    completedAt: DateTime.utc(2026, 1, 1),
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
    await tester.drag(find.text('Push'), const Offset(-90, 0));
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
}
