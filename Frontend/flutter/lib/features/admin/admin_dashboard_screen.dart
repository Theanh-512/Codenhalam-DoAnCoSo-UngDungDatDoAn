import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import 'admin_restaurants_screen.dart';
import 'admin_users_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_route_optimization_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  void _logout(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          )
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildAdminCard(context, Icons.restaurant, 'Quản lý\nNhà hàng', Colors.orange, const AdminRestaurantsScreen()),
          _buildAdminCard(context, Icons.fastfood, 'Quản lý\nMón ăn', Colors.red, null),
          _buildAdminCard(context, Icons.people, 'Quản lý\nNgười dùng', Colors.blue, const AdminUsersScreen()),
          _buildAdminCard(context, Icons.receipt, 'Quản lý\nĐơn hàng', Colors.green, const AdminOrdersScreen()),
          _buildAdminCard(context, Icons.route, 'Tối ưu\nLộ trình', Colors.purple, const AdminRouteScreen()),
          _buildAdminCard(context, Icons.analytics, 'Báo cáo\nThống kê', Colors.purple, null),
          _buildAdminCard(context, Icons.settings, 'Cài đặt\nHệ thống', Colors.grey, null),
        ],
      ),
    );
  }

  Widget _buildAdminCard(BuildContext context, IconData icon, String title, MaterialColor color, Widget? targetScreen) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          if (targetScreen != null) {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => targetScreen));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Tính năng $title đang được phát triển!')),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
