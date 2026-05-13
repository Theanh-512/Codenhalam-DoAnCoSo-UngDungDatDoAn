import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_food_app/common/color_extension.dart';

class BannerSlider extends StatefulWidget {
  const BannerSlider({super.key});

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  Timer? _timer;

  // Mock banners — sau thay bằng data từ Firestore
  final List<_BannerData> _banners = [
    _BannerData(
      title: "Giảm 30%",
      subtitle: "Cho đơn hàng đầu tiên",
      emoji: "🍔",
      color: const Color(0xFFFDD100),
    ),
    _BannerData(
      title: "Miễn phí ship",
      subtitle: "Đơn từ 150.000đ",
      emoji: "🛵",
      color: const Color(0xFFFF6B35),
    ),
    _BannerData(
      title: "Combo trưa",
      subtitle: "Chỉ từ 49.000đ",
      emoji: "🍱",
      color: const Color(0xFF6F0706),
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Tự động chuyển banner mỗi 3 giây
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_currentPage < _banners.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _controller.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _controller,
            itemCount: _banners.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              final b = _banners[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: b.color,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Row(
                  children: [
                    // Text bên trái
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            b.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            b.subtitle,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              "Đặt ngay",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Emoji bên phải
                    Text(b.emoji, style: const TextStyle(fontSize: 64)),
                  ],
                ),
              );
            },
          ),
        ),

        // Dot indicator
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _banners.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentPage == i ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentPage == i ? TColor.primary : TColor.placeholder,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BannerData {
  final String title;
  final String subtitle;
  final String emoji;
  final Color color;
  _BannerData({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.color,
  });
}
