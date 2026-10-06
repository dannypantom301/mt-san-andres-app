import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'asset_status.dart';
import 'asset_type.dart';

class AssetPoint {
  const AssetPoint({
    required this.id,
    required this.name,
    required this.type,
    required this.position,
    required this.sourceFile,
    required this.importedAt,
    this.status = AssetStatus.pendiente,
    this.lastObservation = '',
    this.lastUpdatedAt,
  });

  final String id;
  final String name;
  final AssetType type;
  final LatLng position;
  final String sourceFile;
  final DateTime importedAt;
  final AssetStatus status;
  final String lastObservation;
  final DateTime? lastUpdatedAt;

  String get searchableText {
    return [
      id,
      name,
      type.label,
      type.pluralLabel,
      status.label,
      sourceFile,
      lastObservation,
      position.latitude.toStringAsFixed(6),
      position.longitude.toStringAsFixed(6),
    ].join(' ').toLowerCase();
  }

  AssetPoint copyWith({
    String? name,
    AssetType? type,
    LatLng? position,
    String? sourceFile,
    DateTime? importedAt,
    AssetStatus? status,
    String? lastObservation,
    DateTime? lastUpdatedAt,
  }) {
    return AssetPoint(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      position: position ?? this.position,
      sourceFile: sourceFile ?? this.sourceFile,
      importedAt: importedAt ?? this.importedAt,
      status: status ?? this.status,
      lastObservation: lastObservation ?? this.lastObservation,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'sourceFile': sourceFile,
      'importedAt': importedAt.toIso8601String(),
      'status': status.name,
      'lastObservation': lastObservation,
      'lastUpdatedAt': lastUpdatedAt?.toIso8601String(),
    };
  }

  factory AssetPoint.fromJson(Map<String, dynamic> json) {
    return AssetPoint(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Activo',
      type: AssetType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => AssetType.caja,
      ),
      position: LatLng(
        _readDouble(json['latitude']),
        _readDouble(json['longitude']),
      ),
      sourceFile: json['sourceFile'] as String? ?? '',
      importedAt: DateTime.tryParse(json['importedAt'] as String? ?? '') ??
          DateTime.now(),
      status: assetStatusFromName(json['status'] as String?),
      lastObservation: json['lastObservation'] as String? ?? '',
      lastUpdatedAt: DateTime.tryParse(json['lastUpdatedAt'] as String? ?? ''),
    );
  }
}

double _readDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse('$value') ?? 0;
}
