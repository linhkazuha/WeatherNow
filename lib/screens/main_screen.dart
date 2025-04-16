import 'package:flutter/material.dart';
import 'package:weather_app/screens/home_screen.dart';
import 'package:weather_app/screens/news/news_screen.dart';
import 'package:weather_app/screens/maps/weather_map_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  final List<String> _titles = [
    'Trang Chủ',
    'Bản Đồ',
    'Bạn có biết',
    'Cài Đặt',
  ];

  @override
  void initState() {
    super.initState();
    _initPages();
  }

  void _initPages() {
    _pages = [
      HomeScreen(),
      WeatherMapScreen(),
      NewsScreen(),
      _buildPlaceholderPage('Cài Đặt'),
    ];
  }

  Widget _buildPlaceholderPage(String title) {
    final Color primaryColorWithOpacity = Color(0xFF64B5F6).withOpacity(0.5);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_queue, size: 80, color: primaryColorWithOpacity),
          SizedBox(height: 16),
          Text(
            'Trang $title\nĐang phát triển',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_selectedIndex]), elevation: 0),
      drawer: _buildDrawer(),
      body: _pages[_selectedIndex],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4A6EA9), Color(0xFF6F96CF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top section with app logo and settings
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.home, color: Colors.white, size: 28),
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _selectedIndex = 0; // Trang chủ
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.settings, color: Colors.white, size: 28),
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _selectedIndex = 3; // Cài đặt
                        });
                      },
                    ),
                  ],
                ),
              ),

              // App logo and name
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.wb_sunny,
                              color: Colors.orange,
                              size: 24,
                            ),
                            Icon(
                              Icons.cloud,
                              color: Colors.lightBlue,
                              size: 32,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'WeatherNow',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 30),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TextField(
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Tìm vị trí',
                      hintStyle: TextStyle(color: Colors.white70),
                      prefixIcon: Icon(Icons.search, color: Colors.white),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Weather location cards
              _buildWeatherCard('Yên Lạc', '31', 'Chủ yếu có mây', '31° / 23°'),
              _buildWeatherCard('Hà Nội', '29', 'Chủ yếu có mây', '31° / 23°'),

              Spacer(),

              // "Did you know" button
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Center(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.lightbulb_outline, color: Colors.black54),
                    label: Text(
                      'Bạn có biết ?',
                      style: TextStyle(color: Colors.black54),
                    ),
                    onPressed: () {
                      // Show interesting weather fact
                      Navigator.pop(context);
                      setState(() {
                        _selectedIndex = 2; // Tìm hiểu thêm
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black54,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherCard(
    String location,
    String temperature,
    String condition,
    String range,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Card(
        color: Colors.white12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    condition,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  SizedBox(height: 2),
                  Text(
                    range,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    temperature,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '°',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
