class WeatherData {
  final Map<String, dynamic> current;
  final List<dynamic> hourly;
  final List<dynamic> daily;

  WeatherData({
    required this.current,
    required this.hourly,
    required this.daily,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      current: json['current'],
      hourly: json['hourly'],
      daily: json['daily'],
    );
  }
}
