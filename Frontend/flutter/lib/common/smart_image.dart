import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
    if (path.isEmpty) return _errorWidget();
    
    if (path.startsWith("http") || path.startsWith("https")) {
      String finalUrl = path.trim();
      
      if (kIsWeb) {
        try {
          // Chuẩn hóa URL: Giải mã rồi mã hóa lại để trình duyệt Web đọc được mọi ký tự đặc biệt
          final decoded = Uri.decodeFull(finalUrl);
          finalUrl = Uri.parse(decoded).toString();
        } catch (_) {}
      }

      return Image.network(
        finalUrl,
        width: width,
        height: height,
        fit: fit,
        headers: kIsWeb ? null : kNetworkImageHeaders,
        errorBuilder: (context, error, stackTrace) => errorBuilder?.call(context, error, stackTrace) ?? _errorWidget(),
      );
    } else {
      return Image.asset(path, width: width, height: height, fit: fit, errorBuilder: errorBuilder);
    }
  }

  Widget _errorWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 30)),
    );
  }
}
