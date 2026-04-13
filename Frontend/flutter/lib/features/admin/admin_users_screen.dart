import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/restaurant_provider.dart';

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiService = ref.watch(apiServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Người dùng'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: apiService.getUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return const Center(child: Text('Không có người dùng nào.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final user = users[index];
              final isAdmin = user['email'] == 'admin@foodapp.com';

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isAdmin ? Colors.purple[100] : Colors.blue[100],
                  child: Icon(
                    isAdmin ? Icons.admin_panel_settings : Icons.person,
                    color: isAdmin ? Colors.purple : Colors.blue,
                  ),
                ),
                title: Text(user['fullName'] ?? 'Người dùng', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(user['email'] ?? ''),
                trailing: isAdmin ? null : IconButton(
                  icon: const Icon(Icons.block, color: Colors.grey),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tính năng Khóa người dùng đang phát triển!')),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
