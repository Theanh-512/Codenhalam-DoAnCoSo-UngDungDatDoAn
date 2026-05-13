import 'package:flutter/material.dart';
import 'package:flutter_food_app/common/cart_nav.dart';
import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter_food_app/common/smart_image.dart';
import 'package:flutter_food_app/view/menu/item_detail_view.dart';
import 'package:flutter_food_app/model/menu_item_model.dart';
import 'package:intl/intl.dart';

class MenuItemsView extends StatefulWidget {
  final Map<String, String> mObj;
  const MenuItemsView({super.key, required this.mObj});

  @override
  State<MenuItemsView> createState() => _MenuItemsViewState();
}

class _MenuItemsViewState extends State<MenuItemsView> {
  List<MenuItemModel> _allItems = [];
  List<MenuItemModel> _filteredItems = [];
  bool _isLoading = true;
  bool _isGrid = true;
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchItems();
    _search.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _search.removeListener(_onSearchChanged);
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _search.text.toLowerCase().trim();
    setState(() {
      _filteredItems = q.isEmpty
          ? List.from(_allItems)
          : _allItems.where((i) => i.name.toLowerCase().contains(q)).toList();
    });
  }

  void _fetchItems() async {
    final catName = widget.mObj['name'] ?? '';
    final data = await MenuItemModel.fetchByCategory(catName);
    if (mounted) {
      setState(() {
        _allItems = data;
        _filteredItems = List.from(data);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      backgroundColor: TColor.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon:
              Icon(Icons.arrow_back_ios_new_rounded, color: TColor.primaryText),
        ),
        title: Text(
          widget.mObj['name'] ?? 'Thực đơn',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: TColor.primaryText),
        ),
        actions: [
          IconButton(
            onPressed: () => setState(() => _isGrid = !_isGrid),
            icon: Icon(
                _isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded,
                color: TColor.primaryText),
          ),
          IconButton(
            onPressed: () => openAppCart(context),
            icon: Icon(Icons.shopping_cart_outlined,
                size: 26, color: TColor.primaryText),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: TColor.textfield,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Icon(Icons.search, color: TColor.placeholder),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _search,
                        decoration: InputDecoration(
                          hintText:
                              'Tìm trong ${widget.mObj["name"] ?? "danh mục"}...',
                          hintStyle: TextStyle(
                              color: TColor.placeholder, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    if (_search.text.isNotEmpty)
                      IconButton(
                        onPressed: () {
                          _search.clear();
                        },
                        icon: Icon(Icons.close,
                            color: TColor.placeholder, size: 18),
                      ),
                  ],
                ),
              ),
            ),

            // Divider + count
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Text(
                    '${_filteredItems.length} món',
                    style: TextStyle(
                        fontSize: 13,
                        color: TColor.secondaryText,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

            // Items Grid / List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off_rounded,
                                  size: 60, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text('Không tìm thấy món nào',
                                  style: TextStyle(
                                      color: TColor.secondaryText,
                                      fontSize: 16)),
                            ],
                          ),
                        )
                      : _isGrid
                          ? _buildGrid(currency)
                          : _buildList(currency),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(NumberFormat currency) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.78,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        final imgUrl = item.imageUrl.isNotEmpty
            ? item.imageUrl
            : 'https://picsum.photos/seed/${item.id}/400/400';

        return GestureDetector(
          onTap: () => _openDetail(item, imgUrl),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Expanded(
                  flex: 6,
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: SmartImage(
                      imgUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: TColor.textfield,
                        child: Center(
                          child: Text(item.emoji,
                              style: const TextStyle(fontSize: 50)),
                        ),
                      ),
                    ),
                  ),
                ),
                // Info
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: TColor.primaryText,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.star_rounded,
                                size: 13, color: Colors.amber.shade600),
                            const SizedBox(width: 2),
                            Text('4.9',
                                style: TextStyle(
                                    fontSize: 11, color: TColor.secondaryText)),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                currency.format(item.price),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: TColor.primary,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _openDetail(item, imgUrl),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: TColor.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.add_rounded,
                                    color: Colors.white, size: 18),
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
      },
    );
  }

  Widget _buildList(NumberFormat currency) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        final imgUrl = item.imageUrl.isNotEmpty
            ? item.imageUrl
            : 'https://picsum.photos/seed/${item.id}/400/400';

        return GestureDetector(
          onTap: () => _openDetail(item, imgUrl),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SmartImage(
                    imgUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 80,
                      height: 80,
                      color: TColor.textfield,
                      child: Center(
                          child: Text(item.emoji,
                              style: const TextStyle(fontSize: 36))),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: TColor.primaryText),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(
                          item.description.isNotEmpty
                              ? item.description
                              : item.category,
                          style: TextStyle(
                              fontSize: 12, color: TColor.secondaryText),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(currency.format(item.price),
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: TColor.primary)),
                          const Spacer(),
                          Row(
                            children: [
                              Icon(Icons.star_rounded,
                                  size: 14, color: Colors.amber.shade600),
                              Text(' 4.9',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: TColor.secondaryText)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openDetail(MenuItemModel item, String imgUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemDetailView(
          itemObj: {
            'id': item.id,
            'restaurant_id': item.restaurantId,
            'restaurant_name': '',
            'name': item.name,
            'price': item.price.toStringAsFixed(0),
            'image': imgUrl,
            'category': item.category,
            'emoji': item.emoji,
            'description': item.description,
            'rate': '4.9',
            'food_type': item.category,
          },
        ),
      ),
    );
  }
}
