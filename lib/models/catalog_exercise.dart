class CatalogExercise {
  final String id;
  final String name;
  final String category;

  const CatalogExercise({
    required this.id,
    required this.name,
    required this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
    };
  }

  factory CatalogExercise.fromJson(Map<String, dynamic> json) {
    return CatalogExercise(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
    );
  }
}

/// Built-in exercise catalog (offline)
class ExerciseCatalog {
  static const List<CatalogExercise> all = [
    // Strength
    CatalogExercise(id: 'deadlift', name: 'Deadlift', category: 'Strength'),
    CatalogExercise(id: 'squat', name: 'Squat', category: 'Strength'),
    CatalogExercise(id: 'bench_press', name: 'Bench Press', category: 'Strength'),
    CatalogExercise(id: 'overhead_press', name: 'Overhead Press', category: 'Strength'),
    CatalogExercise(id: 'barbell_row', name: 'Barbell Row', category: 'Strength'),
    CatalogExercise(id: 'romanian_deadlift', name: 'Romanian Deadlift', category: 'Strength'),
    CatalogExercise(id: 'lunges', name: 'Lunges', category: 'Strength'),
    CatalogExercise(id: 'hip_thrust', name: 'Hip Thrust', category: 'Strength'),

    // Bodyweight
    CatalogExercise(id: 'push_ups', name: 'Push-ups', category: 'Bodyweight'),
    CatalogExercise(id: 'pull_ups', name: 'Pull-ups', category: 'Bodyweight'),
    CatalogExercise(id: 'dips', name: 'Dips', category: 'Bodyweight'),
    CatalogExercise(id: 'bodyweight_squat', name: 'Bodyweight Squat', category: 'Bodyweight'),
    CatalogExercise(id: 'pike_push_ups', name: 'Pike Push-ups', category: 'Bodyweight'),
    CatalogExercise(id: 'inverted_rows', name: 'Inverted Rows', category: 'Bodyweight'),

    // Core
    CatalogExercise(id: 'plank', name: 'Plank', category: 'Core'),
    CatalogExercise(id: 'side_plank', name: 'Side Plank', category: 'Core'),
    CatalogExercise(id: 'crunches', name: 'Crunches', category: 'Core'),
    CatalogExercise(id: 'leg_raises', name: 'Leg Raises', category: 'Core'),
    CatalogExercise(id: 'russian_twists', name: 'Russian Twists', category: 'Core'),
    CatalogExercise(id: 'ab_wheel', name: 'Ab Wheel', category: 'Core'),

    // Cardio / HIIT
    CatalogExercise(id: 'burpees', name: 'Burpees', category: 'Cardio'),
    CatalogExercise(id: 'jumping_jacks', name: 'Jumping Jacks', category: 'Cardio'),
    CatalogExercise(id: 'mountain_climbers', name: 'Mountain Climbers', category: 'Cardio'),
    CatalogExercise(id: 'high_knees', name: 'High Knees', category: 'Cardio'),
    CatalogExercise(id: 'jump_rope', name: 'Jump Rope', category: 'Cardio'),
    CatalogExercise(id: 'box_jumps', name: 'Box Jumps', category: 'Cardio'),
    CatalogExercise(id: 'kettlebell_swings', name: 'Kettlebell Swings', category: 'Cardio'),
  ];

  static List<String> get categories {
    return all.map((e) => e.category).toSet().toList()..sort();
  }

  static List<CatalogExercise> byCategory(String category) {
    return all.where((e) => e.category == category).toList();
  }

  static List<CatalogExercise> search(String query) {
    final lower = query.toLowerCase().trim();
    if (lower.isEmpty) return all;
    return all.where((e) => e.name.toLowerCase().contains(lower)).toList();
  }
}
