import 'dart:ui';
import 'package:flutter_food_app/common_widget/round_button.dart';
import 'package:flutter_food_app/view/login/login_view.dart';
import 'package:flutter_food_app/view/login/sing_up_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_food_app/common/color_extension.dart';

class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// 1️⃣ Màu nền
          Container(
            width: double.infinity,
            height: double.infinity,
            color: TColor.placeholder,
          ),

          /// 2️⃣ Ảnh hoạ tiết
          Positioned.fill(
            child: Image.asset("assets/img/nen1.png", fit: BoxFit.cover),
          ),

          /// 3️⃣ Khung kính mờ + nội dung
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: 450,
                  width: 350,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3)),
                  ),

                  /// 🔽 NỘI DUNG TRONG KHUNG
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,

                    children: [
                      /// Logo
                      Image.asset("assets/img/logo.png", width: 160),

                      Text(
                        "Welcome to FastBite",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: TColor.primaryText,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 5),

                      Text(
                        "Delivering delicious food to your door",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: TColor.primaryText,
                        ),
                      ),

                      const SizedBox(height: 30),

                      /// Login
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.7,
                        child: RoundButton(
                          title: "Login",

                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginView(),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// Create Account
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.7,
                        child: RoundButton(
                          title: "Create an Account",
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignUpView(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
