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

//     // try {
//     //   _currentPosition = await Geolocator.getCurrentPosition(
//     //     desiredAccuracy: LocationAccuracy.high,
//     //   );

//     //   if (_currentPosition != null) {
//     //     List<Placemark> placemarks = await placemarkFromCoordinates(
//     //       _currentPosition!.latitude,
//     //       _currentPosition!.longitude,
//     //     );

//     //     if (placemarks.isNotEmpty) {
//     //       Placemark placemark = placemarks.first;
//     //       _currentLocationName =
//     //           placemark.locality ??
//     //           placemark.administrativeArea ??
//     //           'Không xác định';
//     //     } else {
//     //       _currentLocationName = 'Không thể xác định vị trí';
//     //     }
//     //   } else {
//     //     _currentLocationName = 'Không thể lấy vị trí';
//     //   }
//     // }
//     try {
//       List<Placemark> placemarks = await placemarkFromCoordinates(
//         _currentPosition!.latitude,
//         _currentPosition!.longitude,
//       );

//       if (placemarks.isNotEmpty) {
//         Placemark placemark = placemarks.first;
//         // Thêm log để kiểm tra dữ liệu placemark
//         print("Placemark data: $placemark");
//         print("Locality: ${placemark.locality}");
//         print("Administrative area: ${placemark.administrativeArea}");

//         // Thử sử dụng nhiều trường hơn để có tên địa điểm đầy đủ hơn
//         _currentLocationName = [
//           placemark.locality,
//           placemark.subAdministrativeArea,
//           placemark.administrativeArea,
//         ].where((element) => element != null && element.isNotEmpty).join(", ");

//         if (_currentLocationName.isEmpty) {
//           _currentLocationName = 'Không xác định';
//         }
//       }
//     } catch (e) {
//       _currentLocationName = 'Lỗi khi lấy vị trí: $e';
//     }

//     notifyListeners();
//   }
// }

import 'dart:async';

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

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _currentLocationName = 'Dịch vụ vị trí bị tắt';
      notifyListeners();
      return;
    }

    // Check and request location permissions
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
      // Fetch current position with a timeout of 10 seconds
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10), // Increase timeout to 10s
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
            'Không thể lấy vị trí trong thời gian cho phép',
          );
        },
      );

      if (_currentPosition != null) {
        // Fetch placemarks to get location name
        List<Placemark> placemarks = await placemarkFromCoordinates(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark placemark = placemarks.first;
          print("Placemark data: $placemark"); // Debug log
          print("Locality: ${placemark.locality}");
          print("Administrative area: ${placemark.administrativeArea}");

          // Build location name from available fields
          _currentLocationName = [
                placemark.locality,
                placemark.subAdministrativeArea,
                placemark.administrativeArea,
              ]
              .where((element) => element != null && element.isNotEmpty)
              .join(", ");

          if (_currentLocationName.isEmpty) {
            _currentLocationName = 'Không xác định';
          }
        } else {
          _currentLocationName = 'Không thể xác định vị trí';
        }
      } else {
        _currentLocationName = 'Không thể lấy vị trí';
      }
    } catch (e) {
      print("Lỗi khi lấy vị trí: $e"); // Debug log
      _currentLocationName = 'Lỗi khi lấy vị trí: $e';
      _currentPosition = null; // Reset position on error
    }

    notifyListeners();
  }
}
