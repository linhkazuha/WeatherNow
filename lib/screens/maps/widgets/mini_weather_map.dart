// lib/screens/maps/widgets/mini_weather_map_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../services/weather_service.dart';
import '../weather_map_screen.dart';

class MiniWeatherMapWidget extends StatefulWidget {
  final double height;
  final LatLng? initialPosition;
  final bool showNavigationButton;
  final String? preSelectedLayer;
  final bool autoUpdateLocation;

  const MiniWeatherMapWidget({
    super.key,
    this.height = 150,
    this.initialPosition,
    this.showNavigationButton = true,
    this.preSelectedLayer,
    this.autoUpdateLocation = true,
  });

  @override
  MiniWeatherMapWidgetState createState() => MiniWeatherMapWidgetState();
}

class MiniWeatherMapWidgetState extends State<MiniWeatherMapWidget> {
  final MapController _mapController = MapController();
  final WeatherService _weatherService = WeatherService();
  late LatLng _position;
  String _currentLayer = 'temp_new';
  bool _isLoading = false;
  bool _isLocationPermissionChecked = false;

  @override
  void initState() {
    super.initState();
    // Default to Hanoi if no position is provided
    _position = widget.initialPosition ?? LatLng(21.0285, 105.8542);

    if (widget.preSelectedLayer != null) {
      _currentLayer = widget.preSelectedLayer!;
    }

    // Check for location updates if auto-update is enabled
    if (widget.autoUpdateLocation) {
      _checkLocationPermission();
    }
  }

  Future<void> _checkLocationPermission() async {
    if (_isLocationPermissionChecked) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Check location permission
      final permissionStatus = await Permission.location.status;

      if (permissionStatus.isGranted) {
        await _getUserLocation();
      } else if (permissionStatus.isDenied) {
        final status = await Permission.location.request();
        if (status.isGranted) {
          await _getUserLocation();
        }
      }
    } catch (e) {
      debugPrint('Lỗi khi kiểm tra quyền truy cập vị trí: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLocationPermissionChecked = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _getUserLocation() async {
    try {
      // Use lower accuracy to improve performance
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 5),
      );

      if (mounted) {
        setState(() {
          _position = LatLng(position.latitude, position.longitude);
        });

        _mapController.move(_position, 8);
      }
    } catch (e) {
      debugPrint('Lỗi khi lấy vị trí: $e');
      // Keep default position if user location unavailable
    }
  }

  void _navigateToFullMap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WeatherMapScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).round();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      height: widget.height,
      decoration: BoxDecoration(
        color: const Color(0xFF2B3866).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Map content with cached network images
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _position,
              initialZoom: 8.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.weathernow',
                tileProvider: CancellableNetworkTileProvider(),
              ),
              Opacity(
                opacity: 0.7,
                child: TileLayer(
                  urlTemplate:
                      'https://tile.openweathermap.org/map/$_currentLayer/{z}/{x}/{y}.png?appid=${_weatherService.apiKey}&date=$timestamp',
                  userAgentPackageName: 'com.example.weathernow',
                  tileProvider: CancellableNetworkTileProvider(),
                ),
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _position,
                    width: 20,
                    height: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red[300],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black38,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Semi-transparent overlay for better contrast
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.2),
                  ],
                ),
              ),
            ),
          ),
          // Tap area for full map
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _navigateToFullMap(context),
                splashColor: Colors.white24,
                highlightColor: Colors.white10,
                child: const SizedBox.expand(),
              ),
            ),
          ),
          // Button with its own tap handler
          if (widget.showNavigationButton)
            Positioned(
              bottom: 12,
              right: 12,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _navigateToFullMap(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2B3866).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Mở bản đồ',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            size: 14,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.black38,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              ),
            ),
          // Attribution text
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '© OpenWeather',
                style: TextStyle(color: Colors.white70, fontSize: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
