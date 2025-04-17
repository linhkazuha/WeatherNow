import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'package:weather_app/providers/theme_provider.dart';

class AirQuality {
  final int aqi;
  final Map<String, double> components;

  AirQuality({required this.aqi, required this.components});

  factory AirQuality.fromJson(Map<String, dynamic> json) {
    final list = json['list'][0];

    return AirQuality(
      aqi: list['main']['aqi'],
      components: {
        'co': list['components']['co'].toDouble(),
        'no2': list['components']['no2'].toDouble(),
        'o3': list['components']['o3'].toDouble(),
        'pm2_5': list['components']['pm2_5'].toDouble(),
        'pm10': list['components']['pm10'].toDouble(),
      },
    );
  }

  String get aqiDescription {
    switch (aqi) {
      case 1:
        return 'Tốt';
      case 2:
        return 'Trung bình';
      case 3:
        return 'Kém';
      case 4:
        return 'Xấu';
      case 5:
        return 'Rất xấu';
      default:
        return 'Không xác định';
    }
  }

  Color get aqiColor {
    switch (aqi) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.yellow;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.red;
      case 5:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

class WeatherData {
  final String cityName;
  final double temp;
  final double tempMin;
  final double tempMax;
  final String description;
  final String icon;
  final int humidity;
  final double windSpeed;
  final int pressure;
  final int visibility;
  final double feelsLike;
  final DateTime? sunrise;
  final DateTime? sunset;
  final List<HourlyForecast> hourlyForecast;
  final List<DailyForecast> dailyForecast;
  final AirQuality? airQuality;

  WeatherData({
    required this.cityName,
    required this.temp,
    required this.tempMin,
    required this.tempMax,
    required this.description,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
    required this.pressure,
    required this.visibility,
    required this.feelsLike,
    this.sunrise,
    this.sunset,
    required this.hourlyForecast,
    required this.dailyForecast,
    this.airQuality,
  });

  factory WeatherData.fromJson(
    Map<String, dynamic> current,
    List<dynamic> forecast,
    String cityName, {
    AirQuality? airQuality,
  }) {
    final currentWeather = current['weather'][0];

    DateTime? sunrise;
    DateTime? sunset;

    if (current['sys'] != null) {
      if (current['sys']['sunrise'] != null) {
        sunrise = DateTime.fromMillisecondsSinceEpoch(
          current['sys']['sunrise'] * 1000,
        );
      }
      if (current['sys']['sunset'] != null) {
        sunset = DateTime.fromMillisecondsSinceEpoch(
          current['sys']['sunset'] * 1000,
        );
      }
    }

    List<HourlyForecast> hourlyList = [];
    final now = DateTime.now();

    for (var i = 0; i < forecast.length && hourlyList.length < 24; i++) {
      final item = forecast[i];
      final forecastTime = DateTime.fromMillisecondsSinceEpoch(
        item['dt'] * 1000,
      );

      if (forecastTime.isAfter(now)) {
        hourlyList.add(
          HourlyForecast(
            time: forecastTime,
            temp: item['main']['temp'].toDouble(),
            icon: item['weather'][0]['icon'],
          ),
        );
      }
    }

    List<DailyForecast> dailyList = [];
    Map<String, DailyForecast> dailyMap = {};

    for (var item in forecast) {
      final DateTime forecastTime = DateTime.fromMillisecondsSinceEpoch(
        item['dt'] * 1000,
      );
      final String dateKey = DateFormat('yyyy-MM-dd').format(forecastTime);

      if (!dailyMap.containsKey(dateKey)) {
        dailyMap[dateKey] = DailyForecast(
          date: DateTime(
            forecastTime.year,
            forecastTime.month,
            forecastTime.day,
          ),
          tempMax: item['main']['temp_max'].toDouble(),
          tempMin: item['main']['temp_min'].toDouble(),
          icon: item['weather'][0]['icon'],
        );
      } else {
        final existing = dailyMap[dateKey]!;
        if (item['main']['temp_max'].toDouble() > existing.tempMax) {
          dailyMap[dateKey] = DailyForecast(
            date: existing.date,
            tempMax: item['main']['temp_max'].toDouble(),
            tempMin: existing.tempMin,
            icon: existing.icon,
          );
        }
        if (item['main']['temp_min'].toDouble() < existing.tempMin) {
          dailyMap[dateKey] = DailyForecast(
            date: existing.date,
            tempMax: existing.tempMax,
            tempMin: item['main']['temp_min'].toDouble(),
            icon: existing.icon,
          );
        }
      }
    }

    dailyList = dailyMap.values.toList();
    dailyList.sort((a, b) => a.date.compareTo(b.date));

    if (dailyList.length > 7) {
      dailyList = dailyList.sublist(0, 7);
    }

    return WeatherData(
      cityName: cityName,
      temp: current['main']['temp'].toDouble(),
      tempMin: current['main']['temp_min'].toDouble(),
      tempMax: current['main']['temp_max'].toDouble(),
      description: currentWeather['description'],
      icon: currentWeather['icon'],
      humidity: current['main']['humidity'],
      windSpeed: current['wind']['speed'].toDouble(),
      pressure: current['main']['pressure'], // thêm
      visibility: current['visibility'] ?? 0, // thêm
      feelsLike: current['main']['feels_like'].toDouble(), // thêm
      sunrise: sunrise,
      sunset: sunset,
      hourlyForecast: hourlyList,
      dailyForecast: dailyList,
      airQuality: airQuality,
    );
  }
}

class HourlyForecast {
  final DateTime time;
  final double temp;
  final String icon;

  HourlyForecast({required this.time, required this.temp, required this.icon});
}

class DailyForecast {
  final DateTime date;
  final double tempMax;
  final double tempMin;
  final String icon;

  DailyForecast({
    required this.date,
    required this.tempMax,
    required this.tempMin,
    required this.icon,
  });
}

class HomeScreen extends StatefulWidget {
  final Function(String)? onLocationChanged;

  const HomeScreen({Key? key, this.onLocationChanged}) : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

// Đổi từ _HomeScreenState thành HomeScreenState để public
class HomeScreenState extends State<HomeScreen> {
  final String apiKey = '5c2992addc713b68f4ae73b75db853e4';
  bool isLoading = true;
  WeatherData? weatherData;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await _getWeatherByCity("Hanoi");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          await _getWeatherByCity("Hanoi");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        await _getWeatherByCity("Hanoi");
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 5),
      );
      await _getWeatherData(position.latitude, position.longitude);
    } catch (e) {
      await _getWeatherByCity("Hanoi");
    }
  }

  // Chuyển từ private (có dấu gạch dưới) thành public để có thể gọi từ bên ngoài
  void searchCity(String cityName) {
    if (cityName.isEmpty) return;
    _getWeatherByCity(cityName);
  }

  Future<void> _getWeatherByCity(String cityName) async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final currentWeatherUrl =
          'https://api.openweathermap.org/data/2.5/weather?q=$cityName&units=metric&lang=vi&appid=$apiKey';
      final currentResponse = await http.get(Uri.parse(currentWeatherUrl));

      if (currentResponse.statusCode == 200) {
        final currentData = json.decode(currentResponse.body);

        final lat = currentData['coord']['lat'];
        final lon = currentData['coord']['lon'];

        final forecastUrl =
            'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&units=metric&lang=vi&appid=$apiKey';
        final forecastResponse = await http.get(Uri.parse(forecastUrl));

        final airQualityUrl =
            'https://api.openweathermap.org/data/2.5/air_pollution?lat=$lat&lon=$lon&appid=$apiKey';
        final airQualityResponse = await http.get(Uri.parse(airQualityUrl));

        if (forecastResponse.statusCode == 200) {
          final forecastData = json.decode(forecastResponse.body);

          AirQuality? airQuality;
          if (airQualityResponse.statusCode == 200) {
            final airQualityData = json.decode(airQualityResponse.body);
            airQuality = AirQuality.fromJson(airQualityData);
          }

          // Sử dụng tên thành phố từ API nếu có
          String displayName = cityName;
          if (currentData['name'] != null &&
              currentData['name'].toString().isNotEmpty) {
            displayName = currentData['name'];
          }

          setState(() {
            weatherData = WeatherData.fromJson(
              currentData,
              forecastData['list'],
              displayName,
              airQuality: airQuality,
            );
            isLoading = false;
          });

          // Thông báo tên địa điểm mới
          if (widget.onLocationChanged != null) {
            widget.onLocationChanged!(displayName);
          }
        } else {
          throw Exception('Không thể lấy dữ liệu dự báo');
        }
      } else {
        throw Exception('Không tìm thấy thành phố');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Không thể lấy dữ liệu thời tiết: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _getWeatherData(double lat, double lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      String cityName =
          placemarks.first.locality ??
          placemarks.first.administrativeArea ??
          placemarks.first.subAdministrativeArea ??
          'Unknown';

      final currentWeatherUrl =
          'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&lang=vi&appid=$apiKey';
      final currentResponse = await http.get(Uri.parse(currentWeatherUrl));

      final forecastUrl =
          'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&units=metric&lang=vi&appid=$apiKey';
      final forecastResponse = await http.get(Uri.parse(forecastUrl));

      final airQualityUrl =
          'https://api.openweathermap.org/data/2.5/air_pollution?lat=$lat&lon=$lon&appid=$apiKey';
      final airQualityResponse = await http.get(Uri.parse(airQualityUrl));

      if (currentResponse.statusCode == 200 &&
          forecastResponse.statusCode == 200) {
        final currentData = json.decode(currentResponse.body);
        final forecastData = json.decode(forecastResponse.body);

        // Sử dụng tên thành phố từ API nếu có
        if (currentData['name'] != null &&
            currentData['name'].toString().isNotEmpty) {
          cityName = currentData['name'];
        }

        AirQuality? airQuality;
        if (airQualityResponse.statusCode == 200) {
          final airQualityData = json.decode(airQualityResponse.body);
          airQuality = AirQuality.fromJson(airQualityData);
        }

        setState(() {
          weatherData = WeatherData.fromJson(
            currentData,
            forecastData['list'],
            cityName,
            airQuality: airQuality,
          );
          isLoading = false;
        });

        // Thông báo tên địa điểm mới
        if (widget.onLocationChanged != null) {
          widget.onLocationChanged!(cityName);
        }
      } else {
        throw Exception('Lỗi API');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Không thể lấy dữ liệu thời tiết.';
        isLoading = false;
      });
    }
  }

  String _getWeatherIconUrl(String icon) {
    return 'https://openweathermap.org/img/wn/$icon@2x.png';
  }

  String _formatTime(DateTime? time) {
    if (time == null) return "--:--";
    return DateFormat('HH:mm').format(time);
  }

  String _formatDayOfWeek(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));

    if (date.year == today.year &&
        date.month == today.month &&
        date.day == today.day) {
      return 'Hôm nay';
    } else if (date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day) {
      return 'Ngày mai';
    } else {
      final List<String> weekdays = [
        'Chủ nhật',
        'Thứ hai',
        'Thứ ba',
        'Thứ tư',
        'Thứ năm',
        'Thứ sáu',
        'Thứ bảy',
      ];
      return weekdays[date.weekday % 7];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final themeData = themeProvider.themeData;

        if (isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: themeData['mainText']),
                SizedBox(height: 16),
                Text(
                  'Đang tải dữ liệu thời tiết...',
                  style: TextStyle(color: themeData['mainText']),
                ),
              ],
            ),
          );
        }

        if (errorMessage != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: themeData['mainText'],
                    ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _getCurrentLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeData['auxiliaryText'],
                      foregroundColor: themeData['mainText'],
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text('Thử lại'),
                  ),
                ],
              ),
            ),
          );
        }

        final weather = weatherData!;

        return SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card thời tiết hiện tại ==========================================
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 3.0,
                ),
                child: Card(
                  elevation: 0,
                  color: themeData['currentWeatherCardColor'],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  weather.cityName,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: themeData['mainText'],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Cập nhật lúc ${DateFormat('HH:mm').format(DateTime.now())}',
                                  style: TextStyle(
                                    color: themeData['auxiliaryText'],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.refresh,
                                color: themeData['mainText'],
                              ),
                              onPressed: _getCurrentLocation,
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  '${weather.temp.round()}°',
                                  style: TextStyle(
                                    fontSize: 60,
                                    fontWeight: FontWeight.w500,
                                    color: themeData['mainText'],
                                  ),
                                ),
                                Text(
                                  '${weather.tempMin.round()}° / ${weather.tempMax.round()}°',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: themeData['auxiliaryText'],
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Image.network(
                                  _getWeatherIconUrl(weather.icon),
                                  width: 80,
                                  height: 80,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.cloud,
                                      size: 80,
                                      color: themeData['auxiliaryText'],
                                    );
                                  },
                                ),
                                Text(
                                  weather.description,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: themeData['mainText'],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 20),

                        // Sửa lại Row này để thẳng hàng với nhiệt độ
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment:
                              CrossAxisAlignment.center, // Đảm bảo căn giữa
                          children: [
                            Icon(
                              Icons.thermostat,
                              color: themeData['auxiliaryText'],
                            ),
                            SizedBox(
                              width: 8,
                            ), // Thêm khoảng cách giữa icon và text
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${weather.feelsLike.round()}°',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: themeData['mainText'],
                                  ),
                                ),
                                Text(
                                  'Cảm giác thực',
                                  style: TextStyle(
                                    color: themeData['auxiliaryText'],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Dự báo theo giờ =================================================
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 3.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      child:
                          weather.hourlyForecast.isEmpty
                              ? Center(
                                child: Text(
                                  'Không có dữ liệu dự báo theo giờ',
                                  style: TextStyle(
                                    color: themeData['mainText'],
                                  ),
                                ),
                              )
                              : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: weather.hourlyForecast.length,
                                itemBuilder: (context, index) {
                                  final hourly = weather.hourlyForecast[index];
                                  return Card(
                                    margin: EdgeInsets.only(right: 8),
                                    color: themeData['backCardColor']
                                        .withOpacity(0.7),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Container(
                                      width: 80,
                                      padding: EdgeInsets.all(8),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          Text(
                                            DateFormat(
                                              'HH:mm',
                                            ).format(hourly.time),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              color: themeData['mainText'],
                                            ),
                                          ),
                                          Image.network(
                                            _getWeatherIconUrl(hourly.icon),
                                            width: 40,
                                            height: 40,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return Icon(
                                                Icons.cloud,
                                                size: 40,
                                                color:
                                                    themeData['auxiliaryText'],
                                              );
                                            },
                                          ),
                                          Text(
                                            '${hourly.temp.round()}°',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: themeData['mainText'],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                    ),
                  ],
                ),
              ),

              // Dự báo 7 ngày ===================================================
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 3.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8),
                    Card(
                      color: themeData['backCardColor'].withOpacity(0.7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child:
                            weather.dailyForecast.isEmpty
                                ? Center(
                                  child: Text(
                                    'Không có dữ liệu dự báo theo ngày',
                                    style: TextStyle(
                                      color: themeData['mainText'],
                                    ),
                                  ),
                                )
                                : Column(
                                  children:
                                      weather.dailyForecast.map((daily) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8.0,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                flex: 3,
                                                child: Text(
                                                  _formatDayOfWeek(daily.date),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    color:
                                                        themeData['mainText'],
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 1,
                                                child: Image.network(
                                                  _getWeatherIconUrl(
                                                    daily.icon,
                                                  ),
                                                  width: 40,
                                                  height: 40,
                                                  errorBuilder: (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) {
                                                    return Icon(
                                                      Icons.cloud,
                                                      size: 40,
                                                      color:
                                                          themeData['auxiliaryText'],
                                                    );
                                                  },
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      '${daily.tempMin.round()}°',
                                                      style: TextStyle(
                                                        color:
                                                            themeData['mainText'],
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      '${daily.tempMax.round()}°',
                                                      style: TextStyle(
                                                        color:
                                                            themeData['mainText'],
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                ),
                      ),
                    ),
                  ],
                ),
              ),

              // Card các chỉ số phụ =============================================
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 3.0,
                ),
                child: Card(
                  color: themeData['backCardColor'].withOpacity(0.7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Text(
                        //   'Thông số bổ sung',
                        //   style: TextStyle(
                        //     fontSize: 18,
                        //     fontWeight: FontWeight.bold,
                        //     color: themeData['mainText'],
                        //   ),
                        // ),
                        // SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            // _buildWeatherDetail(Icons.wb_sunny, weather.uvIndex.toStringAsFixed(1), 'UV', themeData),
                            _buildWeatherDetail(
                              Icons.water_drop,
                              '${weather.humidity}%',
                              'Độ ẩm',
                              themeData,
                            ),
                            _buildWeatherDetail(
                              Icons.air,
                              '${weather.windSpeed} m/s',
                              'Gió',
                              themeData,
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildWeatherDetail(
                              Icons.speed,
                              '${weather.pressure} hPa',
                              'Áp suất',
                              themeData,
                            ),
                            _buildWeatherDetail(
                              Icons.visibility,
                              '${(weather.visibility / 1000).toStringAsFixed(1)} km',
                              'Tầm nhìn',
                              themeData,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Card chất lượng không khí =======================================
              if (weather.airQuality != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 3.0,
                  ),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: themeData['backCardColor'].withOpacity(0.7),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.air,
                                    color: themeData['auxiliaryText'],
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Chất lượng không khí',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: themeData['mainText'],
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: weather.airQuality!.aqiColor
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: weather.airQuality!.aqiColor,
                                  ),
                                ),
                                child: Text(
                                  'AQI: ${weather.airQuality!.aqi}',
                                  style: TextStyle(
                                    color: weather.airQuality!.aqiColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Text(
                            weather.airQuality!.aqiDescription,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: weather.airQuality!.aqiColor,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Các chỉ số ô nhiễm (μg/m³):',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: themeData['mainText'],
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildAirQualityItem(
                                'PM2.5',
                                weather.airQuality!.components['pm2_5']!
                                    .toStringAsFixed(1),
                                themeData,
                              ),
                              _buildAirQualityItem(
                                'PM10',
                                weather.airQuality!.components['pm10']!
                                    .toStringAsFixed(1),
                                themeData,
                              ),
                              _buildAirQualityItem(
                                'O₃',
                                weather.airQuality!.components['o3']!
                                    .toStringAsFixed(1),
                                themeData,
                              ),
                              _buildAirQualityItem(
                                'NO₂',
                                weather.airQuality!.components['no2']!
                                    .toStringAsFixed(1),
                                themeData,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeatherDetail(
    IconData icon,
    String value,
    String label,
    Map<String, dynamic> themeData,
  ) {
    return Column(
      children: [
        Icon(icon, color: themeData['auxiliaryText']),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: themeData['mainText'],
          ),
        ),
        Text(
          label,
          style: TextStyle(color: themeData['auxiliaryText'], fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildAirQualityItem(
    String label,
    String value,
    Map<String, dynamic> themeData,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: themeData['mainText'],
          ),
        ),
        Text(
          label,
          style: TextStyle(color: themeData['auxiliaryText'], fontSize: 14),
        ),
      ],
    );
  }
}
