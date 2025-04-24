import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/alerts/alerts_screen.dart';

class AlertStorageService {
  static const String _historyKey = 'alert_history';

  Future<void> saveAlertHistory(List<WeatherAlert> alerts) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> alertData =
        alerts.map((alert) {
          return {
            'id': alert.id,
            'title': alert.title,
            'description': alert.description,
            'severity': alert.severity.toString(),
            'location': alert.location,
            'timestamp': alert.timestamp.toIso8601String(),
            'expiryTime': alert.expiryTime.toIso8601String(),
          };
        }).toList();
    await prefs.setString(_historyKey, jsonEncode(alertData));
  }

  Future<List<WeatherAlert>> loadAlertHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyString = prefs.getString(_historyKey);
    if (historyString == null) return [];

    final List<dynamic> historyData = jsonDecode(historyString);
    return historyData.map((data) {
      return WeatherAlert(
        id: data['id'],
        title: data['title'],
        description: data['description'],
        severity: AlertSeverity.values.firstWhere(
          (e) => e.toString() == data['severity'],
          orElse: () => AlertSeverity.info,
        ),
        location: data['location'],
        timestamp: DateTime.parse(data['timestamp']),
        expiryTime: DateTime.parse(data['expiryTime']),
      );
    }).toList();
  }
}
