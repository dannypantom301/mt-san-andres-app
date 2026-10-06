import 'asset_point.dart';

class ImportResult {
  const ImportResult({
    required this.fileName,
    required this.points,
    required this.placemarkCount,
    required this.skippedCount,
  });

  final String fileName;
  final List<AssetPoint> points;
  final int placemarkCount;
  final int skippedCount;

  bool get hasPoints => points.isNotEmpty;
}
