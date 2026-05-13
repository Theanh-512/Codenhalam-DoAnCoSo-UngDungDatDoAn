import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter/material.dart';

import '../login/welcome_view.dart';

class StartupView extends StatefulWidget {
  const StartupView({super.key});

  @override
  State<StartupView> createState() => _StartupViewState();
}

class _StartupViewState extends State<StartupView> {
  @override
  void initState() {
    super.initState();
    goNext();
  }

  Future<void> goNext() async {
    await Future.delayed(const Duration(seconds: 4));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          /// 1️⃣ Background vàng
          Container(
            width: double.infinity,
            height: double.infinity,
            color: TColor.red, // màu nền bạn muốn (vàng / cam / trắng...)
          ),

          /// 3️⃣ Logo tròn đè lên shape
          Positioned(
            top: size.height * 0.35, // chỉnh vị trí logo
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                "assets/img/logo.png", // logo của bạn
                width: 200, // chỉnh to / nhỏ
                fit: BoxFit.contain,
              ),
            ),
          ),

          /// 4️⃣ Text bên dưới logo
          Positioned(
            top: size.height * 0.35 + 180,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  "FastBite",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: TColor.primaryDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "FOOD DELIVERY",
                  style: TextStyle(
                    fontSize: 16,
                    letterSpacing: 2,
                    color: TColor.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
