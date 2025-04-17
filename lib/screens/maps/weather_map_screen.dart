import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../models/weather_models.dart';
import '../../../services/weather_service.dart';
import 'widgets/weather_time_slider.dart';
import 'widgets/weather_layer_dropdown.dart';

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
  // ignore: unused_field
  bool _showLayerOptions = false;

  String _currentLayer = 'temp_new';
  final List<MapLayer> _availableLayers = [
    MapLayer('temp_new', 'Nhiệt độ', const Color(0xFFFF5722), {
      -65: const Color(0xFF821692),
      -55: const Color(0xFF821692),
      -45: const Color(0xFF821692),
      -40: const Color(0xFF821692),
      -30: const Color(0xFF8257DB),
      -20: const Color(0xFF208CEC),
      -10: const Color(0xFF20C4E8),
      0: const Color(0xFF23DDDD),
      10: const Color(0xFFC2FF28),
      20: const Color(0xFFFFF028),
      25: const Color(0xFFFFC228),
      30: const Color(0xFFFC8014),
    }),
    MapLayer('precipitation_new', 'Lượng mưa', const Color(0xFF2196F3), {
      0: const Color(0x00E1C864),
      1: const Color(0x00C89632), // Thay 0.1 bằng 1
      2: const Color(0x009696AA), // Thay 0.2 bằng 2
      5: const Color(0x007878BE), // Thay 0.5 bằng 5
      10: const Color(0x4C6E6ECD),
      100: const Color(0xB25050E1), // Thay 10 bằng 100 để giữ tỷ lệ
      1400: const Color(0xE51414FF), // Thay 140 bằng 1400 để giữ tỷ lệ
    }),
    MapLayer('wind_new', 'Gió', const Color(0xFF4CAF50), {
      1: const Color(0x00FFFFFF),
      5: const Color(0x66EECECC),
      15: const Color(0xB3B364BC),
      25: const Color(0xCC3F213B),
      50: const Color(0xE6744CAC),
      100: const Color(0xFF4600AF),
      200: const Color(0xFF0D1126),
    }),
    MapLayer('clouds_new', 'Mây', const Color(0xFF9E9E9E), {
      0: const Color(0x00FFFFFF),
      10: const Color(0x19FDFDFF),
      20: const Color(0x26FCFBFF),
      30: const Color(0x33FAFAFF),
      40: const Color(0x4CF9F8FF),
      50: const Color(0x66F7F7FF),
      60: const Color(0x8CF6F5FF),
      70: const Color(0xBFF4F4FF),
      80: const Color(0xCCE9E9DF),
      90: const Color(0xD8DEDEDE),
      100: const Color(0xFFD2D2D2),
      200: const Color(0xFFD2D2D2),
    }),
    MapLayer('pressure_new', 'Áp suất', const Color(0xFF673AB7), {
      94000: const Color(0xFF0073FF),
      96000: const Color(0xFF00AAFF),
      98000: const Color(0xFF4BD0D6),
      100000: const Color(0xFF8DE7C7),
      101000: const Color(0xFFB0F720),
      102000: const Color(0xFFF0B800),
      104000: const Color(0xFFFB5515),
      106000: const Color(0xFFF3363B),
      108000: const Color(0xFFC60000),
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

  String _getLegendMinValue(MapLayer layer) {
    if (layer.colorMap.isEmpty) return "Min";

    final minKey = layer.colorMap.keys.reduce((a, b) => a < b ? a : b);

    switch (layer.id) {
      case 'temp_new':
        return "$minKey°C";
      case 'precipitation_new':
        // Điều chỉnh hiển thị cho lớp lượng mưa
        if (minKey == 0) return "0 mm";
        if (minKey == 1) return "0.1 mm";
        if (minKey == 2) return "0.2 mm";
        if (minKey == 5) return "0.5 mm";
        if (minKey == 100) return "10 mm";
        if (minKey == 1400) return "140 mm";
        return "$minKey mm";
      case 'wind_new':
        return "$minKey m/s";
      case 'clouds_new':
        return "$minKey%";
      case 'pressure_new':
        return "${(minKey / 100).toStringAsFixed(0)} hPa";
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
        // Điều chỉnh hiển thị cho lớp lượng mưa
        if (maxKey == 1400) return "140 mm";
        if (maxKey == 100) return "10 mm";
        return "$maxKey mm";
      case 'wind_new':
        return "$maxKey m/s";
      case 'clouds_new':
        return "$maxKey%";
      case 'pressure_new':
        return "${(maxKey / 100).toStringAsFixed(0)} hPa";
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
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final timestamp = (_selectedTime.millisecondsSinceEpoch / 1000).round();

    return Scaffold(
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition,
              initialZoom: 10.0,
              onTap:
                  _isLoading
                      ? null
                      : (tapPosition, point) => _getPointWeather(point),
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
                opacity:
                    0.7, // Giảm độ mờ đục để văn bản trên bản đồ dễ đọc hơn
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
          ),

          // Search bar and layer selector
          SafeArea(
            child: Column(
              children: [
                _buildSearchBar(),
                const SizedBox(height: 10),
                _buildLayerSelector(),
              ],
            ),
          ),

          // Time slider
          _buildTimeSlider(),

          // Info panel
          if (_showInfoPanel) _buildInfoPanel(),

          // Location button
          _buildLocationButton(),

          // Loading indicator
          if (_isLoading) _buildLoadingIndicator(),

          // Legend
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
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
            hintStyle: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: const Icon(Icons.search, color: Colors.black87),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear, color: Colors.black87),
              onPressed: () => _searchController.clear(),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
          ),
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w500,
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
    return WeatherLayerDropdown(
      availableLayers: _availableLayers,
      currentLayerId: _currentLayer,
      isLoading: _isLoading,
      onLayerSelected: (layerId) {
        setState(() {
          _currentLayer = layerId;
          _showLayerOptions = false;
        });
      },
    );
  }

  Widget _buildTimeSlider() {
    return Positioned(
      bottom: 12,
      left: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: WeatherTimeSlider(
          initialTime: _selectedTime,
          initialValue: _timeSliderValue,
          isLoading: _isLoading,
          onTimeChanged: _updateTimeFromSlider,
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 3),
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
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16, color: Colors.black),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => setState(() => _showInfoPanel = false),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_selectedPoint!.temperature.toStringAsFixed(1)}°C',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              _selectedPoint!.description,
              style: const TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.black,
              ),
            ),
            const Divider(height: 16),
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
      bottom: 180,
      left: 20,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thêm tiêu đề cho chú giải
            Text(
              _currentLayerData.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.black87,
              ),
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
            SizedBox(
              width: 150,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getLegendMinValue(_currentLayerData),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    _getLegendMaxValue(_currentLayerData),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationButton() {
    return Positioned(
      bottom: 180,
      right: 20,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.my_location, color: Colors.black87),
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
