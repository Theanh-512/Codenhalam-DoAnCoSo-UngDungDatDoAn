import 'package:flutter/material.dart';
import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter_food_app/model/restaurant_model.dart';
import 'package:flutter_food_app/model/menu_item_model.dart';
import 'package:flutter_food_app/model/cart_item_model.dart';
import 'package:flutter_food_app/common/cart_nav.dart';
import 'package:flutter_food_app/common/smart_image.dart';

class RestaurantDetailView extends StatefulWidget {
  final RestaurantModel restaurant;

  const RestaurantDetailView({super.key, required this.restaurant});

  @override
  State<RestaurantDetailView> createState() => _RestaurantDetailViewState();
}

class _RestaurantDetailViewState extends State<RestaurantDetailView> {
  final CartManager _cart = CartManager();
  List<MenuItemModel> _menuItems = [];
  List<String> _categories = [];
  int _selectedCatIndex = 0;
  bool _loadingMenu = true;

  @override
  void initState() {
    super.initState();
    _loadMenu();
    _cart.addListener(_onCartChanged);
  }

  Future<void> _loadMenu() async {
    final items =
        await MenuItemModel.fetchByRestaurant(widget.restaurant.id);
    if (!mounted) return;
    setState(() {
      _menuItems = items;
      _categories = MenuItemModel.categoriesOf(items);
      _selectedCatIndex = 0;
      _loadingMenu = false;
    });
  }

