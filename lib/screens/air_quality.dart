class AirQuality {
  final int aqi; // Chỉ số chất lượng không khí (1-5)
  final Map<String, double> components; // Các chất ô nhiễm
  final DateTime timestamp; // Thời gian đo

  AirQuality({
    required this.aqi,
    required this.components,
    required this.timestamp,
  });

  factory AirQuality.fromJson(Map<String, dynamic> json) {
    final list = json['list'][0]; // Lấy dữ liệu mới nhất
    
    return AirQuality(
      aqi: list['main']['aqi'],
      components: {
        'co': list['components']['co'].toDouble(),
        'no': list['components']['no'].toDouble(),
        'no2': list['components']['no2'].toDouble(),
        'o3': list['components']['o3'].toDouble(),
        'so2': list['components']['so2'].toDouble(),
        'pm2_5': list['components']['pm2_5'].toDouble(),
        'pm10': list['components']['pm10'].toDouble(),
        'nh3': list['components']['nh3'].toDouble(),
      },
      timestamp: DateTime.fromMillisecondsSinceEpoch(list['dt'] * 1000),
    );
  }

  // Thông tin mô tả AQI
  String get aqiDescription {
    switch (aqi) {
      case 1:
        return 'Tốt';
      case 2:
        return 'Trung bình';
      case 3:
        return 'Trung bình kém';
      case 4:
        return 'Kém';
      case 5:
        return 'Rất kém';
      default:
        return 'Không xác định';
    }
  }

  // Màu hiển thị cho AQI
  String get aqiColor {
    switch (aqi) {
      case 1:
        return '#4CAF50'; // Xanh lá
      case 2:
        return '#FFC107'; // Vàng
      case 3:
        return '#FF9800'; // Cam
      case 4:
        return '#F44336'; // Đỏ
      case 5:
        return '#9C27B0'; // Tím
      default:
        return '#9E9E9E'; // Xám
    }
  }

  // Khuyến nghị sức khỏe dựa trên AQI
  String get healthRecommendation {
    switch (aqi) {
      case 1:
        return 'Chất lượng không khí tốt, thích hợp cho các hoạt động ngoài trời.';
      case 2:
        return 'Chất lượng không khí chấp nhận được. Người nhạy cảm nên hạn chế hoạt động kéo dài ngoài trời.';
      case 3:
        return 'Người nhạy cảm nên hạn chế hoạt động ngoài trời. Mọi người khác nên giảm hoạt động gắng sức ngoài trời.';
      case 4:
        return 'Người nhạy cảm nên tránh hoạt động ngoài trời. Mọi người khác nên hạn chế hoạt động ngoài trời.';
      case 5:
        return 'Tránh hoạt động ngoài trời. Người nhạy cảm nên ở trong nhà và lọc không khí nếu có thể.';
      default:
        return 'Không có dữ liệu.';
    }
  }
}