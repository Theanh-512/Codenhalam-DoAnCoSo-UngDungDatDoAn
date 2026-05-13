import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter/material.dart';

class AboutView extends StatelessWidget {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.background,
      appBar: AppBar(
        backgroundColor: TColor.white,
        elevation: 0,
        iconTheme: IconThemeData(color: TColor.primaryText),
        title: Text(
          'Về FastBite',
          style: TextStyle(
            color: TColor.primaryText,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Image.asset('assets/img/logo.png', width: 120),
            const SizedBox(height: 20),
            Text(
              'FastBite',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: TColor.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Food delivery',
              style: TextStyle(
                letterSpacing: 2,
                color: TColor.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Ứng dụng đặt món, giao tận nơi. Sản phẩm minh họa kết hợp backend Node.js & PostgreSQL.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.45,
                color: TColor.secondaryText,
              ),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Phiên bản',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: TColor.primaryText,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TColor.textfield,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '1.0.0 (build demo)',
                style: TextStyle(color: TColor.primaryText, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
