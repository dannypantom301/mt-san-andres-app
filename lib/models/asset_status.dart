import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum AssetStatus { activo, pendiente, danado, atendido }

extension AssetStatusDetails on AssetStatus {
  String get label {
    switch (this) {
      case AssetStatus.activo:
        return 'Activo';
      case AssetStatus.pendiente:
        return 'Pendiente';
      case AssetStatus.danado:
        return 'Danado';
      case AssetStatus.atendido:
        return 'Atendido';
    }
  }

  IconData get icon {
    switch (this) {
      case AssetStatus.activo:
        return Icons.check_circle_outline;
      case AssetStatus.pendiente:
        return Icons.pending_actions_outlined;
      case AssetStatus.danado:
        return Icons.report_problem_outlined;
      case AssetStatus.atendido:
        return Icons.task_alt_outlined;
    }
  }

  Color get color {
    switch (this) {
      case AssetStatus.activo:
        return const Color(0xFF16803C);
      case AssetStatus.pendiente:
        return const Color(0xFFD97706);
      case AssetStatus.danado:
        return const Color(0xFFDC2626);
      case AssetStatus.atendido:
        return const Color(0xFF2563EB);
    }
  }

  double get markerHue {
    switch (this) {
      case AssetStatus.activo:
        return BitmapDescriptor.hueGreen;
      case AssetStatus.pendiente:
        return BitmapDescriptor.hueYellow;
      case AssetStatus.danado:
        return BitmapDescriptor.hueRed;
      case AssetStatus.atendido:
        return BitmapDescriptor.hueAzure;
    }
  }
}

AssetStatus assetStatusFromName(String? value) {
  return AssetStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => AssetStatus.pendiente,
  );
}
