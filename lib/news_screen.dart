import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'detail_screen.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({Key? key}) : super(key: key);

  @override
  _NewsScreenState createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late final FirebaseFirestore _firestore;
  final List<String> _categories = ['Khí hậu', 'Hiện tượng', 'Thiên tai', 'Dự báo', 'Khác'];
  String _selectedCategory = 'Hiện tượng';
  bool _isFirebaseInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
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

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    
    return Column(
      children: [
        // Category chips
        Container(
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: _categories.map((category) {
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
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? primaryColor : Colors.grey.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        
        // News list
        Expanded(
          child: !_isFirebaseInitialized
              ? Center(child: CircularProgressIndicator())
              : StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('knowledge')
                      .where('type', isEqualTo: _getCategoryType(_selectedCategory))
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
                return ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
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
                            builder: (context) => DetailScreen(
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
        return 'Hiện tượng';
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
    Key? key,
    required this.title,
    required this.imageUrl,
    required this.description,
    required this.reference,
    required this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    
    // Lấy dòng đầu tiên của mô tả
    String firstLine = '';
    if (description.isNotEmpty) {
      List<String> lines = description.split('.');
      if (lines.isNotEmpty) {
        firstLine = lines[0] + '.';
      } else {
        firstLine = description;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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
                  child: imageUrl.isNotEmpty
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
                              child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey[500]),
                            );
                          },
                        )
                      : Container(
                          height: 160,
                          width: double.infinity,
                          color: Colors.grey[300],
                          child: Icon(Icons.image, size: 50, color: Colors.grey[500]),
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
                        Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 14,
                        ),
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
                )
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