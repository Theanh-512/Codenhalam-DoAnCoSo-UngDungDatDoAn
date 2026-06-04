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
                const SizedBox(height: 16),
  
                // ── Illustration ─────────────────────────────────────
                _buildIllustration(size),
  
                const SizedBox(height: 24),
  
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

  Widget _buildIllustration(Size size) {
    final illoSize = size.width * 0.85;
    return SizedBox(
      width: illoSize,
      height: illoSize,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // ── Concentric circles ────────────────────────────────────
          Container(
            width: illoSize,
            height: illoSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: TColor.primary.withValues(alpha: 0.05),
            ),
          ),
          Container(
            width: illoSize * 0.78,
            height: illoSize * 0.78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: TColor.primary.withValues(alpha: 0.10),
            ),
          ),
          Container(
            width: illoSize * 0.6,
            height: illoSize * 0.6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: TColor.primary.withValues(alpha: 0.18),
            ),
          ),
          // White ring around logo
          Container(
            width: illoSize * 0.42,
            height: illoSize * 0.42,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
          // ── Logo + brand pill ─────────────────────────────────────
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: illoSize * 0.32,
                height: illoSize * 0.32,
                child: Image.asset(
                  'assets/img/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: TColor.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'FastBite',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          // ── Decorative floating icons ─────────────────────────────
          const Positioned(top: 8,    left: 24,  child: Text('🌿', style: TextStyle(fontSize: 22))),
          const Positioned(top: 28,   right: 30, child: Text('🍃', style: TextStyle(fontSize: 24))),
          const Positioned(top: 70,   right: 0,  child: Text('🧂', style: TextStyle(fontSize: 22))),
          const Positioned(bottom: 30, right: 18, child: Text('🍋', style: TextStyle(fontSize: 22))),
          const Positioned(bottom: 0,  right: 70, child: Text('🌿', style: TextStyle(fontSize: 18))),
          const Positioned(bottom: 30, left: 14, child: Text('🥚', style: TextStyle(fontSize: 20))),
          const Positioned(bottom: 90, left: 0,  child: Text('🍴', style: TextStyle(fontSize: 22))),
          const Positioned(top: 90,   left: 6,  child: Text('✨', style: TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
