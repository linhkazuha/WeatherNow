import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
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
    // Cập nhật tiêu đề của AppBar trong MainScreen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Scaffold.of(
        context,
      ).context.findAncestorStateOfType<ScaffoldState>()?.setState(() {});
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    // Cập nhật tiêu đề và actions của AppBar chính nếu cần
    if (_isSearching) {
      // Thêm tính năng tìm kiếm vào AppBar chính (được thêm sau từ MainScreen)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final scaffold = Scaffold.of(context);
        if (scaffold.hasAppBar) {
          final appBarWidget = AppBar(
            title: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm hiện tượng thời tiết...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.white70),
              ),
              style: TextStyle(color: Colors.white),
              onChanged: _handleSearch,
            ),
            actions: [
              IconButton(icon: Icon(Icons.close), onPressed: _stopSearch),
            ],
          );
          // Cố gắng cập nhật AppBar
          try {
            scaffold.context.findAncestorStateOfType<ScaffoldState>()?.setState(
              () {},
            );
          } catch (e) {
            print("Không thể cập nhật AppBar: $e");
          }
        }
      });
    }

    return Column(
      children: [
        // Thêm widget chọn giữa hiển thị bình thường hoặc tìm kiếm
        if (!_isSearching)
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.search, color: primaryColor),
                  onPressed: _startSearch,
                ),
              ],
            ),
          ),

        if (_isSearching)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm hiện tượng thời tiết...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: Icon(Icons.close),
                  onPressed: _stopSearch,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: _handleSearch,
            ),
          ),

        // Category chips
        Container(
          color: Colors.white,
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
                        backgroundColor: Colors.grey[100],
                        selectedColor: primaryColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[800],
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color:
                                isSelected
                                    ? primaryColor
                                    : Colors.grey.withOpacity(0.2),
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
                  ? Center(child: CircularProgressIndicator())
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
                        return Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Đã xảy ra lỗi: ${snapshot.error}'),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text('Không có dữ liệu hiện tượng thời tiết'),
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
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Không tìm thấy kết quả cho "$_searchQuery"',
                                    style: TextStyle(color: Colors.grey[600]),
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
                          child: Text('Lỗi khi hiển thị dữ liệu: $e'),
                        );
                      }
                    },
                  ),
        ),
      ],
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
  final VoidCallback onTap;

  const WeatherNewsCard({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.description,
    required this.reference,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

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
        shadowColor: primaryColor.withOpacity(0.2),
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
                                color: Colors.grey[300],
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                  color: Colors.grey[500],
                                ),
                              );
                            },
                          )
                          : Container(
                            height: 160,
                            width: double.infinity,
                            color: Colors.grey[300],
                            child: Icon(
                              Icons.image,
                              size: 50,
                              color: Colors.grey[500],
                            ),
                          ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Chi tiết',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
                      color: Colors.grey[800],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Text(
                    firstLine,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
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
