import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/category_item.dart';
import '../../shared/widgets/restaurant_card.dart';
import '../../core/providers/restaurant_provider.dart';
import '../../core/theme.dart';
import 'restaurant_detail_screen.dart';
import 'ai_recommendation_screen.dart';
import 'food_recognition_screen.dart';
import '../../core/providers/cart_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int selectedCategoryIndex = 0;
  final categories = ['Tất cả', 'Trà sữa', 'Cà phê', 'Bánh ngọt', 'Ăn vặt'];

  @override
  Widget build(BuildContext context) {
    final restaurantsAsyncValue = ref.watch(restaurantsProvider);
    final cartItems = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(restaurantsProvider.future),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Chào buổi sáng 🍵', style: TextStyle(fontSize: 14, color: Colors.grey)),
                          Text('Thưởng thức trà thôi!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(Icons.shopping_basket_outlined, color: AppTheme.darkGreen),
                            if (cartItems.isNotEmpty)
                              Positioned(
                                right: -5,
                                top: -5,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                                  child: Text('${cartItems.length}', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                ),
                              )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),

              // AI Banner (Sour candy theme)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  height: 160,
                  decoration: BoxDecoration(
                    color: const Color(0xFFA5D6A7),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: 10, bottom: 10, top: 10,
                        child: Image.network('https://images.unsplash.com/photo-1550617931-e17a7b70dce2?w=300', fit: BoxFit.contain),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Gợi ý từ AI 🧠', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            const Text('Predict your vibe,\nenjoy the taste!', style: TextStyle(color: Colors.white, fontSize: 14)),
                            const Spacer(),
                            ElevatedButton(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AIRecommendationScreen())),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppTheme.darkGreen,
                                minimumSize: const Size(100, 36),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              child: const Text('Thử ngay', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Categories
              SliverToBoxAdapter(
                child: Container(
                  height: 45,
                  margin: const EdgeInsets.symmetric(vertical: 24),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => setState(() => selectedCategoryIndex = index),
                        child: CategoryItem(
                          name: categories[index],
                          isSelected: selectedCategoryIndex == index,
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Top Favorite Section
              const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: Text('Đang thịnh hành 🔥', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              restaurantsAsyncValue.when(
                data: (restaurants) => SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.8,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final restaurant = restaurants[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => RestaurantDetailScreen(restaurant: restaurant),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                                    child: Image.network(restaurant.imageUrl, fit: BoxFit.cover, width: double.infinity),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(restaurant.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('🔥 Hot', style: TextStyle(color: AppTheme.primaryColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                          Text('\$${15 + index}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        ],
                                      )
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: restaurants.length,
                    ),
                  ),
                ),
                loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
                error: (err, s) => SliverFillRemaining(child: Center(child: Text('Lỗi: $err'))),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }
}
