import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:weather_app/providers/theme_provider.dart';

class DetailScreen extends StatelessWidget {
  final String title;
  final String imageUrl;
  final String description;
  final String reference;

  const DetailScreen({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.description,
    required this.reference,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final themeData = themeProvider.themeData;
        
        // Bọc toàn bộ Scaffold trong Container có gradient
        return Container(
          // Sử dụng gradient từ theme_provider nếu có
          decoration: BoxDecoration(
            gradient: themeData['generalBackgroundColor'],
          ),
          child: Scaffold(
            // Đặt backgroundColor thành transparent để gradient có thể hiển thị
            backgroundColor: Colors.transparent,
            // Sửa AppBar để có nền trong suốt
            appBar: AppBar(
              title: Text(
                title, 
                maxLines: 1, 
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: themeData['mainText']),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              iconTheme: IconThemeData(color: themeData['mainText']),
            ),
            // Body không cần bọc trong Container có gradient nữa
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ảnh
                  Stack(
                    children: [
                      imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              height: 220,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 220,
                                  width: double.infinity,
                                  color: themeData['backCardColor'],
                                  child: Icon(
                                    Icons.image_not_supported, 
                                    size: 80, 
                                    color: themeData['mainText'].withOpacity(0.5),
                                  ),
                                );
                              },
                            )
                          : Container(
                              height: 220,
                              width: double.infinity,
                              color: themeData['backCardColor'],
                              child: Icon(
                                Icons.image, 
                                size: 80, 
                                color: themeData['mainText'].withOpacity(0.5),
                              ),
                            ),
                      // Gradient overlay cho text visibility
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.5),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Title trên ảnh
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 3.0,
                                color: Colors.black.withOpacity(0.8),
                                offset: Offset(1.0, 1.0),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Nội dung
                  Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: themeData['didyouknowCardColor'].withOpacity(0.85),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 16, 
                            height: 1.6,
                            color: themeData['mainText'],
                          ),
                        ),
                        if (reference.isNotEmpty) ...[
                          SizedBox(height: 20),
                          Divider(color: themeData['separateLine'].withOpacity(0.3), thickness: 1),
                          SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.link, size: 16, color: themeData['auxiliaryText']),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Nguồn tham khảo:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: themeData['mainText'],
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    GestureDetector(
                                      onTap: () async {
                                        if (reference.isNotEmpty) {
                                          final Uri url = Uri.parse(reference);
                                          if (await canLaunchUrl(url)) {
                                            await launchUrl(url, mode: LaunchMode.externalApplication);
                                          }
                                        }
                                      },
                                      child: Text(
                                        'Wikipedia',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: themeData['auxiliaryText'],
                                          fontWeight: FontWeight.w500,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }
}