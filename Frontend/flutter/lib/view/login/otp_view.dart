import 'dart:convert';
import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter_food_app/common/globs.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_food_app/common_widget/round_button.dart';
import 'package:flutter_food_app/view/login/new_password_view.dart';
import 'package:flutter/material.dart';
import 'package:otp_pin_field/otp_pin_field.dart';

/// OTP cho luồng [isForgotPassword]. Đăng ký không còn dùng màn này (vào thẳng app sau khi API register).
class OtpView extends StatefulWidget {
  const OtpView({
    super.key,
    required this.email,
    this.isForgotPassword = false,
  });

  final String email;
  final bool isForgotPassword;

  @override
  State<OtpView> createState() => _OtpViewState();
}

class _OtpViewState extends State<OtpView> {
  final _otpPinFieldController = GlobalKey<OtpPinFieldState>();
  String _code = '';
  bool _resending = false;

  Future<void> _resend() async {
    if (!widget.isForgotPassword) return;
    setState(() => _resending = true);
    try {
      final response = await http.post(
        Uri.parse(Globs.forgotPasswordUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email}),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        Map<String, dynamic>? data;
        try {
          data = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {}
        final debugOtp = data?['debug_otp']?.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              debugOtp != null && debugOtp.isNotEmpty
                  ? 'Mã mới (demo): $debugOtp'
                  : 'Đã gửi lại. Xem console server hoặc email.',
            ),
            duration: const Duration(seconds: 6),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Globs.apiErrorMessage(response.body)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  void _next() {
    if (_code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nhập đủ 6 số OTP')),
      );
      return;
    }
    if (!widget.isForgotPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Luồng không hợp lệ')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewPasswordView(
          email: widget.email,
          otp: _code,
        ),
      ),
    );
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
                widget.isForgotPassword
                    ? 'Xác nhận OTP'
                    : 'Nhập mã xác nhận',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: TColor.primaryText,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                widget.isForgotPassword
                    ? 'Mã 6 số đã gửi tới ${widget.email}'
                    : 'Nhập mã cho ${widget.email}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: TColor.secondaryText,
                ),
              ),
              const SizedBox(height: 35),
              SizedBox(
                height: 60,
                child: OtpPinField(
                  key: _otpPinFieldController,
                  autoFillEnable: true,
                  textInputAction: TextInputAction.done,
                  onSubmit: (newCode) => _code = newCode,
                  onChange: (newCode) => _code = newCode,
                  onCodeChanged: (newCode) => _code = newCode,
                  fieldWidth: 40,
                  otpPinFieldStyle: OtpPinFieldStyle(
                    defaultFieldBorderColor: Colors.transparent,
                    activeFieldBorderColor: Colors.transparent,
                    defaultFieldBackgroundColor: TColor.textfield,
                    activeFieldBackgroundColor: TColor.textfield,
                  ),
                  maxLength: 6,
                  showCursor: true,
                  cursorColor: TColor.placeholder,
                  upperChild: const Column(
                    children: [
                      SizedBox(height: 30),
                      Icon(Icons.mark_email_read_outlined, size: 80, color: Color(0xFFFC6011)),
                      SizedBox(height: 20),
                    ],
                  ),
                  showCustomKeyboard: false,
                  cursorWidth: 3,
                  mainAxisAlignment: MainAxisAlignment.center,
                  otpPinFieldDecoration: OtpPinFieldDecoration.defaultPinBoxDecoration,
                ),
              ),
              const SizedBox(height: 35),
              RoundButton(title: 'Tiếp tục', onPressed: _next),
              if (widget.isForgotPassword)
                TextButton(
                  onPressed: _resending ? null : _resend,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: _resending ? 'Đang gửi...' : 'Không nhận được? ',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: TColor.secondaryText,
                          ),
                        ),
                        if (!_resending)
                          TextSpan(
                            text: 'Gửi lại',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: TColor.orangeDark,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
