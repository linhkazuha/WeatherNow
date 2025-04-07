import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import '../models/weather_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  WeatherData? weatherData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadWeather();
  }

  Future<void> loadWeather() async {
    weatherData = await WeatherService().fetchWeather();
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dự báo thời tiết")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : weatherData == null
          ? const Center(child: Text("Không lấy được dữ liệu"))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text("🌤 Thời tiết hiện tại: ${weatherData!.current['weather'][0]['description']}"),
            Text("🌡 Nhiệt độ: ${weatherData!.current['temp']}°C"),
            const SizedBox(height: 20),
            const Text("📆 24 giờ tới:", style: TextStyle(fontWeight: FontWeight.bold)),
            ...weatherData!.hourly.take(24).map((h) => Text("${DateTime.fromMillisecondsSinceEpoch(h['dt'] * 1000)}: ${h['temp']}°C")),
            const SizedBox(height: 20),
            const Text("📅 8 ngày tiếp theo:", style: TextStyle(fontWeight: FontWeight.bold)),
            ...weatherData!.daily.take(8).map((d) => Text("${DateTime.fromMillisecondsSinceEpoch(d['dt'] * 1000)}: ${d['temp']['day']}°C")),
          ],
        ),
      ),
    );
  }
}
