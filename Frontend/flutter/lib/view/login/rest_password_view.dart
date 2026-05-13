import 'dart:convert';
import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter_food_app/common/globs.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_food_app/common_widget/round_button.dart';
import 'package:flutter_food_app/common_widget/round_textfield.dart';
import 'package:flutter_food_app/view/login/otp_view.dart';
import 'package:flutter/material.dart';

class ResetPasswordView extends StatefulWidget {
  const ResetPasswordView({super.key});

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  final _email = TextEditingController();
  bool _loading = false;

  Future<void> _sendCode() async {
    final email = _email.text.trim().toLowerCase();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập email')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final response = await http.post(
        Uri.parse(Globs.forgotPasswordUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      if (!mounted) return;

      if (response.statusCode == 200) {
        Map<String, dynamic>? data;
        try {
          data = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {}

        final debugOtp = data?['debug_otp']?.toString();
        if (debugOtp != null && debugOtp.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Mã OTP (demo): $debugOtp'),
              duration: const Duration(seconds: 8),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Đã gửi yêu cầu. Kiểm tra email hoặc console server (OTP được log tại backend).',
              ),
              duration: Duration(seconds: 5),
            ),
          );
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpView(email: email, isForgotPassword: true),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Globs.apiErrorMessage(response.body, fallback: 'Lỗi ${response.statusCode}'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi kết nối: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: TColor.white,
        elevation: 0,
        iconTheme: IconThemeData(color: TColor.primaryText),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              Text(
                'Quên mật khẩu',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: TColor.primaryText,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                'Nhập email đã đăng ký. Bạn sẽ nhận mã OTP 6 số (hiển thị trong app nếu bật RESET_OTP_IN_RESPONSE trên server).',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: TColor.secondaryText,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 35),
              RoundTextfield(
                hintText: 'Email',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 35),
              RoundButton(
                title: _loading ? 'Đang gửi...' : 'Gửi mã OTP',
                onPressed: _loading ? () {} : _sendCode,
                isDisabled: _loading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
