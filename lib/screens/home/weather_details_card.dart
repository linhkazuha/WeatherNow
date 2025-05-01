import 'package:flutter/material.dart';
import '../../models/weather_models.dart';
import '../../utils/conversion_utils.dart';

class WeatherDetailsCard extends StatelessWidget {
  final WeatherData weather;
  final Map<String, dynamic> themeData;
  final String temperatureUnit;
  final String windSpeedUnit;
  final String pressureUnit;
  final String distanceUnit;

  const WeatherDetailsCard({
    super.key,
    required this.weather,
    required this.themeData,
    required this.temperatureUnit,
    required this.windSpeedUnit,
    required this.pressureUnit,
    required this.distanceUnit,
  });

  String _getUvLevelText(double uvIndex) {
    if (uvIndex < 3) {
      return 'Thấp';
    } else if (uvIndex < 6) {
      return 'Trung bình';
    } else if (uvIndex < 8) {
      return 'Cao';
    } else if (uvIndex < 11) {
      return 'Rất cao';
    } else {
      return 'Cực kỳ cao';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.wb_sunny,
                  iconColor: Colors.orange,
                  label: 'Chỉ số UV',
                  value: _getUvLevelText(weather.uvIndex),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.water_drop,
                  iconColor: Colors.blue,
                  label: 'Độ ẩm',
                  value: '${weather.humidity}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.air,
                  iconColor: Colors.lightBlue,
                  label: 'Tốc độ gió',
                  value:
                      '${convertWindSpeed(weather.windSpeed, windSpeedUnit).toStringAsFixed(2)} $windSpeedUnit',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.opacity,
                  iconColor: Colors.blueAccent,
                  label: 'Điểm sương',
                  value:
                      '${convertTemperature(weather.dewPoint, temperatureUnit).round()}°$temperatureUnit',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.compress,
                  iconColor: Colors.brown,
                  label: 'Áp suất',
                  value:
                      '${convertPressure(weather.pressure.toDouble(), pressureUnit).toStringAsFixed(1)} $pressureUnit',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.visibility,
                  iconColor: Colors.cyan,
                  label: 'Tầm nhìn',
                  value:
                      '${convertDistance(weather.visibility.toDouble(), distanceUnit).toStringAsFixed(1)} $distanceUnit',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Card(
      elevation: 0,
      color: themeData['backCardColor'].withOpacity(0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 22),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: themeData['auxiliaryText'],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                color: themeData['mainText'],
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
