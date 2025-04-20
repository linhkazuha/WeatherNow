import 'package:flutter/material.dart';
import 'package:weather_app/models/location_model.dart';
import 'package:weather_app/providers/theme_provider.dart';
import 'package:weather_app/screens/home_screen.dart';
import 'package:weather_app/screens/news/news_screen.dart';
import 'package:weather_app/screens/maps/weather_map_screen.dart';
import 'package:weather_app/services/location_service.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  String _currentLocation = 'Trang Chủ';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final LocationService _locationService = LocationService();
  List<SavedLocation> _savedLocations = [];
  bool _isSearching = false;

  // Tạo key cho HomeScreen để truy cập từ bên ngoài
  final _homeScreenKey = GlobalKey<HomeScreenState>();

  late final List<Widget> _pages;

  // Danh sách tiêu đề động, sử dụng getter để luôn lấy giá trị mới nhất
  List<String> get _titles => [
    _currentLocation, // Sử dụng tên địa điểm thay vì "Trang Chủ" cố định
    'Bản Đồ',
    'Bạn có biết',
    'Cài Đặt',
  ];

  @override
  void initState() {
    super.initState();
    _initPages();
    _loadSavedLocations();
  }

  Future<void> _loadSavedLocations() async {
    final locations = await _locationService.getSavedLocations();
    setState(() {
      _savedLocations = locations;
    });
  }

  // Hàm cập nhật tên địa điểm khi có thay đổi từ HomeScreen
  void _updateCurrentLocation(String location) {
    setState(() {
      _currentLocation = location;
    });

    // Lưu địa điểm mới cùng với thông tin thời tiết
    _saveCurrentLocationWeather();
  }

  void _initPages() {
    _pages = [
      HomeScreen(
        key: _homeScreenKey,
        onLocationChanged: _updateCurrentLocation,
      ),
      WeatherMapScreen(),
      NewsScreen(),
      _buildPlaceholderPage('Cài Đặt'),
    ];
  }

  Widget _buildPlaceholderPage(String title) {
    // Lấy màu từ theme thay vì sử dụng giá trị cố định
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final Color primaryColorWithOpacity = themeProvider
            .themeData['auxiliaryText']
            .withOpacity(0.5);

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
                  color: themeProvider.themeData['mainText'],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Tìm kiếm địa điểm
  void _searchLocation(String query) {
    if (query.isEmpty) return;

    Navigator.pop(context); // Đóng drawer

    // Sử dụng HomeScreen để tìm kiếm
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0; // Chuyển về trang chủ
      });
    }

    // Truy cập đến HomeScreen và gọi phương thức tìm kiếm
    final homeScreenState = _homeScreenKey.currentState;
    if (homeScreenState != null) {
      homeScreenState.searchCity(query);
    }

    _searchController.clear();
  }

  // Xử lý khi chọn một địa điểm đã lưu
  void _onLocationSelected(String locationName) {
    Navigator.pop(context); // Đóng drawer

    // Sử dụng HomeScreen để tìm kiếm
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0; // Chuyển về trang chủ
      });
    }

    // Truy cập đến HomeScreen và gọi phương thức tìm kiếm
    final homeScreenState = _homeScreenKey.currentState;
    if (homeScreenState != null) {
      homeScreenState.searchCity(locationName);
    }
  }

  // Xóa địa điểm đã lưu
  void _removeLocation(String locationName) {
    _locationService.removeLocation(locationName).then((_) {
      _loadSavedLocations();
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xóa "$locationName" khỏi danh sách'),
          duration: Duration(seconds: 2),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final themeData = themeProvider.themeData;

        return Container(
          decoration: BoxDecoration(
            gradient: themeData['generalBackgroundColor'],
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text(
                _titles[_selectedIndex],
                style: TextStyle(color: themeData['mainText']),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              iconTheme: IconThemeData(color: themeData['mainText']),
            ),
            drawer: _buildDrawer(themeData),
            body: _pages[_selectedIndex],
          ),
        );
      },
    );
  }

  Widget _buildDrawer(Map<String, dynamic> themeData) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          color: themeData['sideBarColor'].withOpacity(0.5),
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
                      icon: Icon(
                        Icons.home,
                        color: themeData['mainText'],
                        size: 28,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _selectedIndex = 0; // Trang chủ
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.settings,
                        color: themeData['mainText'],
                        size: 28,
                      ),
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
                        color: themeData['mainText'],
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
                    color: themeData['searchFieldColor'],
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: themeData['mainText']),
                    decoration: InputDecoration(
                      hintText: 'Tìm vị trí',
                      hintStyle: TextStyle(
                        color: themeData['mainText'].withOpacity(0.7),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: themeData['mainText'],
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onSubmitted: _searchLocation,
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Tiêu đề danh sách đã lưu
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Text(
                  'Địa điểm đã lưu',
                  style: TextStyle(
                    color: themeData['mainText'],
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Weather location cards
              Expanded(
                child:
                    _savedLocations.isEmpty
                        ? Center(
                          child: Text(
                            'Chưa có địa điểm nào được lưu',
                            style: TextStyle(
                              color: themeData['mainText'].withOpacity(0.7),
                            ),
                          ),
                        )
                        : ListView.builder(
                          itemCount: _savedLocations.length,
                          padding: EdgeInsets.only(bottom: 20),
                          itemBuilder: (context, index) {
                            final location = _savedLocations[index];
                            return _buildLocationCard(location, themeData);
                          },
                        ),
              ),

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
                      backgroundColor: themeData['didyouknowButton'],
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

  Widget _buildLocationCard(
    SavedLocation location,
    Map<String, dynamic> themeData,
  ) {
    // Kiểm tra xem địa điểm này có đang hiển thị trên trang chủ không
    final bool isCurrentLocation = _currentLocation == location.name;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Stack(
        children: [
          Card(
            color: themeData['cardLocationColor'],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              // Thêm border nếu đây là địa điểm đang hiển thị
              side:
                  isCurrentLocation
                      ? BorderSide(
                        color: themeData['cardLocationBorderColor'],
                        width: 2,
                      )
                      : BorderSide.none,
            ),
            child: InkWell(
              onTap: () => _onLocationSelected(location.name),
              borderRadius: BorderRadius.circular(10),
              splashColor: Colors.white10,
              highlightColor: Colors.white10,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            location.name,
                            style: TextStyle(
                              color: themeData['mainText'],
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          // SỬA: Sử dụng trực tiếp dữ liệu từ location thay vì gọi Future
                          if (location.description.isNotEmpty)
                            Text(
                              location.description,
                              style: TextStyle(
                                color: themeData['auxiliaryText'],
                                fontSize: 14,
                              ),
                            ),
                          if (location.tempMin > -273 &&
                              location.tempMax >
                                  -273) // Kiểm tra có dữ liệu nhiệt độ không
                            Text(
                              '${location.tempMin.round()}° / ${location.tempMax.round()}°',
                              style: TextStyle(
                                color: themeData['auxiliaryText'],
                                fontSize: 14,
                              ),
                            ),
                          if (location.description.isEmpty &&
                              (location.tempMin <= -273 ||
                                  location.tempMax <= -273))
                            Text(
                              'Chưa có dữ liệu',
                              style: TextStyle(
                                color: themeData['auxiliaryText'],
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // SỬA: Sử dụng trực tiếp dữ liệu từ location thay vì gọi Future
                    location.temp > -273
                        ? Text(
                          '${location.temp.round()}°',
                          style: TextStyle(
                            color: themeData['mainText'],
                            fontSize: 42,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                        : Text(
                          '--°',
                          style: TextStyle(
                            color: themeData['mainText'],
                            fontSize: 42,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ),

          // Dấu 3 chấm ở góc trên bên phải
          Positioned(
            top: 8,
            right: 8,
            child: PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: themeData['mainText'],
                size: 20,
              ),
              color: Colors.white,
              padding: EdgeInsets.zero,
              onSelected: (value) {
                if (value == 'delete') {
                  _removeLocation(location.name);
                }
              },
              itemBuilder:
                  (BuildContext context) => <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('Xóa'),
                        ],
                      ),
                    ),
                  ],
            ),
          ),
        ],
      ),
    );
  }

  // Hàm lưu thông tin thời tiết của địa điểm hiện tại
  void _saveCurrentLocationWeather() {
    // Lưu địa điểm mới cùng thông tin thời tiết
    if (_homeScreenKey.currentState != null) {
      final weatherData = _homeScreenKey.currentState?.weatherData;
      if (weatherData != null) {
        _locationService
            .saveLocation(
              weatherData.cityName,
              temp: weatherData.temp,
              tempMin: weatherData.tempMin,
              tempMax: weatherData.tempMax,
              description: weatherData.description,
              icon: weatherData.icon,
            )
            .then((_) {
              _loadSavedLocations();
            });
      } else {
        // Nếu không có dữ liệu thời tiết, chỉ lưu tên địa điểm
        _locationService.saveLocation(_currentLocation).then((_) {
          _loadSavedLocations();
        });
      }
    } else {
      _locationService.saveLocation(_currentLocation).then((_) {
        _loadSavedLocations();
      });
    }
  }
}
