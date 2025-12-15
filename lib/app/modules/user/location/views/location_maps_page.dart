import 'package:flutter/material.dart';

import '../models/location_destination.dart';
import 'gps_location_view.dart';
import 'live_location_view.dart';
import 'network_location_view.dart';

class LocationMapsPage extends StatelessWidget {
  const LocationMapsPage({super.key, required this.destination});

  final LocationDestination destination;

  @override
  Widget build(BuildContext context) {
  return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Rute ke ${destination.name}'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Live'),
              Tab(text: 'Network'),
              Tab(text: 'GPS'),
            ],
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DestinationHeader(destination: destination),
            const Divider(height: 1),
            const Expanded(
              child: TabBarView(
                children: [
                  LiveLocationView(),
                  NetworkLocationView(),
                  GpsLocationView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DestinationHeader extends StatelessWidget {
  const _DestinationHeader({required this.destination});

  final LocationDestination destination;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coords = destination.coordinatesLabel;
    return ListTile(
      title: Text(destination.name, style: theme.textTheme.titleMedium),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (destination.address != null && destination.address!.isNotEmpty)
            Text(destination.address!),
          if (coords != null) Text(coords),
        ],
      ),
    );
  }
}
