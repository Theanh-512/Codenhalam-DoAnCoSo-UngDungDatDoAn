import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_food_app/common/auth_store.dart';
import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter_food_app/common/globs.dart';
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
  String _joinDate = '';
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
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Vui lòng đăng nhập')));
        Navigator.pop(context);
      }
      return;
    }
    try {
      final res = await http.get(Uri.parse(Globs.profileUrl), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });
      if (!mounted) return;
      if (res.statusCode == 200) {
        final m = jsonDecode(res.body) as Map<String, dynamic>;
        _name.text = (m['fullname'] ?? '').toString();
        _phone.text = (m['phone'] ?? '').toString();
        _address.text = (m['address'] ?? '').toString();
        _email = (m['email'] ?? '').toString();
        final rawDate = m['created_at'];
        if (rawDate != null) {
          try {
            final dt = DateTime.parse(rawDate.toString());
            _joinDate =
                '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
          } catch (_) {}
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Vui lòng nhập họ tên')));
      return;
    }
    final token = await AuthStore.getToken();
    if (token == null || token.isEmpty) return;
    setState(() => _saving = true);
    try {
      final res = await http.patch(
        Uri.parse(Globs.profileUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
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
            const SnackBar(content: Text('✅ Đã cập nhật hồ sơ thành công!')));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  Globs.apiErrorMessage(res.body, fallback: 'Không lưu được'))),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: TColor.background,
        appBar: _buildAppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: TColor.background,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Avatar section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [TColor.primary, TColor.primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _name.text.isNotEmpty
                              ? _name.text[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              fontSize: 38,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Tính năng đổi ảnh đang phát triển')),
                        );
                      },
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 6)
                          ],
                        ),
                        child: Icon(Icons.camera_alt_rounded,
                            size: 16, color: TColor.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Info fields
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionLabel('Thông tin tài khoản'),
                  const SizedBox(height: 12),

                  // Read-only email
                  _readonlyField(
                      Icons.email_outlined,
                      'Email đăng nhập (không thể đổi)',
                      _email.isEmpty ? '—' : _email),
                  const SizedBox(height: 8),

                  // Read-only join date
                  _readonlyField(Icons.calendar_today_outlined, 'Ngày tham gia',
                      _joinDate.isEmpty ? 'Chưa rõ' : _joinDate),
                  const SizedBox(height: 20),

                  _sectionLabel('Chỉnh sửa thông tin'),
                  const SizedBox(height: 12),

                  RoundTextfield(hintText: 'Họ và tên', controller: _name),
                  const SizedBox(height: 14),

                  RoundTextfield(
                    hintText: 'Số điện thoại',
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),

                  RoundTextfield(
                      hintText: 'Địa chỉ giao hàng', controller: _address),
                  const SizedBox(height: 28),

                  RoundButton(
                    title: _saving ? 'Đang lưu...' : 'Lưu thay đổi',
                    onPressed: _saving ? () {} : _save,
                  ),
                  const SizedBox(height: 16),

                  // Change password
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Tính năng đổi mật khẩu đang phát triển')),
                      );
                    },
                    icon: Icon(Icons.lock_outline_rounded,
                        color: TColor.primaryText, size: 18),
                    label: Text('Đổi mật khẩu',
                        style: TextStyle(
                            color: TColor.primaryText,
                            fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: TColor.placeholder),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() => AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: TColor.primaryText),
        title: Text('Cài đặt tài khoản',
            style: TextStyle(
                color: TColor.primaryText,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        centerTitle: true,
      );

  Widget _sectionLabel(String text) => Text(
        text,
        style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: TColor.secondaryText,
            letterSpacing: 0.5),
      );

  Widget _readonlyField(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: TColor.textfield,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: TColor.placeholder, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 11, color: TColor.placeholder)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: TColor.secondaryText)),
              ],
            ),
          ),
          Icon(Icons.lock_outline_rounded, size: 14, color: TColor.placeholder),
        ],
      ),
    );
  }
}
