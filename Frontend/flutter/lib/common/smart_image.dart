import 'package:flutter/material.dart';

/// Nhiều host (loremflickr, v.v.) trả 403 nếu không có User-Agent giống trình duyệt.
const Map<String, String> kNetworkImageHeaders = {
  'User-Agent':
      'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
  'Accept': 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
};

class SmartImage extends StatelessWidget {
  final String path;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const SmartImage(this.path, {super.key, this.width, this.height, this.fit, this.errorBuilder});

  @override
  Widget build(BuildContext context) {
    if (path.isEmpty) return const SizedBox();
    if (path.startsWith("http") || path.startsWith("https")) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        headers: kNetworkImageHeaders,
        errorBuilder: errorBuilder,
      );
    } else {
      return Image.asset(path, width: width, height: height, fit: fit, errorBuilder: errorBuilder);
    }
  }
}
