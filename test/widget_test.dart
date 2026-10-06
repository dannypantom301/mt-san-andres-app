import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:flutter_test/flutter_test.dart';
import 'package:mtsanandres_base/app.dart';
import 'package:mtsanandres_base/models/asset_status.dart';
import 'package:mtsanandres_base/models/asset_type.dart';
import 'package:mtsanandres_base/services/kml_import_service.dart';
import 'package:mtsanandres_base/services/operation_store.dart';
import 'package:mtsanandres_base/ui/home_map_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('KmlImportService', () {
    test('parsea puntos desde KML', () {
      const service = KmlImportService();
      final result = service.parseFile(
        fileName: 'cajas.kml',
        bytes: utf8.encode(_sampleKml),
        type: AssetType.caja,
        startIndex: 0,
      );

      expect(result.points, hasLength(2));
      expect(result.placemarkCount, 3);
      expect(result.skippedCount, 1);
      expect(result.points.first.name, 'Caja 001');
      expect(result.points.first.status, AssetStatus.pendiente);
      expect(result.points.first.position.latitude, closeTo(12.5847, 0.00001));
      expect(
        result.points.first.position.longitude,
        closeTo(-81.7006, 0.00001),
      );
    });

    test('parsea el primer KML dentro de un KMZ', () {
      const service = KmlImportService();
      final kmlBytes = utf8.encode(_sampleKml);
      final archive = Archive()
        ..addFile(ArchiveFile('doc.kml', kmlBytes.length, kmlBytes));
      final kmzBytes = ZipEncoder().encode(archive)!;

      final result = service.parseFile(
        fileName: 'trafos.kmz',
        bytes: kmzBytes,
        type: AssetType.trafo,
        startIndex: 10,
      );

      expect(result.points, hasLength(2));
      expect(result.points.first.id, 'trafo_11');
      expect(result.points.first.type, AssetType.trafo);
    });
  });

  test('OperationStore reporta base local vacia', () async {
    SharedPreferences.setMockInitialValues({});

    final diagnostics = await const OperationStore().inspect();

    expect(diagnostics.hasData, isFalse);
    expect(diagnostics.validJson, isTrue);
    expect(diagnostics.statusLabel, 'Base local vacia');
    expect(diagnostics.rawBytes, 0);
  });

  testWidgets('muestra mapa, panel y tabs principales', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MtSanAndresApp(
        home: HomeMapPage(
          initialPanelOpen: true,
          mapBuilder: (context, configuration) {
            return ColoredBox(
              color: const Color(0xFFE4EEF1),
              child: Center(
                child: Text('Mapa de prueba: ${configuration.markers.length}'),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mapa de prueba: 0'), findsOneWidget);
    expect(find.text('0/0'), findsOneWidget);
    expect(find.text('0 pend.'), findsOneWidget);
    expect(find.text('MT San Andres', skipOffstage: false), findsWidgets);
    expect(find.text('Importar KML/KMZ', skipOffstage: false), findsOneWidget);

    await tester.tap(find.text('Rutas').last);
    await tester.pumpAndSettle();

    expect(find.text('Sin tareas asignadas'), findsOneWidget);
  });

  testWidgets('control muestra estado de base local y Firebase',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MtSanAndresApp(
        home: HomeMapPage(
          mapBuilder: (context, configuration) {
            return const ColoredBox(color: Color(0xFFE4EEF1));
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Control', skipOffstage: false).last);
    await tester.pumpAndSettle();

    expect(
      find.text('Supervision, base local y estado de sincronizacion'),
      findsOneWidget,
    );
    expect(
        find.textContaining('Base local', skipOffstage: false), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Firebase revisado'),
      280,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Firebase revisado'), findsOneWidget);
  });

  testWidgets('mapa operativo arranca blindado sin Google nativo',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MtSanAndresApp(home: HomeMapPage()));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Mapa blindado'), findsOneWidget);
    expect(find.text('Probar Google'), findsNothing);
    expect(find.byType(fm.FlutterMap), findsOneWidget);
    expect(find.byType(fm.PolygonLayer), findsOneWidget);
  });
}

const _sampleKml = '''
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <Placemark>
      <name>Caja 001</name>
      <Point>
        <coordinates>-81.7006,12.5847,0</coordinates>
      </Point>
    </Placemark>
    <Placemark>
      <name>Caja 002</name>
      <Point>
        <coordinates>-81.7011,12.5851,0</coordinates>
      </Point>
    </Placemark>
    <Placemark>
      <name>Sin coordenada</name>
    </Placemark>
  </Document>
</kml>
''';
