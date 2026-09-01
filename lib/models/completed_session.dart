class CompletedSession {
  final String id;
  final String workoutId;
  final String workoutName;
  final DateTime completedAt;
  final int durationSeconds;
  final int totalExercises;

  const CompletedSession({
    required this.id,
    required this.workoutId,
    required this.workoutName,
    required this.completedAt,
    required this.durationSeconds,
    required this.totalExercises,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workoutId': workoutId,
      'workoutName': workoutName,
      'completedAt': completedAt.toIso8601String(),
      'durationSeconds': durationSeconds,
      'totalExercises': totalExercises,
    };
  }

  factory CompletedSession.fromJson(Map<String, dynamic> json) {
    return CompletedSession(
      id: json['id'] as String,
      workoutId: json['workoutId'] as String,
      workoutName: json['workoutName'] as String,
      completedAt: DateTime.parse(json['completedAt'] as String),
      durationSeconds: json['durationSeconds'] as int,
      totalExercises: json['totalExercises'] as int,
    );
  }

  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }
}
