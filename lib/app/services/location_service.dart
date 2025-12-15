import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as handler;

/// Centralized location helper wrapping Geolocator and permission_handler.
class LocationService {
  LocationService._internal();

  static final LocationService _instance = LocationService._internal();

  factory LocationService() => _instance;

  final GeolocatorPlatform _geolocator = GeolocatorPlatform.instance;

  /// Returns true when device location services (GPS / network) are enabled.
  Future<bool> isServiceEnabled() => _geolocator.isLocationServiceEnabled();

  /// Checks current location permission without prompting the user.
  Future<handler.PermissionStatus> checkPermission() async {
    final status = await handler.Permission.location.status;
    if (status == handler.PermissionStatus.denied) {
      return status;
    }
    if (status == handler.PermissionStatus.permanentlyDenied) {
      return status;
    }
    if (status == handler.PermissionStatus.restricted) {
      return status;
    }
    if (status == handler.PermissionStatus.limited) {
      return status;
    }
    return status;
  }

  /// Requests location permission; callers can inspect the returned status.
  Future<handler.PermissionStatus> requestPermission() async {
    handler.PermissionStatus status = await handler.Permission.location.status;
    if (status == handler.PermissionStatus.granted ||
        status == handler.PermissionStatus.limited) {
      return status;
    }

    status = await handler.Permission.location.request();

    // On some devices coarse permission is required separately.
    if (status == handler.PermissionStatus.denied &&
        await handler.Permission.locationWhenInUse.isDenied) {
      final altStatus = await handler.Permission.locationWhenInUse.request();
      if (altStatus != handler.PermissionStatus.denied) {
        status = altStatus;
      }
    }

    return status;
  }

  /// Ensures required permissions are granted, requesting them when needed.
  Future<handler.PermissionStatus> ensurePermission() async {
    var status = await checkPermission();
    if (status == handler.PermissionStatus.denied ||
        status == handler.PermissionStatus.restricted) {
      status = await requestPermission();
    }
    return status;
  }

  bool isPermissionGranted(handler.PermissionStatus status) {
    return status == handler.PermissionStatus.granted ||
        status == handler.PermissionStatus.limited;
  }
  ///
  /// Returns the best known current position.
  Future<Position> getCurrentPosition({bool useGps = true}) {
    final settings = LocationSettings(
      accuracy: useGps ? LocationAccuracy.high : LocationAccuracy.low,
    );
    return _geolocator.getCurrentPosition(locationSettings: settings);
  }

  /// Returns a position stream for real-time tracking.
  Stream<Position> getPositionStream({bool useGps = true}) {
    final settings = LocationSettings(
      accuracy: useGps ? LocationAccuracy.high : LocationAccuracy.low,
      distanceFilter: useGps ? 5 : 25,
    );
    return _geolocator.getPositionStream(locationSettings: settings);
  }

  /// Returns the last known cached position if available.
  Future<Position?> getLastKnownPosition() => _geolocator.getLastKnownPosition();

  /// Opens device location settings page.
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  /// Opens the app settings page for manual permission management.
  Future<bool> openAppSettings() => handler.openAppSettings();
}
