import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/restaurant.dart';
import '../../core/providers/restaurant_provider.dart';
import '../../core/providers/cart_provider.dart';

class RestaurantDetailScreen extends ConsumerStatefulWidget {
  final Restaurant restaurant;

  const RestaurantDetailScreen({super.key, required this.restaurant});

  @override
  ConsumerState<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends ConsumerState<RestaurantDetailScreen> {
  List<dynamic> _menu = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final menu = await apiService.getRestaurantMenu(widget.restaurant.id);
      if (mounted) {
        setState(() {
          _menu = menu;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.restaurant.name),
              background: Image.network(
                widget.restaurant.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => const Icon(Icons.restaurant, size: 50),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Thông tin nhà hàng', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Địa chỉ: ${widget.restaurant.address}'),
                  Text('Giờ mở cửa: ${widget.restaurant.openingHours}'),
                  const SizedBox(height: 16),
                  const Divider(),
                  const Text('Thực đơn', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (_menu.isEmpty)
            const SliverFillRemaining(child: Center(child: Text('Chưa có món ăn nào.')))
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = _menu[index];
                  return ListTile(
                    leading: Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(item['imageUrl'] ?? ''),
                          fit: BoxFit.cover,
                          onError: (_, __) => const Icon(Icons.fastfood),
                        ),
                      ),
                    ),
                    title: Text(item['name'] ?? ''),
                    subtitle: Text('${item['price']} đ'),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.deepOrange),
                      onPressed: () {
                        ref.read(cartProvider.notifier).addItem(
                          item['id'],
                          item['name'],
                          (item['price'] as num).toDouble(),
                          item['imageUrl'] ?? '',
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Đã thêm ${item['name']} vào giỏ hàng'), duration: const Duration(seconds: 1)),
                        );
                      },
                    ),
                  );
                },
                childCount: _menu.length,
              ),
            ),
        ],
      ),
      bottomNavigationBar: Consumer(
        builder: (context, ref, child) {
          final cart = ref.watch(cartProvider);
          if (cart.isEmpty) return const SizedBox.shrink();
          
          final totalPrice = ref.read(cartProvider.notifier).totalPrice;
          return Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: () {
                Navigator.of(context).pop(); // Go back to Home, customer can navigate to Cart tab natively
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vào Giỏ hàng để thanh toán nhé!')),
                );
              },
              child: Text('Giỏ hàng (${cart.length} món) - $totalPrice đ', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          );
        },
      ),
    );
  }
}
