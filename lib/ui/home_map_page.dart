import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../models/asset_point.dart';
import '../models/asset_status.dart';
import '../models/asset_type.dart';
import '../models/field_route.dart';
import '../models/field_task.dart';
import '../models/import_result.dart';
import '../models/operation_event.dart';
import '../models/operation_snapshot.dart';
import '../services/kml_import_service.dart';
import '../services/location_service.dart';
import '../services/marker_clusterer.dart';
import '../services/operation_store.dart';

typedef MapWidgetBuilder = Widget Function(
  BuildContext context,
  MapViewConfiguration configuration,
);

class MapViewConfiguration {
  const MapViewConfiguration({
    required this.initialCameraPosition,
    required this.mapType,
    required this.markers,
    required this.myLocationEnabled,
    required this.onMapCreated,
    required this.onCameraMove,
    required this.onCameraIdle,
  });

  final CameraPosition initialCameraPosition;
  final MapType mapType;
  final Set<Marker> markers;
  final bool myLocationEnabled;
  final ValueChanged<GoogleMapController> onMapCreated;
  final ValueChanged<CameraPosition> onCameraMove;
  final VoidCallback onCameraIdle;
}

const _sanAndresIsland = <ll.LatLng>[
  ll.LatLng(12.6190, -81.7070),
  ll.LatLng(12.6090, -81.6970),
  ll.LatLng(12.5880, -81.6940),
  ll.LatLng(12.5620, -81.7010),
  ll.LatLng(12.5380, -81.7120),
  ll.LatLng(12.5110, -81.7280),
  ll.LatLng(12.5260, -81.7400),
  ll.LatLng(12.5590, -81.7370),
  ll.LatLng(12.5940, -81.7270),
  ll.LatLng(12.6160, -81.7160),
];

const _sanAndresMainRoad = <ll.LatLng>[
  ll.LatLng(12.6140, -81.7075),
  ll.LatLng(12.5950, -81.7030),
  ll.LatLng(12.5740, -81.7075),
  ll.LatLng(12.5530, -81.7170),
  ll.LatLng(12.5300, -81.7300),
  ll.LatLng(12.5130, -81.7280),
  ll.LatLng(12.5350, -81.7180),
  ll.LatLng(12.5630, -81.7070),
  ll.LatLng(12.5940, -81.6990),
];

const _providenciaIsland = <ll.LatLng>[
  ll.LatLng(13.3940, -81.3860),
  ll.LatLng(13.3810, -81.3610),
  ll.LatLng(13.3560, -81.3490),
  ll.LatLng(13.3330, -81.3550),
  ll.LatLng(13.3180, -81.3760),
  ll.LatLng(13.3290, -81.3970),
  ll.LatLng(13.3580, -81.4020),
  ll.LatLng(13.3820, -81.3980),
];

const _providenciaRoad = <ll.LatLng>[
  ll.LatLng(13.3860, -81.3800),
  ll.LatLng(13.3690, -81.3630),
  ll.LatLng(13.3470, -81.3590),
  ll.LatLng(13.3270, -81.3770),
  ll.LatLng(13.3480, -81.3940),
  ll.LatLng(13.3740, -81.3930),
];

const _santaCatalinaIsland = <ll.LatLng>[
  ll.LatLng(13.4010, -81.3750),
  ll.LatLng(13.3980, -81.3660),
  ll.LatLng(13.3900, -81.3650),
  ll.LatLng(13.3890, -81.3750),
  ll.LatLng(13.3950, -81.3810),
];

class HomeMapPage extends StatefulWidget {
  const HomeMapPage({
    super.key,
    this.mapBuilder,
    this.initialPanelOpen = false,
    KmlImportService? importService,
    LocationService? locationService,
    MarkerClusterer? clusterer,
    OperationStore? store,
  })  : importService = importService ?? const KmlImportService(),
        locationService = locationService ?? const LocationService(),
        clusterer = clusterer ?? const MarkerClusterer(),
        store = store ?? const OperationStore();

  final MapWidgetBuilder? mapBuilder;
  final bool initialPanelOpen;
  final KmlImportService importService;
  final LocationService locationService;
  final MarkerClusterer clusterer;
  final OperationStore store;

  @override
  State<HomeMapPage> createState() => _HomeMapPageState();
}

class _HomeMapPageState extends State<HomeMapPage> {
  static const _sanAndres = LatLng(12.5847, -81.7006);
  static const _initialCamera = CameraPosition(target: _sanAndres, zoom: 14);

  final _searchController = TextEditingController();
  final _technicianController = TextEditingController(text: 'Tecnico 1');
  final _assets = <AssetPoint>[];
  final _tasks = <FieldTask>[];
  final _routes = <FieldRoute>[];
  final _events = <OperationEvent>[];
  final _visibleTypes = {for (final type in AssetType.values) type: true};
  final _visibleStatuses = {
    for (final status in AssetStatus.values) status: true,
  };

  final _osmMapController = fm.MapController();
  GoogleMapController? _googleMapController;
  AssetPoint? _selectedAsset;
  LatLng? _currentLocation;
  double? _currentLocationAccuracy;
  DateTime? _currentLocationAt;
  MapType _mapType = MapType.normal;
  final _useGoogleMaps = false;
  var _tileFallbackActive = false;
  var _currentZoom = 14.0;
  var _panelOpen = false;
  var _isImporting = false;
  var _isLoading = true;
  var _isSaving = false;
  var _myLocationEnabled = false;
  var _selectedTab = 0;
  var _onlineMode = true;
  var _activeRole = 'supervisor';
  var _activeTechnician = 'Tecnico 1';
  var _idCounter = 0;
  var _storeDiagnostics = OperationStoreDiagnostics.empty(
    storageKey: OperationStore.storageKey,
  );

  @override
  void initState() {
    super.initState();
    _panelOpen = widget.initialPanelOpen;
    _loadSnapshot();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _technicianController.dispose();
    _googleMapController?.dispose();
    super.dispose();
  }

  Future<void> _loadSnapshot() async {
    final snapshot = await widget.store.load();
    final diagnostics = await widget.store.inspect();

    if (!mounted) {
      return;
    }

    setState(() {
      _assets
        ..clear()
        ..addAll(snapshot.assets);
      _tasks
        ..clear()
        ..addAll(snapshot.tasks);
      _routes
        ..clear()
        ..addAll(snapshot.routes);
      _events
        ..clear()
        ..addAll(snapshot.events);
      _onlineMode = snapshot.onlineMode;
      _activeRole = snapshot.activeRole;
      _activeTechnician = snapshot.activeTechnician;
      _technicianController.text = _activeTechnician;
      _storeDiagnostics = diagnostics;
      _isLoading = false;
    });
  }

