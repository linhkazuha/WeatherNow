import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weather_app/providers/theme_provider.dart';
import 'package:weather_app/providers/location_provider.dart';
import 'package:weather_app/services/weather_service.dart';
import 'package:weather_app/utils/time_formatter.dart';
// import 'package:weather_app/services/notification_service.dart';
import 'package:weather_app/services/alert_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  bool _showActive = true;
  bool _isLoadingWeather = true;
  List<WeatherAlert> _activeAlerts = [];
  List<WeatherAlert> _alertHistory = [];
  List<Map<String, dynamic>> _dailyForecast = [];
  final AlertStorageService _storageService = AlertStorageService();
  Map<String, bool> _alertSubscriptions = {};

  @override
  void initState() {
    super.initState();
    _loadAlertHistory();
    _loadSubscriptions();
    _fetchWeatherData();
  }

  Future<void> _loadAlertHistory() async {
    final history = await _storageService.loadAlertHistory();
    setState(() {
      _alertHistory = history;
    });
  }

  Future<void> _loadSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _alertSubscriptions = {
        'Mưa lớn': prefs.getBool('Mưa lớn') ?? true,
        'Giông sét': prefs.getBool('Giông sét') ?? true,
        'Chỉ số UV cao': prefs.getBool('Chỉ số UV cao') ?? true,
        'Chất lượng không khí': prefs.getBool('Chất lượng không khí') ?? true,
        'Nhiệt độ cao': prefs.getBool('Nhiệt độ cao') ?? true,
        'Lũ lụt': prefs.getBool('Lũ lụt') ?? true,
        'Độ ẩm cao': prefs.getBool('Độ ẩm cao') ?? true,
      };
    });
  }

  Future<void> _saveSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();
    _alertSubscriptions.forEach((key, value) {
      prefs.setBool(key, value);
    });
  }

  Future<void> _fetchWeatherData() async {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    await locationProvider.fetchCurrentLocation();
    if (locationProvider.currentPosition != null) {
      try {
        final weatherService = WeatherService();
        final weatherData = await weatherService.fetchWeatherData(
          locationProvider.currentPosition!,
        );
        final airQualityData = await weatherService.fetchAirQuality(
          locationProvider.currentPosition!,
        );

        final currentWeather = weatherService.parseCurrentWeather(weatherData);
        final hourlyForecast = weatherService.parseHourlyForecast(weatherData);
        final dailyForecast = weatherService.parseDailyForecast(weatherData);

        setState(() {
          _dailyForecast = dailyForecast;
          _activeAlerts = _getActiveAlerts(
            locationProvider.currentLocationName,
            currentWeather,
            hourlyForecast,
            airQualityData,
          );
          _isLoadingWeather = false;
        });

        _updateAlerts();
      } catch (e) {
        setState(() {
          _isLoadingWeather = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lấy dữ liệu thời tiết: $e')),
        );
      }
    }
  }

  void _updateAlerts() {
    final now = DateTime.now();
    final expiredAlerts =
        _activeAlerts.where((alert) {
          return now.difference(alert.timestamp).inHours >= 1;
        }).toList();

    setState(() {
      _activeAlerts.removeWhere((alert) => expiredAlerts.contains(alert));
      _alertHistory.addAll(expiredAlerts);
    });

    _storageService.saveAlertHistory(_alertHistory);
  }

  List<WeatherAlert> _getActiveAlerts(
    String location,
    Map<String, dynamic> currentWeather,
    Map<String, dynamic> hourlyForecast,
    Map<String, dynamic> airQualityData,
  ) {
    final List<WeatherAlert> alerts = [];
    final now = DateTime.now();

    // Dữ liệu hiện tại
    final currentRainVolume = currentWeather['rain'] as double;
    // ignore: unused_local_variable
    final currentWeatherCondition = currentWeather['weather'] as String;
    final currentTemperature = currentWeather['temperature'] as double;
    final currentHumidity = currentWeather['humidity'] as double;
    final currentUvi = currentWeather['uvi'] as double;

    // Dữ liệu dự báo trong 1 giờ tới
    final forecastRainVolume = hourlyForecast['rain'] as double;
    final forecastWeatherCondition = hourlyForecast['weather'] as String;

    // Dự báo hôm nay và ngày mai
    final todayForecast =
        _dailyForecast.isNotEmpty
            ? WeatherAlert(
              id: 'forecast_today',
              title: 'Dự báo hôm nay',
              description:
                  'Nhiệt độ: ${_dailyForecast[0]['temperature'].toStringAsFixed(1)}°C, Tình trạng: ${_dailyForecast[0]['condition']}, Độ ẩm: ${_dailyForecast[0]['humidity']}%, Gió: ${_dailyForecast[0]['wind_speed']} m/s, UV: ${_dailyForecast[0]['uvi']}',
              severity: AlertSeverity.info,
              location: location,
              timestamp: now,
              expiryTime: now.add(const Duration(days: 1)),
            )
            : WeatherAlert(
              id: 'forecast_today',
              title: 'Dự báo hôm nay',
              description: 'Không có dữ liệu thời tiết',
              severity: AlertSeverity.info,
              location: location,
              timestamp: now,
              expiryTime: now.add(const Duration(days: 1)),
            );

    final tomorrowForecast =
        _dailyForecast.length > 1
            ? WeatherAlert(
              id: 'forecast_tomorrow',
              title: 'Dự báo ngày mai',
              description:
                  'Nhiệt độ: ${_dailyForecast[1]['temperature'].toStringAsFixed(1)}°C, Tình trạng: ${_dailyForecast[1]['condition']}, Độ ẩm: ${_dailyForecast[1]['humidity']}%, Gió: ${_dailyForecast[1]['wind_speed']} m/s, UV: ${_dailyForecast[1]['uvi']}',
              severity: AlertSeverity.info,
              location: location,
              timestamp: now,
              expiryTime: now.add(const Duration(days: 2)),
            )
            : WeatherAlert(
              id: 'forecast_tomorrow',
              title: 'Dự báo ngày mai',
              description: 'Không có dữ liệu thời tiết',
              severity: AlertSeverity.info,
              location: location,
              timestamp: now,
              expiryTime: now.add(const Duration(days: 2)),
            );

    alerts.addAll([todayForecast, tomorrowForecast]);

    // Cảnh báo UV cao cho hôm nay
    if (_alertSubscriptions['Chỉ số UV cao'] == true &&
        _dailyForecast.isNotEmpty &&
        _dailyForecast[0]['uvi'] >= 6) {
      alerts.add(
        WeatherAlert(
          id: 'uv_alert_today_${now.millisecondsSinceEpoch}',
          title: 'Cảnh báo chỉ số UV cao hôm nay',
          description:
              'Chỉ số UV hôm nay: ${_dailyForecast[0]['uvi']}. Hạn chế ra ngoài hoặc sử dụng kem chống nắng.',
          severity: AlertSeverity.warning,
          location: location,
          timestamp: now,
          expiryTime: now.add(const Duration(days: 1)),
        ),
      );
    }

    // Cảnh báo UV cao cho ngày mai
    if (_alertSubscriptions['Chỉ số UV cao'] == true &&
        _dailyForecast.length > 1 &&
        _dailyForecast[1]['uvi'] >= 6) {
      alerts.add(
        WeatherAlert(
          id: 'uv_alert_tomorrow_${now.millisecondsSinceEpoch}',
          title: 'Cảnh báo chỉ số UV cao ngày mai',
          description:
              'Chỉ số UV ngày mai: ${_dailyForecast[1]['uvi']}. Hạn chế ra ngoài hoặc sử dụng kem chống nắng.',
          severity: AlertSeverity.warning,
          location: location,
          timestamp: now,
          expiryTime: now.add(const Duration(days: 2)),
        ),
      );
    }

    // Mưa lớn (dự báo trong 1 giờ tới)
    if (_alertSubscriptions['Mưa lớn'] == true && forecastRainVolume > 2.5) {
      alerts.add(
        WeatherAlert(
          id: 'rain_alert_${now.millisecondsSinceEpoch}',
          title: 'Cảnh báo mưa lớn',
          description:
              'Dự kiến có mưa lớn ($forecastRainVolume mm) trong 1 giờ tới, có thể gây ngập úng.',
          severity: AlertSeverity.moderate,
          location: location,
          timestamp: now,
          expiryTime: now.add(const Duration(hours: 1)),
        ),
      );
    }

    // Giông sét (dự báo trong 1 giờ tới)
    if (_alertSubscriptions['Giông sét'] == true &&
        forecastWeatherCondition.toLowerCase().contains('thunderstorm')) {
      alerts.add(
        WeatherAlert(
          id: 'thunderstorm_alert_${now.millisecondsSinceEpoch}',
          title: 'Cảnh báo giông sét',
          description:
              'Dự kiến có giông sét trong 1 giờ tới, hãy tìm nơi trú ẩn an toàn.',
          severity: AlertSeverity.severe,
          location: location,
          timestamp: now,
          expiryTime: now.add(const Duration(hours: 1)),
        ),
      );
    }

    // Chỉ số UV cao (hiện tại)
    if (_alertSubscriptions['Chỉ số UV cao'] == true && currentUvi >= 6) {
      alerts.add(
        WeatherAlert(
          id: 'uv_alert_${now.millisecondsSinceEpoch}',
          title: 'Cảnh báo chỉ số UV cao',
          description:
              'Chỉ số UV: $currentUvi. Hạn chế ra ngoài hoặc sử dụng kem chống nắng.',
          severity: AlertSeverity.warning,
          location: location,
          timestamp: now,
          expiryTime: now.add(const Duration(hours: 1)),
        ),
      );
    }

    // Chất lượng không khí (hiện tại)
    final aqi = WeatherService().parseAirQuality(airQualityData);
    if (_alertSubscriptions['Chất lượng không khí'] == true && aqi >= 4) {
      alerts.add(
        WeatherAlert(
          id: 'air_quality_alert_${now.millisecondsSinceEpoch}',
          title: 'Cảnh báo chất lượng không khí',
          description:
              'Chất lượng không khí kém (AQI: $aqi). Hạn chế ra ngoài hoặc đeo khẩu trang.',
          severity: AlertSeverity.moderate,
          location: location,
          timestamp: now,
          expiryTime: now.add(const Duration(hours: 1)),
        ),
      );
    }

    // Nhiệt độ cao (hiện tại)
    if (_alertSubscriptions['Nhiệt độ cao'] == true &&
        currentTemperature >= 35) {
      alerts.add(
        WeatherAlert(
          id: 'temperature_alert_${now.millisecondsSinceEpoch}',
          title: 'Cảnh báo nhiệt độ cao',
          description:
              'Nhiệt độ: $currentTemperature°C. Tránh hoạt động ngoài trời trong thời gian dài.',
          severity: AlertSeverity.warning,
          location: location,
          timestamp: now,
          expiryTime: now.add(const Duration(hours: 1)),
        ),
      );
    }

    // Lũ lụt (dựa trên lượng mưa hiện tại, giả định > 10mm)
    if (_alertSubscriptions['Lũ lụt'] == true && currentRainVolume > 10) {
      alerts.add(
        WeatherAlert(
          id: 'flood_alert_${now.millisecondsSinceEpoch}',
          title: 'Cảnh báo lũ lụt',
          description:
              'Lượng mưa lớn ($currentRainVolume mm) có thể gây lũ lụt. Hãy di chuyển đến nơi an toàn.',
          severity: AlertSeverity.severe,
          location: location,
          timestamp: now,
          expiryTime: now.add(const Duration(hours: 1)),
        ),
      );
    }

    // Độ ẩm cao (hiện tại)
    if (_alertSubscriptions['Độ ẩm cao'] == true && currentHumidity >= 80) {
      alerts.add(
        WeatherAlert(
          id: 'humidity_alert_${now.millisecondsSinceEpoch}',
          title: 'Cảnh báo độ ẩm cao',
          description:
              'Độ ẩm: $currentHumidity%. Có thể gây khó chịu, hãy giữ không gian thoáng mát.',
          severity: AlertSeverity.info,
          location: location,
          timestamp: now,
          expiryTime: now.add(const Duration(hours: 1)),
        ),
      );
    }

    return alerts;
  }

  // void _sendNotifications(List<WeatherAlert> alerts) {
  //   for (var alert in alerts) {
  //     NotificationService.showNotification(alert);
  //   }
  // }

  void _hideAlert(WeatherAlert alert) {
    setState(() {
      _activeAlerts.remove(alert);
      _alertHistory.add(alert);
    });
    _storageService.saveAlertHistory(_alertHistory);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã ẩn thông báo'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _deleteAlert(WeatherAlert alert) {
    setState(() {
      _alertHistory.remove(alert);
    });
    _storageService.saveAlertHistory(_alertHistory);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã xóa thông báo'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LocationProvider>(
      builder: (context, themeProvider, locationProvider, child) {
        final themeData = themeProvider.themeData;

        return Container(
          decoration: BoxDecoration(
            gradient: themeData['generalBackgroundColor'],
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body:
                _isLoadingWeather
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: themeData['cardLocationColor'],
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap:
                                      () => setState(() => _showActive = true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          _showActive
                                              ? themeData['primaryButtonColor']
                                              : Colors.transparent,
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Text(
                                      'Đang hoạt động',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color:
                                            _showActive
                                                ? Colors.white
                                                : themeData['mainText'],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap:
                                      () => setState(() => _showActive = false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          !_showActive
                                              ? themeData['primaryButtonColor']
                                              : Colors.transparent,
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Text(
                                      'Lịch sử',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color:
                                            !_showActive
                                                ? Colors.white
                                                : themeData['mainText'],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child:
                              _showActive
                                  ? _buildAlertsList(_activeAlerts, themeData)
                                  : _buildAlertsList(_alertHistory, themeData),
                        ),
                      ],
                    ),
            floatingActionButton: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  onPressed: () => _showSubscriptionDialog(context, themeData),
                  backgroundColor: themeData['primaryButtonColor'],
                  child: const Icon(Icons.add_alert),
                  tooltip: 'Quản lý đăng ký thông báo',
                ),
                const SizedBox(width: 16),
                // FloatingActionButton(
                //   onPressed: () => _sendNotifications(_activeAlerts),
                //   backgroundColor: themeData['primaryButtonColor'],
                //   child: const Icon(Icons.notifications),
                //   tooltip: 'Gửi thông báo',
                // ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlertsList(
    List<WeatherAlert> alerts,
    Map<String, dynamic> themeData,
  ) {
    if (alerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 64,
              color: themeData['mainText']?.withOpacity(0.5) ?? Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Không có thông báo nào',
              style: TextStyle(color: themeData['mainText'], fontSize: 18),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final alert = alerts[index];
        return _buildAlertCard(alert, themeData);
      },
    );
  }

  Widget _buildAlertCard(WeatherAlert alert, Map<String, dynamic> themeData) {
    Color severityColor;
    IconData severityIcon;

    switch (alert.severity) {
      case AlertSeverity.severe:
        severityColor = Colors.red;
        severityIcon = Icons.warning_amber_rounded;
        break;
      case AlertSeverity.moderate:
        severityColor = Colors.orange;
        severityIcon = Icons.error_outline;
        break;
      case AlertSeverity.warning:
        severityColor = Colors.amber;
        severityIcon = Icons.info_outline;
        break;
      default:
        severityColor = Colors.blue;
        severityIcon = Icons.info_outline;
    }

    final formatter = CustomTimeFormatter();
    final formattedTime = formatter.format(alert.timestamp);
    final formattedExpiry = formatter.format(alert.expiryTime);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: themeData['cardLocationColor'],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(severityIcon, color: severityColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        style: TextStyle(
                          color: themeData['mainText'],
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: themeData['auxiliaryText'],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            alert.location,
                            style: TextStyle(
                              color: themeData['auxiliaryText'],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              alert.description,
              style: TextStyle(color: themeData['mainText'], fontSize: 15),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Phát hành: $formattedTime',
                  style: TextStyle(
                    color: themeData['auxiliaryText'],
                    fontSize: 12,
                  ),
                ),
                if (alert.expiryTime.isAfter(DateTime.now()))
                  Text(
                    'Hết hạn: $formattedExpiry',
                    style: TextStyle(
                      color: themeData['auxiliaryText'],
                      fontSize: 12,
                    ),
                  )
                else
                  Text(
                    'Đã hết hạn',
                    style: TextStyle(
                      color: themeData['auxiliaryText'],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            if (_showActive)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      _showAlertDetailDialog(context, alert, themeData);
                    },
                    icon: Icon(
                      Icons.arrow_forward,
                      color: themeData['primaryButtonColor'],
                      size: 18,
                    ),
                    label: Text(
                      'Chi tiết',
                      style: TextStyle(
                        color: themeData['primaryButtonColor'],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      _hideAlert(alert);
                    },
                    icon: Icon(
                      Icons.visibility_off,
                      color: themeData['primaryButtonColor'],
                      size: 18,
                    ),
                    label: Text(
                      'Ẩn',
                      style: TextStyle(
                        color: themeData['primaryButtonColor'],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            if (!_showActive)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    _deleteAlert(alert);
                  },
                  icon: Icon(
                    Icons.delete,
                    color: themeData['primaryButtonColor'],
                    size: 18,
                  ),
                  label: Text(
                    'Xóa',
                    style: TextStyle(
                      color: themeData['primaryButtonColor'],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAlertDetailDialog(
    BuildContext context,
    WeatherAlert alert,
    Map<String, dynamic> themeData,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: themeData['cardLocationColor'],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Thông tin chi tiết',
                    style: TextStyle(
                      color: themeData['mainText'],
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: themeData['mainText']),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  children: [
                    _buildDetailItem('Loại cảnh báo', alert.title, themeData),
                    _buildDetailItem('Khu vực', alert.location, themeData),
                    _buildDetailItem(
                      'Mức độ',
                      _getSeverityString(alert.severity),
                      themeData,
                    ),
                    _buildDetailItem('Nội dung', alert.description, themeData),
                    _buildDetailItem(
                      'Thời gian phát hành',
                      _formatFullDateTime(alert.timestamp),
                      themeData,
                    ),
                    _buildDetailItem(
                      'Thời gian hết hạn',
                      _formatFullDateTime(alert.expiryTime),
                      themeData,
                    ),
                    const SizedBox(height: 20),
                    _buildRecommendationsSection(alert, themeData),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _hideAlert(alert);
                },
                icon: const Icon(Icons.visibility_off),
                label: const Text('Ẩn cảnh báo này'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeData['primaryButtonColor'],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(
    String label,
    String value,
    Map<String, dynamic> themeData,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: themeData['auxiliaryText'],
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(color: themeData['mainText'], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection(
    WeatherAlert alert,
    Map<String, dynamic> themeData,
  ) {
    List<String> recommendations = [];

    if (alert.title.toLowerCase().contains('mưa') ||
        alert.title.toLowerCase().contains('lũ lụt')) {
      recommendations = [
        'Mang theo áo mưa hoặc ô khi ra ngoài',
        'Tránh các khu vực thấp trũng dễ ngập lụt',
        'Theo dõi thông tin giao thông để tránh tắc đường',
        'Chuẩn bị các vật dụng chống ngập cho nhà ở nếu cần thiết',
      ];
    } else if (alert.title.toLowerCase().contains('giông sét')) {
      recommendations = [
        'Tránh đứng ở nơi trống trải hoặc gần cây cao',
        'Không sử dụng thiết bị điện tử ngoài trời',
        'Tìm nơi trú ẩn an toàn',
        'Theo dõi thông tin thời tiết liên tục',
      ];
    } else if (alert.title.toLowerCase().contains('uv')) {
      recommendations = [
        'Sử dụng kem chống nắng với SPF cao',
        'Mặc quần áo dài tay và đội mũ',
        'Hạn chế ra ngoài từ 10h sáng đến 2h chiều',
        'Đeo kính râm để bảo vệ mắt',
      ];
    } else if (alert.title.toLowerCase().contains('chất lượng không khí')) {
      recommendations = [
        'Hạn chế ra ngoài nếu không cần thiết',
        'Đeo khẩu trang chống bụi mịn (N95 nếu có)',
        'Giữ cửa sổ đóng và sử dụng máy lọc không khí',
        'Tránh các hoạt động thể thao ngoài trời',
      ];
    } else if (alert.title.toLowerCase().contains('nhiệt độ cao')) {
      recommendations = [
        'Uống đủ nước để tránh mất nước',
        'Tránh hoạt động ngoài trời trong thời gian nắng nóng',
        'Mặc quần áo thoáng mát, sáng màu',
        'Theo dõi các dấu hiệu kiệt sức do nhiệt',
      ];
    } else if (alert.title.toLowerCase().contains('độ ẩm cao')) {
      recommendations = [
        'Giữ không gian sống thoáng mát, khô ráo',
        'Sử dụng máy hút ẩm nếu cần',
        'Tránh mặc quần áo ẩm ướt',
        'Theo dõi sức khỏe nếu cảm thấy khó chịu',
      ];
    } else {
      recommendations = [
        'Theo dõi cập nhật thông tin thời tiết',
        'Chuẩn bị sẵn sàng các vật dụng cần thiết',
        'Lên kế hoạch di chuyển phù hợp',
        'Liên hệ cơ quan chức năng khi cần hỗ trợ',
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Khuyến nghị',
          style: TextStyle(
            color: themeData['mainText'],
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...recommendations.map(
          (rec) => _buildRecommendationItem(rec, themeData),
        ),
      ],
    );
  }

  Widget _buildRecommendationItem(String text, Map<String, dynamic> themeData) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            color: themeData['primaryButtonColor'],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: themeData['mainText'], fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  void _showSubscriptionDialog(
    BuildContext context,
    Map<String, dynamic> themeData,
  ) {
    final List<Map<String, dynamic>> alertTypes = [
      {
        'name': 'Mưa lớn',
        'icon': Icons.water_drop,
        'enabled': _alertSubscriptions['Mưa lớn']!,
      },
      {
        'name': 'Giông sét',
        'icon': Icons.flash_on,
        'enabled': _alertSubscriptions['Giông sét']!,
      },
      {
        'name': 'Chỉ số UV cao',
        'icon': Icons.wb_sunny,
        'enabled': _alertSubscriptions['Chỉ số UV cao']!,
      },
      {
        'name': 'Chất lượng không khí',
        'icon': Icons.cloud,
        'enabled': _alertSubscriptions['Chất lượng không khí']!,
      },
      {
        'name': 'Nhiệt độ cao',
        'icon': Icons.thermostat,
        'enabled': _alertSubscriptions['Nhiệt độ cao']!,
      },
      {
        'name': 'Lũ lụt',
        'icon': Icons.flood,
        'enabled': _alertSubscriptions['Lũ lụt']!,
      },
      {
        'name': 'Độ ẩm cao',
        'icon': Icons.opacity,
        'enabled': _alertSubscriptions['Độ ẩm cao']!,
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.5,
              decoration: BoxDecoration(
                color: themeData['cardLocationColor'],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Quản lý đăng ký thông báo',
                        style: TextStyle(
                          color: themeData['mainText'],
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: themeData['mainText']),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chọn loại thông báo bạn muốn nhận',
                    style: TextStyle(
                      color: themeData['auxiliaryText'],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: alertTypes.length,
                      itemBuilder: (context, index) {
                        final alert = alertTypes[index];
                        return SwitchListTile(
                          title: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: themeData['primaryButtonColor']
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  alert['icon'],
                                  color: themeData['primaryButtonColor'],
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                alert['name'],
                                style: TextStyle(
                                  color: themeData['mainText'],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          value: alert['enabled'],
                          activeColor: themeData['primaryButtonColor'],
                          onChanged: (bool value) {
                            setState(() {
                              alert['enabled'] = value;
                              _alertSubscriptions[alert['name']] = value;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _saveSubscriptions();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã lưu cài đặt thông báo'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeData['primaryButtonColor'],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text(
                      'Lưu cài đặt',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getSeverityString(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.severe:
        return 'Nghiêm trọng';
      case AlertSeverity.moderate:
        return 'Trung bình';
      case AlertSeverity.warning:
        return 'Cảnh báo';
      default:
        return 'Thông tin';
    }
  }

  String _formatFullDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

enum AlertSeverity { severe, moderate, warning, info }

class WeatherAlert {
  final String id;
  final String title;
  final String description;
  final AlertSeverity severity;
  final String location;
  final DateTime timestamp;
  final DateTime expiryTime;

  WeatherAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.location,
    required this.timestamp,
    required this.expiryTime,
  });
}

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:weather_app/providers/theme_provider.dart';
// import 'package:weather_app/providers/location_provider.dart';
// import 'package:weather_app/services/weather_service.dart';
// import 'package:weather_app/utils/time_formatter.dart';
// // import 'package:weather_app/services/notification_service.dart';
// import 'package:weather_app/services/alert_storage_service.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class AlertsScreen extends StatefulWidget {
//   const AlertsScreen({super.key});

//   @override
//   State<AlertsScreen> createState() => _AlertsScreenState();
// }

// class _AlertsScreenState extends State<AlertsScreen> {
//   bool _showActive = true;
//   List<Map<String, dynamic>> _forecastData = [];
//   bool _isLoadingWeather = true;
//   List<WeatherAlert> _activeAlerts = [];
//   List<WeatherAlert> _alertHistory = [];
//   final AlertStorageService _storageService = AlertStorageService();
//   Map<String, bool> _alertSubscriptions = {};

//   @override
//   void initState() {
//     super.initState();
//     _loadAlertHistory();
//     _loadSubscriptions();
//     _fetchWeatherData();
//   }

//   Future<void> _loadAlertHistory() async {
//     final history = await _storageService.loadAlertHistory();
//     setState(() {
//       _alertHistory = history;
//     });
//   }

//   Future<void> _loadSubscriptions() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       _alertSubscriptions = {
//         'Mưa lớn': prefs.getBool('Mưa lớn') ?? true,
//         'Giông sét': prefs.getBool('Giông sét') ?? true,
//         'Chỉ số UV cao': prefs.getBool('Chỉ số UV cao') ?? true,
//         'Chất lượng không khí': prefs.getBool('Chất lượng không khí') ?? true,
//         'Nhiệt độ cao': prefs.getBool('Nhiệt độ cao') ?? true,
//         'Lũ lụt': prefs.getBool('Lũ lụt') ?? true,
//         'Độ ẩm cao': prefs.getBool('Độ ẩm cao') ?? true,
//       };
//     });
//   }

//   Future<void> _saveSubscriptions() async {
//     final prefs = await SharedPreferences.getInstance();
//     _alertSubscriptions.forEach((key, value) {
//       prefs.setBool(key, value);
//     });
//   }

//   Future<void> _fetchWeatherData() async {
//     final locationProvider = Provider.of<LocationProvider>(
//       context,
//       listen: false,
//     );
//     await locationProvider.fetchCurrentLocation();
//     if (locationProvider.currentPosition != null) {
//       try {
//         final weatherService = WeatherService();
//         final weatherData = await weatherService.fetchWeatherData(
//           locationProvider.currentPosition!,
//         );
//         final airQualityData = await weatherService.fetchAirQuality(
//           locationProvider.currentPosition!,
//         );

//         setState(() {
//           _forecastData = weatherService.parseDailyForecast(weatherData);
//           _activeAlerts = _getActiveAlerts(
//             locationProvider.currentLocationName,
//             weatherData,
//             airQualityData,
//           );
//           _isLoadingWeather = false;
//         });

//         // Kiểm tra và chuyển thông báo hết hạn vào lịch sử
//         _updateAlerts();
//       } catch (e) {
//         setState(() {
//           _isLoadingWeather = false;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Lỗi khi lấy dữ liệu thời tiết: $e')),
//         );
//       }
//     }
//   }

//   void _updateAlerts() {
//     final now = DateTime.now();
//     final expiredAlerts =
//         _activeAlerts.where((alert) {
//           return now.difference(alert.timestamp).inHours >= 1;
//         }).toList();

//     setState(() {
//       _activeAlerts.removeWhere((alert) => expiredAlerts.contains(alert));
//       _alertHistory.addAll(expiredAlerts);
//     });

//     _storageService.saveAlertHistory(_alertHistory);
//   }

//   List<WeatherAlert> _getActiveAlerts(
//     String location,
//     Map<String, dynamic> weatherData,
//     Map<String, dynamic> airQualityData,
//   ) {
//     final List<WeatherAlert> alerts = [];
//     final now = DateTime.now();

//     // Dự báo hôm nay và ngày mai
//     final todayForecast =
//         _forecastData.isNotEmpty
//             ? WeatherAlert(
//               id: 'forecast_today',
//               title: 'Dự báo hôm nay',
//               description:
//                   'Nhiệt độ: ${_forecastData[0]['temperature']}°C, Tình trạng: ${_forecastData[0]['condition']}, Độ ẩm: ${_forecastData[0]['humidity']}%, Gió: ${_forecastData[0]['wind']} m/s',
//               severity: AlertSeverity.info,
//               location: location,
//               timestamp: now,
//               expiryTime: now.add(const Duration(days: 1)),
//             )
//             : WeatherAlert(
//               id: 'forecast_today',
//               title: 'Dự báo hôm nay',
//               description: 'Không có dữ liệu thời tiết',
//               severity: AlertSeverity.info,
//               location: location,
//               timestamp: now,
//               expiryTime: now.add(const Duration(days: 1)),
//             );

//     final tomorrowForecast =
//         _forecastData.length > 1
//             ? WeatherAlert(
//               id: 'forecast_tomorrow',
//               title: 'Dự báo ngày mai',
//               description:
//                   'Nhiệt độ: ${_forecastData[1]['temperature']}°C, Tình trạng: ${_forecastData[1]['condition']}, Độ ẩm: ${_forecastData[1]['humidity']}%, Gió: ${_forecastData[1]['wind']} m/s',
//               severity: AlertSeverity.info,
//               location: location,
//               timestamp: now,
//               expiryTime: now.add(const Duration(days: 2)),
//             )
//             : WeatherAlert(
//               id: 'forecast_tomorrow',
//               title: 'Dự báo ngày mai',
//               description: 'Không có dữ liệu thời tiết',
//               severity: AlertSeverity.info,
//               location: location,
//               timestamp: now,
//               expiryTime: now.add(const Duration(days: 2)),
//             );

//     alerts.addAll([todayForecast, tomorrowForecast]);

//     // Dữ liệu trong 1 giờ tới
//     final hourlyData = WeatherService().parseHourlyForecast(weatherData);
//     final rainVolume = hourlyData['rain'] as double;
//     final weatherCondition = hourlyData['weather'] as String;
//     final temperature = hourlyData['temperature'] as double;
//     final humidity = hourlyData['humidity'] as double;
//     final uvi = hourlyData['uvi'] as double;

//     // Mưa lớn (rain > 2.5mm trong 1 giờ tới)
//     if (_alertSubscriptions['Mưa lớn'] == true && rainVolume > 2.5) {
//       alerts.add(
//         WeatherAlert(
//           id: 'rain_alert_${now.millisecondsSinceEpoch}',
//           title: 'Cảnh báo mưa lớn',
//           description:
//               'Dự kiến có mưa lớn ($rainVolume mm) trong 1 giờ tới, có thể gây ngập úng.',
//           severity: AlertSeverity.moderate,
//           location: location,
//           timestamp: now,
//           expiryTime: now.add(const Duration(hours: 1)),
//         ),
//       );
//     }

//     // Giông sét
//     if (_alertSubscriptions['Giông sét'] == true &&
//         weatherCondition.toLowerCase().contains('thunderstorm')) {
//       alerts.add(
//         WeatherAlert(
//           id: 'thunderstorm_alert_${now.millisecondsSinceEpoch}',
//           title: 'Cảnh báo giông sét',
//           description:
//               'Dự kiến có giông sét trong 1 giờ tới, hãy tìm nơi trú ẩn an toàn.',
//           severity: AlertSeverity.severe,
//           location: location,
//           timestamp: now,
//           expiryTime: now.add(const Duration(hours: 1)),
//         ),
//       );
//     }

//     // Chỉ số UV cao (UVI >= 6)
//     if (_alertSubscriptions['Chỉ số UV cao'] == true && uvi >= 6) {
//       alerts.add(
//         WeatherAlert(
//           id: 'uv_alert_${now.millisecondsSinceEpoch}',
//           title: 'Cảnh báo chỉ số UV cao',
//           description:
//               'Chỉ số UV: $uvi. Hạn chế ra ngoài hoặc sử dụng kem chống nắng.',
//           severity: AlertSeverity.warning,
//           location: location,
//           timestamp: now,
//           expiryTime: now.add(const Duration(hours: 1)),
//         ),
//       );
//     }

//     // Chất lượng không khí (AQI >= 4)
//     final aqi = WeatherService().parseAirQuality(airQualityData);
//     if (_alertSubscriptions['Chất lượng không khí'] == true && aqi >= 4) {
//       alerts.add(
//         WeatherAlert(
//           id: 'air_quality_alert_${now.millisecondsSinceEpoch}',
//           title: 'Cảnh báo chất lượng không khí',
//           description:
//               'Chất lượng không khí kém (AQI: $aqi). Hạn chế ra ngoài hoặc đeo khẩu trang.',
//           severity: AlertSeverity.moderate,
//           location: location,
//           timestamp: now,
//           expiryTime: now.add(const Duration(hours: 1)),
//         ),
//       );
//     }

//     // Nhiệt độ cao (nhiệt độ >= 35°C)
//     if (_alertSubscriptions['Nhiệt độ cao'] == true && temperature >= 35) {
//       alerts.add(
//         WeatherAlert(
//           id: 'temperature_alert_${now.millisecondsSinceEpoch}',
//           title: 'Cảnh báo nhiệt độ cao',
//           description:
//               'Nhiệt độ: $temperature°C. Tránh hoạt động ngoài trời trong thời gian dài.',
//           severity: AlertSeverity.warning,
//           location: location,
//           timestamp: now,
//           expiryTime: now.add(const Duration(hours: 1)),
//         ),
//       );
//     }

//     // Lũ lụt (dựa trên lượng mưa lớn kéo dài, giả sử > 10mm trong 1 giờ)
//     if (_alertSubscriptions['Lũ lụt'] == true && rainVolume > 10) {
//       alerts.add(
//         WeatherAlert(
//           id: 'flood_alert_${now.millisecondsSinceEpoch}',
//           title: 'Cảnh báo lũ lụt',
//           description:
//               'Lượng mưa lớn ($rainVolume mm) có thể gây lũ lụt. Hãy di chuyển đến nơi an toàn.',
//           severity: AlertSeverity.severe,
//           location: location,
//           timestamp: now,
//           expiryTime: now.add(const Duration(hours: 1)),
//         ),
//       );
//     }

//     // Độ ẩm cao (độ ẩm >= 80%)
//     if (_alertSubscriptions['Độ ẩm cao'] == true && humidity >= 80) {
//       alerts.add(
//         WeatherAlert(
//           id: 'humidity_alert_${now.millisecondsSinceEpoch}',
//           title: 'Cảnh báo độ ẩm cao',
//           description:
//               'Độ ẩm: $humidity%. Có thể gây khó chịu, hãy giữ không gian thoáng mát.',
//           severity: AlertSeverity.info,
//           location: location,
//           timestamp: now,
//           expiryTime: now.add(const Duration(hours: 1)),
//         ),
//       );
//     }

//     return alerts;
//   }

//   // void _sendNotifications(List<WeatherAlert> alerts) {
//   //   for (var alert in alerts) {
//   //     NotificationService.showNotification(alert);
//   //   }
//   // }

//   void _hideAlert(WeatherAlert alert) {
//     setState(() {
//       _activeAlerts.remove(alert);
//       _alertHistory.add(alert);
//     });
//     _storageService.saveAlertHistory(_alertHistory);
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('Đã ẩn thông báo'),
//         duration: Duration(seconds: 2),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer2<ThemeProvider, LocationProvider>(
//       builder: (context, themeProvider, locationProvider, child) {
//         final themeData = themeProvider.themeData;

//         return Container(
//           decoration: BoxDecoration(
//             gradient: themeData['generalBackgroundColor'],
//           ),
//           child: Scaffold(
//             backgroundColor: Colors.transparent,
//             body:
//                 _isLoadingWeather
//                     ? const Center(child: CircularProgressIndicator())
//                     : Column(
//                       children: [
//                         Container(
//                           margin: const EdgeInsets.all(16),
//                           decoration: BoxDecoration(
//                             color: themeData['cardLocationColor'],
//                             borderRadius: BorderRadius.circular(30),
//                           ),
//                           child: Row(
//                             children: [
//                               Expanded(
//                                 child: GestureDetector(
//                                   onTap:
//                                       () => setState(() => _showActive = true),
//                                   child: Container(
//                                     padding: const EdgeInsets.symmetric(
//                                       vertical: 12,
//                                     ),
//                                     decoration: BoxDecoration(
//                                       color:
//                                           _showActive
//                                               ? themeData['primaryButtonColor']
//                                               : Colors.transparent,
//                                       borderRadius: BorderRadius.circular(30),
//                                     ),
//                                     child: Text(
//                                       'Đang hoạt động',
//                                       textAlign: TextAlign.center,
//                                       style: TextStyle(
//                                         color:
//                                             _showActive
//                                                 ? Colors.white
//                                                 : themeData['mainText'],
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               Expanded(
//                                 child: GestureDetector(
//                                   onTap:
//                                       () => setState(() => _showActive = false),
//                                   child: Container(
//                                     padding: const EdgeInsets.symmetric(
//                                       vertical: 12,
//                                     ),
//                                     decoration: BoxDecoration(
//                                       color:
//                                           !_showActive
//                                               ? themeData['primaryButtonColor']
//                                               : Colors.transparent,
//                                       borderRadius: BorderRadius.circular(30),
//                                     ),
//                                     child: Text(
//                                       'Lịch sử',
//                                       textAlign: TextAlign.center,
//                                       style: TextStyle(
//                                         color:
//                                             !_showActive
//                                                 ? Colors.white
//                                                 : themeData['mainText'],
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         Expanded(
//                           child:
//                               _showActive
//                                   ? _buildAlertsList(_activeAlerts, themeData)
//                                   : _buildAlertsList(_alertHistory, themeData),
//                         ),
//                       ],
//                     ),
//             floatingActionButton: Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 FloatingActionButton(
//                   onPressed: () => _showSubscriptionDialog(context, themeData),
//                   backgroundColor: themeData['primaryButtonColor'],
//                   child: const Icon(Icons.add_alert),
//                   tooltip: 'Quản lý đăng ký thông báo',
//                 ),
//                 const SizedBox(width: 16),
//                 // FloatingActionButton(
//                 //   onPressed: () => _sendNotifications(_activeAlerts),
//                 //   backgroundColor: themeData['primaryButtonColor'],
//                 //   child: const Icon(Icons.notifications),
//                 //   tooltip: 'Gửi thông báo',
//                 // ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildAlertsList(
//     List<WeatherAlert> alerts,
//     Map<String, dynamic> themeData,
//   ) {
//     if (alerts.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.notifications_off_outlined,
//               size: 64,
//               color: themeData['mainText']?.withOpacity(0.5) ?? Colors.grey,
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'Không có thông báo nào',
//               style: TextStyle(color: themeData['mainText'], fontSize: 18),
//             ),
//           ],
//         ),
//       );
//     }

//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: alerts.length,
//       itemBuilder: (context, index) {
//         final alert = alerts[index];
//         return _buildAlertCard(alert, themeData);
//       },
//     );
//   }

//   Widget _buildAlertCard(WeatherAlert alert, Map<String, dynamic> themeData) {
//     Color severityColor;
//     IconData severityIcon;

//     switch (alert.severity) {
//       case AlertSeverity.severe:
//         severityColor = Colors.red;
//         severityIcon = Icons.warning_amber_rounded;
//         break;
//       case AlertSeverity.moderate:
//         severityColor = Colors.orange;
//         severityIcon = Icons.error_outline;
//         break;
//       case AlertSeverity.warning:
//         severityColor = Colors.amber;
//         severityIcon = Icons.info_outline;
//         break;
//       default:
//         severityColor = Colors.blue;
//         severityIcon = Icons.info_outline;
//     }

//     final formatter = CustomTimeFormatter();
//     final formattedTime = formatter.format(alert.timestamp);
//     final formattedExpiry = formatter.format(alert.expiryTime);

//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       color: themeData['cardLocationColor'],
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: severityColor.withOpacity(0.2),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Icon(severityIcon, color: severityColor, size: 24),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         alert.title,
//                         style: TextStyle(
//                           color: themeData['mainText'],
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       Row(
//                         children: [
//                           Icon(
//                             Icons.location_on_outlined,
//                             size: 14,
//                             color: themeData['auxiliaryText'],
//                           ),
//                           const SizedBox(width: 4),
//                           Text(
//                             alert.location,
//                             style: TextStyle(
//                               color: themeData['auxiliaryText'],
//                               fontSize: 14,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Text(
//               alert.description,
//               style: TextStyle(color: themeData['mainText'], fontSize: 15),
//             ),
//             const SizedBox(height: 8),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   'Phát hành: $formattedTime',
//                   style: TextStyle(
//                     color: themeData['auxiliaryText'],
//                     fontSize: 12,
//                   ),
//                 ),
//                 if (alert.expiryTime.isAfter(DateTime.now()))
//                   Text(
//                     'Hết hạn: $formattedExpiry',
//                     style: TextStyle(
//                       color: themeData['auxiliaryText'],
//                       fontSize: 12,
//                     ),
//                   )
//                 else
//                   Text(
//                     'Đã hết hạn',
//                     style: TextStyle(
//                       color: themeData['auxiliaryText'],
//                       fontSize: 12,
//                     ),
//                   ),
//               ],
//             ),
//             if (_showActive)
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   TextButton.icon(
//                     onPressed: () {
//                       _showAlertDetailDialog(context, alert, themeData);
//                     },
//                     icon: Icon(
//                       Icons.arrow_forward,
//                       color: themeData['primaryButtonColor'],
//                       size: 18,
//                     ),
//                     label: Text(
//                       'Chi tiết',
//                       style: TextStyle(
//                         color: themeData['primaryButtonColor'],
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                   TextButton.icon(
//                     onPressed: () {
//                       _hideAlert(alert);
//                     },
//                     icon: Icon(
//                       Icons.visibility_off,
//                       color: themeData['primaryButtonColor'],
//                       size: 18,
//                     ),
//                     label: Text(
//                       'Ẩn',
//                       style: TextStyle(
//                         color: themeData['primaryButtonColor'],
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showAlertDetailDialog(
//     BuildContext context,
//     WeatherAlert alert,
//     Map<String, dynamic> themeData,
//   ) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       isScrollControlled: true,
//       builder: (context) {
//         return Container(
//           height: MediaQuery.of(context).size.height * 0.7,
//           decoration: BoxDecoration(
//             color: themeData['cardLocationColor'],
//             borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
//           ),
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     'Thông tin chi tiết',
//                     style: TextStyle(
//                       color: themeData['mainText'],
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   IconButton(
//                     icon: Icon(Icons.close, color: themeData['mainText']),
//                     onPressed: () => Navigator.pop(context),
//                   ),
//                 ],
//               ),
//               const Divider(),
//               Expanded(
//                 child: ListView(
//                   children: [
//                     _buildDetailItem('Loại cảnh báo', alert.title, themeData),
//                     _buildDetailItem('Khu vực', alert.location, themeData),
//                     _buildDetailItem(
//                       'Mức độ',
//                       _getSeverityString(alert.severity),
//                       themeData,
//                     ),
//                     _buildDetailItem('Nội dung', alert.description, themeData),
//                     _buildDetailItem(
//                       'Thời gian phát hành',
//                       _formatFullDateTime(alert.timestamp),
//                       themeData,
//                     ),
//                     _buildDetailItem(
//                       'Thời gian hết hạn',
//                       _formatFullDateTime(alert.expiryTime),
//                       themeData,
//                     ),
//                     const SizedBox(height: 20),
//                     _buildRecommendationsSection(alert, themeData),
//                   ],
//                 ),
//               ),
//               ElevatedButton.icon(
//                 onPressed: () {
//                   Navigator.pop(context);
//                   _hideAlert(alert);
//                 },
//                 icon: const Icon(Icons.visibility_off),
//                 label: const Text('Ẩn cảnh báo này'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: themeData['primaryButtonColor'],
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(vertical: 12),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(30),
//                   ),
//                   minimumSize: const Size(double.infinity, 50),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildDetailItem(
//     String label,
//     String value,
//     Map<String, dynamic> themeData,
//   ) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             label,
//             style: TextStyle(
//               color: themeData['auxiliaryText'],
//               fontSize: 14,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             value,
//             style: TextStyle(color: themeData['mainText'], fontSize: 16),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildRecommendationsSection(
//     WeatherAlert alert,
//     Map<String, dynamic> themeData,
//   ) {
//     List<String> recommendations = [];

//     if (alert.title.toLowerCase().contains('mưa') ||
//         alert.title.toLowerCase().contains('lũ lụt')) {
//       recommendations = [
//         'Mang theo áo mưa hoặc ô khi ra ngoài',
//         'Tránh các khu vực thấp trũng dễ ngập lụt',
//         'Theo dõi thông tin giao thông để tránh tắc đường',
//         'Chuẩn bị các vật dụng chống ngập cho nhà ở nếu cần thiết',
//       ];
//     } else if (alert.title.toLowerCase().contains('giông sét')) {
//       recommendations = [
//         'Tránh đứng ở nơi trống trải hoặc gần cây cao',
//         'Không sử dụng thiết bị điện tử ngoài trời',
//         'Tìm nơi trú ẩn an toàn',
//         'Theo dõi thông tin thời tiết liên tục',
//       ];
//     } else if (alert.title.toLowerCase().contains('uv')) {
//       recommendations = [
//         'Sử dụng kem chống nắng với SPF cao',
//         'Mặc quần áo dài tay và đội mũ',
//         'Hạn chế ra ngoài từ 10h sáng đến 2h chiều',
//         'Đeo kính râm để bảo vệ mắt',
//       ];
//     } else if (alert.title.toLowerCase().contains('chất lượng không khí')) {
//       recommendations = [
//         'Hạn chế ra ngoài nếu không cần thiết',
//         'Đeo khẩu trang chống bụi mịn (N95 nếu có)',
//         'Giữ cửa sổ đóng và sử dụng máy lọc không khí',
//         'Tránh các hoạt động thể thao ngoài trời',
//       ];
//     } else if (alert.title.toLowerCase().contains('nhiệt độ cao')) {
//       recommendations = [
//         'Uống đủ nước để tránh mất nước',
//         'Tránh hoạt động ngoài trời trong thời gian nắng nóng',
//         'Mặc quần áo thoáng mát, sáng màu',
//         'Theo dõi các dấu hiệu kiệt sức do nhiệt',
//       ];
//     } else if (alert.title.toLowerCase().contains('độ ẩm cao')) {
//       recommendations = [
//         'Giữ không gian sống thoáng mát, khô ráo',
//         'Sử dụng máy hút ẩm nếu cần',
//         'Tránh mặc quần áo ẩm ướt',
//         'Theo dõi sức khỏe nếu cảm thấy khó chịu',
//       ];
//     } else {
//       recommendations = [
//         'Theo dõi cập nhật thông tin thời tiết',
//         'Chuẩn bị sẵn sàng các vật dụng cần thiết',
//         'Lên kế hoạch di chuyển phù hợp',
//         'Liên hệ cơ quan chức năng khi cần hỗ trợ',
//       ];
//     }

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Khuyến nghị',
//           style: TextStyle(
//             color: themeData['mainText'],
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 8),
//         ...recommendations.map(
//           (rec) => _buildRecommendationItem(rec, themeData),
//         ),
//       ],
//     );
//   }

//   Widget _buildRecommendationItem(String text, Map<String, dynamic> themeData) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(
//             Icons.check_circle_outline,
//             color: themeData['primaryButtonColor'],
//             size: 20,
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               text,
//               style: TextStyle(color: themeData['mainText'], fontSize: 15),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showSubscriptionDialog(
//     BuildContext context,
//     Map<String, dynamic> themeData,
//   ) {
//     final List<Map<String, dynamic>> alertTypes = [
//       {
//         'name': 'Mưa lớn',
//         'icon': Icons.water_drop,
//         'enabled': _alertSubscriptions['Mưa lớn']!,
//       },
//       {
//         'name': 'Giông sét',
//         'icon': Icons.flash_on,
//         'enabled': _alertSubscriptions['Giông sét']!,
//       },
//       {
//         'name': 'Chỉ số UV cao',
//         'icon': Icons.wb_sunny,
//         'enabled': _alertSubscriptions['Chỉ số UV cao']!,
//       },
//       {
//         'name': 'Chất lượng không khí',
//         'icon': Icons.cloud,
//         'enabled': _alertSubscriptions['Chất lượng không khí']!,
//       },
//       {
//         'name': 'Nhiệt độ cao',
//         'icon': Icons.thermostat,
//         'enabled': _alertSubscriptions['Nhiệt độ cao']!,
//       },
//       {
//         'name': 'Lũ lụt',
//         'icon': Icons.flood,
//         'enabled': _alertSubscriptions['Lũ lụt']!,
//       },
//       {
//         'name': 'Độ ẩm cao',
//         'icon': Icons.opacity,
//         'enabled': _alertSubscriptions['Độ ẩm cao']!,
//       },
//     ];

//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       isScrollControlled: true,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setState) {
//             return Container(
//               height: MediaQuery.of(context).size.height * 0.5,
//               decoration: BoxDecoration(
//                 color: themeData['cardLocationColor'],
//                 borderRadius: const BorderRadius.vertical(
//                   top: Radius.circular(20),
//                 ),
//               ),
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         'Quản lý đăng ký thông báo',
//                         style: TextStyle(
//                           color: themeData['mainText'],
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       IconButton(
//                         icon: Icon(Icons.close, color: themeData['mainText']),
//                         onPressed: () => Navigator.pop(context),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     'Chọn loại thông báo bạn muốn nhận',
//                     style: TextStyle(
//                       color: themeData['auxiliaryText'],
//                       fontSize: 14,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   Expanded(
//                     child: ListView.builder(
//                       itemCount: alertTypes.length,
//                       itemBuilder: (context, index) {
//                         final alert = alertTypes[index];
//                         return SwitchListTile(
//                           title: Row(
//                             children: [
//                               Container(
//                                 padding: const EdgeInsets.all(8),
//                                 decoration: BoxDecoration(
//                                   color: themeData['primaryButtonColor']
//                                       .withOpacity(0.2),
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                                 child: Icon(
//                                   alert['icon'],
//                                   color: themeData['primaryButtonColor'],
//                                   size: 24,
//                                 ),
//                               ),
//                               const SizedBox(width: 16),
//                               Text(
//                                 alert['name'],
//                                 style: TextStyle(
//                                   color: themeData['mainText'],
//                                   fontSize: 16,
//                                 ),
//                               ),
//                             ],
//                           ),
//                           value: alert['enabled'],
//                           activeColor: themeData['primaryButtonColor'],
//                           onChanged: (bool value) {
//                             setState(() {
//                               alert['enabled'] = value;
//                               _alertSubscriptions[alert['name']] = value;
//                             });
//                           },
//                         );
//                       },
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   ElevatedButton(
//                     onPressed: () {
//                       _saveSubscriptions();
//                       Navigator.pop(context);
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text('Đã lưu cài đặt thông báo'),
//                           duration: Duration(seconds: 2),
//                         ),
//                       );
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: themeData['primaryButtonColor'],
//                       foregroundColor: Colors.white,
//                       padding: const EdgeInsets.symmetric(vertical: 12),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(30),
//                       ),
//                       minimumSize: const Size(double.infinity, 50),
//                     ),
//                     child: const Text(
//                       'Lưu cài đặt',
//                       style: TextStyle(fontSize: 16),
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   String _getSeverityString(AlertSeverity severity) {
//     switch (severity) {
//       case AlertSeverity.severe:
//         return 'Nghiêm trọng';
//       case AlertSeverity.moderate:
//         return 'Trung bình';
//       case AlertSeverity.warning:
//         return 'Cảnh báo';
//       default:
//         return 'Thông tin';
//     }
//   }

//   String _formatFullDateTime(DateTime dateTime) {
//     return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
//   }
// }

// enum AlertSeverity { severe, moderate, warning, info }

// class WeatherAlert {
//   final String id;
//   final String title;
//   final String description;
//   final AlertSeverity severity;
//   final String location;
//   final DateTime timestamp;
//   final DateTime expiryTime;

//   WeatherAlert({
//     required this.id,
//     required this.title,
//     required this.description,
//     required this.severity,
//     required this.location,
//     required this.timestamp,
//     required this.expiryTime,
//   });
// }

// // import 'package:flutter/material.dart';
// // import 'package:provider/provider.dart';
// // import 'package:weather_app/providers/theme_provider.dart';
// // // ignore: unnecessary_import
// // import 'dart:ui';

// // class AlertsScreen extends StatefulWidget {
// //   const AlertsScreen({super.key});

// //   @override
// //   State<AlertsScreen> createState() => _AlertsScreenState();
// // }

// // class _AlertsScreenState extends State<AlertsScreen> {
// //   bool _showActive = true; // Toggle between active and history

// //   // Sample data for weather alerts
// //   final List<WeatherAlert> _activeAlerts = [
// //     WeatherAlert(
// //       id: '1',
// //       title: 'Mưa lớn',
// //       description:
// //           'Mưa lớn kéo dài từ chiều tối nay đến sáng mai, có thể gây ngập úng tạm thời tại các khu vực trũng thấp.',
// //       severity: AlertSeverity.moderate,
// //       location: 'Tp. Hồ Chí Minh',
// //       timestamp: DateTime.now().subtract(const Duration(hours: 2)),
// //       expiryTime: DateTime.now().add(const Duration(hours: 10)),
// //     ),
// //     WeatherAlert(
// //       id: '2',
// //       title: 'Cảnh báo giông sét',
// //       description:
// //           'Giông sét có thể xảy ra vào buổi chiều, kèm theo mưa rào. Hạn chế ra ngoài trong thời gian này.',
// //       severity: AlertSeverity.severe,
// //       location: 'Tp. Hồ Chí Minh',
// //       timestamp: DateTime.now().subtract(const Duration(hours: 1)),
// //       expiryTime: DateTime.now().add(const Duration(hours: 5)),
// //     ),
// //     WeatherAlert(
// //       id: '3',
// //       title: 'Chỉ số UV cao',
// //       description:
// //           'Chỉ số UV đạt mức rất cao (9-10) vào giữa trưa. Nên sử dụng kem chống nắng và hạn chế tiếp xúc trực tiếp với ánh nắng.',
// //       severity: AlertSeverity.warning,
// //       location: 'Tp. Hồ Chí Minh',
// //       timestamp: DateTime.now().subtract(const Duration(hours: 3)),
// //       expiryTime: DateTime.now().add(const Duration(hours: 6)),
// //     ),
// //   ];

// //   final List<WeatherAlert> _alertHistory = [
// //     WeatherAlert(
// //       id: '4',
// //       title: 'Không khí ô nhiễm',
// //       description:
// //           'Chỉ số chất lượng không khí (AQI) ở mức kém. Người già và trẻ em nên hạn chế hoạt động ngoài trời.',
// //       severity: AlertSeverity.moderate,
// //       location: 'Tp. Hồ Chí Minh',
// //       timestamp: DateTime.now().subtract(const Duration(days: 2)),
// //       expiryTime: DateTime.now().subtract(const Duration(hours: 12)),
// //     ),
// //     WeatherAlert(
// //       id: '5',
// //       title: 'Nắng nóng',
// //       description:
// //           'Nhiệt độ cao kỷ lục, có thể lên tới 38-39 độ C. Uống nhiều nước và tránh hoạt động ngoài trời vào giữa trưa.',
// //       severity: AlertSeverity.severe,
// //       location: 'Tp. Hồ Chí Minh',
// //       timestamp: DateTime.now().subtract(const Duration(days: 5)),
// //       expiryTime: DateTime.now().subtract(const Duration(days: 4)),
// //     ),
// //   ];

// //   @override
// //   Widget build(BuildContext context) {
// //     return Consumer<ThemeProvider>(
// //       builder: (context, themeProvider, child) {
// //         final themeData = themeProvider.themeData;

// //         return Container(
// //           decoration: BoxDecoration(
// //             gradient: themeData['generalBackgroundColor'],
// //           ),
// //           child: Scaffold(
// //             backgroundColor: Colors.transparent,
// //             body: Column(
// //               children: [
// //                 // Tab selector
// //                 Container(
// //                   margin: const EdgeInsets.all(16),
// //                   decoration: BoxDecoration(
// //                     color: themeData['cardLocationColor'],
// //                     borderRadius: BorderRadius.circular(30),
// //                   ),
// //                   child: Row(
// //                     children: [
// //                       Expanded(
// //                         child: GestureDetector(
// //                           onTap: () => setState(() => _showActive = true),
// //                           child: Container(
// //                             padding: const EdgeInsets.symmetric(vertical: 12),
// //                             decoration: BoxDecoration(
// //                               color:
// //                                   _showActive
// //                                       ? themeData['primaryButtonColor']
// //                                       : Colors.transparent,
// //                               borderRadius: BorderRadius.circular(30),
// //                             ),
// //                             child: Text(
// //                               'Đang hoạt động',
// //                               textAlign: TextAlign.center,
// //                               style: TextStyle(
// //                                 color:
// //                                     _showActive
// //                                         ? Colors.white
// //                                         : themeData['mainText'],
// //                                 fontWeight: FontWeight.bold,
// //                               ),
// //                             ),
// //                           ),
// //                         ),
// //                       ),
// //                       Expanded(
// //                         child: GestureDetector(
// //                           onTap: () => setState(() => _showActive = false),
// //                           child: Container(
// //                             padding: const EdgeInsets.symmetric(vertical: 12),
// //                             decoration: BoxDecoration(
// //                               color:
// //                                   !_showActive
// //                                       ? themeData['primaryButtonColor']
// //                                       : Colors.transparent,
// //                               borderRadius: BorderRadius.circular(30),
// //                             ),
// //                             child: Text(
// //                               'Lịch sử',
// //                               textAlign: TextAlign.center,
// //                               style: TextStyle(
// //                                 color:
// //                                     !_showActive
// //                                         ? Colors.white
// //                                         : themeData['mainText'],
// //                                 fontWeight: FontWeight.bold,
// //                               ),
// //                             ),
// //                           ),
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                 ),

// //                 // Main content
// //                 Expanded(
// //                   child:
// //                       _showActive
// //                           ? _buildAlertsList(_activeAlerts, themeData)
// //                           : _buildAlertsList(_alertHistory, themeData),
// //                 ),
// //               ],
// //             ),
// //             floatingActionButton: FloatingActionButton(
// //               onPressed: () => _showSubscriptionDialog(context, themeData),
// //               backgroundColor: themeData['primaryButtonColor'],
// //               child: const Icon(Icons.add_alert),
// //               tooltip: 'Quản lý đăng ký thông báo',
// //             ),
// //           ),
// //         );
// //       },
// //     );
// //   }

// //   Widget _buildAlertsList(
// //     List<WeatherAlert> alerts,
// //     Map<String, dynamic> themeData,
// //   ) {
// //     if (alerts.isEmpty) {
// //       return Center(
// //         child: Column(
// //           mainAxisAlignment: MainAxisAlignment.center,
// //           children: [
// //             Icon(
// //               Icons.notifications_off_outlined,
// //               size: 64,
// //               color: themeData['mainText'].withOpacity(0.5),
// //             ),
// //             const SizedBox(height: 16),
// //             Text(
// //               'Không có thông báo nào',
// //               style: TextStyle(color: themeData['mainText'], fontSize: 18),
// //             ),
// //           ],
// //         ),
// //       );
// //     }

// //     return ListView.builder(
// //       padding: const EdgeInsets.all(16),
// //       itemCount: alerts.length,
// //       itemBuilder: (context, index) {
// //         final alert = alerts[index];
// //         return _buildAlertCard(alert, themeData);
// //       },
// //     );
// //   }

// //   Widget _buildAlertCard(WeatherAlert alert, Map<String, dynamic> themeData) {
// //     Color severityColor;
// //     IconData severityIcon;

// //     // Set color and icon based on severity
// //     switch (alert.severity) {
// //       case AlertSeverity.severe:
// //         severityColor = Colors.red;
// //         severityIcon = Icons.warning_amber_rounded;
// //         break;
// //       case AlertSeverity.moderate:
// //         severityColor = Colors.orange;
// //         severityIcon = Icons.error_outline;
// //         break;
// //       case AlertSeverity.warning:
// //         severityColor = Colors.amber;
// //         severityIcon = Icons.info_outline;
// //         break;
// //       default:
// //         severityColor = Colors.blue;
// //         severityIcon = Icons.info_outline;
// //     }

// //     // Format time
// //     final formatter = CustomTimeFormatter();
// //     final formattedTime = formatter.format(alert.timestamp);
// //     final formattedExpiry = formatter.format(alert.expiryTime);

// //     return Card(
// //       margin: const EdgeInsets.only(bottom: 12),
// //       color: themeData['cardLocationColor'],
// //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// //       child: Padding(
// //         padding: const EdgeInsets.all(16),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             Row(
// //               children: [
// //                 Container(
// //                   padding: const EdgeInsets.all(8),
// //                   decoration: BoxDecoration(
// //                     color: severityColor.withOpacity(0.2),
// //                     borderRadius: BorderRadius.circular(8),
// //                   ),
// //                   child: Icon(severityIcon, color: severityColor, size: 24),
// //                 ),
// //                 const SizedBox(width: 12),
// //                 Expanded(
// //                   child: Column(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: [
// //                       Text(
// //                         alert.title,
// //                         style: TextStyle(
// //                           color: themeData['mainText'],
// //                           fontSize: 18,
// //                           fontWeight: FontWeight.bold,
// //                         ),
// //                       ),
// //                       Row(
// //                         children: [
// //                           Icon(
// //                             Icons.location_on_outlined,
// //                             size: 14,
// //                             color: themeData['auxiliaryText'],
// //                           ),
// //                           const SizedBox(width: 4),
// //                           Text(
// //                             alert.location,
// //                             style: TextStyle(
// //                               color: themeData['auxiliaryText'],
// //                               fontSize: 14,
// //                             ),
// //                           ),
// //                         ],
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //               ],
// //             ),
// //             const SizedBox(height: 12),
// //             Text(
// //               alert.description,
// //               style: TextStyle(color: themeData['mainText'], fontSize: 15),
// //             ),
// //             const SizedBox(height: 8),
// //             Row(
// //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //               children: [
// //                 Text(
// //                   'Phát hành: $formattedTime',
// //                   style: TextStyle(
// //                     color: themeData['auxiliaryText'],
// //                     fontSize: 12,
// //                   ),
// //                 ),
// //                 if (alert.expiryTime.isAfter(DateTime.now()))
// //                   Text(
// //                     'Hết hạn: $formattedExpiry',
// //                     style: TextStyle(
// //                       color: themeData['auxiliaryText'],
// //                       fontSize: 12,
// //                     ),
// //                   )
// //                 else
// //                   Text(
// //                     'Đã hết hạn',
// //                     style: TextStyle(
// //                       color: themeData['auxiliaryText'],
// //                       fontSize: 12,
// //                     ),
// //                   ),
// //               ],
// //             ),
// //             if (_showActive)
// //               Align(
// //                 alignment: Alignment.centerRight,
// //                 child: TextButton.icon(
// //                   onPressed: () {
// //                     // Show alert details or actions
// //                     _showAlertDetailDialog(context, alert, themeData);
// //                   },
// //                   icon: Icon(
// //                     Icons.arrow_forward,
// //                     color: themeData['primaryButtonColor'],
// //                     size: 18,
// //                   ),
// //                   label: Text(
// //                     'Chi tiết',
// //                     style: TextStyle(
// //                       color: themeData['primaryButtonColor'],
// //                       fontWeight: FontWeight.bold,
// //                     ),
// //                   ),
// //                 ),
// //               ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   void _showAlertDetailDialog(
// //     BuildContext context,
// //     WeatherAlert alert,
// //     Map<String, dynamic> themeData,
// //   ) {
// //     showModalBottomSheet(
// //       context: context,
// //       backgroundColor: Colors.transparent,
// //       isScrollControlled: true,
// //       builder: (context) {
// //         return Container(
// //           height: MediaQuery.of(context).size.height * 0.7,
// //           decoration: BoxDecoration(
// //             color: themeData['cardLocationColor'],
// //             borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
// //           ),
// //           padding: const EdgeInsets.all(20),
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [
// //               Row(
// //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                 children: [
// //                   Text(
// //                     'Thông tin chi tiết',
// //                     style: TextStyle(
// //                       color: themeData['mainText'],
// //                       fontSize: 20,
// //                       fontWeight: FontWeight.bold,
// //                     ),
// //                   ),
// //                   IconButton(
// //                     icon: Icon(Icons.close, color: themeData['mainText']),
// //                     onPressed: () => Navigator.pop(context),
// //                   ),
// //                 ],
// //               ),
// //               const Divider(),
// //               Expanded(
// //                 child: ListView(
// //                   children: [
// //                     _buildDetailItem('Loại cảnh báo', alert.title, themeData),
// //                     _buildDetailItem('Khu vực', alert.location, themeData),
// //                     _buildDetailItem(
// //                       'Mức độ',
// //                       _getSeverityString(alert.severity),
// //                       themeData,
// //                     ),
// //                     _buildDetailItem('Nội dung', alert.description, themeData),
// //                     _buildDetailItem(
// //                       'Thời gian phát hành',
// //                       _formatFullDateTime(alert.timestamp),
// //                       themeData,
// //                     ),
// //                     _buildDetailItem(
// //                       'Thời gian hết hạn',
// //                       _formatFullDateTime(alert.expiryTime),
// //                       themeData,
// //                     ),
// //                     const SizedBox(height: 20),
// //                     _buildRecommendationsSection(alert, themeData),
// //                   ],
// //                 ),
// //               ),
// //               ElevatedButton.icon(
// //                 onPressed: () {
// //                   // TODO: Integrate with notification service
// //                   Navigator.pop(context);
// //                   ScaffoldMessenger.of(context).showSnackBar(
// //                     const SnackBar(
// //                       content: Text('Đã ẩn cảnh báo này'),
// //                       duration: Duration(seconds: 2),
// //                     ),
// //                   );
// //                 },
// //                 icon: const Icon(Icons.visibility_off),
// //                 label: const Text('Ẩn cảnh báo này'),
// //                 style: ElevatedButton.styleFrom(
// //                   backgroundColor: themeData['primaryButtonColor'],
// //                   foregroundColor: Colors.white,
// //                   padding: const EdgeInsets.symmetric(vertical: 12),
// //                   shape: RoundedRectangleBorder(
// //                     borderRadius: BorderRadius.circular(30),
// //                   ),
// //                   minimumSize: const Size(double.infinity, 50),
// //                 ),
// //               ),
// //             ],
// //           ),
// //         );
// //       },
// //     );
// //   }

// //   Widget _buildDetailItem(
// //     String label,
// //     String value,
// //     Map<String, dynamic> themeData,
// //   ) {
// //     return Padding(
// //       padding: const EdgeInsets.symmetric(vertical: 8),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Text(
// //             label,
// //             style: TextStyle(
// //               color: themeData['auxiliaryText'],
// //               fontSize: 14,
// //               fontWeight: FontWeight.bold,
// //             ),
// //           ),
// //           const SizedBox(height: 4),
// //           Text(
// //             value,
// //             style: TextStyle(color: themeData['mainText'], fontSize: 16),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildRecommendationsSection(
// //     WeatherAlert alert,
// //     Map<String, dynamic> themeData,
// //   ) {
// //     // Sample recommendations based on alert type
// //     List<String> recommendations = [];

// //     if (alert.title.toLowerCase().contains('mưa')) {
// //       recommendations = [
// //         'Mang theo áo mưa hoặc ô khi ra ngoài',
// //         'Tránh các khu vực thấp trũng dễ ngập lụt',
// //         'Theo dõi thông tin giao thông để tránh tắc đường',
// //         'Chuẩn bị các vật dụng chống ngập cho nhà ở nếu cần thiết',
// //       ];
// //     } else if (alert.title.toLowerCase().contains('giông') ||
// //         alert.title.toLowerCase().contains('sét')) {
// //       recommendations = [
// //         'Tránh đứng dưới cây cao hoặc ở những khu vực trống trải',
// //         'Không sử dụng điện thoại hoặc thiết bị điện tử khi đang ở ngoài trời',
// //         'Tìm nơi trú ẩn an toàn như nhà cửa, công trình kiên cố',
// //         'Tránh tiếp xúc với vật dụng kim loại khi có giông sét',
// //       ];
// //     } else if (alert.title.toLowerCase().contains('uv') ||
// //         alert.title.toLowerCase().contains('nắng')) {
// //       recommendations = [
// //         'Sử dụng kem chống nắng có chỉ số SPF tối thiểu 30',
// //         'Mặc quần áo chống nắng, đội mũ rộng vành và đeo kính râm',
// //         'Tránh ra ngoài trời nắng gay gắt từ 10h đến 16h',
// //         'Uống nhiều nước để tránh mất nước',
// //       ];
// //     } else if (alert.title.toLowerCase().contains('ô nhiễm')) {
// //       recommendations = [
// //         'Hạn chế hoạt động ngoài trời',
// //         'Đeo khẩu trang khi ra ngoài',
// //         'Đóng kín cửa sổ để tránh không khí ô nhiễm vào nhà',
// //         'Sử dụng máy lọc không khí nếu có',
// //       ];
// //     } else {
// //       recommendations = [
// //         'Theo dõi cập nhật thông tin thời tiết',
// //         'Chuẩn bị sẵn sàng các vật dụng cần thiết',
// //         'Lên kế hoạch di chuyển phù hợp',
// //         'Liên hệ cơ quan chức năng khi cần hỗ trợ',
// //       ];
// //     }

// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         Text(
// //           'Khuyến nghị',
// //           style: TextStyle(
// //             color: themeData['mainText'],
// //             fontSize: 18,
// //             fontWeight: FontWeight.bold,
// //           ),
// //         ),
// //         const SizedBox(height: 8),
// //         ...recommendations.map(
// //           (rec) => _buildRecommendationItem(rec, themeData),
// //         ),
// //       ],
// //     );
// //   }

// //   Widget _buildRecommendationItem(String text, Map<String, dynamic> themeData) {
// //     return Padding(
// //       padding: const EdgeInsets.only(bottom: 8),
// //       child: Row(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Icon(
// //             Icons.check_circle_outline,
// //             color: themeData['primaryButtonColor'],
// //             size: 20,
// //           ),
// //           const SizedBox(width: 8),
// //           Expanded(
// //             child: Text(
// //               text,
// //               style: TextStyle(color: themeData['mainText'], fontSize: 15),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   void _showSubscriptionDialog(
// //     BuildContext context,
// //     Map<String, dynamic> themeData,
// //   ) {
// //     // Sample alert types
// //     final List<Map<String, dynamic>> alertTypes = [
// //       {'name': 'Mưa lớn', 'icon': Icons.water_drop, 'enabled': true},
// //       {'name': 'Giông sét', 'icon': Icons.flash_on, 'enabled': true},
// //       {'name': 'Chỉ số UV cao', 'icon': Icons.wb_sunny, 'enabled': true},
// //       {'name': 'Chất lượng không khí', 'icon': Icons.air, 'enabled': false},
// //       {'name': 'Nhiệt độ cao', 'icon': Icons.thermostat, 'enabled': true},
// //       {'name': 'Lũ lụt', 'icon': Icons.waves, 'enabled': false},
// //       {'name': 'Độ ẩm cao', 'icon': Icons.water, 'enabled': false},
// //     ];

// //     showModalBottomSheet(
// //       context: context,
// //       backgroundColor: Colors.transparent,
// //       isScrollControlled: true,
// //       builder: (context) {
// //         return StatefulBuilder(
// //           builder: (context, setState) {
// //             return Container(
// //               height: MediaQuery.of(context).size.height * 0.7,
// //               decoration: BoxDecoration(
// //                 color: themeData['cardLocationColor'],
// //                 borderRadius: const BorderRadius.vertical(
// //                   top: Radius.circular(20),
// //                 ),
// //               ),
// //               padding: const EdgeInsets.all(20),
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   Row(
// //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                     children: [
// //                       Text(
// //                         'Quản lý đăng ký thông báo',
// //                         style: TextStyle(
// //                           color: themeData['mainText'],
// //                           fontSize: 18,
// //                           fontWeight: FontWeight.bold,
// //                         ),
// //                       ),
// //                       IconButton(
// //                         icon: Icon(Icons.close, color: themeData['mainText']),
// //                         onPressed: () => Navigator.pop(context),
// //                       ),
// //                     ],
// //                   ),
// //                   const SizedBox(height: 8),
// //                   Text(
// //                     'Chọn loại thông báo bạn muốn nhận',
// //                     style: TextStyle(
// //                       color: themeData['auxiliaryText'],
// //                       fontSize: 14,
// //                     ),
// //                   ),
// //                   const SizedBox(height: 16),
// //                   Expanded(
// //                     child: ListView.builder(
// //                       itemCount: alertTypes.length,
// //                       itemBuilder: (context, index) {
// //                         final alert = alertTypes[index];
// //                         return SwitchListTile(
// //                           title: Row(
// //                             children: [
// //                               Container(
// //                                 padding: const EdgeInsets.all(8),
// //                                 decoration: BoxDecoration(
// //                                   color: themeData['primaryButtonColor']
// //                                       .withOpacity(0.2),
// //                                   borderRadius: BorderRadius.circular(8),
// //                                 ),
// //                                 child: Icon(
// //                                   alert['icon'],
// //                                   color: themeData['primaryButtonColor'],
// //                                   size: 24,
// //                                 ),
// //                               ),
// //                               const SizedBox(width: 16),
// //                               Text(
// //                                 alert['name'],
// //                                 style: TextStyle(
// //                                   color: themeData['mainText'],
// //                                   fontSize: 16,
// //                                 ),
// //                               ),
// //                             ],
// //                           ),
// //                           value: alert['enabled'],
// //                           activeColor: themeData['primaryButtonColor'],
// //                           onChanged: (bool value) {
// //                             setState(() {
// //                               alert['enabled'] = value;
// //                             });
// //                           },
// //                         );
// //                       },
// //                     ),
// //                   ),
// //                   const SizedBox(height: 16),
// //                   ElevatedButton(
// //                     onPressed: () {
// //                       Navigator.pop(context);
// //                       ScaffoldMessenger.of(context).showSnackBar(
// //                         const SnackBar(
// //                           content: Text('Đã lưu cài đặt thông báo'),
// //                           duration: Duration(seconds: 2),
// //                         ),
// //                       );
// //                     },
// //                     style: ElevatedButton.styleFrom(
// //                       backgroundColor: themeData['primaryButtonColor'],
// //                       foregroundColor: Colors.white,
// //                       padding: const EdgeInsets.symmetric(vertical: 12),
// //                       shape: RoundedRectangleBorder(
// //                         borderRadius: BorderRadius.circular(30),
// //                       ),
// //                       minimumSize: const Size(double.infinity, 50),
// //                     ),
// //                     child: const Text(
// //                       'Lưu cài đặt',
// //                       style: TextStyle(fontSize: 16),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             );
// //           },
// //         );
// //       },
// //     );
// //   }

// //   String _getSeverityString(AlertSeverity severity) {
// //     switch (severity) {
// //       case AlertSeverity.severe:
// //         return 'Nghiêm trọng';
// //       case AlertSeverity.moderate:
// //         return 'Trung bình';
// //       case AlertSeverity.warning:
// //         return 'Cảnh báo';
// //       default:
// //         return 'Thông tin';
// //     }
// //   }

// //   String _formatFullDateTime(DateTime dateTime) {
// //     return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
// //   }
// // }

// // // Enum for alert severity levels
// // enum AlertSeverity { severe, moderate, warning, info }

// // // Weather Alert model class
// // class WeatherAlert {
// //   final String id;
// //   final String title;
// //   final String description;
// //   final AlertSeverity severity;
// //   final String location;
// //   final DateTime timestamp;
// //   final DateTime expiryTime;

// //   WeatherAlert({
// //     required this.id,
// //     required this.title,
// //     required this.description,
// //     required this.severity,
// //     required this.location,
// //     required this.timestamp,
// //     required this.expiryTime,
// //   });
// // }

// // // Helper class for time formatting
// // class CustomTimeFormatter {
// //   String format(DateTime dateTime) {
// //     final now = DateTime.now();
// //     final difference = now.difference(dateTime);

// //     if (difference.isNegative) {
// //       // For future times (like expiry)
// //       if (dateTime.day == now.day) {
// //         return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
// //       } else if (dateTime.difference(now).inDays < 7) {
// //         return 'T${dateTime.weekday}, ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
// //       } else {
// //         return '${dateTime.day}/${dateTime.month}, ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
// //       }
// //     } else {
// //       // For past times
// //       if (difference.inMinutes < 60) {
// //         return '${difference.inMinutes} phút trước';
// //       } else if (difference.inHours < 24) {
// //         return '${difference.inHours} giờ trước';
// //       } else if (difference.inDays < 7) {
// //         return '${difference.inDays} ngày trước';
// //       } else {
// //         return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
// //       }
// //     }
// //   }
// // }
