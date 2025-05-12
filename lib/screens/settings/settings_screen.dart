import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weather_app/providers/settings_provider.dart';
import 'package:weather_app/services/notification_service.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback onSettingsChanged;

  const SettingsScreen({super.key, required this.onSettingsChanged});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      //appBar: AppBar(title: Text('Cài Đặt'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Đơn vị
          Text(
            'Đơn vị',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          _buildDropdownTile(
            title: 'Nhiệt độ',
            value: settingsProvider.temperatureUnit,
            items: ['C', 'F'],
            labels: ['Độ C (°C)', 'Độ F (°F)'],
            onChanged: (value) {
              settingsProvider.setTemperatureUnit(value!);
              onSettingsChanged();
            },
          ),
          _buildDropdownTile(
            title: 'Gió',
            value: settingsProvider.windSpeedUnit,
            items: ['m/s', 'km/h', 'mph', 'bft', 'kn'],
            labels: ['m/s', 'km/h', 'mph', 'bft', 'kn'],
            onChanged: (value) {
              settingsProvider.setWindSpeedUnit(value!);
              onSettingsChanged();
            },
          ),
          _buildDropdownTile(
            title: 'Áp suất',
            value: settingsProvider.pressureUnit,
            items: ['hPa', 'mm Hg', 'mbar', 'inHg', 'Kpa'],
            labels: ['hPa', 'mm Hg', 'mbar', 'inHg', 'Kpa'],
            onChanged: (value) {
              settingsProvider.setPressureUnit(value!);
              onSettingsChanged();
            },
          ),
          _buildDropdownTile(
            title: 'Khoảng cách',
            value: settingsProvider.distanceUnit,
            items: ['m', 'km'],
            labels: ['Mét (m)', 'Ki-lô-mét (km)'],
            onChanged: (value) {
              settingsProvider.setDistanceUnit(value!);
              onSettingsChanged();
            },
          ),
          SizedBox(height: 24),

          // Cài đặt khác
          Text(
            'Cài đặt khác',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          // SizedBox(height: 16),
          // _buildSwitchTile(
          //   title: 'Widget',
          //   value: settingsProvider.isWidgetEnabled,
          //   onChanged: (value) {
          //     settingsProvider.setWidgetEnabled(value);
          //     onSettingsChanged();
          //   },
          // ),
          // Phần thông báo
          ExpansionTile(
            title: Text('Thông báo thời tiết'),
            initiallyExpanded: true,
            children: [
              _buildSwitchTile(
                title: 'Bật thông báo thời tiết hàng ngày',
                value: settingsProvider.isNotificationEnabled,
                onChanged: (value) async {
                  // Yêu cầu quyền thông báo nếu chưa được cấp
                  if (value) {
                    final hasPermission =
                        await NotificationService.requestNotificationPermission();
                    if (!hasPermission) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Vui lòng cấp quyền thông báo trong cài đặt ứng dụng',
                          ),
                          action: SnackBarAction(
                            label: 'Mở cài đặt',
                            onPressed: () {
                              NotificationService.openNotificationSettings();
                            },
                          ),
                        ),
                      );
                      return;
                    }
                  }

                  await settingsProvider.setNotificationEnabled(value);
                  onSettingsChanged();
                },
              ),

              // Thời gian thông báo
              Visibility(
                visible: settingsProvider.isNotificationEnabled,
                child: ListTile(
                  title: Text('Thời gian nhận thông báo'),
                  subtitle: Text(
                    '${settingsProvider.notificationTime.format(context)}',
                  ),
                  trailing: Icon(Icons.access_time),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: settingsProvider.notificationTime,
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            dialogBackgroundColor: Colors.grey[850]!
                                .withOpacity(0.95), // Nền tối, hơi xám
                            timePickerTheme: TimePickerThemeData(
                              backgroundColor: Colors.grey[850]!.withOpacity(
                                0.95,
                              ),
                              dialBackgroundColor: Colors.grey[800]!,
                              hourMinuteTextColor: Colors.white,
                              dialTextColor: Colors.grey[300],
                              entryModeIconColor: Colors.teal[300],
                              hourMinuteColor: Colors.grey[700]!,
                              dayPeriodTextColor: Colors.white,
                              dayPeriodColor: Colors.grey[800]!,
                            ),
                            colorScheme: ColorScheme.dark(
                              primary: Colors.teal[400]!,
                              onPrimary: Colors.black,
                              surface: Colors.grey[850]!,
                              onSurface:
                                  Colors
                                      .white, // Đổi thành trắng để các nhãn nổi bật
                            ),
                            textTheme: TextTheme(
                              // Tùy chỉnh thêm nếu cần, ví dụ cho tiêu đề "Select time"
                              titleMedium: TextStyle(
                                color:
                                    Colors
                                        .white, // "Select time" sẽ có màu trắng
                                fontWeight: FontWeight.w500,
                              ),
                              bodyMedium: TextStyle(
                                color:
                                    Colors
                                        .grey[200], // Các nhãn khác như "Hour", "Minute"
                              ),
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );

                    if (picked != null) {
                      await settingsProvider.setNotificationTime(picked);
                      onSettingsChanged();
                    }
                  },
                ),
              ),

              // Thông tin thông báo thời tiết
              Visibility(
                visible: settingsProvider.isNotificationEnabled,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Bạn sẽ nhận được thông báo thời tiết hàng ngày tại thời gian đã chọn. '
                    'Thông báo sẽ hiển thị thông tin thời tiết tại vị trí hiện tại của bạn.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  ),
                ),
              ),
            ],
          ),

          // _buildSwitchTile(
          //   title:
          //       'Thông báo: ${settingsProvider.isNotificationEnabled ? 'Bật' : 'Tắt'}',
          //   value: settingsProvider.isNotificationEnabled,
          //   onChanged: (value) {
          //     settingsProvider.setNotificationEnabled(value);
          //     onSettingsChanged();
          //   },
          // ),

          // ListTile(
          //   title: Text('Thời gian nhận thông báo'),
          //   subtitle: Text(
          //     '${settingsProvider.notificationTime.format(context)}',
          //   ),
          //   trailing: Icon(Icons.access_time),
          //   onTap: () async {
          //     final picked = await showTimePicker(
          //       context: context,
          //       initialTime: settingsProvider.notificationTime,
          //       builder: (context, child) {
          //         return Theme(
          //           data: Theme.of(context).copyWith(
          //             dialogBackgroundColor: Colors.grey[850]!.withOpacity(
          //               0.95,
          //             ), // Nền tối, hơi xám
          //             timePickerTheme: TimePickerThemeData(
          //               backgroundColor: Colors.grey[850]!.withOpacity(0.95),
          //               dialBackgroundColor: Colors.grey[800]!,
          //               hourMinuteTextColor: Colors.white,
          //               dialTextColor: Colors.grey[300],
          //               entryModeIconColor: Colors.teal[300],
          //               hourMinuteColor: Colors.grey[700]!,
          //               dayPeriodTextColor: Colors.white,
          //               dayPeriodColor: Colors.grey[800]!,
          //             ),
          //             colorScheme: ColorScheme.dark(
          //               primary: Colors.teal[400]!,
          //               onPrimary: Colors.black,
          //               surface: Colors.grey[850]!,
          //               onSurface:
          //                   Colors.white, // Đổi thành trắng để các nhãn nổi bật
          //             ),
          //             textTheme: TextTheme(
          //               // Tùy chỉnh thêm nếu cần, ví dụ cho tiêu đề "Select time"
          //               titleMedium: TextStyle(
          //                 color: Colors.white, // "Select time" sẽ có màu trắng
          //                 fontWeight: FontWeight.w500,
          //               ),
          //               bodyMedium: TextStyle(
          //                 color:
          //                     Colors
          //                         .grey[200], // Các nhãn khác như "Hour", "Minute"
          //               ),
          //             ),
          //           ),
          //           child: child!,
          //         );
          //       },
          //     );

          //     if (picked != null) {
          //       settingsProvider.setNotificationTime(picked);
          //       onSettingsChanged();
          //     }
          //   },
          // ),
          SizedBox(height: 24),

          // // Tìm hiểu thêm
          // ListTile(
          //   title: Text('Tìm hiểu thêm'),
          //   trailing: Icon(Icons.arrow_forward_ios),
          //   onTap: () {
          //     // Navigate to "Learn More" page
          //   },
          // ),
          // SizedBox(height: 24),

          // Khôi phục cài đặt mặc định
          ElevatedButton(
            onPressed: () {
              settingsProvider.resetToDefault();
              onSettingsChanged();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã khôi phục cài đặt mặc định')),
              );
            },
            child: Text('Khôi phục cài đặt mặc định'),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String value,
    required List<String> items,
    required List<String> labels,
    required ValueChanged<String?> onChanged,
  }) {
    return ListTile(
      title: Text(title),
      trailing: DropdownButton<String>(
        value: value,
        items: List.generate(
          items.length,
          (index) =>
              DropdownMenuItem(value: items[index], child: Text(labels[index])),
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }
}
