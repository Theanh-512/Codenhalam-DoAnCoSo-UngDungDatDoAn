import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/restaurant_provider.dart';

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.read(authProvider);
    if (user == null) return const Scaffold(body: Center(child: Text('Vui lòng đăng nhập')));

    final apiService = ref.watch(apiServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử đơn hàng'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: apiService.getUserOrders(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Chưa có lịch sử đặt hàng.'));
          }

          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return const Center(child: Text('Chưa có lịch sử đặt hàng.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Đơn hàng #${order['id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(order['status'] ?? 'Pending', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Ngày đặt: ${DateTime.parse(order['orderDate']).toLocal().toString().split(".")[0]}'),
                      Text('Tổng tiền: ${order['totalAmount']} đ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Divider(),
                      const Text('Chi tiết món:', style: TextStyle(color: Colors.grey)),
                      ...((order['orderItems'] as List<dynamic>).map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text('${item['quantity']}x ${item['foodItem']['name']}'),
                        );
                      }).toList()),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
