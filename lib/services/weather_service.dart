import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

class WeatherService {
  final double lat = 20.1624;
  final double lon = 106.0070;

  Future<WeatherData?> fetchWeather() async {
    final apiKey = dotenv.env['OPENWEATHER_API_KEY'];
    final url = Uri.parse(
      'https://api.openweathermap.org/data/3.0/onecall?lat=$lat&lon=$lon&exclude=minutely&units=metric&lang=vi&appid=$apiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return WeatherData.fromJson(jsonDecode(response.body));
      } else {
        print("Lỗi API: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Lỗi kết nối: $e");
      return null;
    }
  }
}
