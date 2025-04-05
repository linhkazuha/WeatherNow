import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/news_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NewsApiService {
  final String apiKey = dotenv.env['NEWS_API_KEY'] ?? '';
  final String baseUrl = 'https://newsapi.org/v2';

  final List<String> weatherKeywords = [
    'thời tiết', 
    'dự báo thời tiết', 
    'bão', 
    'áp thấp nhiệt đới',
    'gió mùa', 
    'nắng nóng', 
    'rét đậm', 
    'mưa lớn',
    'sương mù', 
    'lũ lụt', 
    'hạn hán', 
    'ngập úng',
    'không khí lạnh', 
    'không khí ô nhiễm', 
    'nhiệt độ', 
    'cảnh báo thời tiết',
    'thiên tai', 
    'biến đổi khí hậu'
  ];

  Future<List<NewsArticle>> getWeatherNews() async {
    try {
      String queryParams = weatherKeywords.map((keyword) => '"$keyword"').join(' OR ');

      final url = Uri.parse(
        '$baseUrl/everything?q=($queryParams)&language=vi&sortBy=publishedAt&pageSize=50&apiKey=$apiKey'
      );
            
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        if (jsonData.containsKey('articles')) {
          final articlesList = jsonData['articles'] as List;
          
          if (articlesList.isEmpty) {
            return [];
          }
          
          final articles = articlesList
              .map((article) => NewsArticle.fromJson(article))
              .toList();
          
          // Lọc thủ công để chỉ lấy các bài viết thực sự liên quan đến thời tiết
          final filteredArticles = articles.where((article) {
            final title = article.title.toLowerCase();
            // final description = article.description.toLowerCase();
            
            // Kiểm tra xem tiêu đề hoặc mô tả có chứa bất kỳ từ khóa thời tiết nào
            return weatherKeywords.any((keyword) => 
                title.contains(keyword.toLowerCase())
                // description.contains(keyword.toLowerCase())
            );
          }).toList();
          
          return filteredArticles;
        } else {
          return [];
        }
      } else {
        throw Exception('Không thể lấy tin tức thời tiết: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Hàm dự phòng nếu API không có tin tức thời tiết
  Future<List<NewsArticle>> getBackupWeatherNews() async {
    try {
      // Sử dụng endpoint top-headlines với danh mục khoa học (thường có tin thời tiết/môi trường)
      final url = Uri.parse(
        '$baseUrl/top-headlines?country=vn&category=science&apiKey=$apiKey'
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        if (jsonData.containsKey('articles')) {
          final articlesList = jsonData['articles'] as List;
          final articles = articlesList
              .map((article) => NewsArticle.fromJson(article))
              .toList();
          
          return articles;
        }
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }
}