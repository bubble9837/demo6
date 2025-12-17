import 'package:intl/intl.dart';

import 'base_location_controller.dart';

/// Controller dedicated to GPS (high accuracy) positioning.
class GpsLocationController extends BaseLocationController {
  GpsLocationController({
    required super.locationService,
    super.destination,
    required super.destinationLabel,
  }) : super(
          initialZoom: destination != null ? 16.0 : 13.0,
        );

  final DateFormat _formatter = DateFormat('dd MMM yyyy HH:mm:ss');
  ///
  @override
  bool get useGps => true;

  String? get formattedTimestamp {
    final timestamp = lastUpdatedAt.value;
    if (timestamp == null) return null;
    return _formatter.format(timestamp.toLocal());
  }

  double? get accuracyMeters => currentPosition.value?.accuracy;

  double? get speedKph {
    final speed = currentPosition.value?.speed;
    if (speed == null) return null;
    if (speed.isNaN) return null;
    return speed * 3.6;
  }

  @override
  void onInit() {
    super.onInit();
    refreshPosition();
  }
}
