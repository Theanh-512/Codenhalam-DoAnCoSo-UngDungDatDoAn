import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_food_app/common/auth_store.dart';
import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter_food_app/common/globs.dart';
import 'package:flutter_food_app/model/restaurant_model.dart';
import 'package:flutter_food_app/view/home/widget/restaurant_cell.dart';
import 'package:flutter_food_app/view/restaurant/restaurant_detail_view.dart';

/// Bọc 1 nhà hàng + lời giải thích AI sinh ra (SCR Framework).
class _AiPick {
  final RestaurantModel restaurant;
  final String explanation;

  _AiPick({required this.restaurant, required this.explanation});
}

class _AiResult {
  final List<_AiPick> picks;
  final String framework;
  final String algorithm;
  final String note;

  _AiResult({
    required this.picks,
    required this.framework,
    required this.algorithm,
    required this.note,
  });
}

/// Màn AI Recommend: gọi `/api/Recommendations/{userId}` (.NET RecommendationEngine,
/// dùng SCR Framework — Long-term & Short-term Sequential Fusion, có fallback popularity).
class AiRecommendationScreen extends StatefulWidget {
  const AiRecommendationScreen({super.key});

  @override
  State<AiRecommendationScreen> createState() => _AiRecommendationScreenState();
}

class _AiRecommendationScreenState extends State<AiRecommendationScreen> {
  bool _isLoading = true;
  String? _error;
  _AiResult? _result;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final userId = await AuthStore.getUserId();
    if (userId == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Bạn cần đăng nhập để xem gợi ý cá nhân hoá';
      });
      return;
    }

    try {
      final url = Uri.parse('${Globs.recommendUrl(userId)}?topN=10');
      final headers = await AuthStore.authHeaders();
      final res = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        throw Exception('Server trả ${res.statusCode}: ${res.body}');
      }
      final data = jsonDecode(res.body);
      if (data is! Map<String, dynamic>) {
        throw Exception('Định dạng response không hợp lệ');
      }
      final result = _parse(data);
      if (!mounted) return;
      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Không kết nối được AI: $e';
      });
    }
  }

  _AiResult _parse(Map<String, dynamic> json) {
    String s(String camel, String pascal) =>
        (json[camel] ?? json[pascal] ?? '').toString();

    final list = (json['recommendations'] ??
            json['Recommendations'] ??
            const <dynamic>[]) as List;
    final picks = list
        .map((raw) {
          if (raw is! Map) return null;
          final m = raw.cast<String, dynamic>();
          final restRaw = m['restaurant'] ?? m['Restaurant'];
          if (restRaw is! Map) return null;
          final restaurant = RestaurantModel.fromJson(
            restRaw.cast<String, dynamic>(),
          );
          if (restaurant.name.isEmpty) return null;
          final explanation =
              (m['explanation'] ?? m['Explanation'] ?? '').toString();
          return _AiPick(restaurant: restaurant, explanation: explanation);
        })
        .whereType<_AiPick>()
        .toList();

    return _AiResult(
      picks: picks,
      framework: s('framework', 'Framework'),
      algorithm: s('algorithm', 'Algorithm'),
      note: s('note', 'Note'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.background,
      appBar: AppBar(
        title: const Text(
          'Gợi ý từ AI',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: TColor.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại gợi ý',
            onPressed: _isLoading ? null : _fetch,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: TColor.primary),
            const SizedBox(height: 16),
            Text(
              'AI đang phân tích sở thích & ngữ cảnh\ncủa bạn...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: TColor.secondaryText,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: TColor.primary, size: 56),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: TColor.primaryText),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColor.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: _fetch,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final result = _result!;
    if (result.picks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Chưa đủ dữ liệu để gợi ý cho bạn.\n'
            'Hãy lướt vài nhà hàng và thử lại nhé!',
            textAlign: TextAlign.center,
            style: TextStyle(color: TColor.secondaryText, fontSize: 15),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: TColor.primary,
      onRefresh: _fetch,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _buildHeader(result),
          ...result.picks.map(_buildPick),
        ],
      ),
    );
  }

  Widget _buildHeader(_AiResult r) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            TColor.primary.withValues(alpha: 0.95),
            TColor.primary.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Cá nhân hoá theo sở thích',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (r.framework.isNotEmpty)
            Text(
              'Framework: ${r.framework}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          if (r.algorithm.isNotEmpty)
            Text(
              'Algorithm: ${r.algorithm}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          if (r.note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              r.note,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPick(_AiPick pick) {
    return Column(
      children: [
        if (pick.explanation.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: TColor.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: TColor.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pick.explanation,
                    style: TextStyle(
                      color: TColor.primaryText,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        RestaurantCell(
          restaurant: pick.restaurant,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    RestaurantDetailView(restaurant: pick.restaurant),
              ),
            );
          },
        ),
      ],
    );
  }
}
