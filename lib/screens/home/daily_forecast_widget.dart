import 'package:flutter/material.dart';
import '../../models/weather_models.dart';
import '../../utils/conversion_utils.dart';

class DailyForecastWidget extends StatelessWidget {
  final List<DailyForecast> dailyForecast;
  final Map<String, dynamic> themeData;
  final String temperatureUnit;

  const DailyForecastWidget({
    super.key,
    required this.dailyForecast,
    required this.themeData,
    required this.temperatureUnit,
  });

  String _getWeatherIconUrl(String icon) {
    return 'https://openweathermap.org/img/wn/$icon@2x.png';
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
    return Column(
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
            child: dailyForecast.isEmpty
                ? Center(
                    child: Text(
                      'Không có dữ liệu dự báo theo ngày',
                      style: TextStyle(color: themeData['mainText']),
                    ),
                  )
                : Column(
                    children: List.generate(dailyForecast.length * 2 - 1, (
                      index,
                    ) {
                      // Nếu index chẵn, hiển thị dự báo thời tiết
                      if (index % 2 == 0) {
                        final forecastIndex = index ~/ 2;
                        final daily = dailyForecast[forecastIndex];

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  _formatDayOfWeek(daily.date),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: themeData['mainText'],
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Image.network(
                                  _getWeatherIconUrl(daily.icon),
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
                              ),
                              Expanded(
                                flex: 2,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${convertTemperature(daily.tempMin, temperatureUnit).round()}°',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: themeData['mainText'],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      '${convertTemperature(daily.tempMax, temperatureUnit).round()}°',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: themeData['mainText'],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        // Nếu index lẻ, hiển thị thanh phân cách
                        return Divider(
                          color: themeData['separateLine']?.withOpacity(0.3) ??
                              Colors.grey.withOpacity(0.3),
                          height: 1,
                        );
                      }
                    }),
                  ),
          ),
        ),
      ],
    );
  }
}
