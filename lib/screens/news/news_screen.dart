import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:weather_app/providers/theme_provider.dart';
import 'detail_screen.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  _NewsScreenState createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late final FirebaseFirestore _firestore;
  final List<String> _categories = [
    'Tất cả',
    'Khí hậu',
    'Hiện tượng',
    'Thiên tai',
    'Dự báo',
    'Khác',
  ];
  String _selectedCategory = 'Tất cả';
  bool _isFirebaseInitialized = false;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      _firestore = FirebaseFirestore.instance;
      setState(() {
        _isFirebaseInitialized = true;
      });
    } catch (e) {
      print("Firebase initialization error: $e");
    }
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
    
    // Cập nhật AppBar khi bắt đầu tìm kiếm
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scaffold = Scaffold.of(context);
      if (scaffold.hasAppBar) {
        try {
          scaffold.context.findAncestorStateOfType<ScaffoldState>()?.setState(() {});
        } catch (e) {
          print("Không thể cập nhật AppBar: $e");
        }
      }
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
    
    // Cập nhật AppBar khi dừng tìm kiếm
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scaffold = Scaffold.of(context);
      if (scaffold.hasAppBar) {
        try {
          scaffold.context.findAncestorStateOfType<ScaffoldState>()?.setState(() {});
        } catch (e) {
          print("Không thể cập nhật AppBar: $e");
        }
      }
    });
  }

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final themeData = themeProvider.themeData;

        // Cập nhật tiêu đề và actions của AppBar chính
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final scaffold = Scaffold.of(context);
          if (scaffold.hasAppBar) {
            try {
              // Thêm nút search vào AppBar
              if (_isSearching) {
                // Hiển thị SearchBar khi đang tìm kiếm
                final appBarWidget = AppBar(
                  title: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm hiện tượng thời tiết...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: themeData['mainText'].withOpacity(0.7)),
                    ),
                    style: TextStyle(color: themeData['mainText']),
                    onChanged: _handleSearch,
                  ),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  actions: [
                    IconButton(
                      icon: Icon(Icons.close, color: themeData['mainText']),
                      onPressed: _stopSearch
                    ),
                  ],
                );
              } else {
                // Hiển thị icon search khi không tìm kiếm
                final appBarWidget = AppBar(
                  title: Text(
                    'Bạn có biết',
                    style: TextStyle(color: themeData['mainText']),
                  ),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  actions: [
                    IconButton(
                      icon: Icon(Icons.search, color: themeData['mainText']),
                      onPressed: _startSearch,
                    ),
                  ],
                );
              }
              
              scaffold.context.findAncestorStateOfType<ScaffoldState>()?.setState(() {});
            } catch (e) {
              print("Không thể cập nhật AppBar: $e");
            }
          }
        });

        return Column(
          children: [
            // Thêm widget chọn giữa hiển thị bình thường hoặc tìm kiếm
            if (!_isSearching)
              // Thay thế phần hiện tại có icon tìm kiếm với một TextField đầy đủ
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: themeData['searchFieldColor'],
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    onTap: _startSearch,
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: 'Bạn đang tìm gì?',
                      hintStyle: TextStyle(
                        color: themeData['mainText'].withOpacity(0.5),
                      ),
                      prefixIcon: Icon(Icons.search, color: themeData['mainText'].withOpacity(0.6)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),

            if (_isSearching)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Bạn đang tìm gì?',
                    prefixIcon: Icon(Icons.search, color: themeData['mainText']),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.close, color: themeData['mainText']),
                      onPressed: _stopSearch,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: themeData['separateLine']),
                    ),
                    filled: true,
                    fillColor: themeData['searchFieldColor'],
                  ),
                  style: TextStyle(color: themeData['mainText']),
                  onChanged: _handleSearch,
                ),
              ),
            // Category chips
            Container(
              color: Colors.transparent,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children:
                      _categories.map((category) {
                        final isSelected = _selectedCategory == category;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedCategory = category;
                                });
                              }
                            },
                            backgroundColor: themeData['typeColor'],
                            selectedColor: themeData['auxiliaryText'],
                            labelStyle: TextStyle(
                              color: () {
                                if (isSelected) {
                                  final Color mainText = themeData['mainText'];
                                  final double luminance = (0.299 * mainText.red + 0.587 * mainText.green + 0.114 * mainText.blue);
                                  return luminance < 186 ? Color(0xFFEFF5F1) : Color(0xFF1E1F33);
                                } else {
                                  return themeData['mainText'];
                                }
                              }(),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color:
                                    isSelected
                                        ? themeData['typeBorderColor']
                                        : themeData['typeBorderColor'].withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),

            // News list
            Expanded(
              child:
                  !_isFirebaseInitialized
                      ? Center(child: CircularProgressIndicator(
                          color: themeData['mainText'],
                        ))
                      : StreamBuilder<QuerySnapshot>(
                        stream:
                            _selectedCategory == 'Tất cả'
                                ? _firestore.collection('knowledge').snapshots()
                                : _firestore
                                    .collection('knowledge')
                                    .where(
                                      'type',
                                      isEqualTo: _getCategoryType(
                                        _selectedCategory,
                                      ),
                                    )
                                    .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator(
                              color: themeData['mainText'],
                            ));
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Đã xảy ra lỗi: ${snapshot.error}',
                                style: TextStyle(color: themeData['mainText']),
                              ),
                            );
                          }

                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return Center(
                              child: Text(
                                'Không có dữ liệu hiện tượng thời tiết',
                                style: TextStyle(color: themeData['mainText']),
                              ),
                            );
                          }

                          try {
                            var docs = snapshot.data!.docs;

                            // Lọc theo từ khóa tìm kiếm nếu có - chỉ tìm theo name
                            if (_searchQuery.isNotEmpty) {
                              docs =
                                  docs.where((doc) {
                                    final data = doc.data() as Map<String, dynamic>;
                                    final name =
                                        (data['name'] ?? '')
                                            .toString()
                                            .toLowerCase();
                                    final query = _searchQuery.toLowerCase();
                                    return name.contains(query);
                                  }).toList();

                              if (docs.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.search_off,
                                        size: 64,
                                        color: themeData['auxiliaryText'],
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Không tìm thấy kết quả cho "$_searchQuery"',
                                        style: TextStyle(color: themeData['mainText']),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            }

                            return ListView.builder(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              itemCount: docs.length,
                              itemBuilder: (context, index) {
                                final doc = docs[index];
                                final data = doc.data() as Map<String, dynamic>;

                                return WeatherNewsCard(
                                  title: data['name'] ?? '',
                                  imageUrl: data['image_link'] ?? '',
                                  description: data['content'] ?? '',
                                  reference: data['reference'] ?? '',
                                  themeData: themeData,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => DetailScreen(
                                              title: data['name'] ?? '',
                                              imageUrl: data['image_link'] ?? '',
                                              description: data['content'] ?? '',
                                              reference: data['reference'] ?? '',
                                            ),
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          } catch (e) {
                            return Center(
                              child: Text(
                                'Lỗi khi hiển thị dữ liệu: $e',
                                style: TextStyle(color: themeData['mainText']),
                              ),
                            );
                          }
                        },
                      ),
            ),
          ],
        );
      }
    );
  }

  String _getCategoryType(String category) {
    switch (category) {
      case 'Tất cả':
        return 'Tất cả'; // Trả về tất cả, nhưng không dùng trong truy vấn
      case 'Khí hậu':
        return 'Khí hậu';
      case 'Hiện tượng':
        return 'Hiện tượng';
      case 'Thiên tai':
        return 'Thiên tai';
      case 'Dự báo':
        return 'Dự báo';
      case 'Khác':
        return 'Khác';
      default:
        return 'Tất cả';
    }
  }
}

class WeatherNewsCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final String description;
  final String reference;
  final Map<String, dynamic> themeData;
  final VoidCallback onTap;

  const WeatherNewsCard({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.description,
    required this.reference,
    required this.themeData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Lấy dòng đầu tiên của mô tả
    String firstLine = '';
    if (description.isNotEmpty) {
      List<String> lines = description.split('.');
      if (lines.isNotEmpty) {
        firstLine = '${lines[0]}.';
      } else {
        firstLine = description;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        color: themeData['didyouknowCardColor'],
        shadowColor: themeData['auxiliaryText'].withOpacity(0.2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  child:
                      imageUrl.isNotEmpty
                          ? Image.network(
                            imageUrl,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 160,
                                width: double.infinity,
                                color: themeData['cardLocationColor'],
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                  color: themeData['mainText'].withOpacity(0.5),
                                ),
                              );
                            },
                          )
                          : Container(
                            height: 160,
                            width: double.infinity,
                            color: themeData['cardLocationColor'],
                            child: Icon(
                              Icons.image,
                              size: 50,
                              color: themeData['mainText'].withOpacity(0.5),
                            ),
                          ),
                ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeData['mainText'],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Text(
                    firstLine,
                    style: TextStyle(
                      fontSize: 14,
                      color: themeData['auxiliaryText'],
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}