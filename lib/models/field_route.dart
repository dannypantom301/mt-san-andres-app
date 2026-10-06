class FieldRoute {
  const FieldRoute({
    required this.id,
    required this.name,
    required this.technicianId,
    required this.date,
    required this.taskIds,
  });

  final String id;
  final String name;
  final String technicianId;
  final DateTime date;
  final List<String> taskIds;

  FieldRoute copyWith({
    String? name,
    String? technicianId,
    DateTime? date,
    List<String>? taskIds,
  }) {
    return FieldRoute(
      id: id,
      name: name ?? this.name,
      technicianId: technicianId ?? this.technicianId,
      date: date ?? this.date,
      taskIds: taskIds ?? this.taskIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'technicianId': technicianId,
      'date': date.toIso8601String(),
      'taskIds': taskIds,
    };
  }

  factory FieldRoute.fromJson(Map<String, dynamic> json) {
    return FieldRoute(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Ruta',
      technicianId: json['technicianId'] as String? ?? 'tecnico-1',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      taskIds: (json['taskIds'] as List? ?? const [])
          .whereType<String>()
          .toList(growable: false),
    );
  }
}
