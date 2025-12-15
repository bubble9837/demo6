import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/location_controller.dart';

class LiveLocationView extends GetView<LocationController> {
  const LiveLocationView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = DateFormat('dd MMM yyyy HH:mm:ss');

    return Obx(() {
      final position = controller.currentPosition.value;
      final error = controller.errorMessage.value;
      final isLoading = controller.isLoading.value;
      final isTracking = controller.isTracking.value;
      final serviceEnabled = controller.isGpsEnabled.value;
      final permissionStatus = controller.permissionStatus.value;
      final lastUpdated = controller.lastUpdatedAt.value;
      final userLatLng = controller.currentLatLng;
      final destination = controller.activeDestination;
      final manualDestination = controller.manualDestination.value;
      final accuracyMeters = position?.accuracy;

      final markers = <Marker>[];
      if (userLatLng != null) {
        markers.add(
          Marker(
            width: 58,
            height: 58,
            point: userLatLng,
            child: _markerBadge(
              color: Colors.indigo,
              icon: Icons.person_pin_circle,
              label: 'Anda',
            ),
          ),
        );
      }
      if (destination != null) {
        markers.add(
          Marker(
            width: 58,
            height: 58,
            point: destination,
            child: _markerBadge(
              color: Colors.orangeAccent,
              icon: Icons.location_on,
              label: 'Tujuan',
            ),
          ),
        );
      }

      final timestampLabel = lastUpdated == null
          ? '-'
          : formatter.format(lastUpdated.toLocal());
      final showAccuracyCircle =
          userLatLng != null && accuracyMeters != null && accuracyMeters > 0;
      final circles = showAccuracyCircle
          ? [
              CircleMarker(
                point: userLatLng!,
                radius: accuracyMeters!.clamp(8, 2000).toDouble(),
                useRadiusInMeter: true,
                color: theme.colorScheme.primary.withOpacity(0.12),
                borderColor: theme.colorScheme.primary.withOpacity(0.48),
                borderStrokeWidth: 2,
              ),
            ]
          : const <CircleMarker>[];
      final providerColor = controller.useGpsToggle.value
          ? theme.colorScheme.primary
          : theme.colorScheme.secondary;

      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Live Location Tracker',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                if (isTracking)
                  Chip(
                    avatar: const Icon(Icons.wifi_tethering, size: 16),
                    label: const Text('LIVE'),
                    backgroundColor: theme.colorScheme.primary.withOpacity(
                      0.15,
                    ),
                    labelStyle: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  avatar: const Icon(Icons.gps_fixed, size: 16),
                  label: const Text('GPS'),
                  selected: controller.useGpsToggle.value,
                  onSelected: (_) => controller.toggleProvider(true),
                ),
                ChoiceChip(
                  avatar: const Icon(Icons.network_wifi, size: 16),
                  label: const Text('Network'),
                  selected: !controller.useGpsToggle.value,
                  onSelected: (_) => controller.toggleProvider(false),
                ),
                InputChip(
                  label: Text(
                    serviceEnabled ? 'Service aktif' : 'Service mati',
                  ),
                  avatar: Icon(
                    serviceEnabled ? Icons.check_circle : Icons.error_outline,
                    color: serviceEnabled ? Colors.green : Colors.redAccent,
                  ),
                  onPressed: () async {
                    if (!serviceEnabled) {
                      await controller.openLocationSettings();
                    }
                  },
                ),
                if (permissionStatus != null)
                  InputChip(
                    label: Text(permissionStatus.toString().split('.').last),
                    avatar: const Icon(Icons.verified_user, size: 18),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isLoading ? null : controller.refreshPosition,
                    icon: isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.openAppPermissionSettings,
                    icon: const Icon(Icons.settings),
                    label: const Text('Pengaturan'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: controller.toggleTracking,
                    icon: Icon(isTracking ? Icons.stop : Icons.play_arrow),
                    label: Text(
                      isTracking ? 'Stop Tracking' : 'Mulai Tracking',
                    ),
                  ),
                ),
              ],
            ),
            if (error.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: theme.colorScheme.errorContainer,
                ),
                child: Text(
                  error,
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          FlutterMap(
                            mapController: controller.mapController,
                            options: MapOptions(
                              initialCenter: controller.fallbackCenter,
                              initialZoom: controller.initialZoom,
                              onMapReady: controller.onMapReady,
                              onLongPress: (_, latLng) =>
                                  controller.setManualDestination(latLng),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.demo_3',
                              ),
                              if (circles.isNotEmpty)
                                CircleLayer(circles: circles),
                              MarkerLayer(markers: markers),
                            ],
                          ),
                          if (showAccuracyCircle)
                            Positioned(
                              top: 12,
                              left: 12,
                              child: _accuracyBadge(
                                context,
                                accuracyMeters!,
                                providerColor,
                              ),
                            ),
                          if (destination == null)
                            Positioned(
                              top: 12,
                              right: 12,
                              child: _tipBadge(
                                context,
                                'Tekan lama peta untuk tambah tujuan.',
                                providerColor,
                              ),
                            )
                          else
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _miniButton(
                                    context,
                                    icon: Icons.center_focus_strong,
                                    tooltip: 'Fokus ke tujuan',
                                    onPressed: controller.focusOnDestination,
                                    color: providerColor,
                                  ),
                                  if (manualDestination != null) ...[
                                    const SizedBox(width: 8),
                                    _miniButton(
                                      context,
                                      icon: Icons.delete_outline,
                                      tooltip: 'Hapus tujuan manual',
                                      onPressed:
                                          controller.resetManualDestination,
                                      color: providerColor,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          Positioned(
                            right: 12,
                            bottom: 12,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (accuracyMeters != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: _mapAccuracyButton(
                                      context,
                                      accuracyMeters,
                                      providerColor,
                                      onPressed:
                                          controller.centerOnLatestPosition,
                                    ),
                                  ),
                                _mapControlButton(
                                  context,
                                  icon: Icons.add,
                                  onPressed: controller.zoomIn,
                                ),
                                const SizedBox(height: 8),
                                _mapControlButton(
                                  context,
                                  icon: Icons.remove,
                                  onPressed: controller.zoomOut,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    fit: FlexFit.loose,
                    child: SingleChildScrollView(
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Wrap(
                            spacing: 24,
                            runSpacing: 14,
                            children: [
                              _infoTile('Provider', controller.providerLabel),
                              _infoTile(
                                'Latitude',
                                position != null
                                    ? position.latitude.toStringAsFixed(6)
                                    : '-',
                              ),
                              _infoTile(
                                'Longitude',
                                position != null
                                    ? position.longitude.toStringAsFixed(6)
                                    : '-',
                              ),
                              _infoTile(
                                'Akurasi',
                                position?.accuracy != null
                                    ? '${position!.accuracy.toStringAsFixed(2)} m'
                                    : '-',
                              ),
                              _infoTile(
                                'Kecepatan',
                                position?.speed != null
                                    ? '${(position!.speed * 3.6).toStringAsFixed(1)} km/j'
                                    : '-',
                              ),
                              _infoTile('Update', timestampLabel),
                              if (destination != null)
                                _infoTile(
                                  'Tujuan',
                                  '${destination.latitude.toStringAsFixed(5)}, ${destination.longitude.toStringAsFixed(5)}',
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  static Widget _markerBadge({
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.85),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.35), blurRadius: 8),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ],
    );
  }

  static Widget _infoTile(String label, String value) {
    return SizedBox(
      width: 148,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  static Widget _mapControlButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    return Material(
      elevation: 3,
      shape: const CircleBorder(),
      color: theme.colorScheme.surface.withOpacity(0.92),
      child: IconButton(
        icon: Icon(icon, color: theme.colorScheme.onSurface),
        onPressed: onPressed,
        splashRadius: 24,
        constraints: const BoxConstraints.tightFor(width: 46, height: 46),
      ),
    );
  }

  static Widget _accuracyBadge(
    BuildContext context,
    double accuracyMeters,
    Color highlight,
  ) {
    final theme = Theme.of(context);
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(14),
      color: theme.colorScheme.surface.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.center_focus_strong, size: 16, color: highlight),
            const SizedBox(width: 8),
            Text(
              'Akurasi ±${accuracyMeters.toStringAsFixed(1)} m',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _mapAccuracyButton(
    BuildContext context,
    double accuracyMeters,
    Color highlight, {
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    return Tooltip(
      message: 'Pusatkan (±${accuracyMeters.toStringAsFixed(1)} m)',
      child: FloatingActionButton.small(
        heroTag: 'center-accuracy-button',
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: highlight,
        onPressed: onPressed,
        elevation: 4,
        child: const Icon(Icons.center_focus_strong),
      ),
    );
  }

  static Widget _tipBadge(
    BuildContext context,
    String message,
    Color highlight,
  ) {
    final theme = Theme.of(context);
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(14),
      color: theme.colorScheme.surface.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 16, color: highlight),
            const SizedBox(width: 8),
            Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _miniButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: theme.colorScheme.surface.withOpacity(0.92),
        shape: const CircleBorder(),
        elevation: 3,
        child: IconButton(
          icon: Icon(icon, color: color, size: 18),
          onPressed: onPressed,
          splashRadius: 22,
          constraints: const BoxConstraints.tightFor(width: 42, height: 42),
        ),
      ),
    );
  }
}
