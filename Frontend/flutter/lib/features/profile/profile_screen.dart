import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/auth_provider.dart';
import '../auth/login_screen.dart';
import 'order_history_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _logout(BuildContext context, WidgetRef ref) {
    ref.read(authProvider.notifier).logout();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.deepOrange[100],
                    child: const Icon(Icons.person, size: 40, color: Colors.deepOrange),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'Khách',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(user?.email ?? '', style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.deepOrange),
                    onPressed: () {},
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildMenuItems(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context, WidgetRef ref) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _buildItem(context, Icons.favorite_border, 'Món yêu thích', null),
          const Divider(height: 1),
          _buildItem(context, Icons.location_on_outlined, 'Địa chỉ giao hàng', null),
          const Divider(height: 1),
          _buildItem(context, Icons.payment, 'Phương thức thanh toán', null),
          const Divider(height: 1),
          _buildItem(context, Icons.history, 'Lịch sử đơn hàng', const OrderHistoryScreen()),
          const Divider(height: 1),
          _buildItem(context, Icons.settings_outlined, 'Cài đặt', null),
          const Divider(height: 1),
          _buildItem(context, Icons.help_outline, 'Trợ giúp & Hỗ trợ', null),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Đăng xuất', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () => _logout(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, IconData icon, String title, Widget? targetScreen) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {
        if (targetScreen != null) {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => targetScreen));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chức năng đang phát triển')));
        }
      },
    );
  }
}
