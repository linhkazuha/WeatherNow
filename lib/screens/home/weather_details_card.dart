import 'package:flutter/material.dart';
import '../../models/weather_models.dart';

class WeatherDetailsCard extends StatelessWidget {
  final WeatherData weather;
  final Map<String, dynamic> themeData;

  const WeatherDetailsCard({
    super.key,
    required this.weather,
    required this.themeData,
  });

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

  @override
  Widget build(BuildContext context) {
    return Card(
      color: themeData['backCardColor'].withOpacity(0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
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
    );
  }
}