import 'package:flutter/material.dart';
import 'package:flutter_food_app/common/auth_store.dart';
import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter_food_app/common/globs.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_food_app/view/login/login_view.dart';
import 'package:flutter_food_app/view/profile/account_settings_view.dart';
import 'package:flutter_food_app/view/profile/help_center_view.dart';
import 'package:flutter_food_app/view/profile/order_history_view.dart';
import 'package:flutter_food_app/view/profile/payment_methods_view.dart';
import 'package:flutter_food_app/view/profile/vouchers_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool _hasToken = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final token = await AuthStore.getToken();
      _hasToken = token != null && token.isNotEmpty;
      if (!_hasToken) {
        if (mounted)
          setState(() {
            userData = null;
            isLoading = false;
          });
        return;
      }
      final url = Uri.parse(Globs.profileUrl);
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });
      if (response.statusCode == 200) {
        if (mounted)
          setState(() {
            userData = jsonDecode(response.body) as Map<String, dynamic>;
            isLoading = false;
          });
      } else {
        if (mounted)
          setState(() {
            userData = null;
            isLoading = false;
          });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _logout() async {
    await AuthStore.clear();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginView()),
      (route) => false,
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2)
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: TColor.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final name = userData?['fullname'] ?? 'Người dùng FastBite';
    final email = userData?['email'] ?? '';
    final phone = userData?['phone'];
    final joinDate = userData?['created_at'] != null
        ? DateFormat('dd/MM/yyyy')
            .format(DateTime.parse(userData!['created_at']))
        : 'Chưa rõ';

    return Scaffold(
      backgroundColor: TColor.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchProfile,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // ── Header gradient banner ──────────────────────────
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [TColor.primary, TColor.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 30),
                      // Avatar with edit overlay
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.25),
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: userData?['avatar_url'] != null
                                ? ClipOval(
                                    child: Image.network(
                                      userData!['avatar_url'],
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Center(
                                        child: Text(
                                          _getInitials(name),
                                          style: const TextStyle(
                                            fontSize: 36,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      _getInitials(name),
                                      style: const TextStyle(
                                        fontSize: 38,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                          ),
                          // Edit avatar button
                          GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Tính năng đổi ảnh đang phát triển')),
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
                                      color: Colors.black26, blurRadius: 4)
                                ],
                              ),
                              child: Icon(Icons.camera_alt_rounded,
                                  size: 16, color: TColor.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (email.isNotEmpty)
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),

                // ── Info cards ──────────────────────────────────────
                Transform.translate(
                  offset: const Offset(0, -20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // Quick stats row
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatItem('12', 'Đơn hàng',
                                  Icons.receipt_long_outlined),
                              _buildDivider(),
                              _buildStatItem(phone ?? 'Chưa cập nhật', 'SĐT',
                                  Icons.phone_outlined),
                              _buildDivider(),
                              _buildStatItem(joinDate, 'Tham gia',
                                  Icons.calendar_today_outlined),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Guest prompt
                        if (!_hasToken) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: TColor.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: TColor.primary.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: TColor.primary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Đăng nhập để xem hồ sơ và lịch sử đơn hàng.',
                                    style: TextStyle(
                                        color: TColor.primaryDark,
                                        fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const LoginView()),
                                ).then((_) => _fetchProfile());
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: TColor.primary,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Text('Đăng nhập',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Action menu card
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildActionMenu(Icons.receipt_long_outlined,
                                  'Lịch sử đơn hàng',
                                  subtitle: '12 đơn hàng gần đây',
                                  onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const OrderHistoryView()))),
                              _buildDividerLine(),
                              _buildActionMenu(
                                  Icons.account_balance_wallet_outlined,
                                  'Phương thức thanh toán',
                                  subtitle: 'Thẻ tín dụng, COD, Ví',
                                  onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const PaymentMethodsView()))),
                              _buildDividerLine(),
                              _buildActionMenu(
                                  Icons.local_offer_outlined, 'Voucher của tôi',
                                  subtitle: '3 voucher khả dụng',
                                  onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const VouchersView()))),
                              _buildDividerLine(),
                              _buildActionMenu(
                                  Icons.settings_outlined, 'Cài đặt tài khoản',
                                  subtitle: 'Chỉnh sửa SĐT, địa chỉ, thông tin',
                                  onTap: () {
                                if (!_hasToken) {
                                  Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  const LoginView()))
                                      .then((_) => _fetchProfile());
                                  return;
                                }
                                Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const AccountSettingsView()),
                                ).then((v) {
                                  if (v == true) _fetchProfile();
                                });
                              }),
                              _buildDividerLine(),
                              _buildActionMenu(
                                  Icons.help_outline, 'Trung tâm hỗ trợ',
                                  subtitle: 'FAQ và liên hệ',
                                  onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const HelpCenterView()))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Logout
                        if (_hasToken)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _logout,
                              icon: Icon(Icons.logout_rounded,
                                  color: Colors.red.shade400),
                              label: Text('Đăng xuất',
                                  style: TextStyle(
                                      color: Colors.red.shade400,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(color: Colors.red.shade200),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: TColor.primary, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                fontSize: value.length > 10 ? 10 : 13,
                fontWeight: FontWeight.w700,
                color: TColor.primaryText,
              ),
              textAlign: TextAlign.center,
              maxLines: 2),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 11, color: TColor.secondaryText)),
        ],
      ),
    );
  }

  Widget _buildDivider() => Container(
        width: 1,
        height: 40,
        color: Colors.black12,
      );

  Widget _buildDividerLine() =>
      const Divider(color: Colors.black12, height: 1, indent: 56);

  Widget _buildActionMenu(IconData icon, String title,
      {String? subtitle, VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: TColor.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: TColor.primary, size: 20),
      ),
      title: Text(title,
          style: TextStyle(
              color: TColor.primaryText,
              fontSize: 15,
              fontWeight: FontWeight.w600)),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: TextStyle(color: TColor.secondaryText, fontSize: 12))
          : null,
      trailing: const Icon(Icons.arrow_forward_ios_rounded,
          size: 14, color: Colors.black38),
      onTap: onTap ??
          () => ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('$title đang phát triển'))),
    );
  }
}
