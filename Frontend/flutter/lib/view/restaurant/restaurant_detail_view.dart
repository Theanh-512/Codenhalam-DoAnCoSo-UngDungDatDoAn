import 'package:flutter/material.dart';
import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter_food_app/model/restaurant_model.dart';
import 'package:flutter_food_app/model/menu_item_model.dart';
import 'package:flutter_food_app/model/cart_item_model.dart';
import 'package:flutter_food_app/common/cart_nav.dart';
import 'package:flutter_food_app/common/smart_image.dart';
import 'package:flutter_food_app/common_widget/app_search_bar.dart';

class RestaurantDetailView extends StatefulWidget {
  final RestaurantModel restaurant;
  final String? initialCategoryName;

  const RestaurantDetailView({
    super.key,
    required this.restaurant,
    this.initialCategoryName,
  });

  @override
  State<RestaurantDetailView> createState() => _RestaurantDetailViewState();
}

class _RestaurantDetailViewState extends State<RestaurantDetailView> {
  final CartManager _cart = CartManager();
  final TextEditingController _txtSearch = TextEditingController();
  List<MenuItemModel> _menuItems = [];
  List<String> _categories = [];
  int _selectedCatIndex = 0;
  bool _loadingMenu = true;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadMenu();
    _cart.addListener(_onCartChanged);
  }

  Future<void> _loadMenu() async {
    final items = await MenuItemModel.fetchByRestaurant(widget.restaurant.id);
    if (!mounted) return;
    setState(() {
      _menuItems = items;
      _categories = MenuItemModel.categoriesOf(items);

      if (widget.initialCategoryName != null) {
        final idx = _categories.indexOf(widget.initialCategoryName!);
        if (idx != -1) {
          _selectedCatIndex = idx;
        } else {
          _selectedCatIndex = 0;
        }
      } else {
        _selectedCatIndex = 0;
      }

      _loadingMenu = false;
    });
  }

  @override
  void dispose() {
    _cart.removeListener(_onCartChanged);
    _txtSearch.dispose();
    super.dispose();
  }

  void _onCartChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final r = widget.restaurant;

    // Lọc món ăn dựa trên category được chọn VÀ từ khóa tìm kiếm
    final filteredItems = _menuItems.where((m) {
      final matchesCategory = _categories.isEmpty ||
          m.category == _categories[_selectedCatIndex];
      final matchesSearch = _searchQuery.isEmpty ||
          m.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: TColor.background,
      body: _loadingMenu
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    _buildSliverAppBar(r),
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildRestaurantInfo(r),
                          _buildSearchBox(),
                        ],
                      ),
                    ),
                    if (_categories.isNotEmpty)
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _CategoryTabDelegate(
                          categories: _categories,
                          selectedIndex: _selectedCatIndex,
                          onSelect: (i) => setState(() => _selectedCatIndex = i),
                          color: TColor.background,
                        ),
                      ),
                    if (filteredItems.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 60, horizontal: 40),
                          child: Column(
                            children: [
                              Icon(Icons.search_off_rounded,
                                  size: 60, color: TColor.placeholder),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'Chưa có món trong thực đơn.'
                                    : 'Không tìm thấy món "${_searchQuery}"',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: TColor.secondaryText, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return _buildMenuItem(filteredItems[index]);
                          },
                          childCount: filteredItems.length,
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ],
                ),
                if (!_cart.isEmpty) _buildCartButton(context),
              ],
            ),
    );
  }

  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: AppSearchBar.inline(
        controller: _txtSearch,
        hintText: 'Tìm món trong nhà hàng...',
        onChanged: (val) => setState(() => _searchQuery = val),
        onClear: () => setState(() => _searchQuery = ''),
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
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: SmartImage(
              item.imageUrl.trim().isNotEmpty
                  ? item.imageUrl.trim()
                  : 'https://picsum.photos/seed/${item.id}/200/200',
              width: 85,
              height: 85,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: TColor.primaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: TextStyle(fontSize: 12, color: TColor.secondaryText),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  CartManager.formatPrice(item.price),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: TColor.primary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (qty == 0)
                _addButton(item)
              else
                _quantityControl(item, qty),
            ],
          ),
        ],
      ),
    );
  }

  Widget _addButton(MenuItemModel item) {
    return InkWell(
      onTap: () => _cart.addItem(item, widget.restaurant.id, widget.restaurant.name),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: TColor.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: TColor.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _quantityControl(MenuItemModel item, int qty) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _cart.increaseItem(item.id),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: TColor.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            qty.toString(),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: TColor.primaryText,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => _cart.decreaseItem(item.id),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: TColor.primary),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.remove_rounded, color: TColor.primary, size: 18),
          ),
        ),
      ],
    );
  }

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
