import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stackfit/models/account_snapshot.dart';
import 'package:stackfit/models/catalog_exercise.dart';
import 'package:stackfit/models/custom_catalog.dart';
import 'package:stackfit/models/exercise.dart';
import 'package:stackfit/providers/app_providers.dart';
import 'package:stackfit/providers/custom_catalog_provider.dart';
import 'package:stackfit/screens/catalog/catalog_screen.dart';
import 'package:stackfit/services/account/snapshot_merge.dart';
import 'package:stackfit/services/storage_service.dart';

void main() {
  test('a new custom exercise is added under Custom', () {
    final next = withCustomExercise(const [], _farmer(sets: 4, reps: 6));

    expect(next, hasLength(1));
    expect(next.single.name, 'Farmer Carry');
    expect(next.single.category, ExerciseCatalog.customCategory);
    expect(next.single.id, 'custom-farmer-carry');
    expect(next.single.sets, 4);
    expect(next.single.reps, 6);
    expect(next.single.preset?.sets, 4);
  });

  test('built-in names are skipped and the same custom name is updated', () {
    final once = withCustomExercise(const [], _farmer(sets: 4, reps: 6));

    expect(withCustomExercise(once, _farmer(sets: 4, reps: 6)), same(once));
    expect(withCustomExercise(const [], _squat()), isEmpty);

    final updated = withCustomExercise(once, _farmer(sets: 5, reps: 5));
    expect(updated.single.id, 'custom-farmer-carry');
    expect(updated.single.sets, 5);
    expect(updated.single.reps, 5);
  });

  test('two names that slug the same get different ids', () {
    final first = withCustomExercise(const [], _named('A!'));
    final second = withCustomExercise(first, _named('A?'));

    expect(second.map((item) => item.id), ['custom-a', 'custom-a-2']);
  });

  test('search includes custom exercises and hides built-in duplicates', () {
    const custom = [
      CatalogExercise(
        id: 'custom-farmer-carry',
        name: 'Farmer Carry',
        category: 'Custom',
      ),
      CatalogExercise(id: 'custom-squat', name: 'Squat', category: 'Custom'),
    ];

    expect(
      ExerciseCatalog.search('far', custom: custom).map((item) => item.name),
      ['Farmer Carry'],
    );
    expect(
      ExerciseCatalog.search('squat', custom: custom).map((item) => item.id),
      isNot(contains('custom-squat')),
    );
    expect(
      ExerciseCatalog.search(
        '',
        custom: custom,
        category: 'Custom',
      ).map((item) => item.name),
      ['Farmer Carry'],
    );
  });

  test('merge keeps each custom name once and the local copy wins', () {
    final merged = mergeSnapshots(
      _snapshot([
        const CatalogExercise(
          id: 'custom-farmer-carry',
          name: 'Farmer Carry',
          category: 'Custom',
          sets: 4,
        ),
      ]),
      _snapshot([
        const CatalogExercise(
          id: 'other',
          name: 'farmer carry',
          category: 'Custom',
          sets: 1,
        ),
        const CatalogExercise(
          id: 'custom-suitcase-carry',
          name: 'Suitcase Carry',
          category: 'Custom',
        ),
      ]),
    );

    expect(merged.customExercises.map((item) => item.name), [
      'Farmer Carry',
      'Suitcase Carry',
    ]);
    expect(merged.customExercises.first.id, 'custom-farmer-carry');
    expect(merged.customExercises.first.sets, 4);
  });

  test('a snapshot without custom exercises still loads', () {
    final snapshot = AccountSnapshot.fromJson({
      'workouts': <Object>[],
      'sessions': <Object>[],
    });

    expect(snapshot.customExercises, isEmpty);
    expect(
      snapshot
          .copyWith(customExercises: withCustomExercise(const [], _farmer()))
          .hasProgress,
      isTrue,
    );
  });

  test('remember stores the exercise on the phone', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final notifier = CustomCatalogNotifier(StorageService(prefs));

    await notifier.remember(_farmer(sets: 4, reps: 6));
    await notifier.remember(_squat());

    expect(notifier.state.map((item) => item.name), ['Farmer Carry']);
    final loaded = CustomCatalogNotifier(StorageService(prefs));
    expect(loaded.state.single.sets, 4);
    expect(loaded.state.single.reps, 6);
  });

  testWidgets('the catalog lists an exercise you added', (tester) async {
    SharedPreferences.setMockInitialValues({
      'stackfit_custom_exercises': jsonEncode([
        {
          'id': 'custom-farmer-carry',
          'name': 'Farmer Carry',
          'category': 'Custom',
          'type': 'sets',
          'restSeconds': 90,
          'sets': 4,
          'reps': 6,
        },
      ]),
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(home: CatalogScreen()),
      ),
    );
    await tester.enterText(find.byType(TextField), 'Farmer');
    await tester.pump();

    expect(find.text('Farmer Carry'), findsOneWidget);
    expect(find.text('Custom'), findsWidgets);
  });
}

Exercise _farmer({int sets = 4, int reps = 6}) {
  return Exercise.sets(
    id: 'made',
    name: 'Farmer Carry',
    sets: sets,
    reps: reps,
    restSeconds: 90,
  );
}

Exercise _squat() {
  return Exercise.sets(
    id: 'made',
    name: ' Squat ',
    sets: 3,
    reps: 5,
    restSeconds: 90,
  );
}

Exercise _named(String name) {
  return Exercise.sets(
    id: 'made',
    name: name,
    sets: 1,
    reps: 1,
    restSeconds: 30,
  );
}

AccountSnapshot _snapshot(List<CatalogExercise> custom) {
  return AccountSnapshot(
    workouts: const [],
    deletedWorkouts: const [],
    sessions: const [],
    themeMode: 'dark',
    skin: 'classic',
    appearanceUpdatedAt: DateTime.utc(1970),
    customExercises: custom,
  );
}
