// lib/screens/maps/weather_map_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../models/weather_models.dart';
import '../../../services/weather_service.dart';

class WeatherMapScreen extends StatefulWidget {
  const WeatherMapScreen({super.key});

  @override
  WeatherMapScreenState createState() => WeatherMapScreenState();
}

class WeatherMapScreenState extends State<WeatherMapScreen>
    with AutomaticKeepAliveClientMixin {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  // Default location: Hanoi
  LatLng _currentPosition = LatLng(21.0285, 105.8542);
  LatLng? _userPosition;
  bool _isLoading = false;
  bool _isLocationPermissionChecked = false;
  bool _showLayerOptions = false;

  String _currentLayer = 'temp_new';
  final List<MapLayer> _availableLayers = [
    MapLayer('temp_new', 'Nhiệt độ', const Color(0xFFFF5722), {
      -65: const Color(0xFF120F3B),
      -55: const Color(0xFF331A80),
      -45: const Color(0xFF5A32A0),
      -40: const Color(0xFF6B3EB3),
      -35: const Color(0xFF6A50C8),
      -30: const Color(0xFF796ED9),
      -25: const Color(0xFF8B91EB),
      -20: const Color(0xFF98B3F8),
      -15: const Color(0xFFADD2F3),
      -10: const Color(0xFF94D4EB),
      -5: const Color(0xFF77D9E5),
      0: const Color(0xFF5CD9DD),
      5: const Color(0xFF50D4C3),
      10: const Color(0xFF68D28C),
      15: const Color(0xFF8AD159),
      20: const Color(0xFFB0CE38),
      25: const Color(0xFFDCC632),
      30: const Color(0xFFF5B734),
      35: const Color(0xFFF78C26),
      40: const Color(0xFFED6024),
      45: const Color(0xFFE34427),
      50: const Color(0xFFDB292D),
    }),
    MapLayer('precipitation_new', 'Lượng mưa', const Color(0xFF2196F3), {
      0: const Color(0xFFFFFFFF),
      1: const Color(0xFFA4F9FF),
      5: const Color(0xFF5EDFFF),
      10: const Color(0xFF45B8FF),
      20: const Color(0xFF2F91FF),
      30: const Color(0xFF1F6CFF),
      40: const Color(0xFF1F46FF),
      60: const Color(0xFF4E1FFF),
      80: const Color(0xFF7E1FFF),
      100: const Color(0xFFAE1FFF),
      120: const Color(0xFFDA1FFF),
      140: const Color(0xFFFF1FF6),
      160: const Color(0xFFFF1FB8),
      180: const Color(0xFFFF1F7A),
      200: const Color(0xFFFF2C39),
      220: const Color(0xFFFF5D1F),
    }),
    MapLayer('wind_new', 'Gió', const Color(0xFF4CAF50), {
      1: const Color(0xFFCAFFBF),
      5: const Color(0xFFB3FF99),
      10: const Color(0xFF99FF72),
      15: const Color(0xFF85FF4D),
      20: const Color(0xFF70FF26),
      25: const Color(0xFF50FF00),
      30: const Color(0xFF45E000),
      35: const Color(0xFF3BC000),
      40: const Color(0xFF32A000),
      45: const Color(0xFF288500),
      50: const Color(0xFF1E6500),
      100: const Color(0xFF0D3000),
    }),
    MapLayer('clouds_new', 'Mây', const Color(0xFF9E9E9E), {
      0: const Color(0xFFFFFFFF),
      10: const Color(0xFFE6E6E6),
      20: const Color(0xFFCCCCCC),
      30: const Color(0xFFB3B3B3),
      40: const Color(0xFF999999),
      50: const Color(0xFF808080),
      60: const Color(0xFF666666),
      70: const Color(0xFF4D4D4D),
      80: const Color(0xFF333333),
      90: const Color(0xFF1A1A1A),
      100: const Color(0xFF000000),
    }),
    MapLayer('pressure_new', 'Áp suất', const Color(0xFF673AB7), {
      950: const Color(0xFFDAE2F8),
      970: const Color(0xFFBACEF8),
      990: const Color(0xFF9ABAFF),
      1000: const Color(0xFF809CFF),
      1010: const Color(0xFF6384FF),
      1020: const Color(0xFF4E68FA),
      1030: const Color(0xFF4052F4),
      1040: const Color(0xFF3640F5),
      1050: const Color(0xFF332EF0),
      1070: const Color(0xFF311CF0),
      1080: const Color(0xFF2F0ADD),
    }),
  ];

  DateTime _selectedTime = DateTime.now();
  double _timeSliderValue = 0.0;
  final int _maxForecastHours = 120;

  WeatherPoint? _selectedPoint;
  bool _showInfoPanel = false;

  // Weather data cache
  final WeatherService _weatherService = WeatherService();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Initialize map with default location immediately
    // Then check location permission in background
    _checkLocationPermission();
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
      setState(() {
        _isLocationPermissionChecked = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _getUserLocation() async {
    try {
      // Use lower accuracy to improve speed
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 5),
      );

      if (mounted) {
        setState(() {
          _userPosition = LatLng(position.latitude, position.longitude);
          _currentPosition = _userPosition!;
        });

        _mapController.move(_currentPosition, 10);
      }
    } catch (e) {
      debugPrint('Lỗi khi lấy vị trí: $e');
      // Keep default position if user location unavailable
    }
  }

  void _goToCurrentLocation() {
    if (_userPosition != null) {
      _mapController.move(_userPosition!, 10);
    } else {
      _getUserLocation();
    }
  }

  Future<void> _getPointWeather(LatLng point) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final weatherPoint = await _weatherService.getWeatherAtPoint(point);

      if (mounted) {
        setState(() {
          _selectedPoint = weatherPoint;
          _showInfoPanel = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lấy dữ liệu thời tiết: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final position = await _weatherService.searchLocation(query);

      if (position != null) {
        _mapController.move(position, 10);
        await _getPointWeather(position);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không tìm thấy địa điểm')),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tìm kiếm địa điểm: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _updateTimeFromSlider(double value) {
    final now = DateTime.now();
    final hours = (value * _maxForecastHours).floor();

    setState(() {
      _timeSliderValue = value;
      _selectedTime = now.add(Duration(hours: hours));
    });
  }

  String _getFormattedTime() {
    return DateFormat('HH:mm - dd/MM/yyyy').format(_selectedTime);
  }

  void _toggleLayerOptions() {
    setState(() {
      _showLayerOptions = !_showLayerOptions;
    });
  }

  Color _getLayerLegendColor(MapLayer layer, double proportion) {
    final colorMap = layer.colorMap;
    if (colorMap.isEmpty) return layer.color;

    // Sort keys in ascending order
    final sortedKeys = colorMap.keys.toList()..sort();

    // Find appropriate key based on proportion
    final int targetValue =
        (sortedKeys.first + (sortedKeys.last - sortedKeys.first) * proportion)
            .round();

    // Find closest value in color map
    int closestKey = sortedKeys.first;

    for (final key in sortedKeys) {
      if (key <= targetValue) {
        closestKey = key;
      } else {
        break;
      }
    }

    return colorMap[closestKey] ?? layer.color;
  }

  MapLayer get _currentLayerData {
    return _availableLayers.firstWhere(
      (layer) => layer.id == _currentLayer,
      orElse: () => _availableLayers.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: Stack(
        children: [
          _buildMap(),
          SafeArea(
            child: Column(
              children: [
                _buildSearchBar(),
                const SizedBox(height: 10),
                _buildLayerSelector(),
              ],
            ),
          ),
          _buildTimeSlider(),
          if (_showInfoPanel) _buildInfoPanel(),
          _buildLocationButton(),
          if (_isLoading) _buildLoadingIndicator(),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }

  Widget _buildMap() {
    final timestamp = (_selectedTime.millisecondsSinceEpoch / 1000).round();

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentPosition,
        initialZoom: 10.0,
        onTap:
            _isLoading ? null : (tapPosition, point) => _getPointWeather(point),
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
          opacity: 0.9, // Increased opacity as requested
          child: TileLayer(
            urlTemplate:
                'https://tile.openweathermap.org/map/$_currentLayer/{z}/{x}/{y}.png?appid=${_weatherService.apiKey}&date=$timestamp',
            userAgentPackageName: 'com.example.weathernow',
            tileProvider: CancellableNetworkTileProvider(),
          ),
        ),
        MarkerLayer(
          markers: [
            if (_userPosition != null)
              Marker(
                point: _userPosition!,
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
            if (_selectedPoint != null)
              Marker(
                point: _selectedPoint!.coordinates,
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm địa điểm',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => _searchController.clear(),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              _searchLocation(value);
            }
          },
          enabled: !_isLoading,
        ),
      ),
    );
  }

  Widget _buildLayerSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Align(
        alignment: Alignment.topRight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _toggleLayerOptions,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _currentLayerData.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(_currentLayerData.name),
                        const SizedBox(width: 8),
                        Icon(
                          _showLayerOptions
                              ? Icons.arrow_drop_up
                              : Icons.arrow_drop_down,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_showLayerOptions)
              Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children:
                      _availableLayers
                          .map((layer) => _buildLayerOption(layer))
                          .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayerOption(MapLayer layer) {
    final isSelected = _currentLayer == layer.id;
    Color backgroundColor = Colors.transparent;

    if (isSelected) {
      backgroundColor = Color.alphaBlend(
        layer.color.withOpacity(0.2),
        Colors.white,
      );
    }

    return Material(
      color: backgroundColor,
      child: InkWell(
        onTap:
            _isLoading
                ? null
                : () {
                  setState(() {
                    _currentLayer = layer.id;
                    _showLayerOptions = false;
                  });
                },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: layer.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(layer.name),
              const SizedBox(width: 16),
              if (isSelected) const Icon(Icons.check, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSlider() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Hiện tại'),
                Text(_getFormattedTime()),
                const Text('+5 ngày'),
              ],
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.amber,
                inactiveTrackColor: Colors.grey.shade300,
                thumbColor: Colors.amber,
                overlayColor: const Color.fromRGBO(255, 193, 7, 0.2),
              ),
              child: Slider(
                value: _timeSliderValue,
                onChanged: _isLoading ? null : _updateTimeFromSlider,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPanel() {
    if (_selectedPoint == null) return const SizedBox.shrink();

    return Positioned(
      top: 170,
      left: 20,
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _selectedPoint!.location,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => setState(() => _showInfoPanel = false),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_selectedPoint!.temperature.toStringAsFixed(1)}°C',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              _selectedPoint!.description,
              style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 8),
            _infoRow(
              'Cảm giác như',
              '${_selectedPoint!.feelsLike.toStringAsFixed(1)}°C',
            ),
            _infoRow('Độ ẩm', '${_selectedPoint!.humidity}%'),
            _infoRow('Gió', '${_selectedPoint!.windSpeed} m/s'),
            _infoRow('Áp suất', '${_selectedPoint!.pressure} hPa'),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Positioned(
      bottom: 100,
      left: 20,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Chú giải: ${_currentLayerData.name}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Container(
              width: 150,
              height: 10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                gradient: LinearGradient(
                  colors: List.generate(
                    10,
                    (index) =>
                        _getLayerLegendColor(_currentLayerData, index / 9),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getLegendMinValue(_currentLayerData),
                  style: const TextStyle(fontSize: 10),
                ),
                Text(
                  _getLegendMaxValue(_currentLayerData),
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getLegendMinValue(MapLayer layer) {
    if (layer.colorMap.isEmpty) return "Min";

    final minKey = layer.colorMap.keys.reduce((a, b) => a < b ? a : b);

    switch (layer.id) {
      case 'temp_new':
        return "$minKey°C";
      case 'precipitation_new':
        return "$minKey mm";
      case 'wind_new':
        return "$minKey m/s";
      case 'clouds_new':
        return "$minKey%";
      case 'pressure_new':
        return "$minKey hPa";
      default:
        return "$minKey";
    }
  }

  String _getLegendMaxValue(MapLayer layer) {
    if (layer.colorMap.isEmpty) return "Max";

    final maxKey = layer.colorMap.keys.reduce((a, b) => a > b ? a : b);

    switch (layer.id) {
      case 'temp_new':
        return "$maxKey°C";
      case 'precipitation_new':
        return "$maxKey mm";
      case 'wind_new':
        return "$maxKey m/s";
      case 'clouds_new':
        return "$maxKey%";
      case 'pressure_new':
        return "$maxKey hPa";
      default:
        return "$maxKey";
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildLocationButton() {
    return Positioned(
      bottom: 110,
      right: 20,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.my_location),
          onPressed: _isLoading ? null : _goToCurrentLocation,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

// Class to support cancelling unnecessary map data loading
class CancellableNetworkTileProvider extends NetworkTileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return NetworkImage(getTileUrl(coordinates, options));
  }
}
