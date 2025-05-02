import 'dart:convert';
import 'dart:typed_data';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/providers/settings_provider.dart';

class NotificationService {
  static const String weatherChannelKey = 'weather_channel';
  static const String weatherChannelName = 'Thông báo thời tiết';
  static const String weatherChannelDescription =
      'Thông báo dự báo thời tiết hàng ngày';

  // ID cố định cho thông báo thời tiết
  static const int dailyWeatherNotificationId = 1;
  static const int immediateWeatherNotificationId = 100;

  // Cờ và thời gian để kiểm soát việc cập nhật thông báo
  static bool _isUpdatingNotification = false;
  static String? _lastNotificationBody;
  static DateTime? _lastUpdateTime;
  static const int _minUpdateIntervalSeconds = 300; // 5 phút

  // Khởi tạo awesome_notifications
  static Future<void> initializeNotifications() async {
    await AwesomeNotifications().initialize(null, [
      NotificationChannel(
        channelKey: weatherChannelKey,
        channelName: weatherChannelName,
        channelDescription: weatherChannelDescription,
        defaultColor: Colors.blue,
        ledColor: Colors.blue,
        importance: NotificationImportance.High,
        defaultRingtoneType: DefaultRingtoneType.Notification,
        locked: false,
        enableVibration: true,
        playSound: true,
        vibrationPattern: Int64List.fromList([0, 200]),
      ),
    ], debug: true);

    // Đăng ký listener cho sự kiện thông báo
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
      onNotificationCreatedMethod: onNotificationCreatedMethod,
      onNotificationDisplayedMethod: onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: onDismissActionReceivedMethod,
    );
  }

  // Các phương thức callback cho awesome_notifications
  @pragma('vm:entry-point')
  static Future<void> onNotificationCreatedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    print('Thông báo đã được tạo: ${receivedNotification.title}');
  }

  @pragma('vm:entry-point')
  static Future<void> onNotificationDisplayedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    print('Thông báo đã được hiển thị: ${receivedNotification.title}');
    if (receivedNotification.channelKey == weatherChannelKey &&
        (receivedNotification.id == dailyWeatherNotificationId ||
            receivedNotification.id == immediateWeatherNotificationId)) {
      // Kiểm tra thời gian cập nhật gần nhất
      if (_lastUpdateTime != null &&
          DateTime.now().difference(_lastUpdateTime!).inSeconds <
              _minUpdateIntervalSeconds) {
        print('Bỏ qua cập nhật: quá sớm kể từ lần cập nhật trước');
        return;
      }
      await updateWeatherNotificationContent(receivedNotification.id!);
    }
  }

  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    print(
      'Người dùng tương tác với thông báo: ${receivedAction.buttonKeyPressed}',
    );
  }

  @pragma('vm:entry-point')
  static Future<void> onDismissActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    print('Người dùng đã bỏ qua thông báo: ${receivedAction.title}');
  }

  // Yêu cầu quyền thông báo
  static Future<bool> requestNotificationPermission() async {
    return await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  // Lập lịch thông báo dự báo thời tiết hàng ngày
  static Future<void> scheduleWeatherNotification(
    TimeOfDay notificationTime,
    String latitude,
    String longitude,
    SettingsProvider settingsProvider,
  ) async {
    // Hủy lịch thông báo cũ
    await cancelScheduledNotifications();

    // Lưu vị trí
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notification_latitude', latitude);
    await prefs.setString('notification_longitude', longitude);

    // Kiểm tra thông báo đã lên lịch
    if (await isNotificationScheduled()) {
      print('Thông báo đã được lên lịch, bỏ qua...');
      return;
    }

    // Lập lịch thông báo hàng ngày
    bool success = await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: dailyWeatherNotificationId,
        channelKey: weatherChannelKey,
        title: 'Dự báo thời tiết hôm nay',
        body: 'Đang cập nhật thông tin thời tiết...',
        notificationLayout: NotificationLayout.Default,
        category: NotificationCategory.Alarm,
      ),
      schedule: NotificationCalendar(
        hour: notificationTime.hour,
        minute: notificationTime.minute,
        second: 0,
        millisecond: 0,
        repeats: true,
        preciseAlarm: true,
      ),
    );

    print(
      success
          ? 'Đã lên lịch thông báo lúc ${notificationTime.hour}:${notificationTime.minute}'
          : 'Không thể lên lịch thông báo',
    );
  }

  // Hủy tất cả các thông báo đã lên lịch
  static Future<void> cancelScheduledNotifications() async {
    await AwesomeNotifications().cancelAllSchedules();
    await AwesomeNotifications().cancel(dailyWeatherNotificationId);
    await AwesomeNotifications().cancel(immediateWeatherNotificationId);
    _lastNotificationBody = null;
    _lastUpdateTime = null;
    print('Đã hủy tất cả các thông báo đã lên lịch');
  }

  // Cập nhật nội dung thông báo thời tiết
  static Future<void> updateWeatherNotificationContent(
    int notificationId,
  ) async {
    if (_isUpdatingNotification) {
      print('Đang cập nhật thông báo, bỏ qua...');
      return;
    }

    _isUpdatingNotification = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final latitude = prefs.getString('notification_latitude') ?? '21.0278';
      final longitude = prefs.getString('notification_longitude') ?? '105.8342';

      print('Lấy dữ liệu thời tiết cho: $latitude, $longitude');

      // Lấy dữ liệu thời tiết
      final weatherData = await getCurrentWeather(latitude, longitude);
      if (weatherData == null) {
        print('Không thể lấy dữ liệu thời tiết');
        return;
      }

      print('Dữ liệu thời tiết nhận được: ${weatherData['name']}');

      // Tạo nội dung thông báo
      String notificationBody = _buildWeatherNotificationBody(weatherData);
      String notificationTitle = 'Thời tiết hôm nay tại ${weatherData['name']}';

      // So sánh nội dung mới và cũ
      if (_lastNotificationBody != null &&
          _lastNotificationBody!.trim() == notificationBody.trim()) {
        print('Nội dung không thay đổi, bỏ qua cập nhật');
        return;
      }

      // Cập nhật nội dung và thời gian
      _lastNotificationBody = notificationBody;
      _lastUpdateTime = DateTime.now();

      // Hủy thông báo cũ trước khi tạo mới
      await AwesomeNotifications().cancel(notificationId);

      // Tạo thông báo mới
      bool success = await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId,
          channelKey: weatherChannelKey,
          title: notificationTitle,
          body: notificationBody,
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Alarm,
          autoDismissible: true,
          showWhen: true,
          wakeUpScreen: false,
          displayOnForeground: true,
          displayOnBackground: true,
        ),
      );

      print(
        success
            ? 'Đã cập nhật thông báo: $notificationBody'
            : 'Không thể cập nhật thông báo',
      );
    } catch (e) {
      print('Lỗi cập nhật thông báo: $e');
    } finally {
      _isUpdatingNotification = false;
    }
  }

  // Xây dựng nội dung thông báo
  static String _buildWeatherNotificationBody(
    Map<String, dynamic> weatherData,
  ) {
    final temp = weatherData['main']['temp'].round();
    final description = weatherData['weather'][0]['description'];
    final humidity = weatherData['main']['humidity'];
    final windSpeed = weatherData['wind']['speed'];
    final feelsLike = weatherData['main']['feels_like'].round();

    return 'Nhiệt độ: ${temp}°C, cảm giác như ${feelsLike}°C. $description. Độ ẩm: $humidity%. Gió: ${windSpeed}m/s';
  }

  // Kiểm tra quyền thông báo
  static Future<bool> checkNotificationPermission() async {
    return await AwesomeNotifications().isNotificationAllowed();
  }

  // Mở cài đặt thông báo
  static Future<void> openNotificationSettings() async {
    await AwesomeNotifications().showNotificationConfigPage();
  }

  // Gửi thông báo ngay lập tức
  static Future<void> sendImmediateWeatherNotification() async {
    final prefs = await SharedPreferences.getInstance();
    // ignore: unused_local_variable
    final latitude = prefs.getString('notification_latitude') ?? '21.0278';
    // ignore: unused_local_variable
    final longitude = prefs.getString('notification_longitude') ?? '105.8342';

    // Hủy thông báo trước đó
    await AwesomeNotifications().cancel(immediateWeatherNotificationId);

    // Tạo thông báo
    bool success = await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: immediateWeatherNotificationId,
        channelKey: weatherChannelKey,
        title: 'Kiểm tra thông báo thời tiết',
        body: 'Đang cập nhật thông tin thời tiết...',
        notificationLayout: NotificationLayout.Default,
        category: NotificationCategory.Alarm,
      ),
    );

    print(
      success
          ? 'Đã gửi thông báo kiểm tra'
          : 'Không thể gửi thông báo kiểm tra',
    );
  }

  // Lấy dữ liệu thời tiết hiện tại
  static Future<Map<String, dynamic>?> getCurrentWeather(
    String lat,
    String lon,
  ) async {
    try {
      final apiKey = dotenv.env['OPENWEATHER_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        print('API key không được cấu hình');
        return null;
      }

      final response = await http
          .get(
            Uri.parse(
              'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=vi',
            ),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Lỗi API: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Lỗi kết nối: $e');
      return null;
    }
  }

  // Lấy dự báo thời tiết 5 ngày
  static Future<Map<String, dynamic>?> getForecast(
    String lat,
    String lon,
  ) async {
    try {
      final apiKey = dotenv.env['OPENWEATHER_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        print('API key không được cấu hình');
        return null;
      }

      final response = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=vi',
        ),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Lỗi API: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Lỗi kết nối: $e');
      return null;
    }
  }

  // Chuyển đổi đơn vị nhiệt độ
  static String formatTemperature(double tempC, String unit) {
    if (unit == 'F') {
      return '${(tempC * 9 / 5 + 32).round()}°F';
    }
    return '${tempC.round()}°C';
  }

  // Chuyển đổi đơn vị tốc độ gió
  static String formatWindSpeed(double speedMS, String unit) {
    switch (unit) {
      case 'km/h':
        return '${(speedMS * 3.6).toStringAsFixed(1)} km/h';
      case 'mph':
        return '${(speedMS * 2.237).toStringAsFixed(1)} mph';
      case 'kn':
        return '${(speedMS * 1.944).toStringAsFixed(1)} kn';
      case 'bft':
        if (speedMS < 0.5) return '0 bft';
        if (speedMS < 1.6) return '1 bft';
        if (speedMS < 3.4) return '2 bft';
        if (speedMS < 5.5) return '3 bft';
        if (speedMS < 8.0) return '4 bft';
        if (speedMS < 10.8) return '5 bft';
        if (speedMS < 13.9) return '6 bft';
        if (speedMS < 17.2) return '7 bft';
        if (speedMS < 20.8) return '8 bft';
        if (speedMS < 24.5) return '9 bft';
        if (speedMS < 28.5) return '10 bft';
        if (speedMS < 32.7) return '11 bft';
        return '12+ bft';
      default:
        return '${speedMS.toStringAsFixed(1)} m/s';
    }
  }

  // Chuyển đổi đơn vị áp suất
  static String formatPressure(double pressureHpa, String unit) {
    switch (unit) {
      case 'mm Hg':
        return '${(pressureHpa * 0.75006).round()} mm Hg';
      case 'inHg':
        return '${(pressureHpa * 0.02953).toStringAsFixed(2)} inHg';
      case 'Kpa':
        return '${(pressureHpa / 10).toStringAsFixed(1)} Kpa';
      case 'mbar':
        return '$pressureHpa mbar';
      default:
        return '$pressureHpa hPa';
    }
  }

  // Chuyển đổi đơn vị khoảng cách
  static String formatDistance(double distanceM, String unit) {
    if (unit == 'km') {
      return '${(distanceM / 1000).toStringAsFixed(1)} km';
    }
    return '${distanceM.round()} m';
  }

  // Kiểm tra thông báo đã lên lịch
  static Future<bool> isNotificationScheduled() async {
    final List<NotificationModel> scheduledNotifications =
        await AwesomeNotifications().listScheduledNotifications();

    return scheduledNotifications.any(
      (notification) => notification.content?.id == dailyWeatherNotificationId,
    );
  }
}
