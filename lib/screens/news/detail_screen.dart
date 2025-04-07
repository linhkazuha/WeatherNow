import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final primaryColor = Theme.of(context).primaryColor;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
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
                            color: Colors.grey[300],
                            child: Icon(Icons.image_not_supported, size: 80, color: Colors.grey[500]),
                          );
                        },
                      )
                    : Container(
                        height: 220,
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: Icon(Icons.image, size: 80, color: Colors.grey[500]),
                      ),
                // Gradient overlay for better text visibility if needed
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
                // Title on image
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
            
            // Content
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.1),
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
                      color: Colors.grey[800],
                    ),
                  ),
                  if (reference.isNotEmpty) ...[
                    SizedBox(height: 20),
                    Divider(color: Colors.grey.withOpacity(0.3), thickness: 1),
                    SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.link, size: 16, color: primaryColor),
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
                                  color: Colors.grey[700],
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
                                    color: primaryColor,
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
    );
  }
}