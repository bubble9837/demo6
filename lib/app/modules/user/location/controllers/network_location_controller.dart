import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../../services/location_service.dart';
import 'base_location_controller.dart';

/// Controller dedicated to network-based positioning (low accuracy provider).
class NetworkLocationController extends BaseLocationController {
  NetworkLocationController({
    required LocationService locationService,
    LatLng? destination,
    required String destinationLabel,
  }) : super(
          locationService: locationService,
          destination: destination,
          destinationLabel: destinationLabel,
          initialZoom: destination != null ? 15.0 : 12.0,
        );

  final DateFormat _formatter = DateFormat('dd MMM yyyy HH:mm:ss');

  @override
  bool get useGps => false;

  String? get formattedTimestamp {
    final timestamp = lastUpdatedAt.value;
    if (timestamp == null) return null;
    return _formatter.format(timestamp.toLocal());
  }

  double? get accuracyMeters => currentPosition.value?.accuracy;

  @override
  void onInit() {
    super.onInit();
    refreshPosition();
  }
}
