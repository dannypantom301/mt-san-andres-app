import 'package:google_maps_flutter/google_maps_flutter.dart';

enum TaskStatus { pendiente, enProceso, completada, bloqueada }

extension TaskStatusDetails on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.pendiente:
        return 'Pendiente';
      case TaskStatus.enProceso:
        return 'En proceso';
      case TaskStatus.completada:
        return 'Completada';
      case TaskStatus.bloqueada:
        return 'Bloqueada';
    }
  }
}

TaskStatus taskStatusFromName(String? value) {
  return TaskStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => TaskStatus.pendiente,
  );
}

class EvidenceRecord {
  const EvidenceRecord({
    required this.id,
    required this.fileName,
    required this.sizeBytes,
    required this.createdAt,
    this.localPath,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String fileName;
  final int sizeBytes;
  final DateTime createdAt;
  final String? localPath;
  final double? latitude;
  final double? longitude;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'sizeBytes': sizeBytes,
      'createdAt': createdAt.toIso8601String(),
      'localPath': localPath,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory EvidenceRecord.fromJson(Map<String, dynamic> json) {
    return EvidenceRecord(
      id: json['id'] as String? ?? '',
      fileName: json['fileName'] as String? ?? 'evidencia',
      sizeBytes: json['sizeBytes'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      localPath: json['localPath'] as String?,
      latitude: _readNullableDouble(json['latitude']),
      longitude: _readNullableDouble(json['longitude']),
    );
  }
}

class FieldTask {
  const FieldTask({
    required this.id,
    required this.assetId,
    required this.routeId,
    required this.technicianId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.observation = '',
    this.evidence = const [],
    this.completedLatitude,
    this.completedLongitude,
  });

  final String id;
  final String assetId;
  final String routeId;
  final String technicianId;
  final TaskStatus status;
  final String observation;
  final List<EvidenceRecord> evidence;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? completedLatitude;
  final double? completedLongitude;

  bool get hasEvidence => evidence.isNotEmpty;
  bool get isCompleted => status == TaskStatus.completada;

  LatLng? get completedPosition {
    if (completedLatitude == null || completedLongitude == null) {
      return null;
    }

    return LatLng(completedLatitude!, completedLongitude!);
  }

  FieldTask copyWith({
    String? routeId,
    String? technicianId,
    TaskStatus? status,
    String? observation,
    List<EvidenceRecord>? evidence,
    DateTime? updatedAt,
    double? completedLatitude,
    double? completedLongitude,
  }) {
    return FieldTask(
      id: id,
      assetId: assetId,
      routeId: routeId ?? this.routeId,
      technicianId: technicianId ?? this.technicianId,
      status: status ?? this.status,
      observation: observation ?? this.observation,
      evidence: evidence ?? this.evidence,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      completedLatitude: completedLatitude ?? this.completedLatitude,
      completedLongitude: completedLongitude ?? this.completedLongitude,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assetId': assetId,
      'routeId': routeId,
      'technicianId': technicianId,
      'status': status.name,
      'observation': observation,
      'evidence': evidence.map((record) => record.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'completedLatitude': completedLatitude,
      'completedLongitude': completedLongitude,
    };
  }

  factory FieldTask.fromJson(Map<String, dynamic> json) {
    return FieldTask(
      id: json['id'] as String? ?? '',
      assetId: json['assetId'] as String? ?? '',
      routeId: json['routeId'] as String? ?? '',
      technicianId: json['technicianId'] as String? ?? 'tecnico-1',
      status: taskStatusFromName(json['status'] as String?),
      observation: json['observation'] as String? ?? '',
      evidence: (json['evidence'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => EvidenceRecord.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      completedLatitude: _readNullableDouble(json['completedLatitude']),
      completedLongitude: _readNullableDouble(json['completedLongitude']),
    );
  }
}

double? _readNullableDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value == null) {
    return null;
  }

  return double.tryParse('$value');
}