  Future<void> _persist() async {
    setState(() {
      _isSaving = true;
    });

    final snapshot = OperationSnapshot(
      assets: List.unmodifiable(_assets),
      tasks: List.unmodifiable(_tasks),
      routes: List.unmodifiable(_routes),
      events: List.unmodifiable(_events),
      onlineMode: _onlineMode,
      activeRole: _activeRole,
      activeTechnician: _activeTechnician,
    );

    await widget.store.save(snapshot);
    final diagnostics = await widget.store.inspect();

    if (mounted) {
      setState(() {
        _storeDiagnostics = diagnostics;
        _isSaving = false;
      });
    }
  }

  Future<void> _refreshDatabaseDiagnostics({bool showMessage = true}) async {
    final diagnostics = await widget.store.inspect();
    if (!mounted) {
      return;
    }

    setState(() {
      _storeDiagnostics = diagnostics;
    });

    if (showMessage) {
      _showSnack('Estado de base revisado: ${diagnostics.statusLabel}.');
    }
  }

  List<AssetPoint> get _filteredAssets {
    final query = _searchController.text.trim().toLowerCase();

    return _assets.where((asset) {
      if (!(_visibleTypes[asset.type] ?? true)) {
        return false;
      }
      if (!(_visibleStatuses[asset.status] ?? true)) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }

      return asset.searchableText.contains(query);
    }).toList(growable: false);
  }

  Map<AssetType, int> get _countsByType {
    final counts = {for (final type in AssetType.values) type: 0};

    for (final asset in _assets) {
      counts[asset.type] = (counts[asset.type] ?? 0) + 1;
    }

    return counts;
  }

  Map<AssetStatus, int> get _countsByStatus {
    final counts = {for (final status in AssetStatus.values) status: 0};

    for (final asset in _assets) {
      counts[asset.status] = (counts[asset.status] ?? 0) + 1;
    }

    return counts;
  }

  int get _pendingSyncCount => _events.where((event) => !event.synced).length;
  int get _completedTaskCount =>
      _tasks.where((task) => task.status == TaskStatus.completada).length;
  int get _blockedTaskCount =>
      _tasks.where((task) => task.status == TaskStatus.bloqueada).length;
  int get _evidenceCount =>
      _tasks.fold(0, (sum, task) => sum + task.evidence.length);

  double get _progress {
    if (_tasks.isEmpty) {
      return 0;
    }

    return _completedTaskCount / _tasks.length;
  }

  Future<void> _importAssetFile(AssetType type) async {
    if (_isImporting) {
      return;
    }

    setState(() {
      _isImporting = true;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['kml', 'kmz'],
        withData: true,
      );

      if (result == null) {
        return;
      }

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        throw const KmlImportException('No pude leer el archivo seleccionado.');
      }

      final import = widget.importService.parseFile(
        fileName: file.name,
        bytes: bytes,
        type: type,
        startIndex: _assets.length,
      );

      if (!mounted) {
        return;
      }

      if (!import.hasPoints) {
        _showSnack(
          'No encontre coordenadas validas en ${import.fileName}.',
          isError: true,
        );
        return;
      }

      final route = _ensureRouteForToday();
      final newTasks = _createTasksForImport(import, route.id);
      final updatedRoute = route.copyWith(
        taskIds: [...route.taskIds, ...newTasks.map((task) => task.id)],
      );

      setState(() {
        _upsertRoute(updatedRoute);
        _assets.addAll(import.points);
        _tasks.addAll(newTasks);
        _selectedAsset = import.points.first;
        _panelOpen = false;
        _selectedTab = 0;
        _addEvent(
          OperationEventType.importacion,
          'Importacion de ${type.pluralLabel.toLowerCase()}',
          '${import.points.length} activos y ${newTasks.length} tareas desde ${import.fileName}',
        );
      });

      await _persist();
      _showSnack(_importMessage(import, type));
      await _fitToPoints(import.points);
    } on KmlImportException catch (error) {
      _showSnack(error.message, isError: true);
    } on Object {
      _showSnack(
        'No pude importar el archivo. Revisa el formato e intenta otra vez.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  void _showImportChooser() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 22),
            children: [
              Text(
                'Subir mapas anteriores',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              const Text('Selecciona el tipo de activo para importar KML/KMZ.'),
              const SizedBox(height: 14),
              for (final type in AssetType.values)
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: type.color.withValues(alpha: 0.14),
                    child: Icon(type.icon, color: type.color),
                  ),
                  title: Text(type.pluralLabel),
                  subtitle: const Text('Archivo .kml o .kmz'),
                  trailing: const Icon(Icons.upload_file),
                  onTap: () {
                    Navigator.of(context).pop();
                    _importAssetFile(type);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  List<FieldTask> _createTasksForImport(ImportResult import, String routeId) {
    final now = DateTime.now();

    return import.points.map((asset) {
      return FieldTask(
        id: _newId('task'),
        assetId: asset.id,
        routeId: routeId,
        technicianId: _activeTechnician,
        status: TaskStatus.pendiente,
        createdAt: now,
        updatedAt: now,
      );
    }).toList(growable: false);
  }

  FieldRoute _ensureRouteForToday() {
    for (final route in _routes) {
      if (_sameDay(route.date, DateTime.now()) &&
          route.technicianId == _activeTechnician) {
        return route;
      }
    }

    final route = FieldRoute(
      id: _newId('route'),
      name: 'Ruta ${_formatDate(DateTime.now())}',
      technicianId: _activeTechnician,
      date: DateTime.now(),
      taskIds: const [],
    );
    _routes.add(route);
    return route;
  }

  void _upsertRoute(FieldRoute route) {
    final index = _routes.indexWhere((item) => item.id == route.id);
    if (index == -1) {
      _routes.add(route);
      return;
    }

    _routes[index] = route;
  }

  String _importMessage(ImportResult import, AssetType type) {
    final skipped =
        import.skippedCount == 0 ? '' : ' (${import.skippedCount} omitidos)';
    return '${import.points.length} ${type.pluralLabel.toLowerCase()} importados$skipped.';
  }

  Future<void> _goToMyLocation() async {
    try {
      final position = await widget.locationService.currentPosition();

      if (!mounted) {
        return;
      }

      final currentLocation = LatLng(position.latitude, position.longitude);

      setState(() {
        _myLocationEnabled = true;
        _currentLocation = currentLocation;
        _currentLocationAccuracy = position.accuracy;
        _currentLocationAt = position.timestamp;
      });

      await _moveMapTo(currentLocation, 19);
      _showSnack(
        'Ubicacion exacta: ${position.latitude.toStringAsFixed(7)}, '
        '${position.longitude.toStringAsFixed(7)} '
        '(${_formatAccuracy(position.accuracy)})',
      );
    } on LocationFailure catch (error) {
      _showSnack(error.message, isError: true);
    } on Object {
      _showSnack('No pude obtener tu ubicacion actual.', isError: true);
    }
  }

  Future<void> _fitToPoints(List<AssetPoint> points) async {
    if (points.isEmpty) {
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 250));

    if (points.length == 1) {
      await _moveMapTo(points.first.position, 18);
      return;
    }

    var minLat = points.first.position.latitude;
    var maxLat = points.first.position.latitude;
    var minLng = points.first.position.longitude;
    var maxLng = points.first.position.longitude;

    for (final point in points.skip(1)) {
      minLat = math.min(minLat, point.position.latitude);
      maxLat = math.max(maxLat, point.position.latitude);
      minLng = math.min(minLng, point.position.longitude);
      maxLng = math.max(maxLng, point.position.longitude);
    }

    final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
    final span = math.max((maxLat - minLat).abs(), (maxLng - minLng).abs());
    final zoom = _zoomForSpan(span);
    if (_useGoogleMaps && _googleMapController != null) {
      try {
        await _googleMapController?.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(minLat, minLng),
              northeast: LatLng(maxLat, maxLng),
            ),
            80,
          ),
        );
        return;
      } on Object {
        // Fallback to center/zoom if bounds are rejected before first layout.
      }
    }
    await _moveMapTo(center, zoom);
  }

  Future<void> _moveToAsset(AssetPoint asset) async {
    setState(() {
      _selectedAsset = asset;
      _selectedTab = 0;
    });

    await _moveMapTo(asset.position, math.max(_currentZoom, 17));
  }

  Future<void> _zoomToCluster(AssetCluster cluster) async {
    await _moveMapTo(cluster.position, math.min(20, _currentZoom + 2));
  }

  Future<void> _moveMapTo(LatLng position, double zoom) async {
    if (_useGoogleMaps && _googleMapController != null) {
      await _googleMapController?.animateCamera(
        CameraUpdate.newLatLngZoom(position, zoom),
      );
      return;
    }

    _osmMapController.move(_toOsm(position), zoom);
  }

  void _clearData() {
    if (_assets.isEmpty && _tasks.isEmpty && _events.isEmpty) {
      _showSnack('No hay datos cargados todavia.');
      return;
    }

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Limpiar operacion'),
          content: const Text(
            'Se quitaran activos, tareas, rutas, evidencias e historial local.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                setState(() {
                  _assets.clear();
                  _tasks.clear();
                  _routes.clear();
                  _events.clear();
                  _selectedAsset = null;
                  _panelOpen = false;
                });
                await widget.store.clear();
                await _refreshDatabaseDiagnostics(showMessage: false);
                _showSnack('Datos locales limpiados.');
              },
              child: const Text('Limpiar'),
            ),
          ],
        );
      },
    );
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red.shade700 : null,
      ),
    );
  }

  String _formatAccuracy(double? accuracy) {
    if (accuracy == null || accuracy.isNaN) {
      return 'precision no disponible';
    }

    final decimals = accuracy >= 10 ? 0 : 1;
    return '+/- ${accuracy.toStringAsFixed(decimals)} m';
  }

  String _formatTimestamp(DateTime? value) {
    if (value == null) {
      return 'recien obtenida';
    }

    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final second = local.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  Set<Marker> _buildGoogleMarkers() {
    final clusters = widget.clusterer.cluster(_filteredAssets, _currentZoom);

    final markers = clusters.map((cluster) {
      if (cluster.isSingle) {
        final asset = cluster.points.first;
        return Marker(
          markerId: MarkerId(asset.id),
          position: asset.position,
          icon: BitmapDescriptor.defaultMarkerWithHue(asset.status.markerHue),
          infoWindow: InfoWindow(
            title: asset.name,
            snippet: '${asset.type.label} - ${asset.status.label}',
          ),
          onTap: () {
            setState(() {
              _selectedAsset = asset;
            });
          },
        );
      }

      return Marker(
        markerId: MarkerId(cluster.id),
        position: cluster.position,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
        infoWindow: InfoWindow(
          title: '${cluster.points.length} activos',
          snippet: 'Acerca para separarlos',
        ),
        onTap: () => _zoomToCluster(cluster),
      );
    }).toSet();

    final currentLocation = _currentLocation;
    if (currentLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: currentLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: InfoWindow(
            title: 'Mi ubicacion exacta',
            snippet:
                '${currentLocation.latitude.toStringAsFixed(7)}, ${currentLocation.longitude.toStringAsFixed(7)} - ${_formatAccuracy(_currentLocationAccuracy)}',
          ),
        ),
      );
    }

    return markers;
  }

  List<fm.Marker> _buildOsmMarkers() {
    final clusters = widget.clusterer.cluster(_filteredAssets, _currentZoom);

    final markers = clusters.map((cluster) {
      if (cluster.isSingle) {
        final asset = cluster.points.first;
        return fm.Marker(
          point: _toOsm(asset.position),
          width: 48,
          height: 54,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedAsset = asset;
              });
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: asset.status.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(asset.type.icon, color: Colors.white, size: 20),
                ),
                const Icon(Icons.arrow_drop_down,
                    color: Colors.black54, size: 18),
              ],
            ),
          ),
        );
      }

      return fm.Marker(
        point: _toOsm(cluster.position),
        width: 56,
        height: 56,
        child: GestureDetector(
          onTap: () => _zoomToCluster(cluster),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              '${cluster.points.length}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      );
    }).toList();

    final currentLocation = _currentLocation;
    if (currentLocation != null) {
      markers.add(
        fm.Marker(
          point: _toOsm(currentLocation),
          width: 136,
          height: 76,
          child: _CurrentLocationMarker(
            accuracyLabel: _formatAccuracy(_currentLocationAccuracy),
          ),
        ),
      );
    }

    return markers;
  }

  Future<void> _changeTaskStatus(FieldTask task, TaskStatus status) async {
    if (status == TaskStatus.completada && !task.hasEvidence) {
      _showSnack('Para completar una tarea debes adjuntar evidencia.',
          isError: true);
      return;
    }

    double? lat;
    double? lng;
    if (status == TaskStatus.completada) {
      try {
        final position = await widget.locationService.currentPosition();
        lat = position.latitude;
        lng = position.longitude;
      } on Object {
        // GPS improves traceability, but completion can continue if evidence exists.
      }
    }

    final updatedTask = task.copyWith(
      status: status,
      completedLatitude: lat,
      completedLongitude: lng,
    );
    final assetStatus = _assetStatusForTask(status);

    setState(() {
      _replaceTask(updatedTask);
      _updateAssetForTask(
        updatedTask,
        status: assetStatus,
        observation: updatedTask.observation,
      );
      _addEvent(
        OperationEventType.tarea,
        'Tarea ${status.label.toLowerCase()}',
        '${_assetForTask(task)?.name ?? task.assetId} - $_activeTechnician',
      );
    });

    await _persist();
    _showSnack('Tarea actualizada: ${status.label}.');
  }

  AssetStatus _assetStatusForTask(TaskStatus status) {
    switch (status) {
      case TaskStatus.pendiente:
        return AssetStatus.pendiente;
      case TaskStatus.enProceso:
        return AssetStatus.activo;
      case TaskStatus.completada:
        return AssetStatus.atendido;
      case TaskStatus.bloqueada:
        return AssetStatus.danado;
    }
  }

  Future<void> _saveObservation(FieldTask task) async {
    final controller = TextEditingController(text: task.observation);

    final observation = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Observacion tecnica'),
          content: TextField(
            controller: controller,
            autofocus: true,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: 'Describe hallazgos, novedades o causa de bloqueo',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (observation == null) {
      return;
    }

    final updatedTask = task.copyWith(observation: observation);

    setState(() {
      _replaceTask(updatedTask);
      _updateAssetForTask(updatedTask, observation: observation);
      _addEvent(
        OperationEventType.tarea,
        'Observacion registrada',
        '${_assetForTask(task)?.name ?? task.assetId}: $observation',
      );
    });

    await _persist();
    _showSnack('Observacion guardada.');
  }

  Future<void> _attachEvidence(FieldTask task) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'heic', 'webp'],
      withData: false,
    );

    if (result == null) {
      return;
    }

    double? lat;
    double? lng;
    try {
      final position = await widget.locationService.currentPosition();
      lat = position.latitude;
      lng = position.longitude;
    } on Object {
      // Evidence can still be attached; GPS failure is visible in the record.
    }

    final file = result.files.single;
    final evidence = EvidenceRecord(
      id: _newId('ev'),
      fileName: file.name,
      localPath: file.path,
      sizeBytes: file.size,
      createdAt: DateTime.now(),
      latitude: lat,
      longitude: lng,
    );

    final updatedTask = task.copyWith(
      evidence: [...task.evidence, evidence],
      status: task.status == TaskStatus.pendiente
          ? TaskStatus.enProceso
          : task.status,
    );

    setState(() {
      _replaceTask(updatedTask);
      _updateAssetForTask(updatedTask, status: AssetStatus.activo);
      _addEvent(
        OperationEventType.evidencia,
        'Evidencia agregada',
        '${_assetForTask(task)?.name ?? task.assetId}: ${file.name}',
      );
    });

    await _persist();
    _showSnack('Evidencia agregada.');
  }

  void _replaceTask(FieldTask task) {
    final index = _tasks.indexWhere((item) => item.id == task.id);
    if (index == -1) {
      _tasks.add(task);
      return;
    }

    _tasks[index] = task;
  }

  void _updateAssetForTask(
    FieldTask task, {
    AssetStatus? status,
    String? observation,
  }) {
    final index = _assets.indexWhere((asset) => asset.id == task.assetId);
    if (index == -1) {
      return;
    }

    _assets[index] = _assets[index].copyWith(
      status: status,
      lastObservation: observation,
      lastUpdatedAt: DateTime.now(),
    );

    if (_selectedAsset?.id == _assets[index].id) {
      _selectedAsset = _assets[index];
    }
  }

  AssetPoint? _assetForTask(FieldTask task) {
    for (final asset in _assets) {
      if (asset.id == task.assetId) {
        return asset;
      }
    }

    return null;
  }

  FieldTask? _taskForAsset(AssetPoint asset) {
    for (final task in _tasks) {
      if (task.assetId == asset.id) {
        return task;
      }
    }

    return null;
  }

  FieldRoute? _routeForTask(FieldTask task) {
    for (final route in _routes) {
      if (route.id == task.routeId) {
        return route;
      }
    }

    return null;
  }

  void _addEvent(OperationEventType type, String title, String detail) {
    _events.insert(
      0,
      OperationEvent(
        id: _newId('event'),
        type: type,
        title: title,
        detail: detail,
        createdAt: DateTime.now(),
        synced: _onlineMode,
      ),
    );
  }

  Future<void> _syncPendingEvents() async {
    if (!_onlineMode) {
      _showSnack('Estas en modo offline. Activa conexion para sincronizar.',
          isError: true);
      return;
    }

    if (_pendingSyncCount == 0) {
      _showSnack('No hay cambios pendientes por sincronizar.');
      return;
    }

    setState(() {
      for (var i = 0; i < _events.length; i++) {
        _events[i] = _events[i].copyWith(synced: true);
      }
      _events.insert(
        0,
        OperationEvent(
          id: _newId('event'),
          type: OperationEventType.sincronizacion,
          title: 'Sincronizacion completada',
          detail: 'Cambios locales marcados como enviados.',
          createdAt: DateTime.now(),
          synced: true,
        ),
      );
    });

    await _persist();
    _showSnack('Sincronizacion local completada.');
  }

  void _openTaskSheet(FieldTask task) {
    final asset = _assetForTask(task);
    final route = _routeForTask(task);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
            children: [
              Text(
                asset?.name ?? task.assetId,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '${asset?.type.label ?? 'Activo'} - ${task.status.label} - ${route?.name ?? 'Sin ruta'}',
              ),
              const SizedBox(height: 14),
              _TaskFactRow(
                icon: Icons.person_outline,
                label: 'Tecnico',
                value: task.technicianId,
              ),
              _TaskFactRow(
                icon: Icons.photo_camera_outlined,
                label: 'Evidencias',
                value: '${task.evidence.length}',
              ),
              if (task.observation.isNotEmpty)
                _TaskFactRow(
                  icon: Icons.notes_outlined,
                  label: 'Observacion',
                  value: task.observation,
                ),
              const Divider(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.play_arrow),
                    label: const Text('En proceso'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _changeTaskStatus(task, TaskStatus.enProceso);
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Evidencia'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _attachEvidence(task);
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.notes_outlined),
                    label: const Text('Observacion'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _saveObservation(task);
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.report_problem_outlined),
                    label: const Text('Bloquear'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _changeTaskStatus(task, TaskStatus.bloqueada);
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.task_alt),
                    label: const Text('Completar'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _changeTaskStatus(task, TaskStatus.completada);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: asset == null
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        _moveToAsset(asset);
                      },
                icon: const Icon(Icons.map_outlined),
                label: const Text('Ver en mapa'),
              ),
            ],
          ),
        );
      },
    );
  }

  String _newId(String prefix) {
    _idCounter++;
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}_$_idCounter';
  }

  ll.LatLng _toOsm(LatLng position) {
    return ll.LatLng(position.latitude, position.longitude);
  }

  double _zoomForSpan(double span) {
    if (span <= 0.0006) {
      return 18;
    }
    if (span <= 0.002) {
      return 17;
    }
    if (span <= 0.006) {
      return 16;
    }
    if (span <= 0.02) {
      return 14;
    }
    if (span <= 0.08) {
      return 12;
    }

    return 10;
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month ${hour}h$minute';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedTab,
        children: [
          _buildMapTab(context),
          _buildTasksTab(context),
          _buildActivityTab(context),
          _buildProfileTab(context),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) {
          setState(() {
            _selectedTab = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: 'Rutas',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none),
            selectedIcon: Icon(Icons.notifications),
            label: 'Novedades',
          ),
          NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings),
            label: 'Control',
          ),
        ],
      ),
    );
  }

  Widget _buildMapTab(BuildContext context) {
    final configuration = MapViewConfiguration(
      initialCameraPosition: _initialCamera,
      mapType: _mapType,
      markers: _buildGoogleMarkers(),
      myLocationEnabled: _myLocationEnabled,
      onMapCreated: (controller) {
        _googleMapController = controller;
      },
      onCameraMove: (position) => _currentZoom = position.zoom,
      onCameraIdle: () {
        if (mounted) {
          setState(() {});
        }
      },
    );

    final map = widget.mapBuilder?.call(context, configuration) ??
        (_useGoogleMaps ? _buildGoogleMap(configuration) : _buildOsmMap());

    return Stack(
      children: [
        Positioned.fill(child: map),
        _buildTopSearchBar(context),
        _buildSidePanel(context),
        _buildMapActions(),
        _buildMapProviderToggle(),
        _buildCurrentLocationCard(),
        _buildMapStats(),
        _buildSelectedAssetSheet(),
        if (_isImporting || _isSaving)
          const LinearProgressIndicator(minHeight: 3),
      ],
    );
  }

  Widget _buildGoogleMap(MapViewConfiguration configuration) {
    return GoogleMap(
      initialCameraPosition: configuration.initialCameraPosition,
      mapType: configuration.mapType,
      markers: configuration.markers,
      myLocationEnabled: configuration.myLocationEnabled,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: true,
      onMapCreated: configuration.onMapCreated,
      onCameraMove: configuration.onCameraMove,
      onCameraIdle: configuration.onCameraIdle,
    );
  }

  Widget _buildOsmMap() {
    final satellite = _mapType == MapType.satellite;

    return fm.FlutterMap(
      mapController: _osmMapController,
      options: fm.MapOptions(
        initialCenter: const ll.LatLng(12.5847, -81.7006),
        initialZoom: 14,
        minZoom: 3,
        maxZoom: 20,
        backgroundColor:
            satellite ? const Color(0xFF0F2538) : const Color(0xFFDCEEF4),
        onPositionChanged: (position, hasGesture) {
          final zoom = position.zoom;
          if (zoom != null) {
            _currentZoom = zoom;
          }
        },
        onMapEvent: (_) {
          if (mounted) {
            setState(() {});
          }
        },
      ),
      children: [
        ..._buildLocalBaseLayers(satellite),
        fm.TileLayer(
          urlTemplate: satellite
              ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
              : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          fallbackUrl: satellite
              ? 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png'
              : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          maxNativeZoom: satellite ? 18 : 19,
          userAgentPackageName: 'com.dannyestrada.mtsanandres_base',
          errorTileCallback: (_, __, ___) => _markTileFallbackActive(),
        ),
        if (satellite)
          fm.TileLayer(
            urlTemplate:
                'https://services.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}',
            fallbackUrl:
                'https://{s}.basemaps.cartocdn.com/light_only_labels/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c', 'd'],
            maxNativeZoom: 18,
            userAgentPackageName: 'com.dannyestrada.mtsanandres_base',
            errorTileCallback: (_, __, ___) => _markTileFallbackActive(),
          ),
        fm.MarkerLayer(markers: _buildOsmMarkers()),
        fm.RichAttributionWidget(
          attributions: [
            fm.TextSourceAttribution(
              satellite ? 'Esri World Imagery' : 'OpenStreetMap contributors',
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildLocalBaseLayers(bool satellite) {
    final landColor =
        satellite ? const Color(0xFF375B45) : const Color(0xFFE1D09C);
    final landBorder =
        satellite ? const Color(0xFFEAF4D3) : const Color(0xFF8A7644);
    final gridColor = satellite
        ? Colors.white.withValues(alpha: 0.22)
        : const Color(0xFF2B6F84).withValues(alpha: 0.22);
    final routeColor = satellite
        ? const Color(0xFF8BD8FF).withValues(alpha: 0.75)
        : const Color(0xFF0E7C86).withValues(alpha: 0.64);

    return [
      fm.PolylineLayer(polylines: _buildFallbackGridLines(gridColor)),
      fm.PolygonLayer(
        polygons: [
          fm.Polygon(
            points: _sanAndresIsland,
            color: landColor.withValues(alpha: 0.92),
            borderColor: landBorder,
            borderStrokeWidth: 2,
            isFilled: true,
            label: 'San Andres',
            labelStyle: TextStyle(
              color: satellite ? Colors.white : const Color(0xFF263238),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          fm.Polygon(
            points: _providenciaIsland,
            color: landColor.withValues(alpha: 0.88),
            borderColor: landBorder,
            borderStrokeWidth: 2,
            isFilled: true,
            label: 'Providencia',
            labelStyle: TextStyle(
              color: satellite ? Colors.white : const Color(0xFF263238),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          fm.Polygon(
            points: _santaCatalinaIsland,
            color: landColor.withValues(alpha: 0.84),
            borderColor: landBorder,
            borderStrokeWidth: 1.4,
            isFilled: true,
          ),
        ],
      ),
      fm.PolylineLayer(
        polylines: [
          fm.Polyline(
            points: _sanAndresMainRoad,
            color: routeColor,
            strokeWidth: 4,
            borderColor: satellite
                ? Colors.black.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.8),
            borderStrokeWidth: 2,
          ),
          fm.Polyline(
            points: _providenciaRoad,
            color: routeColor,
            strokeWidth: 3,
            borderColor: satellite
                ? Colors.black.withValues(alpha: 0.28)
                : Colors.white.withValues(alpha: 0.72),
            borderStrokeWidth: 1.5,
          ),
        ],
      ),
      fm.CircleLayer(
        circles: [
          fm.CircleMarker(
            point: const ll.LatLng(12.5847, -81.7006),
            radius: 6,
            color: const Color(0xFFDC2626),
            borderColor: Colors.white,
            borderStrokeWidth: 2,
          ),
          fm.CircleMarker(
            point: const ll.LatLng(12.5554, -81.7191),
            radius: 4.5,
            color: const Color(0xFF2563EB),
            borderColor: Colors.white,
            borderStrokeWidth: 2,
          ),
          fm.CircleMarker(
            point: const ll.LatLng(12.5940, -81.7000),
            radius: 4.5,
            color: const Color(0xFF16803C),
            borderColor: Colors.white,
            borderStrokeWidth: 2,
          ),
        ],
      ),
      fm.MarkerLayer(markers: _buildLocalBaseLabels()),
    ];
  }

  List<fm.Polyline> _buildFallbackGridLines(Color color) {
    final lines = <fm.Polyline>[];
    const minLat = 12.30;
    const maxLat = 13.45;
    const minLng = -81.90;
    const maxLng = -81.20;

    for (var lat = minLat; lat <= maxLat; lat += 0.10) {
      lines.add(
        fm.Polyline(
          points: [ll.LatLng(lat, minLng), ll.LatLng(lat, maxLng)],
          color: color,
          strokeWidth: 1,
        ),
      );
    }

    for (var lng = minLng; lng <= maxLng; lng += 0.10) {
      lines.add(
        fm.Polyline(
          points: [ll.LatLng(minLat, lng), ll.LatLng(maxLat, lng)],
          color: color,
          strokeWidth: 1,
        ),
      );
    }

    return lines;
  }

  List<fm.Marker> _buildLocalBaseLabels() {
    const style = TextStyle(
      color: Color(0xFF263238),
      fontSize: 11,
      fontWeight: FontWeight.w800,
    );

    return [
      fm.Marker(
        point: const ll.LatLng(12.5847, -81.7006),
        width: 150,
        height: 32,
        child: _FallbackMapLabel(text: 'Centro / North End', style: style),
      ),
      fm.Marker(
        point: const ll.LatLng(12.5554, -81.7191),
        width: 120,
        height: 32,
        child: _FallbackMapLabel(text: 'San Luis', style: style),
      ),
      fm.Marker(
        point: const ll.LatLng(12.5138, -81.7256),
        width: 130,
        height: 32,
        child: _FallbackMapLabel(text: 'Hoyo Soplador', style: style),
      ),
      fm.Marker(
        point: const ll.LatLng(13.3500, -81.3740),
        width: 130,
        height: 32,
        child: _FallbackMapLabel(text: 'Providencia', style: style),
      ),
    ];
  }

  void _markTileFallbackActive() {
    if (_tileFallbackActive || !mounted) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_tileFallbackActive) {
        setState(() => _tileFallbackActive = true);
      }
    });
  }

  Widget _buildTopSearchBar(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Row(
            children: [
              _RoundIconButton(
                icon: Icons.menu,
                tooltip: 'Abrir panel',
                onPressed: () {
                  setState(() {
                    _panelOpen = !_panelOpen;
                  });
                },
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Material(
                  color: Colors.white,
                  elevation: 3,
                  borderRadius: BorderRadius.circular(16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Buscar activo, estado, ID o archivo',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Limpiar busqueda',
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.close),
                            ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _RoundIconButton(
                icon: Icons.upload_file,
                tooltip: 'Subir KML/KMZ',
                onPressed: _showImportChooser,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidePanel(BuildContext context) {
    final width = math.min(MediaQuery.sizeOf(context).width * 0.88, 360.0);
    final countsByType = _countsByType;
    final countsByStatus = _countsByStatus;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      top: 0,
      bottom: 0,
      left: _panelOpen ? 0 : -width - 12,
      width: width,
      child: SafeArea(
        bottom: false,
        child: Material(
          elevation: 16,
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(22),
            bottomRight: Radius.circular(22),
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFE0F2F1),
                    child: Icon(Icons.map, color: Color(0xFF0E7C86)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MT San Andres',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        Text(
                          '${_assets.length} activos - ${_tasks.length} tareas',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar panel',
                    onPressed: () => setState(() => _panelOpen = false),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _ProgressHeader(
                  progress: _progress, pendingSync: _pendingSyncCount),
              const SizedBox(height: 22),
              Text('Importar KML/KMZ',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              for (final type in AssetType.values)
                _ImportTile(
                  type: type,
                  count: countsByType[type] ?? 0,
                  enabled: !_isImporting,
                  onTap: () => _importAssetFile(type),
                ),
              const Divider(height: 26),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                initiallyExpanded: true,
                leading: const Icon(Icons.category_outlined),
                title: const Text('Capas por tipo'),
                children: [
                  for (final type in AssetType.values)
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: _visibleTypes[type] ?? true,
                      secondary: Icon(type.icon, color: type.color),
                      title: Text(type.pluralLabel),
                      subtitle: Text('${countsByType[type] ?? 0} cargados'),
                      onChanged: (value) {
                        setState(() {
                          _visibleTypes[type] = value ?? false;
                          _selectedAsset = null;
                        });
                      },
                    ),
                ],
              ),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Capas por estado'),
                children: [
                  for (final status in AssetStatus.values)
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: _visibleStatuses[status] ?? true,
                      secondary: Icon(status.icon, color: status.color),
                      title: Text(status.label),
                      subtitle: Text('${countsByStatus[status] ?? 0} activos'),
                      onChanged: (value) {
                        setState(() {
                          _visibleStatuses[status] = value ?? false;
                          _selectedAsset = null;
                        });
                      },
                    ),
                ],
              ),
              const Divider(height: 28),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _mapType == MapType.satellite,
                secondary: const Icon(Icons.layers_outlined),
                title: const Text('Vista satelital'),
                onChanged: (value) {
                  setState(() {
                    _mapType = value ? MapType.satellite : MapType.normal;
                  });
                },
              ),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.verified_outlined),
                title: Text('Mapa blindado'),
                subtitle: Text(
                  'OSM, Carto, Esri y base local para evitar pantalla blanca.',
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _clearData,
                icon: const Icon(Icons.delete_sweep_outlined),
                label: const Text('Limpiar operacion local'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapActions() {
    return Positioned(
      right: 14,
      bottom: _selectedAsset == null ? 116 : 228,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RoundIconButton(
            icon: Icons.my_location,
            tooltip: 'Mi ubicacion',
            onPressed: _goToMyLocation,
          ),
          const SizedBox(height: 10),
          _RoundIconButton(
            icon: Icons.layers,
            tooltip: 'Cambiar vista',
            onPressed: () {
              setState(() {
                _mapType = _mapType == MapType.satellite
                    ? MapType.normal
                    : MapType.satellite;
              });
            },
          ),
          const SizedBox(height: 10),
          _RoundIconButton(
            icon: Icons.center_focus_strong,
            tooltip: 'Ver activos',
            onPressed: () => _fitToPoints(_filteredAssets),
          ),
        ],
      ),
    );
  }

  Widget _buildMapProviderToggle() {
    return Positioned(
      top: 72,
      right: 14,
      child: SafeArea(
        child: Material(
          color: Colors.white,
          elevation: 3,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _tileFallbackActive
                      ? Icons.offline_bolt_outlined
                      : Icons.verified_outlined,
                  size: 18,
                  color: const Color(0xFF0E7C86),
                ),
                const SizedBox(width: 8),
                Text(
                  _tileFallbackActive ? 'Base local activa' : 'Mapa blindado',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapStats() {
    return Positioned(
      left: 14,
      right: 86,
      bottom: 14,
      child: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Material(
            color: Colors.black.withValues(alpha: 0.66),
            borderRadius: BorderRadius.circular(14),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _MapStatChip(
                  icon: Icons.place_outlined,
                  label: '${_filteredAssets.length}/${_assets.length}',
                ),
                _MapStatChip(
                  icon: Icons.cloud_sync_outlined,
                  label: '$_pendingSyncCount pend.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentLocationCard() {
    final currentLocation = _currentLocation;
    if (currentLocation == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 112,
      left: 14,
      right: 14,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 370),
            child: Material(
              color: Colors.white,
              elevation: 5,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFFE0ECFF),
                      child: Icon(
                        Icons.my_location,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Mi ubicacion exacta',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${currentLocation.latitude.toStringAsFixed(7)}, ${currentLocation.longitude.toStringAsFixed(7)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_formatAccuracy(_currentLocationAccuracy)} - ${_formatTimestamp(_currentLocationAt)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar ubicacion',
                      onPressed: () {
                        setState(() {
                          _currentLocation = null;
                          _currentLocationAccuracy = null;
                          _currentLocationAt = null;
                        });
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedAssetSheet() {
    final asset = _selectedAsset;
    if (asset == null) {
      return const SizedBox.shrink();
    }

    final task = _taskForAsset(asset);

    return Positioned(
      left: 14,
      right: 14,
      bottom: 72,
      child: SafeArea(
        top: false,
        child: Material(
          color: Colors.white,
          elevation: 8,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: asset.status.color.withValues(alpha: 0.14),
                  child: Icon(asset.status.icon, color: asset.status.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        asset.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${asset.type.label} - ${asset.status.label} - ${asset.position.latitude.toStringAsFixed(6)}, ${asset.position.longitude.toStringAsFixed(6)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Abrir tarea',
                  onPressed: task == null ? null : () => _openTaskSheet(task),
                  icon: const Icon(Icons.assignment_outlined),
                ),
                IconButton(
                  tooltip: 'Cerrar detalle',
                  onPressed: () => setState(() => _selectedAsset = null),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTasksTab(BuildContext context) {
    final sortedTasks = [..._tasks]
      ..sort((a, b) => a.status.index.compareTo(b.status.index));

    return _TabSurface(
      title: 'Rutas y tareas',
      subtitle: 'Asignacion diaria, evidencia y progreso de campo',
      actions: [
        IconButton(
          tooltip: 'Sincronizar',
          onPressed: _syncPendingEvents,
          icon: const Icon(Icons.sync),
        ),
      ],
      child: _tasks.isEmpty
          ? const _EmptyState(
              icon: Icons.route_outlined,
              title: 'Sin tareas asignadas',
              message:
                  'Importa activos desde el panel del mapa para crear la ruta diaria.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
              children: [
                for (final route in _routes)
                  _RouteSummary(route: route, tasks: _tasks),
                const SizedBox(height: 10),
                Text('Cola de trabajo',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        )),
                const SizedBox(height: 8),
                for (final task in sortedTasks)
                  _TaskTile(
                    task: task,
                    asset: _assetForTask(task),
                    onTap: () => _openTaskSheet(task),
                  ),
              ],
            ),
    );
  }

  Widget _buildActivityTab(BuildContext context) {
    return _TabSurface(
      title: 'Novedades',
      subtitle: 'Historial por punto y cola offline de sincronizacion',
      actions: [
        IconButton(
          tooltip: 'Sincronizar pendientes',
          onPressed: _syncPendingEvents,
          icon: Badge(
            isLabelVisible: _pendingSyncCount > 0,
            label: Text('$_pendingSyncCount'),
            child: const Icon(Icons.cloud_sync_outlined),
          ),
        ),
      ],
      child: _events.isEmpty
          ? const _EmptyState(
              icon: Icons.notifications_none,
              title: 'Sin novedades',
              message:
                  'Las importaciones, evidencias, cambios de estado y sincronizaciones apareceran aqui.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
              itemCount: _events.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final event = _events[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: event.color.withValues(alpha: 0.14),
                    child: Icon(event.icon, color: event.color),
                  ),
                  title: Text(event.title),
                  subtitle: Text(event.detail),
                  trailing: Icon(
                    event.synced ? Icons.cloud_done : Icons.cloud_off,
                    color: event.synced ? Colors.green : Colors.orange,
                  ),
                );
              },
            ),
    );
  }

  Widget _buildProfileTab(BuildContext context) {
    final damaged = _countsByStatus[AssetStatus.danado] ?? 0;

    return _TabSurface(
      title: 'Control',
      subtitle: 'Supervision, base local y estado de sincronizacion',
      actions: [
        IconButton(
          tooltip: 'Revisar base',
          onPressed: _refreshDatabaseDiagnostics,
          icon: const Icon(Icons.refresh),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        children: [
          _MetricGrid(
            totalAssets: _assets.length,
            totalTasks: _tasks.length,
            completedTasks: _completedTaskCount,
            blockedTasks: _blockedTaskCount,
            evidenceCount: _evidenceCount,
            pendingSync: _pendingSyncCount,
          ),
          const SizedBox(height: 16),
          _buildDatabaseStatusPanel(context),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'tecnico',
                label: Text('Tecnico'),
                icon: Icon(Icons.engineering_outlined),
              ),
              ButtonSegment(
                value: 'supervisor',
                label: Text('Supervisor'),
                icon: Icon(Icons.admin_panel_settings_outlined),
              ),
            ],
            selected: {_activeRole},
            onSelectionChanged: (selection) async {
              setState(() {
                _activeRole = selection.first;
                _addEvent(
                  OperationEventType.sistema,
                  'Rol activo cambiado',
                  _activeRole,
                );
              });
              await _persist();
            },
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _technicianController,
            decoration: const InputDecoration(
              labelText: 'Tecnico activo',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline),
            ),
            onSubmitted: (_) => _saveTechnician(),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _saveTechnician,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Guardar tecnico'),
          ),
          const Divider(height: 28),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _onlineMode,
            secondary: Icon(_onlineMode ? Icons.wifi : Icons.wifi_off),
            title: Text(_onlineMode ? 'Modo online' : 'Modo offline'),
            subtitle: Text(
              _onlineMode
                  ? 'Los nuevos eventos se marcan como sincronizados.'
                  : 'Los cambios quedan en cola pendiente.',
            ),
            onChanged: (value) async {
              setState(() {
                _onlineMode = value;
                _addEvent(
                  OperationEventType.sistema,
                  value ? 'Conexion activada' : 'Modo offline activado',
                  value
                      ? 'La app puede sincronizar pendientes.'
                      : 'Los cambios se guardaran localmente.',
                );
              });
              await _persist();
            },
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _syncPendingEvents,
            icon: const Icon(Icons.cloud_sync_outlined),
            label: Text('Sincronizar $_pendingSyncCount pendientes'),
          ),
          const Divider(height: 28),
          _InfoRow(
            icon: Icons.storage_outlined,
            title: 'Base local',
            value: _storeDiagnostics.statusLabel,
          ),
          const _InfoRow(
            icon: Icons.cloud_off_outlined,
            title: 'Firebase',
            value:
                'Proyecto activo revisado, pero esta app aun no tiene firebase_core, cloud_firestore ni google-services.json.',
            color: Color(0xFFD97706),
          ),
          _InfoRow(
            icon: Icons.warning_amber_outlined,
            title: 'Activos danados',
            value: '$damaged',
            color: Colors.red,
          ),
          _InfoRow(
            icon: Icons.verified_user_outlined,
            title: 'Seguridad',
            value: 'Google Maps se configura fuera del codigo fuente.',
          ),
        ],
      ),
    );
  }

  Widget _buildDatabaseStatusPanel(BuildContext context) {
    final diagnostics = _storeDiagnostics;
    final statusColor = diagnostics.validJson
        ? (diagnostics.hasData ? const Color(0xFF16803C) : Colors.blueGrey)
        : const Color(0xFFDC2626);
    final lastEvent = diagnostics.lastEventAt == null
        ? 'Sin eventos'
        : _formatDateTime(diagnostics.lastEventAt!);

    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withValues(alpha: 0.14),
                  child: Icon(Icons.storage_outlined, color: statusColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        diagnostics.statusLabel,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Guardado: ${diagnostics.sizeLabel} - $lastEvent',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusPill(
                    label: 'Activos', value: '${diagnostics.assetCount}'),
                _StatusPill(label: 'Tareas', value: '${diagnostics.taskCount}'),
                _StatusPill(label: 'Rutas', value: '${diagnostics.routeCount}'),
                _StatusPill(
                  label: 'Eventos',
                  value: '${diagnostics.eventCount}',
                ),
                _StatusPill(
                  label: 'Evidencias',
                  value: '${diagnostics.evidenceCount}',
                ),
                _StatusPill(
                  label: 'Pendientes',
                  value: '${diagnostics.pendingSyncCount}',
                  color: diagnostics.pendingSyncCount == 0
                      ? const Color(0xFF16803C)
                      : const Color(0xFFD97706),
                ),
              ],
            ),
            if (!diagnostics.validJson) ...[
              const SizedBox(height: 10),
              Text(
                diagnostics.errorMessage,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFFDC2626)),
              ),
            ],
            const Divider(height: 24),
            const _FirebaseStatusRow(),
          ],
        ),
      ),
    );
  }

  Future<void> _saveTechnician() async {
    final value = _technicianController.text.trim();
    if (value.isEmpty) {
      _showSnack('Escribe el nombre del tecnico.', isError: true);
      return;
    }

    setState(() {
      _activeTechnician = value;
      _addEvent(
        OperationEventType.sistema,
        'Tecnico activo actualizado',
        value,
      );
    });
    await _persist();
    _showSnack('Tecnico guardado.');
  }
}

class _MapStatChip extends StatelessWidget {
  const _MapStatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 17),
          const SizedBox(width: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.value,
    this.color = const Color(0xFF0E7C86),
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 5),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _FirebaseStatusRow extends StatelessWidget {
  const _FirebaseStatusRow();

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFD97706);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.14),
          child: const Icon(Icons.cloud_off_outlined, color: color),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Firebase revisado',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 2),
              Text(
                'mt-sanandres-app esta activo; Realtime DB esta vacia y esta app aun no sincroniza con Firebase.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FallbackMapLabel extends StatelessWidget {
  const _FallbackMapLabel({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ),
    );
  }
}

class _CurrentLocationMarker extends StatelessWidget {
  const _CurrentLocationMarker({required this.accuracyLabel});

  final String accuracyLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(Icons.my_location, color: Colors.white, size: 18),
        ),
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            'Mi ubicacion - $accuracyLabel',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.progress,
    required this.pendingSync,
  });

  final double progress;
  final int pendingSync;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Avance operativo',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            Text('$percent%'),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(value: progress),
        const SizedBox(height: 8),
        Text('Pendientes de sincronizar: $pendingSync'),
      ],
    );
  }
}

class _ImportTile extends StatelessWidget {
  const _ImportTile({
    required this.type,
    required this.count,
    required this.enabled,
    required this.onTap,
  });

  final AssetType type;
  final int count;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: enabled,
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: type.color.withValues(alpha: 0.14),
        child: Icon(type.icon, color: type.color),
      ),
      title: Text(type.pluralLabel),
      subtitle: Text('$count cargados'),
      trailing: const Icon(Icons.upload_file),
      onTap: onTap,
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );
  }
}

