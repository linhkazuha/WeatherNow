// // import 'package:flutter/material.dart';
// // import 'package:geolocator/geolocator.dart';
// // import 'package:geocoding/geocoding.dart';

// // class LocationProvider with ChangeNotifier {
// //   Position? _currentPosition;
// //   String _currentLocationName = 'Đang xác định...';

// //   Position? get currentPosition => _currentPosition;
// //   String get currentLocationName => _currentLocationName;

// //   Future<void> fetchCurrentLocation() async {
// //     bool serviceEnabled;
// //     LocationPermission permission;

// //     serviceEnabled = await Geolocator.isLocationServiceEnabled();
// //     if (!serviceEnabled) {
// //       _currentLocationName = 'Dịch vụ vị trí bị tắt';
// //       notifyListeners();
// //       return;
// //     }

// //     permission = await Geolocator.checkPermission();
// //     if (permission == LocationPermission.denied) {
// //       permission = await Geolocator.requestPermission();
// //       if (permission == LocationPermission.denied) {
// //         _currentLocationName = 'Quyền truy cập vị trí bị từ chối';
// //         notifyListeners();
// //         return;
// //       }
// //     }

// //     if (permission == LocationPermission.deniedForever) {
// //       _currentLocationName = 'Quyền truy cập vị trí bị từ chối vĩnh viễn';
// //       notifyListeners();
// //       return;
// //     }

// //     // try {
// //     //   _currentPosition = await Geolocator.getCurrentPosition(
// //     //     desiredAccuracy: LocationAccuracy.high,
// //     //   );

// //     //   if (_currentPosition != null) {
// //     //     List<Placemark> placemarks = await placemarkFromCoordinates(
// //     //       _currentPosition!.latitude,
// //     //       _currentPosition!.longitude,
// //     //     );

// //     //     if (placemarks.isNotEmpty) {
// //     //       Placemark placemark = placemarks.first;
// //     //       _currentLocationName =
// //     //           placemark.locality ??
// //     //           placemark.administrativeArea ??
// //     //           'Không xác định';
// //     //     } else {
// //     //       _currentLocationName = 'Không thể xác định vị trí';
// //     //     }
// //     //   } else {
// //     //     _currentLocationName = 'Không thể lấy vị trí';
// //     //   }
// //     // }
// //     try {
// //       List<Placemark> placemarks = await placemarkFromCoordinates(
// //         _currentPosition!.latitude,
// //         _currentPosition!.longitude,
// //       );

// //       if (placemarks.isNotEmpty) {
// //         Placemark placemark = placemarks.first;
// //         // Thêm log để kiểm tra dữ liệu placemark
// //         print("Placemark data: $placemark");
// //         print("Locality: ${placemark.locality}");
// //         print("Administrative area: ${placemark.administrativeArea}");

// //         // Thử sử dụng nhiều trường hơn để có tên địa điểm đầy đủ hơn
// //         _currentLocationName = [
// //           placemark.locality,
// //           placemark.subAdministrativeArea,
// //           placemark.administrativeArea,
// //         ].where((element) => element != null && element.isNotEmpty).join(", ");

// //         if (_currentLocationName.isEmpty) {
// //           _currentLocationName = 'Không xác định';
// //         }
// //       }
// //     } catch (e) {
// //       _currentLocationName = 'Lỗi khi lấy vị trí: $e';
// //     }

// //     notifyListeners();
// //   }
// // }

// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart';

// class LocationProvider with ChangeNotifier {
//   Position? _currentPosition;
//   String _currentLocationName = 'Đang xác định...';

//   Position? get currentPosition => _currentPosition;
//   String get currentLocationName => _currentLocationName;

//   Future<void> fetchCurrentLocation() async {
//     bool serviceEnabled;
//     LocationPermission permission;

//     // Check if location services are enabled
//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       _currentLocationName = 'Dịch vụ vị trí bị tắt';
//       notifyListeners();
//       return;
//     }

//     // Check and request location permissions
//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         _currentLocationName = 'Quyền truy cập vị trí bị từ chối';
//         notifyListeners();
//         return;
//       }
//     }

//     if (permission == LocationPermission.deniedForever) {
//       _currentLocationName = 'Quyền truy cập vị trí bị từ chối vĩnh viễn';
//       notifyListeners();
//       return;
//     }

//     try {
//       // Fetch current position with a timeout of 10 seconds
//       _currentPosition = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//         timeLimit: const Duration(seconds: 10), // Increase timeout to 10s
//       ).timeout(
//         const Duration(seconds: 10),
//         onTimeout: () {
//           throw TimeoutException(
//             'Không thể lấy vị trí trong thời gian cho phép',
//           );
//         },
//       );

//       if (_currentPosition != null) {
//         // Fetch placemarks to get location name
//         List<Placemark> placemarks = await placemarkFromCoordinates(
//           _currentPosition!.latitude,
//           _currentPosition!.longitude,
//         );

//         if (placemarks.isNotEmpty) {
//           Placemark placemark = placemarks.first;
//           print("Placemark data: $placemark"); // Debug log
//           print("Locality: ${placemark.locality}");
//           print("Administrative area: ${placemark.administrativeArea}");

