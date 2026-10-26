import 'package:flutter_test/flutter_test.dart';
import 'package:stackfit/models/models.dart';
import 'package:stackfit/services/plan_workout_builder.dart';

void main() {
  group('PlanLibrary', () {
    test('has plans with unique ids', () {
      final ids = PlanLibrary.all.map((plan) => plan.id).toList();
      expect(ids, isNotEmpty);
      expect(ids.toSet().length, ids.length);
    });

    test('every plan has at least one day with at least one exercise', () {
      for (final plan in PlanLibrary.all) {
        expect(plan.days, isNotEmpty, reason: plan.id);
        for (final day in plan.days) {
          expect(day.exercises, isNotEmpty, reason: '${plan.id}/${day.name}');
        }
      }
    });

    test('every exercise has valid timer or set values', () {
      for (final plan in PlanLibrary.all) {
        for (final day in plan.days) {
          for (final exercise in day.exercises) {
            final where = '${plan.id}/${day.name}/${exercise.name}';
            expect(exercise.name.trim(), isNotEmpty, reason: where);
            if (exercise.type == ExerciseType.timer) {
              expect(exercise.workSeconds, greaterThan(0), reason: where);
              expect(exercise.restSeconds, isNotNull, reason: where);
              expect(exercise.sets, greaterThan(0), reason: where);
            } else {
              expect(exercise.sets, greaterThan(0), reason: where);
              expect(exercise.restSeconds, isNotNull, reason: where);
            }
          }
        }
      }
    });

    test('exercise ids are unique within each day', () {
      for (final plan in PlanLibrary.all) {
        for (final day in plan.days) {
          final ids = day.exercises.map((exercise) => exercise.id).toList();
          expect(
            ids.toSet().length,
            ids.length,
            reason: '${plan.id}/${day.name}',
          );
        }
      }
    });

    test('every category has at least one plan', () {
      final categories = PlanLibrary.categories;
      expect(categories, isNotEmpty);
      for (final category in categories) {
        expect(PlanLibrary.byCategory(category), isNotEmpty, reason: category);
      }
    });

    test('covers the sports the library promises', () {
      final categories = PlanLibrary.categories;
      expect(
        categories,
        containsAll(['Gym', 'Home', 'Running', 'Swimming', 'Cycling']),
      );
    });

    test('search matches name, category and day names', () {
      expect(PlanLibrary.search('bro split'), isNotEmpty);
      expect(PlanLibrary.search('swimming'), isNotEmpty);
      expect(PlanLibrary.search('Norwegian'), isNotEmpty);
      expect(PlanLibrary.search(''), hasLength(PlanLibrary.all.length));
      expect(PlanLibrary.search('zzzz-no-such-plan'), isEmpty);
    });

    test('byId finds a plan and returns null otherwise', () {
      expect(PlanLibrary.byId('gym_bro_split')?.name, 'Bro Split');
      expect(PlanLibrary.byId('missing'), isNull);
    });
  });

  group('PlanWorkoutBuilder', () {
    test('regenerates ids and keeps exercise order', () {
      final plan = PlanLibrary.byId('gym_bro_split')!;
      final day = plan.days.first;
      var counter = 0;
      final workout = PlanWorkoutBuilder.buildWorkoutFromPlanDay(
        plan,
        day,
        newId: () => 'id_${counter++}',
        now: DateTime(2026, 1, 1),
      );

      expect(workout.name, 'Chest');
      expect(workout.section, 'Bro Split');
      expect(workout.exercises.length, day.exercises.length);
      for (var i = 0; i < day.exercises.length; i++) {
        expect(workout.exercises[i].name, day.exercises[i].name);
        expect(workout.exercises[i].id, isNot(day.exercises[i].id));
        expect(workout.exercises[i].id, startsWith('id_'));
      }
      expect(workout.id, startsWith('id_'));
      expect(workout.createdAt, DateTime(2026, 1, 1));
      expect(workout.updatedAt, DateTime(2026, 1, 1));
    });

    test('single-day plans use the plan name', () {
      final plan = PlanLibrary.byId('home_ten_minute_core')!;
      final workout = PlanWorkoutBuilder.buildWorkoutFromPlanDay(
        plan,
        plan.days.single,
      );
      expect(workout.name, plan.name);
      expect(workout.section, isNull);
    });

    test('buildWorkoutsFromPlan returns one workout per day', () {
      final plan = PlanLibrary.byId('running_couch_to_5k')!;
      final workouts = PlanWorkoutBuilder.buildWorkoutsFromPlan(plan);
      expect(workouts.length, plan.days.length);
      final ids = workouts.map((workout) => workout.id).toSet();
      expect(ids.length, workouts.length);
      expect(workouts.every((workout) => workout.section == plan.name), isTrue);
    });
  });

  group('Home sections', () {
    Workout fake(String id, {String? section}) {
      return Workout(
        id: id,
        name: id,
        exercises: const <Exercise>[],
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        section: section,
      );
    }

    test('gathers the same section at its first appearance', () {
      final groups = groupWorkoutsForHome([
        fake('push'),
        fake('chest', section: 'Bro Split'),
        fake('core'),
        fake('back', section: 'Bro Split'),
      ]);
      expect(groups, hasLength(3));
      expect(groups[0].section, isNull);
      expect(groups[0].workouts.single.id, 'push');
      expect(groups[1].section, 'Bro Split');
      expect(groups[1].workouts.map((w) => w.id), ['chest', 'back']);
      expect(groups[2].workouts.single.id, 'core');
    });

    test('omits section from JSON when ungrouped', () {
      final workout = fake('solo');
      expect(workout.toJson().containsKey('section'), isFalse);
      final restored = Workout.fromJson({
        ...workout.toJson(),
        'section': '  Gym  ',
      });
      expect(restored.section, 'Gym');
    });
  });
}
