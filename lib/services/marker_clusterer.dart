import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/asset_point.dart';

class AssetCluster {
  const AssetCluster({
    required this.id,
    required this.points,
    required this.position,
  });

  final String id;
  final List<AssetPoint> points;
  final LatLng position;

  bool get isSingle => points.length == 1;
}

class MarkerClusterer {
  const MarkerClusterer();

  List<AssetCluster> cluster(Iterable<AssetPoint> points, double zoom) {
    final step = _gridStepForZoom(zoom);
    final groups = <String, List<AssetPoint>>{};

    for (final point in points) {
      final latCell = (point.position.latitude / step).floor();
      final lngCell = (point.position.longitude / step).floor();
      final key = '${zoom.floor()}_$latCell:$lngCell';
      groups.putIfAbsent(key, () => <AssetPoint>[]).add(point);
    }

    return groups.entries.map((entry) {
      final grouped = entry.value;
      var lat = 0.0;
      var lng = 0.0;

      for (final point in grouped) {
        lat += point.position.latitude;
        lng += point.position.longitude;
      }

      return AssetCluster(
        id: grouped.length == 1 ? grouped.first.id : 'cluster_${entry.key}',
        points: grouped,
        position: LatLng(lat / grouped.length, lng / grouped.length),
      );
    }).toList(growable: false);
  }

  double _gridStepForZoom(double zoom) {
    if (zoom <= 11) {
      return 0.0100;
    }
    if (zoom <= 13) {
      return 0.0045;
    }
    if (zoom <= 15) {
      return 0.0020;
    }
    if (zoom <= 17) {
      return 0.0007;
    }

    return math.max(0.00005, 0.0002 / (zoom - 16));
  }
}
