import 'dart:async';

import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart' as handler;

import '../../../../services/location_service.dart';

/// Shared logic for all location controllers used in the map module.
abstract class BaseLocationController extends GetxController {
  BaseLocationController({
    required this.locationService,
    this.destination,
    required this.destinationLabel,
    this.initialZoom = 15.0,
  });

  final LocationService locationService;
  final LatLng? destination;
  final String destinationLabel;
  final double initialZoom;

  final MapController mapController = MapController();
  final Rxn<Position> currentPosition = Rxn<Position>();
  final Rxn<Position> lastKnownPosition = Rxn<Position>();
  final Rxn<DateTime> lastUpdatedAt = Rxn<DateTime>();
  final RxBool isLoading = false.obs;
  final RxBool isTracking = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isGpsEnabled = false.obs;
  final Rx<handler.PermissionStatus?> permissionStatus =
      Rx<handler.PermissionStatus?>(null);
  final Rxn<LatLng> manualDestination = Rxn<LatLng>();

  StreamSubscription<Position>? _positionSubscription;
  bool _mapReady = false;
  static const double _minZoomLevel = 3.0;
  static const double _maxZoomLevel = 19.0;
  static const double _zoomStep = 0.75;
  static const LatLng _defaultCenter = LatLng(-6.200000, 106.816666);

  /// Whether the current mode prefers GPS (high accuracy) or network provider.
  bool get useGps;

  /// Returns the fallback center when neither user nor destination position is known.
  LatLng get fallbackCenter => activeDestination ?? _defaultCenter;

  /// Destination used by the map; manual pin overrides predefined target.
  LatLng? get activeDestination => manualDestination.value ?? destination;

  /// Convenience getter for views to access the current user LatLng.
  LatLng? get currentLatLng {
    final position = currentPosition.value;
    if (position == null) return null;
    return LatLng(position.latitude, position.longitude);
  }

  LocationAccuracy get accuracy =>
      useGps ? LocationAccuracy.high : LocationAccuracy.low;

  LocationSettings get locationSettings =>
      LocationSettings(accuracy: accuracy, distanceFilter: useGps ? 5 : 25);

  @override
  void onClose() {
    _positionSubscription?.cancel();
    super.onClose();
  }

  /// Called by the view once the FlutterMap widget is ready.
  void onMapReady() {
    _mapReady = true;
    final destinationTarget = activeDestination;
    final position = currentPosition.value ?? lastKnownPosition.value;
    if (position != null) {
      mapController.move(_toLatLng(position), initialZoom);
      return;
    }
    if (destinationTarget != null) {
      mapController.move(destinationTarget, initialZoom);
      return;
    }
    mapController.move(_defaultCenter, 12);
  }

  /// Zooms the map view in by a single step.
  void zoomIn() => _changeZoom(_zoomStep);

  /// Zooms the map view out by a single step.
  void zoomOut() => _changeZoom(-_zoomStep);

  /// Fetches a single location update using the active provider.
  Future<void> refreshPosition() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final ready = await _ensureReady();
      if (!ready) {
        await _loadFallbackPosition();
        return;
      }
      final position = await locationService.getCurrentPosition(useGps: useGps);
      _updatePosition(position);
    } catch (e) {
      errorMessage.value = 'Tidak dapat memuat lokasi: $e';
      await _loadFallbackPosition();
    } finally {
      isLoading.value = false;
    }
  }
  ///
  /// Starts continuous tracking.
  Future<void> startTracking() async {
    if (isTracking.value) return;
    errorMessage.value = '';
    final ready = await _ensureReady();
    if (!ready) return;
    await _positionSubscription?.cancel();
    isTracking.value = true;
    _positionSubscription = locationService
        .getPositionStream(useGps: useGps)
        .listen(
          _updatePosition,
          onError: (Object error) {
            errorMessage.value = 'Tracking terhenti: $error';
            stopTracking();
          },
        );
  }

  /// Stops an active tracking stream.
  Future<void> stopTracking() async {
    if (!isTracking.value) return;
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    isTracking.value = false;
  }

  /// Restarts the stream with the current provider selection.
  Future<void> restartTracking() async {
    if (!isTracking.value) return;
    await stopTracking();
    await startTracking();
  }

  /// Convenience wrapper to open system location settings.
  Future<void> openLocationSettings() => locationService.openLocationSettings();

  /// Convenience wrapper to open app settings for permissions.
  Future<void> openAppPermissionSettings() => locationService.openAppSettings();

  /// Invoked when the data provider toggle changes.
  void handleProviderChanged() {
    if (isTracking.value) {
      restartTracking();
    } else {
      refreshPosition();
    }
  }

  Future<bool> _ensureReady() async {
    final serviceEnabled = await locationService.isServiceEnabled();
    isGpsEnabled.value = serviceEnabled;
    if (!serviceEnabled) {
      errorMessage.value = 'Layanan lokasi perangkat nonaktif.';
      return false;
    }

    final status = await locationService.ensurePermission();
    permissionStatus.value = status;
    if (!locationService.isPermissionGranted(status)) {
      if (status == handler.PermissionStatus.permanentlyDenied) {
        errorMessage.value =
            'Izin lokasi ditolak permanen. Buka pengaturan untuk mengaktifkan.';
      } else {
        errorMessage.value = 'Izin lokasi belum diberikan.';
      }
      return false;
    }

    return true;
  }

  Future<void> _loadFallbackPosition() async {
    final cached = await locationService.getLastKnownPosition();
    if (cached != null) {
      lastKnownPosition.value = cached;
      _updatePosition(cached);
    }
  }

  void _updatePosition(Position position) {
    currentPosition.value = position;
    lastUpdatedAt.value = position.timestamp ?? DateTime.now();
    if (_mapReady) {
      final camera = mapController.camera;
      final currentZoom = camera.zoom;
      final targetZoom = currentZoom.isFinite ? currentZoom : initialZoom;
      mapController.move(_toLatLng(position), targetZoom);
    }
  }

  LatLng _toLatLng(Position position) =>
      LatLng(position.latitude, position.longitude);

  void _changeZoom(double delta) {
    if (!_mapReady) return;
    final camera = mapController.camera;
    final newZoom = (camera.zoom + delta).clamp(_minZoomLevel, _maxZoomLevel);
    mapController.move(camera.center, newZoom.toDouble());
  }

  /// Recenters the map on the most recent known user position.
  void centerOnLatestPosition() {
    if (!_mapReady) return;
    LatLng? target = currentLatLng;
    final lastKnown = lastKnownPosition.value;
    if (target == null && lastKnown != null) {
      target = _toLatLng(lastKnown);
    }
    target ??= activeDestination ?? _defaultCenter;

    final camera = mapController.camera;
    final fallbackZoom = camera.zoom.isFinite ? camera.zoom : initialZoom;
    mapController.move(target, fallbackZoom);
  }

  /// Stores a manual destination marker selected by the user.
  void setManualDestination(LatLng? value) {
    manualDestination.value = value;
    if (!_mapReady) return;
    focusOnDestination();
  }

  void resetManualDestination() {
    manualDestination.value = null;
    focusOnDestination();
  }

  void focusOnDestination() {
    if (!_mapReady) return;
    final target = activeDestination;
    if (target == null) return;
    final camera = mapController.camera;
    final newZoom = camera.zoom.isFinite ? camera.zoom : initialZoom;
    mapController.move(target, newZoom);
  }
}
