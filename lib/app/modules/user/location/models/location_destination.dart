import 'package:latlong2/latlong.dart';

class LocationDestination {
  const LocationDestination({
    required this.name,
    this.address,
    this.latitude,
    this.longitude,
  });

  factory LocationDestination.fromMap(Map<String, dynamic> data) {
    final lat = data['latitude'];
    final lng = data['longitude'];
    return LocationDestination(
      name: data['name'] as String? ?? 'Lokasi',
      address: data['address'] as String?,
      latitude: lat is num ? lat.toDouble() : null,
      longitude: lng is num ? lng.toDouble() : null,
    );
  }

  final String name;
  final String? address;
  final double? latitude;
  final double? longitude;

  LatLng? get latLng {
    if (latitude == null || longitude == null) return null;
    return LatLng(latitude!, longitude!);
  }

  String? get coordinatesLabel {
    if (latitude == null || longitude == null) return null;
    return '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}';
  }
}
