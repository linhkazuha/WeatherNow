import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../models/weather_models.dart';

class WeatherMapView extends StatelessWidget {
  final MapController mapController;
  final LatLng currentPosition;
  final LatLng? userPosition;
  final WeatherPoint? selectedPoint;
  final String currentLayer;
  final DateTime selectedTime;
  final String apiKey;
  final bool isLoading;
  final Function(LatLng) onMapTap;

  const WeatherMapView({
    Key? key,
    required this.mapController,
    required this.currentPosition,
    required this.userPosition,
    required this.selectedPoint,
    required this.currentLayer,
    required this.selectedTime,
    required this.apiKey,
    required this.isLoading,
    required this.onMapTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final timestamp = (selectedTime.millisecondsSinceEpoch / 1000).round();

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: currentPosition,
        initialZoom: 10.0,
        onTap: isLoading ? null : (tapPosition, point) => onMapTap(point),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.weathernow',
          tileProvider: CancellableNetworkTileProvider(),
        ),
        Opacity(
          opacity: 0.9,
          child: TileLayer(
            urlTemplate:
                'https://tile.openweathermap.org/map/$currentLayer/{z}/{x}/{y}.png?appid=$apiKey&date=$timestamp',
            userAgentPackageName: 'com.example.weathernow',
            tileProvider: CancellableNetworkTileProvider(),
          ),
        ),
        MarkerLayer(
          markers: [
            if (userPosition != null)
              Marker(
                point: userPosition!,
                width: 20,
                height: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xDD2196F3),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            if (selectedPoint != null)
              Marker(
                point: selectedPoint!.coordinates,
                width: 20,
                height: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xDDFF5722),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// Class to support cancelling unnecessary map data loading
class CancellableNetworkTileProvider extends NetworkTileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return NetworkImage(getTileUrl(coordinates, options));
  }
}
