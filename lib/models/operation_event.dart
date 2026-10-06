import 'package:flutter/material.dart';

enum OperationEventType {
  importacion,
  tarea,
  evidencia,
  sincronizacion,
  sistema,
}

class OperationEvent {
  const OperationEvent({
    required this.id,
    required this.type,
    required this.title,
    required this.detail,
    required this.createdAt,
    required this.synced,
  });

  final String id;
  final OperationEventType type;
  final String title;
  final String detail;
  final DateTime createdAt;
  final bool synced;

  IconData get icon {
    switch (type) {
      case OperationEventType.importacion:
        return Icons.upload_file_outlined;
      case OperationEventType.tarea:
        return Icons.task_alt_outlined;
      case OperationEventType.evidencia:
        return Icons.photo_camera_outlined;
      case OperationEventType.sincronizacion:
        return Icons.sync_outlined;
      case OperationEventType.sistema:
        return Icons.info_outline;
    }
  }

  Color get color {
    switch (type) {
      case OperationEventType.importacion:
        return const Color(0xFF0E7C86);
      case OperationEventType.tarea:
        return const Color(0xFF2563EB);
      case OperationEventType.evidencia:
        return const Color(0xFF7C3AED);
      case OperationEventType.sincronizacion:
        return const Color(0xFF16803C);
      case OperationEventType.sistema:
        return const Color(0xFF475569);
    }
  }

  OperationEvent copyWith({bool? synced}) {
    return OperationEvent(
      id: id,
      type: type,
      title: title,
      detail: detail,
      createdAt: createdAt,
      synced: synced ?? this.synced,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'detail': detail,
      'createdAt': createdAt.toIso8601String(),
      'synced': synced,
    };
  }

  factory OperationEvent.fromJson(Map<String, dynamic> json) {
    return OperationEvent(
      id: json['id'] as String? ?? '',
      type: OperationEventType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => OperationEventType.sistema,
      ),
      title: json['title'] as String? ?? 'Evento',
      detail: json['detail'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      synced: json['synced'] as bool? ?? false,
    );
  }
}
