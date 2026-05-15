import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter_food_app/common/smart_image.dart';

/// Banner quảng cáo tự chuyển slide mỗi [autoPlayInterval].
class BannerSlider extends StatefulWidget {
  final Duration autoPlayInterval;

  const BannerSlider({
    super.key,
    this.autoPlayInterval = const Duration(seconds: 5),
  });

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  static const List<_BannerData> _banners = [
    _BannerData(
      title: 'Giảm 50% Món Mới',
      imageUrl:
          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?q=80&w=800&auto=format&fit=crop',
    ),
    _BannerData(
      title: 'Món Ngon Cuối Tuần',
      imageUrl:
          'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?q=80&w=800&auto=format&fit=crop',
    ),
    _BannerData(
      title: 'Giao Hàng Miễn Phí',
      imageUrl:
          'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?q=80&w=800&auto=format&fit=crop',
    ),
  ];

  late final PageController _controller;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.9);
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.autoPlayInterval, (_) => _goToNext());
  }

  void _goToNext() {
    if (!mounted || !_controller.hasClients) return;
    final next = (_currentPage + 1) % _banners.length;
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
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
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    SmartImage(
                      b.imageUrl,
                      fit: BoxFit.cover,
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.7),
                            Colors.transparent,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Text(
                          b.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
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
  final String imageUrl;
  const _BannerData({required this.title, required this.imageUrl});
}