//           // Build location name from available fields
//           _currentLocationName = [
//                 placemark.locality,
//                 placemark.subAdministrativeArea,
//                 placemark.administrativeArea,
//               ]
//               .where((element) => element != null && element.isNotEmpty)
//               .join(", ");

//           if (_currentLocationName.isEmpty) {
//             _currentLocationName = 'Không xác định';
//           }
//         } else {
//           _currentLocationName = 'Không thể xác định vị trí';
//         }
//       } else {
//         _currentLocationName = 'Không thể lấy vị trí';
//       }
//     } catch (e) {
//       print("Lỗi khi lấy vị trí: $e"); // Debug log
//       _currentLocationName = 'Lỗi khi lấy vị trí: $e';
//       _currentPosition = null; // Reset position on error
//     }

//     notifyListeners();
//   }
// }
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationProvider with ChangeNotifier {
  Position? _currentPosition;
  String _currentLocationName = 'Đang xác định...';
  static const int _maxRetries = 2; // Số lần thử lại
  static const Duration _retryDelay = Duration(
    seconds: 2,
  ); // Thời gian chờ giữa các lần thử

  Position? get currentPosition => _currentPosition;
  String get currentLocationName => _currentLocationName;

  Future<void> fetchCurrentLocation() async {
    // Thử lấy vị trí với nhiều lần thử
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          _currentLocationName = 'Dịch vụ vị trí bị tắt';
          return await _tryFallback();
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            _currentLocationName = 'Quyền truy cập vị trí bị từ chối';
            return await _tryFallback();
          }
        }

        if (permission == LocationPermission.deniedForever) {
          _currentLocationName = 'Quyền truy cập vị trí bị từ chối vĩnh viễn';
          return await _tryFallback();
        }

        // Thử lấy vị trí hiện tại với thời gian chờ 10 giây
        _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException(
              'Không thể lấy vị trí trong thời gian cho phép',
            );
          },
        );

        // Cập nhật tên vị trí
        await _updateLocationName();
        await _saveLastKnownLocation(); // Lưu vị trí thành công
        notifyListeners();
        return; // Thành công, thoát
      } catch (e) {
        print("Thử lần $attempt thất bại: $e");
        if (attempt < _maxRetries) {
          await Future.delayed(_retryDelay); // Chờ trước khi thử lại
          continue;
        }
        _currentLocationName = 'Lỗi khi lấy vị trí: $e';
        await _tryFallback(); // Tất cả lần thử thất bại, chuyển sang dự phòng
        return;
      }
    }
  }

  Future<void> _updateLocationName() async {
    if (_currentPosition == null) return;

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      ).timeout(const Duration(seconds: 5));

      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        print("Dữ liệu placemark: $placemark");
        print("Khu vực: ${placemark.locality}");
        print("Khu vực hành chính: ${placemark.administrativeArea}");

        _currentLocationName = [
          placemark.locality,
          placemark.subAdministrativeArea,
          placemark.administrativeArea,
        ].where((element) => element != null && element.isNotEmpty).join(", ");

        if (_currentLocationName.isEmpty) {
          _currentLocationName = 'Không xác định';
        }
      } else {
        _currentLocationName = 'Không thể xác định vị trí';
      }
    } catch (e) {
      print("Lỗi khi lấy tên vị trí: $e");
      _currentLocationName = 'Không thể xác định vị trí';
    }
  }

  Future<void> _tryFallback() async {
    // Bước 1: Thử tải vị trí đã lưu trước đó từ SharedPreferences
    bool success = await _loadLastKnownLocation();
    if (success && _currentPosition != null) {
      print("Sử dụng vị trí đã lưu: $_currentLocationName");
      notifyListeners();
      return;
    }

    // Bước 2: Dự phòng bằng vị trí mặc định (Hà Nội)
    _currentPosition = Position(
      latitude: 21.0285, // Tọa độ Hà Nội
      longitude: 105.8542,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
    _currentLocationName = 'Hà Nội';
    print("Sử dụng vị trí mặc định: $_currentLocationName");
    await _saveLastKnownLocation(); // Lưu vị trí mặc định
    notifyListeners();
  }

  Future<bool> _loadLastKnownLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble('last_latitude');
      final lon = prefs.getDouble('last_longitude');
      final name = prefs.getString('last_location_name');

      if (lat != null && lon != null && name != null) {
        _currentPosition = Position(
          latitude: lat,
          longitude: lon,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
        _currentLocationName = name;
        return true;
      }
      return false;
    } catch (e) {
      print("Lỗi khi tải vị trí đã lưu: $e");
      return false;
    }
  }

  Future<void> _saveLastKnownLocation() async {
    if (_currentPosition == null ||
        _currentLocationName == 'Đang xác định...') {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('last_latitude', _currentPosition!.latitude);
      await prefs.setDouble('last_longitude', _currentPosition!.longitude);
      await prefs.setString('last_location_name', _currentLocationName);
      print("Đã lưu vị trí: $_currentLocationName");
    } catch (e) {
      print("Lỗi khi lưu vị trí: $e");
    }
  }
}