class _TabSurface extends StatelessWidget {
  const _TabSurface({
    required this.title,
    required this.subtitle,
    required this.child,
    this.actions = const [],
  });

  final String title;
  final String subtitle;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.black54,
                            ),
                      ),
                    ],
                  ),
                ),
                ...actions,
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black54,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteSummary extends StatelessWidget {
  const _RouteSummary({
    required this.route,
    required this.tasks,
  });

  final FieldRoute route;
  final List<FieldTask> tasks;

  @override
  Widget build(BuildContext context) {
    final routeTasks =
        tasks.where((task) => task.routeId == route.id).toList(growable: false);
    final completed =
        routeTasks.where((task) => task.status == TaskStatus.completada).length;
    final progress = routeTasks.isEmpty ? 0.0 : completed / routeTasks.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.route_outlined),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      route.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text('$completed/${routeTasks.length}'),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 6),
              Text('Tecnico: ${route.technicianId}'),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.asset,
    required this.onTap,
  });

  final FieldTask task;
  final AssetPoint? asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = _taskColor(task.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.14),
          child: Icon(asset?.type.icon ?? Icons.place_outlined,
              color: statusColor),
        ),
        title: Text(asset?.name ?? task.assetId),
        subtitle: Text(
          '${task.status.label} - Evidencias: ${task.evidence.length}'
          '${task.observation.isEmpty ? '' : ' - Obs: ${task.observation}'}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Color _taskColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pendiente:
        return const Color(0xFFD97706);
      case TaskStatus.enProceso:
        return const Color(0xFF2563EB);
      case TaskStatus.completada:
        return const Color(0xFF16803C);
      case TaskStatus.bloqueada:
        return const Color(0xFFDC2626);
    }
  }
}

