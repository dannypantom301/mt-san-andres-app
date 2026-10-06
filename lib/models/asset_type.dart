import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum AssetType { caja, trafo, gabinete, concentrador }

extension AssetTypeDetails on AssetType {
  String get label {
    switch (this) {
      case AssetType.caja:
        return 'Caja';
      case AssetType.trafo:
        return 'Trafo';
      case AssetType.gabinete:
        return 'Gabinete';
      case AssetType.concentrador:
        return 'Concentrador';
    }
  }

  String get pluralLabel {
    switch (this) {
      case AssetType.caja:
        return 'Cajas';
      case AssetType.trafo:
        return 'Trafos';
      case AssetType.gabinete:
        return 'Gabinetes';
      case AssetType.concentrador:
        return 'Concentradores';
    }
  }

  IconData get icon {
    switch (this) {
      case AssetType.caja:
        return Icons.inventory_2_outlined;
      case AssetType.trafo:
        return Icons.bolt_outlined;
      case AssetType.gabinete:
        return Icons.dns_outlined;
      case AssetType.concentrador:
        return Icons.router_outlined;
    }
  }

  Color get color {
    switch (this) {
      case AssetType.caja:
        return const Color(0xFF2563EB);
      case AssetType.trafo:
        return const Color(0xFFEA580C);
      case AssetType.gabinete:
        return const Color(0xFF16803C);
      case AssetType.concentrador:
        return const Color(0xFF7C3AED);
    }
  }

  double get markerHue {
    switch (this) {
      case AssetType.caja:
        return BitmapDescriptor.hueAzure;
      case AssetType.trafo:
        return BitmapDescriptor.hueOrange;
      case AssetType.gabinete:
        return BitmapDescriptor.hueGreen;
      case AssetType.concentrador:
        return BitmapDescriptor.hueViolet;
    }
  }
}
