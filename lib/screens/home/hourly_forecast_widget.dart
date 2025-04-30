// lib/screens/home/hourly_forecast_widget.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/weather_models.dart';
import '../../utils/conversion_utils.dart';

class HourlyForecastWidget extends StatelessWidget {
  final List<HourlyForecast> hourlyForecast;
  final Map<String, dynamic> themeData;
  final String temperatureUnit;

  const HourlyForecastWidget({
    super.key,
    required this.hourlyForecast,
    required this.themeData,
    required this.temperatureUnit,
  });

  String _getWeatherIconUrl(String icon) {
    return 'https://openweathermap.org/img/wn/$icon@2x.png';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8),
        SizedBox(
          height: 120,
          child:
              hourlyForecast.isEmpty
                  ? Center(
                    child: Text(
                      'Không có dữ liệu dự báo theo giờ',
                      style: TextStyle(color: themeData['mainText']),
                    ),
                  )
                  : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: hourlyForecast.length,
                    itemBuilder: (context, index) {
                      final hourly = hourlyForecast[index];
                      return Card(
                        margin: EdgeInsets.only(right: 8),
                        color: themeData['backCardColor'].withOpacity(0.7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          width: 80,
                          padding: EdgeInsets.all(8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text(
                                DateFormat('HH:mm').format(hourly.time),
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: themeData['mainText'],
                                ),
                              ),
                              Image.network(
                                _getWeatherIconUrl(hourly.icon),
                                width: 40,
                                height: 40,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.cloud,
                                    size: 40,
                                    color: themeData['auxiliaryText'],
                                  );
                                },
                              ),
                              Text(
                                '${convertTemperature(hourly.temp, temperatureUnit).round()}°$temperatureUnit',
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
    );
  }
}
