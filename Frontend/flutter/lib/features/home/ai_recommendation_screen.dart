import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';
import '../../core/providers/auth_provider.dart';
import '../../shared/widgets/restaurant_card.dart';
import 'restaurant_detail_screen.dart';
import '../../core/models/restaurant.dart';

class AIRecommendationScreen extends ConsumerStatefulWidget {
  const AIRecommendationScreen({super.key});

  @override
  ConsumerState<AIRecommendationScreen> createState() => _AIRecommendationScreenState();
}

class _AIRecommendationScreenState extends ConsumerState<AIRecommendationScreen> {
  List<Restaurant> _recommended = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAIRecommendations();
  }

  Future<void> _fetchAIRecommendations() async {
    try {
      final user = ref.read(authProvider);
      final userId = user?.id ?? 1;
      
      // Lấy tọa độ giả định (Sẽ thay bằng LocationService)
      final dummyLat = 21.0285;
      final dummyLng = 105.8542;

      // Sử dụng ApiService thay vì gọi HTTP trực tiếp
      final apiService = ApiService();
      final data = await apiService.getRecommendedRestaurants(userId, dummyLat, dummyLng);
      
      if (mounted) {
        setState(() {
          _recommended = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi kết nối Backend: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gợi ý từ Context-Aware AI 🧠', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Colors.deepOrange),
                const SizedBox(height: 20),
                Text(
                  'Hệ thống AI đang phân tích dữ liệu\nkhông gian và lịch sử của bạn...',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
                ),
              ],
            ),
          )
        : _recommended.isEmpty
          ? const Center(child: Text('Không có gợi ý nào tại thời điểm và vị trí này.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _recommended.length,
              itemBuilder: (context, index) {
                final restaurant = _recommended[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => RestaurantDetailScreen(restaurant: restaurant)));
                  },
                  child: RestaurantCard(
                    name: restaurant.name,
                    info: restaurant.info,
                    imageUrl: restaurant.imageUrl,
                  ),
                );
              },
            )
    );
  }
}
