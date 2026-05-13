import 'dart:convert';
import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter_food_app/common/globs.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_food_app/common_widget/round_button.dart';
import 'package:flutter_food_app/common_widget/round_textfield.dart';
import 'package:flutter_food_app/view/login/login_view.dart';
import 'package:flutter/material.dart';

class NewPasswordView extends StatefulWidget {
  const NewPasswordView({
    super.key,
    required this.email,
    required this.otp,
  });

  final String email;
  final String otp;

  @override
  State<NewPasswordView> createState() => _NewPasswordViewState();
}

class _NewPasswordViewState extends State<NewPasswordView> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  Future<void> _submit() async {
    if (_password.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu tối thiểu 6 ký tự')),
      );
      return;
    }
    if (_password.text != _confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu xác nhận không khớp')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final response = await http.post(
        Uri.parse(Globs.resetPasswordUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'code': widget.otp,
          'newPassword': _password.text,
        }),
      );
      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đổi mật khẩu thành công. Vui lòng đăng nhập.')),
        );
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginView()),
          (route) => false,
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
    _password.dispose();
    _confirm.dispose();
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
                'Mật khẩu mới',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: TColor.primaryText,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                'Nhập mật khẩu mới cho ${widget.email}',
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
                hintText: 'Mật khẩu mới',
                controller: _password,
                obscureText: true,
              ),
              const SizedBox(height: 20),
              RoundTextfield(
                hintText: 'Xác nhận mật khẩu',
                controller: _confirm,
                obscureText: true,
              ),
              const SizedBox(height: 35),
              RoundButton(
                title: _loading ? 'Đang lưu...' : 'Xác nhận',
                onPressed: _loading ? () {} : _submit,
                isDisabled: _loading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
