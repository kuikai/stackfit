import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stackfit/main.dart';
import 'package:stackfit/providers/app_providers.dart';
import 'package:stackfit/screens/plans/plan_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Home screen shows StackFit and create action', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const StackFitApp(),
      ),
    );

    expect(find.text('StackFit'), findsOneWidget);
    expect(find.text('No workouts yet'), findsOneWidget);
    expect(find.text('Create Workout'), findsWidgets);
    expect(find.byTooltip('History'), findsOneWidget);
    expect(find.byTooltip('Settings'), findsOneWidget);
  });

  testWidgets('Plans open from Home and Start is Pro-gated', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const StackFitApp(),
      ),
    );

    expect(find.text('Browse plans'), findsOneWidget);
    await tester.tap(find.byTooltip('Plans'));
    await tester.pumpAndSettle();

    expect(find.text('Workout plans'), findsOneWidget);
    expect(find.text('Gym'), findsWidgets);
    expect(find.text('Bro Split'), findsOneWidget);

    await tester.tap(find.text('Bro Split'));
    await tester.pumpAndSettle();

    expect(find.text('Chest'), findsOneWidget);
    await tester.tap(find.text('Chest'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start Chest'));
    await tester.pumpAndSettle();

    expect(find.text(PlanDetailScreen.proMessage), findsOneWidget);
  });

  testWidgets('Settings explains that an account is optional', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const StackFitApp(),
      ),
    );

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(
      find.textContaining('everything stays on this device'),
      findsOneWidget,
    );
  });

  testWidgets('History deletes a finished session, including one with no sets', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'stackfit_completed_sessions': jsonEncode([
        {
          'id': 'session-1',
          'workoutId': 'w1',
          'workoutName': 'Push day',
          'completedAt': '2026-10-31T18:00:00.000Z',
          'durationSeconds': 600,
          'totalExercises': 1,
        },
      ]),
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const StackFitApp(),
      ),
    );

    await tester.tap(find.byTooltip('History'));
    await tester.pumpAndSettle();

    expect(find.text('Push day'), findsOneWidget);
    await tester.tap(find.byTooltip('Delete session'));
    await tester.pumpAndSettle();

    expect(find.text('Delete session?'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('No sessions yet'), findsOneWidget);
    expect(prefs.getString('stackfit_deleted_sessions'), contains('session-1'));
  });
}
