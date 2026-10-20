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
    CatalogExercise(id: 'lat_pulldown', name: 'Lat Pulldown', category: 'Strength'),
    CatalogExercise(id: 'seated_cable_row', name: 'Seated Cable Row', category: 'Strength'),
    CatalogExercise(id: 'lateral_raise', name: 'Lateral Raise', category: 'Strength'),
    CatalogExercise(id: 'face_pull', name: 'Face Pull', category: 'Strength'),
    CatalogExercise(id: 'leg_press', name: 'Leg Press', category: 'Strength'),
    CatalogExercise(id: 'leg_curl', name: 'Leg Curl', category: 'Strength'),
    CatalogExercise(id: 'calf_raise', name: 'Calf Raise', category: 'Strength'),
    CatalogExercise(id: 'barbell_curl', name: 'Barbell Curl', category: 'Strength'),
    CatalogExercise(id: 'triceps_pushdown', name: 'Triceps Pushdown', category: 'Strength'),

    // Kettlebell
    CatalogExercise(id: 'kettlebell_swing', name: 'Kettlebell Swing', category: 'Kettlebell'),
    CatalogExercise(id: 'goblet_squat', name: 'Goblet Squat', category: 'Kettlebell'),
    CatalogExercise(id: 'gorilla_row', name: 'Gorilla Row', category: 'Kettlebell'),
    CatalogExercise(id: 'kettlebell_shoulder_press', name: 'Kettlebell Shoulder Press', category: 'Kettlebell'),

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

    // Running
    CatalogExercise(id: 'brisk_walk', name: 'Brisk Walk', category: 'Running'),
    CatalogExercise(id: 'easy_run', name: 'Easy Run', category: 'Running'),
    CatalogExercise(id: 'tempo_run', name: 'Tempo Run', category: 'Running'),
    CatalogExercise(id: 'hill_sprint', name: 'Hill Sprint', category: 'Running'),

    // Swimming
    CatalogExercise(id: 'freestyle', name: 'Freestyle', category: 'Swimming'),
    CatalogExercise(id: 'kick', name: 'Kick', category: 'Swimming'),
    CatalogExercise(id: 'pull', name: 'Pull', category: 'Swimming'),
    CatalogExercise(id: 'swim_drill', name: 'Drill', category: 'Swimming'),

    // Cycling
    CatalogExercise(id: 'easy_spin', name: 'Easy Spin', category: 'Cycling'),
    CatalogExercise(id: 'sweet_spot', name: 'Sweet Spot', category: 'Cycling'),
    CatalogExercise(id: 'vo2_interval', name: 'VO2 Interval', category: 'Cycling'),

    // Rowing
    CatalogExercise(id: 'steady_row', name: 'Steady Row', category: 'Rowing'),
    CatalogExercise(id: 'row_interval', name: 'Row Interval', category: 'Rowing'),
    CatalogExercise(id: 'row_500m', name: '500m Row', category: 'Rowing'),

    // Boxing
    CatalogExercise(id: 'shadow_boxing', name: 'Shadow Boxing', category: 'Boxing'),
    CatalogExercise(id: 'heavy_bag_round', name: 'Heavy Bag Round', category: 'Boxing'),

    // Mobility
    CatalogExercise(id: 'cat_cow', name: 'Cat-Cow', category: 'Mobility'),
    CatalogExercise(id: 'childs_pose', name: "Child's Pose", category: 'Mobility'),
    CatalogExercise(id: 'downward_dog', name: 'Downward Dog', category: 'Mobility'),
    CatalogExercise(id: 'low_lunge', name: 'Low Lunge', category: 'Mobility'),
    CatalogExercise(id: 'pigeon', name: 'Pigeon', category: 'Mobility'),
    CatalogExercise(id: 'ninety_ninety', name: '90/90 Hip Stretch', category: 'Mobility'),
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