class _TaskFactRow extends StatelessWidget {
  const _TaskFactRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          SizedBox(width: 90, child: Text(label)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({
    required this.totalAssets,
    required this.totalTasks,
    required this.completedTasks,
    required this.blockedTasks,
    required this.evidenceCount,
    required this.pendingSync,
  });

  final int totalAssets;
  final int totalTasks;
  final int completedTasks;
  final int blockedTasks;
  final int evidenceCount;
  final int pendingSync;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      (
        'Activos',
        '$totalAssets',
        Icons.place_outlined,
        const Color(0xFF0E7C86)
      ),
      ('Tareas', '$totalTasks', Icons.route_outlined, const Color(0xFF2563EB)),
      (
        'Completadas',
        '$completedTasks',
        Icons.task_alt,
        const Color(0xFF16803C)
      ),
      (
        'Bloqueadas',
        '$blockedTasks',
        Icons.report_problem_outlined,
        const Color(0xFFDC2626)
      ),
      (
        'Evidencias',
        '$evidenceCount',
        Icons.photo_camera_outlined,
        const Color(0xFF7C3AED)
      ),
      (
        'Pend. sync',
        '$pendingSync',
        Icons.cloud_off_outlined,
        const Color(0xFFD97706)
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 2.4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        for (final metric in metrics)
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: metric.$4.withValues(alpha: 0.14),
                    child: Icon(metric.$3, color: metric.$4),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          metric.$2,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          metric.$1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: effectiveColor.withValues(alpha: 0.14),
        child: Icon(icon, color: effectiveColor),
      ),
      title: Text(title),
      subtitle: Text(value),
    );
  }
}
