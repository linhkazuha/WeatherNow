import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/location_service.dart';
import '../widgets/weather_map_viewer.dart';
import '../widgets/search_bar.dart';
import '../widgets/layer_selector.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  double _lat = AppConstants.defaultLat;
  double _lon = AppConstants.defaultLon;
  int _zoom = AppConstants.defaultZoom;
  String _layer = AppConstants.defaultLayer;

  Future<void> _goToCurrentLocation() async {
    final position = await LocationService.getCurrentPosition(context);
    if (position != null) {
      setState(() {
        _lat = position.latitude;
        _lon = position.longitude;
        _zoom = 12;
      });
    }
  }

  Future<void> _searchPlace(String placeName) async {
    if (placeName.trim().isEmpty) return;

    final location = await LocationService.searchLocation(placeName, context);
    if (location != null) {
      setState(() {
        _lat = location.latitude;
        _lon = location.longitude;
        _zoom = 10;
      });
    }
  }

  void _changeLayer(String selectedLayer) {
    setState(() {
      _layer = selectedLayer;
    });
  }

  void _setLoadingState(bool isLoading) {
    setState(() {
      _isLoading = isLoading;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map WebView
          WeatherMapViewer(
            latitude: _lat,
            longitude: _lon,
            zoom: _zoom,
            layer: _layer,
            onLoadingChanged: _setLoadingState,
          ),

          // Safety padding for status bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).padding.top,
              color: Color.fromRGBO(255, 255, 255, 0.8),
            ),
          ),

          // Search Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0,
            right: 0,
            child: WeatherSearchBar(
              controller: _searchController,
              onSearch: _searchPlace,
            ),
          ),

          // Layer Selector
          LayerSelector(currentLayer: _layer, onLayerChanged: _changeLayer),

          // Current Location Button
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: _goToCurrentLocation,
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: Colors.blue),
            ),
          ),

          // Loading Indicator
          if (_isLoading)
            Container(
              color: Color.fromRGBO(0, 0, 0, 0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