  @override
  void dispose() {
    _cart.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final r = widget.restaurant;

    return Scaffold(
      backgroundColor: TColor.background,
      body: _loadingMenu
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    _buildSliverAppBar(r),
                    SliverToBoxAdapter(child: _buildRestaurantInfo(r)),
                    if (_categories.isNotEmpty)
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _CategoryTabDelegate(
                          categories: _categories,
                          selectedIndex: _selectedCatIndex,
                          onSelect: (i) =>
                              setState(() => _selectedCatIndex = i),
                          color: TColor.background,
                        ),
                      ),
                    if (_categories.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Chưa có món trong thực đơn.',
                            style: TextStyle(color: TColor.secondaryText),
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final filtered = _menuItems
                                .where((m) =>
                                    m.category ==
                                    _categories[_selectedCatIndex])
                                .toList();
                            if (index >= filtered.length) return null;
                            return _buildMenuItem(filtered[index]);
                          },
                          childCount: _menuItems
                              .where((m) =>
                                  m.category ==
                                  _categories[_selectedCatIndex])
                              .length,
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
                if (!_cart.isEmpty) _buildCartButton(context),
              ],
            ),
    );
  }

  // ── SLIVER APP BAR ──
  Widget _buildSliverAppBar(RestaurantModel r) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: TColor.background,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
          ),
          child: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
          ),
          child: IconButton(
            icon: const Icon(Icons.favorite_border_rounded, color: Colors.black87),
            onPressed: () {},
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: SmartImage(
                r.imageUrl.trim().isNotEmpty
                    ? r.imageUrl.trim()
                    : 'https://picsum.photos/seed/${r.id}/800/450',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => ColoredBox(
                  color: TColor.textfield,
                  child: Center(
                    child: Text(
                      _categoryEmoji(
                        r.category.isNotEmpty ? r.category : r.type1,
                      ),
                      style: const TextStyle(fontSize: 80),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 80,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.45),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── RESTAURANT INFO ──
  Widget _buildRestaurantInfo(RestaurantModel r) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tên + badge open/close
          Row(
            children: [
              Expanded(
                child: Text(
                  r.name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: TColor.primaryText,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: r.isOpen
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  r.isOpen ? "Đang mở" : "Đóng cửa",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: r.isOpen ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (r.typeTagsDisplayLine.isNotEmpty) ...[
            Text(
              r.typeTagsDisplayLine,
              style: TextStyle(
                fontSize: 14,
                color: TColor.secondaryText,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Stats row
          Row(
            children: [
              _statChip(Icons.star_rounded, TColor.primary,
                  "${r.rating} (${r.reviewCount})"),
              const SizedBox(width: 16),
              _statChip(Icons.access_time_rounded, TColor.secondaryText,
                  r.deliveryTime),
              const SizedBox(width: 16),
              _statChip(Icons.delivery_dining_rounded, TColor.secondaryText,
                  r.deliveryFee == 0
                      ? "Miễn phí ship"
                      : CartManager.formatPrice(r.deliveryFee)),
            ],
          ),

          const SizedBox(height: 16),
          Divider(color: TColor.textfield, thickness: 1),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, Color color, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(fontSize: 13, color: TColor.secondaryText)),
      ],
    );
  }

  // ── MENU ITEM CARD ──
  Widget _buildMenuItem(MenuItemModel item) {
    final qty = _cart.quantityOf(item.id);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TColor.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TColor.textfield, width: 1.5),
      ),
      child: Row(
        children: [
          // Ảnh món: URL từ API hoặc ảnh cố định theo id (mỗi món một seed)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 72,
              height: 72,
              child: SmartImage(
                item.imageUrl.trim().isNotEmpty
                    ? item.imageUrl.trim()
                    : 'https://picsum.photos/seed/${item.id}/200/200',
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => ColoredBox(
                  color: TColor.textfield,
                  child: Center(
                    child: Text(
                      item.emoji,
                      style: const TextStyle(fontSize: 36),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Tên + mô tả + giá
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: TColor.primaryText,
                        ),
                      ),
                    ),
                    if (item.isBestSeller)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: TColor.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "🔥 Best",
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: TextStyle(fontSize: 12, color: TColor.secondaryText),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      CartManager.formatPrice(item.price),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: TColor.orangeDark,
                      ),
                    ),
                    // Nút thêm/bớt
                    qty == 0
                        ? _addButton(item)
                        : _quantityControl(item, qty),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Nút "+" khi chưa thêm
  Widget _addButton(MenuItemModel item) {
    return GestureDetector(
      onTap: () => _cart.addItem(item, widget.restaurant.id, widget.restaurant.name),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: TColor.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
      ),
    );
  }

  // Nút tăng/giảm khi đã có trong giỏ
  Widget _quantityControl(MenuItemModel item, int qty) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => _cart.decreaseItem(item.id),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: TColor.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.remove_rounded,
                color: Colors.white, size: 16),
          ),
        ),
        SizedBox(
          width: 28,
          child: Center(
            child: Text(
              qty.toString(),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: TColor.primaryText,
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () => _cart.increaseItem(item.id),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: TColor.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
          ),
        ),
      ],
    );
  }

  // ── FLOATING CART BUTTON ──
  Widget _buildCartButton(BuildContext context) {
    return Positioned(
      bottom: 24,
      left: 20,
      right: 20,
      child: GestureDetector(
        onTap: () => openAppCart(context),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: TColor.primaryDark,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: TColor.primary.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${_cart.totalQuantity}",
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Xem giỏ hàng",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                CartManager.formatPrice(_cart.total),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _categoryEmoji(String cat) {
    if (cat.contains('Phở')) return '🍜';
    if (cat.contains('Bánh mì')) return '🥖';
    if (cat.contains('Pizza')) return '🍕';
    if (cat.contains('Burger')) return '🍔';
    if (cat.contains('Cơm')) return '🍚';
    return '🍱';
  }
}

// ── STICKY CATEGORY TAB ──
class _CategoryTabDelegate extends SliverPersistentHeaderDelegate {
  final List<String> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final Color color;

  _CategoryTabDelegate({
    required this.categories,
    required this.selectedIndex,
    required this.onSelect,
    required this.color,
  });

  @override
  double get minExtent => 52;
  @override
  double get maxExtent => 52;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: color,
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: categories.length,
        itemBuilder: (context, i) {
          final selected = selectedIndex == i;
          return GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? TColor.primary : TColor.textfield,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                categories[i],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : TColor.secondaryText,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  bool shouldRebuild(_CategoryTabDelegate old) =>
      old.selectedIndex != selectedIndex;
}
