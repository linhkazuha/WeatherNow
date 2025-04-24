// lib/screens/home/current_weather_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/weather_models.dart';

class CurrentWeatherCard extends StatelessWidget {
  final WeatherData weather;
  final Map<String, dynamic> themeData;
  final VoidCallback onRefresh;

  const CurrentWeatherCard({
    super.key,
    required this.weather,
    required this.themeData,
    required this.onRefresh,
  });

  String _getWeatherIconUrl(String icon) {
    return 'https://openweathermap.org/img/wn/$icon@2x.png';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.thermostat,
                  color: themeData['auxiliaryText'],
                ),
                SizedBox(width: 8),
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
    );
  }
}