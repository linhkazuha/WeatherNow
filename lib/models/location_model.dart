class SavedLocation {
  final String name;
  final DateTime savedAt;
  final double temp;
  final double tempMin;
  final double tempMax;
  final String description;
  final String icon;
  final double uvIndex; // Thêm chỉ số UV
  final double dewPoint; // Thêm điểm sương

  SavedLocation({
    required this.name,
    required this.savedAt,
    this.temp = 0,
    this.tempMin = 0,
    this.tempMax = 0,
    this.description = '',
    this.icon = '',
    this.uvIndex = 0, // Giá trị mặc định
    this.dewPoint = 0, // Giá trị mặc định
  });

  // Chuyển từ Map sang SavedLocation (để đọc từ SharedPreferences)
  factory SavedLocation.fromMap(Map<String, dynamic> map) {
    // Đảm bảo các giá trị số được chuyển đổi đúng thành double
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) {
        try {
          return double.parse(value);
        } catch (_) {
          return 0.0;
        }
      }
      return 0.0;
    }

    return SavedLocation(
      name: map['name'] ?? '',
      savedAt: map['savedAt'] != null 
          ? DateTime.parse(map['savedAt']) 
          : DateTime.now(),
      temp: parseDouble(map['temp']),
      tempMin: parseDouble(map['tempMin']),
      tempMax: parseDouble(map['tempMax']),
      description: map['description'] ?? '',
      icon: map['icon'] ?? '',
      uvIndex: parseDouble(map['uvIndex']), // Đọc chỉ số UV
      dewPoint: parseDouble(map['dewPoint']), // Đọc điểm sương
    );
  }

  // Chuyển từ SavedLocation sang Map (để lưu vào SharedPreferences)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'savedAt': savedAt.toIso8601String(),
      'temp': temp,
      'tempMin': tempMin,
      'tempMax': tempMax,
      'description': description,
      'icon': icon,
      'uvIndex': uvIndex, // Lưu chỉ số UV
      'dewPoint': dewPoint, // Lưu điểm sương
    };
  }
}