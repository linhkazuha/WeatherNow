import 'package:flutter/material.dart';
import 'news_screen.dart';

// Class chính để quản lý menu và các trang
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  
  // Danh sách các trang trong ứng dụng
  late final List<Widget> _pages;
  
  // Tiêu đề tương ứng với từng trang
  final List<String> _titles = [
    'Tìm hiểu về thời tiết',
    'Thời Tiết Hiện Tại',
    'Dự Báo',
    'Cài Đặt'
  ];
  
  @override
  void initState() {
    super.initState();
    _initPages();
  }
  
  void _initPages() {
    _pages = [
      NewsScreen(),
      _buildPlaceholderPage('Thời Tiết Hiện Tại'),
      _buildPlaceholderPage('Dự Báo Thời Tiết'),
      _buildPlaceholderPage('Cài Đặt'),
    ];
  }

  Widget _buildPlaceholderPage(String title) {
    // Sử dụng màu cố định thay vì Theme.of(context)
    final Color primaryColorWithOpacity = Color(0xFF64B5F6).withOpacity(0.5);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_queue,
            size: 80,
            color: primaryColorWithOpacity,
          ),
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
    final primaryColor = Theme.of(context).primaryColor;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        elevation: 0,
      ),
      drawer: _buildDrawer(),
      body: _pages[_selectedIndex],
    );
  }
  
  // Xây dựng drawer menu
  Widget _buildDrawer() {
    final primaryColor = Theme.of(context).primaryColor;
    
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor,
                  Color(0xFF90CAF9),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 32,
                  child: Icon(
                    Icons.cloud,
                    size: 36,
                    color: primaryColor,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Ứng Dụng Thời Tiết',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Thông tin & Dự báo',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(0, 'Tin Tức Thời Tiết', Icons.article),
          _buildDrawerItem(1, 'Thời Tiết Hiện Tại', Icons.cloud),
          _buildDrawerItem(2, 'Dự Báo Thời Tiết', Icons.calendar_today),
          Divider(color: Colors.grey.withOpacity(0.3), thickness: 1),
          _buildDrawerItem(3, 'Cài Đặt', Icons.settings),
          ListTile(
            leading: Icon(Icons.info_outline, color: Colors.grey[700]),
            title: Text(
              'Thông Tin Ứng Dụng',
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 15,
              ),
            ),
            onTap: () {
              // Hiển thị dialog về thông tin ứng dụng
              Navigator.pop(context);
              _showAboutDialog();
            },
          ),
        ],
      ),
    );
  }
  
  // Hàm tạo các mục trong drawer
  Widget _buildDrawerItem(int index, String title, IconData icon) {
    final primaryColor = Theme.of(context).primaryColor;
    final isSelected = _selectedIndex == index;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? primaryColor : Colors.grey[700],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? primaryColor : Colors.grey[800],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 15,
        ),
      ),
      selected: isSelected,
      selectedTileColor: primaryColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        Navigator.pop(context);
      },
    );
  }
  
  // Hiển thị dialog thông tin
  void _showAboutDialog() {
    final primaryColor = Theme.of(context).primaryColor;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: primaryColor),
            SizedBox(width: 8),
            Text('Thông Tin Ứng Dụng'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ứng Dụng Thời Tiết',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            SizedBox(height: 8),
            Text('Phiên bản 1.0.0'),
            SizedBox(height: 12),
            Text('Cung cấp thông tin thời tiết và tin tức cập nhật nhất về các hiện tượng thời tiết.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Đóng',
              style: TextStyle(color: primaryColor),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}