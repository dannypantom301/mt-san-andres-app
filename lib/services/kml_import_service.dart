import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:xml/xml.dart';

import '../models/asset_point.dart';
import '../models/asset_type.dart';
import '../models/import_result.dart';

class KmlImportException implements Exception {
  const KmlImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

class KmlImportService {
  const KmlImportService();

  ImportResult parseFile({
    required String fileName,
    required List<int> bytes,
    required AssetType type,
    required int startIndex,
  }) {
    final content = _readKmlContent(fileName, bytes);
    final document = _parseXml(content, fileName);
    final placemarks = document.findAllElements('Placemark').toList();
    final importedAt = DateTime.now();
    final points = <AssetPoint>[];
    var skipped = 0;

    for (final placemark in placemarks) {
      final position = _readPosition(placemark);
      if (position == null) {
        skipped++;
        continue;
      }

      final name = _readName(placemark);
      final sequence = startIndex + points.length + 1;

      points.add(
        AssetPoint(
          id: '${type.name}_$sequence',
          name: name.isEmpty ? '${type.label} $sequence' : name,
          type: type,
          position: position,
          sourceFile: fileName,
          importedAt: importedAt,
        ),
      );
    }

    return ImportResult(
      fileName: fileName,
      points: points,
      placemarkCount: placemarks.length,
      skippedCount: skipped,
    );
  }

  String _readKmlContent(String fileName, List<int> bytes) {
    final lowerName = fileName.toLowerCase();

    if (lowerName.endsWith('.kml')) {
      return utf8.decode(bytes, allowMalformed: true);
    }

    if (!lowerName.endsWith('.kmz')) {
      throw const KmlImportException('Selecciona un archivo .kml o .kmz.');
    }

    Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } on Object {
      throw const KmlImportException(
        'No pude abrir el KMZ. Verifica el archivo.',
      );
    }

    for (final file in archive.files) {
      if (!file.isFile || !file.name.toLowerCase().endsWith('.kml')) {
        continue;
      }

      final content = file.content;
      if (content is List<int>) {
        return utf8.decode(content, allowMalformed: true);
      }

      return utf8.decode(
        List<int>.from(content as Iterable),
        allowMalformed: true,
      );
    }

    throw const KmlImportException('El KMZ no contiene ningún archivo KML.');
  }

  XmlDocument _parseXml(String content, String fileName) {
    try {
      return XmlDocument.parse(content);
    } on Object {
      throw KmlImportException(
        'El archivo "$fileName" no tiene un KML válido.',
      );
    }
  }

  LatLng? _readPosition(XmlElement placemark) {
    for (final coordinates in placemark.findAllElements('coordinates')) {
      final position = _parseFirstCoordinate(coordinates.innerText);
      if (position != null) {
        return position;
      }
    }

    return null;
  }

  LatLng? _parseFirstCoordinate(String rawCoordinates) {
    final tuples = rawCoordinates.trim().split(RegExp(r'\s+'));

    for (final tuple in tuples) {
      final values = tuple.split(',');
      if (values.length < 2) {
        continue;
      }

      final lng = double.tryParse(values[0].trim());
      final lat = double.tryParse(values[1].trim());

      if (lat == null || lng == null) {
        continue;
      }

      if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
        continue;
      }

      return LatLng(lat, lng);
    }

    return null;
  }

  String _readName(XmlElement placemark) {
    for (final name in placemark.findElements('name')) {
      return name.innerText.trim();
    }

    return '';
  }
}
