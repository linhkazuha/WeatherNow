import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weather_app/models/weather_models.dart';
import 'package:weather_app/providers/theme_provider.dart';
import 'package:weather_app/providers/settings_provider.dart';
//import 'package:weather_app/utils/conversion_utils.dart';
import 'package:weather_app/screens/maps/widgets/mini_weather_map.dart';
import 'package:weather_app/services/weather_api_service.dart';
import 'package:weather_app/widgets/weather_widget_provider.dart';

// Import các widget con
import 'home/current_weather_card.dart';
import 'home/hourly_forecast_widget.dart';
import 'home/daily_forecast_widget.dart';
import 'home/weather_details_card.dart';
import 'home/air_quality_card.dart';
import 'home/sunrise_sunset_card.dart';

class HomeScreen extends StatefulWidget {
  final Function(String)? onLocationChanged;

  const HomeScreen({super.key, this.onLocationChanged});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final WeatherApiService _weatherService = WeatherApiService();
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
      final data = await _weatherService.getCurrentLocationWeather();
      setState(() {
        weatherData = data;
        isLoading = false;
      });

      // Thông báo tên địa điểm mới
      if (widget.onLocationChanged != null) {
        widget.onLocationChanged!(data.cityName);
      }
      
      // Cập nhật widget trên màn hình chính với đầy đủ thông tin
      final tempText = '${data.temp.round()}°C';
      WeatherWidgetProvider.updateWidget(
        tempText,
        data.cityName,
        data.description,
        data.icon
      );
    } catch (e) {
      setState(() {
        errorMessage = 'Không thể lấy dữ liệu thời tiết: $e';
        isLoading = false;
      });
    }
  }

  // Public method để có thể gọi từ bên ngoài
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

      final data = await _weatherService.getWeatherByCity(cityName);
      setState(() {
        weatherData = data;
        isLoading = false;
      });

      // Thông báo tên địa điểm mới
      if (widget.onLocationChanged != null) {
        widget.onLocationChanged!(data.cityName);
      }
      
      // Cập nhật widget trên màn hình chính với đầy đủ thông tin
      final tempText = '${data.temp.round()}°C';
      WeatherWidgetProvider.updateWidget(
        tempText,
        data.cityName,
        data.description,
        data.icon
      );
    } catch (e) {
      setState(() {
        errorMessage = 'Không thể lấy dữ liệu thời tiết: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final themeData = themeProvider.themeData;

        return Consumer<SettingsProvider>(
          builder: (context, settingsProvider, child) {
            final temperatureUnit = settingsProvider.temperatureUnit;
            final windSpeedUnit = settingsProvider.windSpeedUnit;
            final pressureUnit = settingsProvider.pressureUnit;
            final distanceUnit = settingsProvider.distanceUnit;

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
                  // Card thời tiết hiện tại
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 3.0,
                    ),
                    child: CurrentWeatherCard(
                      weather: weather,
                      themeData: themeData,
                      //temperature: temperature,
                      temperatureUnit: temperatureUnit,
                      onRefresh: _getCurrentLocation,
                    ),
                  ),

                  // Dự báo theo giờ
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 3.0,
                    ),
                    child: HourlyForecastWidget(
                      hourlyForecast: weather.hourlyForecast,
                      themeData: themeData,
                      temperatureUnit: temperatureUnit,
                    ),
                  ),

                  // Dự báo 7 ngày
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 3.0,
                    ),
                    child: DailyForecastWidget(
                      dailyForecast: weather.dailyForecast,
                      themeData: themeData,
                      temperatureUnit: temperatureUnit,
                    ),
                  ),

                  // Card các chỉ số phụ
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 3.0,
                    ),
                    child: WeatherDetailsCard(
                      weather: weather,
                      themeData: themeData,
                      temperatureUnit: temperatureUnit,
                      windSpeedUnit: windSpeedUnit,
                      pressureUnit: pressureUnit,
                      distanceUnit: distanceUnit,
                    ),
                  ),

                  // Card chất lượng không khí
                  // if (weather.airQuality != null)
                  //   Padding(
                  //     padding: const EdgeInsets.symmetric(
                  //       horizontal: 16.0,
                  //       vertical: 3.0,
                  //     ),
                  //     child: AirQualityCard(
                  //       airQuality: weather.airQuality!,
                  //       themeData: themeData,
                  //     ),
                  //   ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 3.0,
                    ),
                    child:
                        weather.airQuality != null
                            ? AirQualityCard(
                              airQuality: weather.airQuality!,
                              themeData: themeData,
                            )
                            : Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              color: themeData['backCardColor'].withOpacity(
                                0.7,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                    SizedBox(height: 16),
                                    Center(
                                      child: Text(
                                        'Không có dữ liệu chất lượng không khí',
                                        style: TextStyle(
                                          color: themeData['mainText'],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                  ),

                  // Card mặt trời mọc/lặn ở đây
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 3.0,
                    ),
                    child: SunriseSunsetCard(
                      weather: weather,
                      themeData: themeData,
                    ),
                  ),

                  // Bản đồ mini
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 8),
                    child: MiniWeatherMapWidget(height: 180),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}