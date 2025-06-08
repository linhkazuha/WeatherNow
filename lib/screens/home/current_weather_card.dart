// lib/screens/home/current_weather_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/weather_models.dart';
import '../../utils/conversion_utils.dart';

class CurrentWeatherCard extends StatelessWidget {
  final WeatherData weather;
  final Map<String, dynamic> themeData;
  final VoidCallback onRefresh;
  final String temperatureUnit;

  const CurrentWeatherCard({
    super.key,
    required this.weather,
    required this.themeData,
    required this.onRefresh,
    required this.temperatureUnit,
  });

  String _getWeatherIconUrl(String icon) {
    return 'https://openweathermap.org/img/wn/$icon@2x.png';
  }

  // Hàm lấy nhiệt độ min/max từ daily forecast thay vì current weather
  String _getMinMaxTemperature() {
    if (weather.dailyForecast.isNotEmpty) {
      // Sử dụng dữ liệu từ daily forecast (ngày hôm nay)
      final todayForecast = weather.dailyForecast[0];
      final minTemp = convertTemperature(todayForecast.tempMin, temperatureUnit).round();
      final maxTemp = convertTemperature(todayForecast.tempMax, temperatureUnit).round();
      return '$minTemp° / $maxTemp°$temperatureUnit';
    } else {
      // Fallback về current weather nếu không có daily forecast
      final minTemp = convertTemperature(weather.tempMin, temperatureUnit).round();
      final maxTemp = convertTemperature(weather.tempMax, temperatureUnit).round();
      return '$minTemp° / $maxTemp°$temperatureUnit';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: themeData['currentWeatherCardColor'],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                      'Cập nhật lúc ${DateFormat('HH:mm').format(DateTime.now())}',
                      style: TextStyle(
                        color: themeData['auxiliaryText'],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: themeData['mainText']),
                  onPressed: onRefresh,
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
                      '${convertTemperature(weather.temp, temperatureUnit).round()}°$temperatureUnit',
                      style: TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.w500,
                        color: themeData['mainText'],
                      ),
                    ),
                    // Sử dụng hàm mới để lấy min/max từ daily forecast
                    Text(
                      _getMinMaxTemperature(),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.thermostat, color: themeData['auxiliaryText']),
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${convertTemperature(weather.feelsLike, temperatureUnit).round()}°$temperatureUnit',
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
    );
  }
}