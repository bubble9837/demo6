import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../../../services/location_service.dart';
import '../controllers/location_controller.dart';

class LocationBinding extends Bindings {
  LocationBinding({
    required this.destinationLabel,
    this.destination,
  });

  final String destinationLabel;
  final LatLng? destination;

  @override
  void dependencies() {
    if (!Get.isRegistered<LocationService>()) {
      Get.put(LocationService());
    }

    Get.lazyPut<LocationController>(
      () => LocationController(
        locationService: Get.find<LocationService>(),
        destination: destination,
        destinationLabel: destinationLabel,
      ),
    );
  }
}
