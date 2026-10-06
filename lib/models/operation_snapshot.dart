import 'asset_point.dart';
import 'field_route.dart';
import 'field_task.dart';
import 'operation_event.dart';

class OperationSnapshot {
  const OperationSnapshot({
    required this.assets,
    required this.tasks,
    required this.routes,
    required this.events,
    required this.onlineMode,
    required this.activeRole,
    required this.activeTechnician,
  });

  factory OperationSnapshot.empty() {
    return const OperationSnapshot(
      assets: [],
      tasks: [],
      routes: [],
      events: [],
      onlineMode: true,
      activeRole: 'supervisor',
      activeTechnician: 'Tecnico 1',
    );
  }

  final List<AssetPoint> assets;
  final List<FieldTask> tasks;
  final List<FieldRoute> routes;
  final List<OperationEvent> events;
  final bool onlineMode;
  final String activeRole;
  final String activeTechnician;

  OperationSnapshot copyWith({
    List<AssetPoint>? assets,
    List<FieldTask>? tasks,
    List<FieldRoute>? routes,
    List<OperationEvent>? events,
    bool? onlineMode,
    String? activeRole,
    String? activeTechnician,
  }) {
    return OperationSnapshot(
      assets: assets ?? this.assets,
      tasks: tasks ?? this.tasks,
      routes: routes ?? this.routes,
      events: events ?? this.events,
      onlineMode: onlineMode ?? this.onlineMode,
      activeRole: activeRole ?? this.activeRole,
      activeTechnician: activeTechnician ?? this.activeTechnician,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assets': assets.map((asset) => asset.toJson()).toList(),
      'tasks': tasks.map((task) => task.toJson()).toList(),
      'routes': routes.map((route) => route.toJson()).toList(),
      'events': events.map((event) => event.toJson()).toList(),
      'onlineMode': onlineMode,
      'activeRole': activeRole,
      'activeTechnician': activeTechnician,
    };
  }

  factory OperationSnapshot.fromJson(Map<String, dynamic> json) {
    return OperationSnapshot(
      assets: (json['assets'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => AssetPoint.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false),
      tasks: (json['tasks'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => FieldTask.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false),
      routes: (json['routes'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => FieldRoute.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false),
      events: (json['events'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => OperationEvent.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
      onlineMode: json['onlineMode'] as bool? ?? true,
      activeRole: json['activeRole'] as String? ?? 'supervisor',
      activeTechnician: json['activeTechnician'] as String? ?? 'Tecnico 1',
    );
  }
}
