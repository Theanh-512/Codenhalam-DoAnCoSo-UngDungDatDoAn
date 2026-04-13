import 'package:flutter/material.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _logout(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Người dùng Demo',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text('Thành viên Bạc', style: TextStyle(color: Colors.grey)),
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
            _buildMenuItems(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _buildItem(Icons.favorite_border, 'Món yêu thích'),
          const Divider(height: 1),
          _buildItem(Icons.location_on_outlined, 'Địa chỉ giao hàng'),
          const Divider(height: 1),
          _buildItem(Icons.payment, 'Phương thức thanh toán'),
          const Divider(height: 1),
          _buildItem(Icons.history, 'Lịch sử đơn hàng'),
          const Divider(height: 1),
          _buildItem(Icons.settings_outlined, 'Cài đặt'),
          const Divider(height: 1),
          _buildItem(Icons.help_outline, 'Trợ giúp & Hỗ trợ'),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Đăng xuất', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {},
    );
  }
}
