import 'package:flutter/material.dart';
import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter_food_app/view/login/login_view.dart';
import 'package:flutter_food_app/view/login/sing_up_view.dart';

class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
  
                // ── Logo + Brand ─────────────────────────────────────
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: TColor.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Image.asset(
                      'assets/img/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
  
                Text(
                  'FastBite',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: TColor.primaryDark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'FOOD DELIVERY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: TColor.primary,
                    letterSpacing: 3,
                  ),
                ),
  
                const SizedBox(height: 40),
  
                // ── Illustration placeholder ─────────────────────────
                Container(
                  width: size.width * 0.7,
                  height: size.width * 0.7,
                  decoration: BoxDecoration(
                    color: TColor.primary.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer ring
                        Container(
                          width: size.width * 0.55,
                          height: size.width * 0.55,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: TColor.primary.withValues(alpha: 0.15),
                              width: 1.5,
                            ),
                          ),
                        ),
                        // Inner content
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🍜', style: const TextStyle(fontSize: 64)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: TColor.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Ngon · Nhanh · Tiện',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
  
                const SizedBox(height: 40),
  
                // ── Tagline ──────────────────────────────────────────
                Text(
                  'Đặt đồ ăn ngon trong\nvài giây',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: TColor.primaryText,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Hàng nghìn nhà hàng gần bạn,\ngiao hàng siêu tốc tận nơi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: TColor.secondaryText,
                    height: 1.5,
                  ),
                ),
  
                const SizedBox(height: 40),
  
                // ── Buttons ──────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginView()),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TColor.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Đăng nhập',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
  
                const SizedBox(height: 14),
  
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpView()),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: TColor.primary, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Tạo tài khoản mới',
                      style: TextStyle(
                        color: TColor.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
  
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
