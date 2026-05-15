import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter_food_app/common/auth_store.dart';
import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter_food_app/common/globs.dart';
import 'package:flutter_food_app/common_widget/round_button.dart';
import 'package:flutter_food_app/common_widget/round_textfield.dart';
import 'package:flutter_food_app/view/login/rest_password_view.dart';
import 'package:flutter_food_app/view/login/sing_up_view.dart';
import 'package:flutter_food_app/common/auth_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  TextEditingController txtEmail = TextEditingController();
  TextEditingController txtPassword = TextEditingController();

  Future<void> _login() async {
    if (txtEmail.text.isEmpty || txtPassword.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập Email và Mật khẩu")),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final url = Uri.parse(Globs.loginUrl);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': txtEmail.text.trim().toLowerCase(),
          'password': txtPassword.text,
        }),
      );

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (response.statusCode == 200) {
        await AuthStore.saveTokenFromResponseBody(response.body);
        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          const SnackBar(content: Text("Đăng nhập thành công!")),
        );
        await replaceWithPostAuthHome(context);
      } else {
        final msg = Globs.apiErrorMessage(
          response.body,
          fallback: 'Mã ${response.statusCode}',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng nhập thất bại (${response.statusCode}): $msg'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi kết nối server: $e")));
    }
  }

  Future<void> _handleSocialLogin(
    String provider,
    String email,
    String fullname,
    String providerId,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final url = Uri.parse(Globs.socialLoginUrl);
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'provider': provider,
          'email': email,
          'fullname': fullname,
          'provider_id': providerId,
        }),
      );

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (response.statusCode == 200) {
        await AuthStore.saveTokenFromResponseBody(response.body);
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Đăng nhập $provider thành công!")),
        );
        await replaceWithPostAuthHome(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lỗi chứng thực từ server")),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi kết nối: $e")));
    }
  }

  Widget _socialLoginButton({
    required String title,
    required String iconAsset,
    required Color backgroundColor,
    required VoidCallback onPressed,
  }) {
    const radius = 28.0;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.32),
            blurRadius: 14,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onPressed,
          child: SizedBox(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(iconAsset, width: 24, height: 24),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 74),
              Text(
                "Login",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: TColor.primaryText,
                ),
              ),
              Text(
                "Add your details to login",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: TColor.secondaryText,
                ),
              ),
              const SizedBox(height: 35),
              RoundTextfield(
                hintText: "Your Email",
                controller: txtEmail,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 25),
              RoundTextfield(
                hintText: "Password",
                controller: txtPassword,
                obscureText: true,
              ),
              const SizedBox(height: 25),
              RoundButton(title: "Login", onPressed: _login),
              const SizedBox(height: 25),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ResetPasswordView(),
                    ),
                  );
                },
                child: Text(
                  "Forgot your password?",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: TColor.orangeDark,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Text(
                "or login with",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: TColor.secondaryText,
                ),
              ),
              const SizedBox(height: 35),
              _socialLoginButton(
                title: "Login with Facebook",
                iconAsset: "assets/img/facebook_logo.png",
                backgroundColor: const Color(0xff367FC0),
                onPressed: () async {
                  try {
                    // Chỉ xin public_profile: quyền `email` phải bật trong Meta
                    // (Use cases / Quyền) — nếu không sẽ lỗi "Invalid Scopes: email".
                    final LoginResult result = await FacebookAuth.instance
                        .login(permissions: ['public_profile']);
                    if (!context.mounted) return;

                    if (result.status == LoginStatus.success) {
                      final userData = await FacebookAuth.instance.getUserData(
                        fields: 'id,name,picture.width(200)',
                      );
                      if (!context.mounted) return;
                      await _handleSocialLogin(
                        'facebook',
                        userData['email'] ?? "${userData['id']}@facebook.com",
                        userData['name'] ?? 'Facebook User',
                        userData['id'] ?? '',
                      );
                    } else if (result.status == LoginStatus.failed) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Lỗi Facebook: ${result.message}',
                          ),
                        ),
                      );
                    }
                  } catch (_) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Yêu cầu cấu hình App ID Facebook để dùng tính năng này.',
                        ),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 25),
              _socialLoginButton(
                title: "Login with Google",
                iconAsset: "assets/img/google_logo.png",
                backgroundColor: const Color(0xFF6F0706),
                onPressed: () async {
                  try {
                    final GoogleSignIn googleSignIn = GoogleSignIn();
                    final GoogleSignInAccount? googleUser =
                        await googleSignIn.signIn();
                    if (!context.mounted) return;
                    if (googleUser != null) {
                      await _handleSocialLogin(
                        'google',
                        googleUser.email,
                        googleUser.displayName ?? 'Google User',
                        googleUser.id,
                      );
                    }
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi Google Sign In: $e'),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 30),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignUpView()),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: TColor.secondaryText,
                      ),
                    ),
                    Text(
                      "Sign Up",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: TColor.orangeDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
