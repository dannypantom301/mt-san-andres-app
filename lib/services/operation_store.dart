import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/operation_snapshot.dart';

class OperationStore {
  const OperationStore();

  static const storageKey = 'ams_mapa_operation_snapshot_v2';

  Future<OperationSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);

    if (raw == null || raw.isEmpty) {
      return OperationSnapshot.empty();
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return OperationSnapshot.fromJson(decoded);
      }
      if (decoded is Map) {
        return OperationSnapshot.fromJson(Map<String, dynamic>.from(decoded));
      }
    } on Object {
      return OperationSnapshot.empty();
    }

    return OperationSnapshot.empty();
  }

  Future<void> save(OperationSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, jsonEncode(snapshot.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }

  Future<OperationStoreDiagnostics> inspect() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);

    if (raw == null || raw.isEmpty) {
      return OperationStoreDiagnostics.empty(storageKey: storageKey);
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return OperationStoreDiagnostics.fromSnapshot(
          storageKey: storageKey,
          rawBytes: utf8.encode(raw).length,
          snapshot: OperationSnapshot.fromJson(decoded),
        );
      }
      if (decoded is Map) {
        return OperationStoreDiagnostics.fromSnapshot(
          storageKey: storageKey,
          rawBytes: utf8.encode(raw).length,
          snapshot: OperationSnapshot.fromJson(
            Map<String, dynamic>.from(decoded),
          ),
        );
      }
    } on Object catch (error) {
      return OperationStoreDiagnostics.invalid(
        storageKey: storageKey,
        rawBytes: utf8.encode(raw).length,
        errorMessage: '$error',
      );
    }

    return OperationStoreDiagnostics.invalid(
      storageKey: storageKey,
      rawBytes: utf8.encode(raw).length,
      errorMessage: 'La estructura guardada no es un objeto JSON.',
    );
  }
}

class OperationStoreDiagnostics {
  const OperationStoreDiagnostics({
    required this.storageKey,
    required this.hasData,
    required this.validJson,
    required this.rawBytes,
    required this.assetCount,
    required this.taskCount,
    required this.routeCount,
    required this.eventCount,
    required this.evidenceCount,
    required this.pendingSyncCount,
    this.lastEventAt,
    this.errorMessage = '',
  });

  factory OperationStoreDiagnostics.empty({required String storageKey}) {
    return OperationStoreDiagnostics(
      storageKey: storageKey,
      hasData: false,
      validJson: true,
      rawBytes: 0,
      assetCount: 0,
      taskCount: 0,
      routeCount: 0,
      eventCount: 0,
      evidenceCount: 0,
      pendingSyncCount: 0,
    );
  }

  factory OperationStoreDiagnostics.invalid({
    required String storageKey,
    required int rawBytes,
    required String errorMessage,
  }) {
    return OperationStoreDiagnostics(
      storageKey: storageKey,
      hasData: true,
      validJson: false,
      rawBytes: rawBytes,
      assetCount: 0,
      taskCount: 0,
      routeCount: 0,
      eventCount: 0,
      evidenceCount: 0,
      pendingSyncCount: 0,
      errorMessage: errorMessage,
    );
  }

  factory OperationStoreDiagnostics.fromSnapshot({
    required String storageKey,
    required int rawBytes,
    required OperationSnapshot snapshot,
  }) {
    DateTime? lastEventAt;
    for (final event in snapshot.events) {
      if (lastEventAt == null || event.createdAt.isAfter(lastEventAt)) {
        lastEventAt = event.createdAt;
      }
    }

    return OperationStoreDiagnostics(
      storageKey: storageKey,
      hasData: true,
      validJson: true,
      rawBytes: rawBytes,
      assetCount: snapshot.assets.length,
      taskCount: snapshot.tasks.length,
      routeCount: snapshot.routes.length,
      eventCount: snapshot.events.length,
      evidenceCount: snapshot.tasks.fold(
        0,
        (sum, task) => sum + task.evidence.length,
      ),
      pendingSyncCount: snapshot.events.where((event) => !event.synced).length,
      lastEventAt: lastEventAt,
    );
  }

  final String storageKey;
  final bool hasData;
  final bool validJson;
  final int rawBytes;
  final int assetCount;
  final int taskCount;
  final int routeCount;
  final int eventCount;
  final int evidenceCount;
  final int pendingSyncCount;
  final DateTime? lastEventAt;
  final String errorMessage;

  bool get isHealthy => validJson && (hasData || rawBytes == 0);

  String get statusLabel {
    if (!validJson) {
      return 'Base local con error';
    }
    if (!hasData) {
      return 'Base local vacia';
    }
    return 'Base local sana';
  }

  String get sizeLabel {
    if (rawBytes < 1024) {
      return '$rawBytes B';
    }

    return '${(rawBytes / 1024).toStringAsFixed(1)} KB';
  }
}
