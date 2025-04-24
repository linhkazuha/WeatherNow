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

  // Phương thức định dạng giá trị UV thành chuỗi
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

  // Phương thức tạo một dòng thông tin
  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: themeData['mainText'],
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: themeData['mainText'],
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            color: themeData['separateLine'].withOpacity(0.3),
            height: 1,
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
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          children: [
            _buildInfoRow(
              icon: Icons.wb_sunny,
              iconColor: Colors.orange,
              label: 'Chỉ số UV',
              value: _getUvLevelText(weather.uvIndex),
            ),
            _buildInfoRow(
              icon: Icons.water_drop,
              iconColor: Colors.blue,
              label: 'Độ ẩm',
              value: '${weather.humidity}%',
            ),
            _buildInfoRow(
              icon: Icons.air,
              iconColor: Colors.lightBlue,
              label: 'Tốc độ gió',
              value: '${weather.windSpeed} m/s',
            ),
            _buildInfoRow(
              icon: Icons.opacity,
              iconColor: Colors.blueAccent,
              label: 'Điểm sương',
              value: '${weather.dewPoint.round()}°',
            ),
            _buildInfoRow(
              icon: Icons.compress,
              iconColor: Colors.brown,
              label: 'Áp suất',
              value: '${weather.pressure.toStringAsFixed(1)}mb',
            ),
            _buildInfoRow(
              icon: Icons.visibility,
              iconColor: Colors.cyan,
              label: 'Tầm nhìn',
              value: '${(weather.visibility / 1000).toStringAsFixed(2)} km',
              showDivider: false,
            ),
          ],
        ),
      ),
    );
  }
}