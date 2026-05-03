import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/restaurant.dart';
import '../../core/providers/restaurant_provider.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/theme.dart';

class RestaurantDetailScreen extends ConsumerStatefulWidget {
  final Restaurant restaurant;

  const RestaurantDetailScreen({super.key, required this.restaurant});

  @override
  ConsumerState<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends ConsumerState<RestaurantDetailScreen> {
  int quantity = 1;
  String selectedSize = 'Medium';
  String selectedSugar = '70%';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: Stack(
        children: [
          // Content
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Image with rounded bottom header effect
                Container(
                  height: MediaQuery.of(context).size.height * 0.45,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
                    image: DecorationImage(
                      image: NetworkImage(widget.restaurant.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.restaurant.name,
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.black, color: AppTheme.darkGreen),
                            ),
                          ),
                          const Text('\$25', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(widget.restaurant.description, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                      
                      const SizedBox(height: 32),
                      
                      // Size Selection
                      const Text('Size', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        children: ['Small', 'Medium', 'Large'].map((size) {
                          bool isSelected = selectedSize == size;
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: ActionChip(
                              label: Text(size),
                              onPressed: () => setState(() => selectedSize = size),
                              backgroundColor: isSelected ? AppTheme.secondaryGreen : Colors.white,
                              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      // Toppings (Mocked as icons like in image)
                      const Text('Topping', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _ToppingIcon(icon: Icons.brightness_3, label: 'Pear', price: '\$5'),
                          _ToppingIcon(icon: Icons.Eco, label: 'Lemongrass', price: '\$2'),
                          _ToppingIcon(icon: Icons.grass, label: 'Cinnamon', price: '\$1'),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Sugar Level
                      const Text('Sugar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        children: ['Ice', '100%', '70%', '50%'].map((sugar) {
                          bool isSelected = selectedSugar == sugar;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: ActionChip(
                                label: Text(sugar),
                                onPressed: () => setState(() => selectedSugar = sugar),
                                backgroundColor: isSelected ? AppTheme.secondaryGreen : Colors.white,
                                labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black, fontSize: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 120), // Spacing for footer
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Header Buttons
          Positioned(
            top: 50, left: 16, right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _CircleBtn(icon: Icons.arrow_back_ios_new, onTap: () => Navigator.pop(context)),
                _CircleBtn(icon: Icons.shopping_bag_outlined, onTap: () {}),
              ],
            ),
          ),

          // Bottom Bar
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Row(
                children: [
                  // Quantity
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        IconButton(onPressed: () => setState(() => quantity > 1 ? quantity-- : null), icon: const Icon(Icons.remove, size: 16)),
                        Text('$quantity', style: const TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(onPressed: () => setState(() => quantity++), icon: const Icon(Icons.add, size: 16)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(cartProvider.notifier).addItem(
                          widget.restaurant.id,
                          widget.restaurant.name,
                          25.0, // Mock price
                          widget.restaurant.imageUrl,
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                      child: const Text('Add to order'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]),
        child: Icon(icon, size: 18, color: AppTheme.darkGreen),
      ),
    );
  }
}

class _ToppingIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final String price;
  const _ToppingIcon({required this.icon, required this.label, required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90, height: 100,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[100]!)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          Text(price, style: const TextStyle(fontSize: 10, color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
