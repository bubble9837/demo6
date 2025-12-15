import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../../../services/location_service.dart';
import '../controllers/network_location_controller.dart';

class NetworkLocationBinding extends Bindings {
  NetworkLocationBinding({
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

    Get.lazyPut<NetworkLocationController>(
      () => NetworkLocationController(
        locationService: Get.find<LocationService>(),
        destination: destination,
        destinationLabel: destinationLabel,
      ),
    );
  }
}
