import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: index == 0 ? Colors.red[100] : Colors.blue[100],
              child: Icon(
                index == 0 ? Icons.local_offer : Icons.delivery_dining,
                color: index == 0 ? Colors.red : Colors.blue,
              ),
            ),
            title: Text(
              index == 0 ? 'Khuyến mãi đặc biệt! 🎉' : 'Đơn hàng đang giao',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              index == 0
                  ? 'Giảm 50% cho người dùng mới khi đặt Pizza 4P\'s.'
                  : 'Tài xế đang trên đường đến. Vui lòng chuẩn bị nhận hàng.',
            ),
            trailing: const Text(
              '12:00',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          );
        },
      ),
    );
  }
}
