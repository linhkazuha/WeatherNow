import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/location_model.dart';

class LocationService {
  static const String _locationsKey = 'saved_locations';
  
  // Lấy danh sách địa điểm đã lưu
  Future<List<SavedLocation>> getSavedLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final locationsJson = prefs.getStringList(_locationsKey) ?? [];
    
    try {
      return locationsJson
          .map((json) => SavedLocation.fromMap(jsonDecode(json)))
          .toList();
    } catch (e) {
      print('Lỗi khi đọc dữ liệu địa điểm: $e');
      return [];
    }
  }
  
  // Tìm địa điểm theo tên
  Future<SavedLocation?> getLocationByName(String locationName) async {
    final locations = await getSavedLocations();
    try {
      return locations.firstWhere((location) => location.name == locationName);
    } catch (e) {
      return null; // Không tìm thấy
    }
  }
  
  // Lưu địa điểm mới kèm thông tin thời tiết
  Future<void> saveLocation(String locationName, {
    double temp = 0,
    double tempMin = 0,
    double tempMax = 0,
    String description = '',
    String icon = '',
    double uvIndex = 0,  // Thêm tham số mới cho chỉ số UV
    double dewPoint = 0, // Thêm tham số mới cho điểm sương
  }) async {
    if (locationName.isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    final locationsJson = prefs.getStringList(_locationsKey) ?? [];
    
    // Kiểm tra xem địa điểm đã tồn tại chưa
    final locations = locationsJson
        .map((json) => SavedLocation.fromMap(jsonDecode(json)))
        .toList();
    
    // Nếu địa điểm đã tồn tại, xóa nó (để thêm lại vào đầu danh sách với dữ liệu mới)
    locations.removeWhere((location) => location.name == locationName);
    
    // Thêm địa điểm mới vào đầu danh sách kèm thông tin thời tiết
    locations.insert(
      0,
      SavedLocation(
        name: locationName,
        savedAt: DateTime.now(),
        temp: temp,
        tempMin: tempMin,
        tempMax: tempMax,
        description: description,
        icon: icon,
        uvIndex: uvIndex,  // Thêm chỉ số UV
        dewPoint: dewPoint, // Thêm điểm sương
      ),
    );
    
    // Giới hạn số lượng địa điểm lưu trữ (10 địa điểm)
    if (locations.length > 10) {
      locations.removeLast();
    }
    
    // Lưu danh sách mới
    try {
      final updatedLocationsJson = locations
          .map((location) => jsonEncode(location.toMap()))
          .toList();
      
      await prefs.setStringList(_locationsKey, updatedLocationsJson);
      print('Đã lưu thành công địa điểm: $locationName với nhiệt độ: $temp°C');
    } catch (e) {
      print('Lỗi khi lưu địa điểm: $e');
    }
  }
  
  // Xóa địa điểm
  Future<void> removeLocation(String locationName) async {
    final prefs = await SharedPreferences.getInstance();
    final locationsJson = prefs.getStringList(_locationsKey) ?? [];
    
    final locations = locationsJson
        .map((json) => SavedLocation.fromMap(jsonDecode(json)))
        .toList();
    
    locations.removeWhere((location) => location.name == locationName);
    
    final updatedLocationsJson = locations
        .map((location) => jsonEncode(location.toMap()))
        .toList();
    
    await prefs.setStringList(_locationsKey, updatedLocationsJson);
  }
}