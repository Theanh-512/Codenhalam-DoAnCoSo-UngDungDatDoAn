import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/restaurant_provider.dart';
import '../../core/theme.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: const Text('My cart', style: TextStyle(fontWeight: FontWeight.black)),
        centerTitle: true,
      ),
      body: cartItems.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Cart Items
                  ...cartItems.map((item) => _buildCartItem(item, cartNotifier)).toList(),
                  
                  const SizedBox(height: 24),
                  
                  // Summary Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Column(
                      children: [
                        _summaryRow('Item total', '\$${cartNotifier.totalPrice}'),
                        const SizedBox(height: 12),
                        _summaryRow('Delivery fee', '\$2'),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(color: AppTheme.bgColor),
                        ),
                        _summaryRow('Total', '\$${cartNotifier.totalPrice + 2}', isTotal: true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Payment Method
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      children: [
                        const Icon(Icons.credit_card, color: Colors.blue),
                        const SizedBox(width: 12),
                        const Text('VISA  *** *** 520', style: TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  ElevatedButton(
                    onPressed: _isLoading ? null : () {},
                    child: _isLoading ? const CircularProgressIndicator() : const Text('CHECK OUT'),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }

  Widget _buildCartItem(CartItem item, CartNotifier notifier) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Row(
        children: [
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(image: NetworkImage(item.imageUrl), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('M, Ice, 70% Sugar', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                const SizedBox(height: 4),
                Text('\$${item.price}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkGreen)),
              ],
            ),
          ),
          Row(
            children: [
              _qtyBtn(Icons.remove, () => notifier.updateQuantity(item.foodItemId, -1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              _qtyBtn(Icons.add, () => notifier.updateQuantity(item.foodItemId, 1)),
            ],
          )
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback tap) {
    return GestureDetector(
      onTap: tap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
        child: Icon(icon, size: 12),
      ),
    );
  }

  Widget _summaryRow(String label, String val, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isTotal ? Colors.black : Colors.grey[500], fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
        Text(val, style: TextStyle(fontSize: isTotal ? 20 : 16, fontWeight: FontWeight.bold, color: isTotal ? AppTheme.primaryColor : Colors.black)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_basket_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          const Text('Your cart is empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
