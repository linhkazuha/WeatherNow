import 'package:flutter/material.dart';
import '../models/news_model.dart';
import '../services/news_api_service.dart';
import '../widgets/news_card.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _NewsScreenState createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final NewsApiService _newsService = NewsApiService();
  List<NewsArticle> _newsList = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isUsingBackup = false;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isUsingBackup = false;
    });

    try {
      // Thử lấy tin tức thời tiết từ API chính
      final news = await _newsService.getWeatherNews();
      
      // Nếu không tìm thấy tin tức thời tiết nào, sử dụng API dự phòng
      if (news.isEmpty) {
        setState(() {
          _isUsingBackup = true;
        });
        final backupNews = await _newsService.getBackupWeatherNews();
        setState(() {
          _newsList = backupNews;
          _isLoading = false;
        });
      } else {
        setState(() {
          _newsList = news;
          _isLoading = false;
        });
      }
    } catch (e) {
      // print('Lỗi khi tải tin tức: $e');
      
      // Nếu API chính thất bại, thử sử dụng API dự phòng
      try {
        setState(() {
          _isUsingBackup = true;
        });
        final backupNews = await _newsService.getBackupWeatherNews();
        setState(() {
          _newsList = backupNews;
          _isLoading = false;
        });
      } catch (backupError) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Không thể tải tin tức: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tin tức thời tiết'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNews,
            tooltip: 'Làm mới tin tức',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Đã xảy ra lỗi: $_errorMessage', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadNews,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }
    
    if (_newsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Không có tin tức thời tiết nào'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadNews,
              child: const Text('Làm mới'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Hiển thị thông báo nếu đang sử dụng API dự phòng
        if (_isUsingBackup)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.amber.shade100,
            width: double.infinity,
            child: const Text(
              'Hiển thị các tin tức khoa học & môi trường do không tìm thấy tin thời tiết cụ thể.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadNews,
            child: ListView.builder(
              itemCount: _newsList.length,
              itemBuilder: (context, index) {
                return NewsCard(article: _newsList[index]);
              },
            ),
          ),
        ),
      ],
    );
  }
}