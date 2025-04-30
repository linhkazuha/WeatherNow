import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weather_app/providers/settings_provider.dart';

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
            items: ['km', 'm'],
            labels: ['Ki-lô-mét (km)', 'Mét (m)'],
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
          SizedBox(height: 16),
          _buildSwitchTile(
            title: 'Widget',
            value: settingsProvider.isWidgetEnabled,
            onChanged: (value) {
              settingsProvider.setWidgetEnabled(value);
              onSettingsChanged();
            },
          ),

          _buildSwitchTile(
            title:
                'Thông báo :${settingsProvider.isNotificationEnabled ? 'Bật' : 'Tắt'}',
            value: settingsProvider.isNotificationEnabled,
            onChanged: (value) {
              settingsProvider.setNotificationEnabled(value);
              onSettingsChanged();
            },
          ),
          SizedBox(height: 24),

          // Tìm hiểu thêm
          ListTile(
            title: Text('Tìm hiểu thêm'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navigate to "Learn More" page
            },
          ),
          SizedBox(height: 24),

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
