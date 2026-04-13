import 'package:flutter/material.dart';

class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Đơn hàng'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final isDelivered = index > 2;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: isDelivered ? Colors.green[100] : Colors.orange[100],
              child: Icon(
                isDelivered ? Icons.check_circle : Icons.pending,
                color: isDelivered ? Colors.green : Colors.orange,
              ),
            ),
            title: Text('Đơn hàng #${1000 + index}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(isDelivered ? 'Đã giao thành công' : 'Đang xử lý'),
            trailing: Text(
              '${(index + 1) * 150}.000đ',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Xem chi tiết đơn hàng (đang phát triển)')),
              );
            },
          );
        },
      ),
    );
  }
}
