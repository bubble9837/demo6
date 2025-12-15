import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../../../services/location_service.dart';
import 'base_location_controller.dart';

/// Live tracking controller with provider toggle (GPS / Network).
class LocationController extends BaseLocationController {
  LocationController({
    required LocationService locationService,
    LatLng? destination,
    required String destinationLabel,
  })  : useGpsToggle = true.obs,
        super(
          locationService: locationService,
          destination: destination,
          destinationLabel: destinationLabel,
          initialZoom: destination != null ? 15.5 : 12.0,
        );

  final RxBool useGpsToggle;

  @override
  bool get useGps => useGpsToggle.value;

  /// Switches the active provider and refreshes the latest location.
  void toggleProvider(bool gps) {
    if (useGpsToggle.value == gps) return;
    useGpsToggle.value = gps;
    handleProviderChanged();
  }

  /// Convenience helper to switch between start and stop tracking.
  Future<void> toggleTracking() async {
    if (isTracking.value) {
      await stopTracking();
    } else {
      await startTracking();
    }
  }

  String get providerLabel =>
      useGps ? 'GPS (High Accuracy)' : 'Network (Balanced)';

  @override
  void onInit() {
    super.onInit();
    refreshPosition();
  }
}
