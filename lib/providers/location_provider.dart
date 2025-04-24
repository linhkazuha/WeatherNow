import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationProvider with ChangeNotifier {
  Position? _currentPosition;
  String _currentLocationName = 'Đang xác định...';

  Position? get currentPosition => _currentPosition;
  String get currentLocationName => _currentLocationName;

  Future<void> fetchCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _currentLocationName = 'Dịch vụ vị trí bị tắt';
      notifyListeners();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _currentLocationName = 'Quyền truy cập vị trí bị từ chối';
        notifyListeners();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _currentLocationName = 'Quyền truy cập vị trí bị từ chối vĩnh viễn';
      notifyListeners();
      return;
    }

    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (_currentPosition != null) {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark placemark = placemarks.first;
          _currentLocationName =
              placemark.locality ??
              placemark.administrativeArea ??
              'Không xác định';
        } else {
          _currentLocationName = 'Không thể xác định vị trí';
        }
      } else {
        _currentLocationName = 'Không thể lấy vị trí';
      }
    } catch (e) {
      _currentLocationName = 'Lỗi khi lấy vị trí: $e';
    }

    notifyListeners();
  }
}

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

//     // Kiểm tra quyền truy cập vị trí
//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       _currentLocationName = 'Dịch vụ vị trí bị tắt';
//       notifyListeners();
//       return;
//     }

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

//     // Lấy vị trí hiện tại
//     try {
//       _currentPosition = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );

//       // Chuyển đổi tọa độ thành địa chỉ
//       if (_currentPosition != null) {
//         List<Placemark> placemarks = await placemarkFromCoordinates(
//           _currentPosition!.latitude,
//           _currentPosition!.longitude,
//         );

//         if (placemarks.isNotEmpty) {
//           Placemark placemark = placemarks.first;
//           _currentLocationName =
//               placemark.locality ??
//               placemark.administrativeArea ??
//               'Không xác định';
//         } else {
//           _currentLocationName = 'Không thể xác định vị trí';
//         }
//       } else {
//         _currentLocationName = 'Không thể lấy vị trí';
//       }
//     } catch (e) {
//       _currentLocationName = 'Lỗi khi lấy vị trí: $e';
//     }

//     notifyListeners();
//   }
// }
