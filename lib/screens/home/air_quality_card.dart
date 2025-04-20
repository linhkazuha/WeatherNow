import 'package:flutter/material.dart';
import '../../models/weather_models.dart';

class AirQualityCard extends StatelessWidget {
  final AirQuality airQuality;
  final Map<String, dynamic> themeData;

  const AirQualityCard({
    super.key,
    required this.airQuality,
    required this.themeData,
  });

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

  @override
  Widget build(BuildContext context) {
    return Card(
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
                    // ignore: deprecated_member_use
                    color: airQuality.aqiColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: airQuality.aqiColor,
                    ),
                  ),
                  child: Text(
                    'AQI: ${airQuality.aqi}',
                    style: TextStyle(
                      color: airQuality.aqiColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              airQuality.aqiDescription,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: airQuality.aqiColor,
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
                  airQuality.components['pm2_5']!.toStringAsFixed(1),
                  themeData,
                ),
                _buildAirQualityItem(
                  'PM10',
                  airQuality.components['pm10']!.toStringAsFixed(1),
                  themeData,
                ),
                _buildAirQualityItem(
                  'O₃',
                  airQuality.components['o3']!.toStringAsFixed(1),
                  themeData,
                ),
                _buildAirQualityItem(
                  'NO₂',
                  airQuality.components['no2']!.toStringAsFixed(1),
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