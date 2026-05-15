import 'package:flutter/material.dart';
import 'package:flutter_food_app/common/cart_nav.dart';
import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter_food_app/common/smart_image.dart';
import 'package:flutter_food_app/model/category_model.dart';
import 'package:flutter_food_app/model/restaurant_model.dart';
import 'package:flutter_food_app/view/restaurant/restaurant_detail_view.dart';
import 'package:flutter_food_app/common_widget/app_search_bar.dart';

class MenuView extends StatefulWidget {
  const MenuView({super.key});

  @override
  State<MenuView> createState() => _MenuViewState();
}

class _MenuViewState extends State<MenuView> {
  List<CategoryModel> _categories = [];
  List<RestaurantModel> _restaurants = [];
  int _selectedIndex = 0;
  bool _loadingCategories = true;
  bool _loadingRestaurants = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loadingCategories = true;
      _error = null;
    });
    final list = await CategoryModel.fetchAll();
    if (!mounted) return;
    if (list.isEmpty) {
      setState(() {
        _categories = [];
        _loadingCategories = false;
        _error = 'Không tải được danh mục.\nKiểm tra backend đang chạy (port 5149).';
      });
      return;
    }
    setState(() {
      _categories = list;
      _selectedIndex = 0;
      _loadingCategories = false;
    });
    _loadRestaurants(list.first.name);
  }

  Future<void> _loadRestaurants(String categoryName) async {
    setState(() => _loadingRestaurants = true);
    final list = await RestaurantModel.fetchByCategory(categoryName);
    if (!mounted) return;
    setState(() {
      _restaurants = list;
      _loadingRestaurants = false;
    });
  }

  void _onCategoryTap(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    _loadRestaurants(_categories[index].name);
  }

  CategoryModel? get _selectedCategory =>
      _categories.isEmpty ? null : _categories[_selectedIndex];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            const SizedBox(height: 12),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
      child: Row(
        children: [
          Text(
            'Thực đơn',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: TColor.primaryText,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => openAppCart(context),
            icon: Icon(Icons.shopping_cart_outlined, size: 26, color: TColor.primaryText),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: AppSearchBar.tap(),
    );
  }

  Widget _buildBody() {
    if (_loadingCategories) {
      return const Center(child: CircularProgressIndicator(color: Color(0xff00B14F)));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded, size: 56, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: TColor.secondaryText, fontSize: 15, height: 1.4),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _loadCategories,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
                style: FilledButton.styleFrom(
                  backgroundColor: TColor.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCategorySidebar(),
        Expanded(child: _buildRestaurantPanel()),
      ],
    );
  }

  Widget _buildCategorySidebar() {
    return Container(
      width: 108,
      margin: const EdgeInsets.only(left: 0),
      decoration: BoxDecoration(
        color: TColor.primary,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: TColor.primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final selected = index == _selectedIndex;
          return GestureDetector(
            onTap: () => _onCategoryTap(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
              decoration: BoxDecoration(
                color: selected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCategoryIcon(cat, selected),
                  const SizedBox(height: 6),
                  Text(
                    cat.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      height: 1.2,
                      color: selected ? TColor.primary : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryIcon(CategoryModel cat, bool selected) {
    if (cat.imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SmartImage(
          cat.imageUrl,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _emojiIcon(cat.displayEmoji, selected),
        ),
      );
    }
    return _emojiIcon(cat.displayEmoji, selected);
  }

  Widget _emojiIcon(String emoji, bool selected) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? TColor.primary.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 24)),
    );
  }

  Widget _buildRestaurantPanel() {
    final cat = _selectedCategory;
    if (cat == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  cat.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: TColor.primaryText,
                  ),
                ),
              ),
              if (cat.itemsCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: TColor.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${cat.itemsCount} món',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: TColor.primary),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: _loadingRestaurants
              ? const Center(child: CircularProgressIndicator(color: Color(0xff00B14F)))
              : _restaurants.isEmpty
                  ? _buildEmptyRestaurants()
                  : RefreshIndicator(
                      color: TColor.primary,
                      onRefresh: () => _loadRestaurants(cat.name),
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(12, 0, 16, 16),
                        itemCount: _restaurants.length,
                        itemBuilder: (context, index) {
                          final r = _restaurants[index];
                          return _MenuRestaurantCard(
                            restaurant: r,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RestaurantDetailView(
                                    restaurant: r,
                                    initialCategoryName: cat.name,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildEmptyRestaurants() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront_outlined, size: 52, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'Chưa có nhà hàng\ncho danh mục này',
              textAlign: TextAlign.center,
              style: TextStyle(color: TColor.secondaryText, fontSize: 15, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuRestaurantCard extends StatelessWidget {
  final RestaurantModel restaurant;
  final VoidCallback onTap;

  const _MenuRestaurantCard({required this.restaurant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
              child: SmartImage(
                restaurant.imageUrl,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 100,
                  height: 100,
                  color: Colors.grey.shade200,
                  child: Icon(Icons.restaurant, color: Colors.grey.shade400, size: 36),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: TColor.primaryText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, color: Colors.amber.shade700, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${restaurant.rating}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: TColor.primaryText,
                          ),
                        ),
                        Text(
                          ' (${restaurant.reviewCount}+)',
                          style: TextStyle(fontSize: 12, color: TColor.secondaryText),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      restaurant.typeTagsDisplayLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: TColor.secondaryText),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 13, color: TColor.secondaryText),
                        const SizedBox(width: 4),
                        Text(
                          restaurant.deliveryTime,
                          style: TextStyle(fontSize: 11, color: TColor.secondaryText),
                        ),
                        const Spacer(),
                        if (restaurant.isOpen)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Mở cửa',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
