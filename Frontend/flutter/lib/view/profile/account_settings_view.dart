import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_food_app/common/auth_store.dart';
import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter_food_app/common/globs.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_food_app/common_widget/round_button.dart';
import 'package:flutter_food_app/common_widget/round_textfield.dart';

class AccountSettingsView extends StatefulWidget {
  const AccountSettingsView({super.key});

  @override
  State<AccountSettingsView> createState() => _AccountSettingsViewState();
}

class _AccountSettingsViewState extends State<AccountSettingsView> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  String _email = '';
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final token = await AuthStore.getToken();
    if (token == null || token.isEmpty) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng đăng nhập')),
        );
        Navigator.pop(context);
      }
      return;
    }
    try {
      final res = await http.get(
        Uri.parse(Globs.profileUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final m = jsonDecode(res.body) as Map<String, dynamic>;
        _name.text = (m['fullname'] ?? '').toString();
        _phone.text = (m['phone'] ?? '').toString();
        _address.text = (m['address'] ?? '').toString();
        _email = (m['email'] ?? '').toString();
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final token = await AuthStore.getToken();
    if (token == null || token.isEmpty) return;
    setState(() => _saving = true);
    try {
      final res = await http.patch(
        Uri.parse(Globs.profileUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'fullname': _name.text.trim(),
          'phone': _phone.text.trim(),
          'address': _address.text.trim(),
        }),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật hồ sơ')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Globs.apiErrorMessage(res.body, fallback: 'Không lưu được'),
            ),
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
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: TColor.background,
        appBar: AppBar(
          backgroundColor: TColor.white,
          elevation: 0,
          iconTheme: IconThemeData(color: TColor.primaryText),
          title: Text('Cài đặt tài khoản', style: TextStyle(color: TColor.primaryText, fontWeight: FontWeight.w700)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: TColor.background,
      appBar: AppBar(
        backgroundColor: TColor.white,
        elevation: 0,
        iconTheme: IconThemeData(color: TColor.primaryText),
        title: Text(
          'Cài đặt tài khoản',
          style: TextStyle(
            color: TColor.primaryText,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Email đăng nhập (không đổi)',
              style: TextStyle(fontSize: 12, color: TColor.secondaryText),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: TColor.textfield,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(
                _email.isEmpty ? '—' : _email,
                style: TextStyle(
                  color: TColor.placeholder,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),
            RoundTextfield(hintText: 'Họ tên', controller: _name),
            const SizedBox(height: 16),
            RoundTextfield(
              hintText: 'Số điện thoại',
              controller: _phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            RoundTextfield(hintText: 'Địa chỉ', controller: _address),
            const SizedBox(height: 28),
            RoundButton(
              title: _saving ? 'Đang lưu...' : 'Lưu thay đổi',
              onPressed: _saving ? () {} : _save,
            ),
          ],
        ),
      ),
    );
  }
}
