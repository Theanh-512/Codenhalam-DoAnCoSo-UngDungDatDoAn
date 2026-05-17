import 'package:flutter/material.dart';
import 'package:flutter_food_app/common/add_to_cart_bar.dart';
import 'package:flutter_food_app/common/cart_nav.dart';
import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter_food_app/common/smart_image.dart';
import 'package:flutter_food_app/model/cart_item_model.dart';
import 'package:flutter_food_app/model/menu_item_model.dart';

class ItemDetailView extends StatefulWidget {
  final Map<String, String> itemObj;

  const ItemDetailView({super.key, required this.itemObj});

  @override
  State<ItemDetailView> createState() => _ItemDetailViewState();
}

class _ItemDetailViewState extends State<ItemDetailView> {
  final CartManager _cart = CartManager();
  late int _quantity;

  @override
  void initState() {
    super.initState();
    final inCart = _cart.quantityOf(_resolvedItemId);
    _quantity = inCart > 0 ? inCart : 1;
    _cart.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    _cart.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    final inCart = _cart.quantityOf(_resolvedItemId);
    if (!mounted) return;
    setState(() {
      if (inCart > 0) _quantity = inCart;
    });
  }

  String get _resolvedItemId {
    final id = widget.itemObj['id']?.trim() ?? '';
    if (id.isNotEmpty) return id;
    final name = widget.itemObj['name'] ?? '';
    final rid = widget.itemObj['restaurant_id'] ?? '';
    return 'tmp-$rid-$name';
  }

  double get _unitPrice =>
      double.tryParse(widget.itemObj['price']?.toString() ?? '') ?? 75000;

  MenuItemModel _toMenuItem() {
    return MenuItemModel(
      id: _resolvedItemId,
      restaurantId: widget.itemObj['restaurant_id'] ?? '',
      name: widget.itemObj['name'] ?? 'Món ăn',
      description: widget.itemObj['description'] ?? '',
      price: _unitPrice,
      category: widget.itemObj['category'] ?? '',
      emoji: widget.itemObj['emoji'] ?? '🍽️',
      imageUrl: widget.itemObj['image'] ?? '',
    );
  }

  void _addToCart() {
    final item = _toMenuItem();
    final rid = item.restaurantId;
    final rname = widget.itemObj['restaurant_name'] ?? '';
    _cart.removeItem(item.id);
    _cart.addItem(item, rid, rname, quantity: _quantity);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã thêm $_quantity phần vào giỏ hàng!'),
        backgroundColor: TColor.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.itemObj['id']?.toString() ?? 'item';
    final rawImg = widget.itemObj['image'];
    final img = (rawImg is String && rawImg.trim().isNotEmpty)
        ? rawImg.trim()
        : 'https://picsum.photos/seed/$id/500/500';
    final lineTotal = CartManager.formatPrice(_unitPrice * _quantity);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SmartImage(
                        img,
                        width: double.infinity,
                        height: MediaQuery.sizeOf(context).width,
                        fit: BoxFit.cover,
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                    color: Colors.white),
                              ),
                              IconButton(
                                onPressed: () => openAppCart(context),
                                icon: const Icon(Icons.shopping_cart_outlined,
                                    color: Colors.white, size: 28),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 50,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(50),
                              topRight: Radius.circular(50),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 25,
                        right: 35,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Icon(Icons.favorite,
                              color: TColor.primary, size: 25),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.itemObj['name'] ??
                              'Gà nướng Tandoori Pizza',
                          style: TextStyle(
                            color: TColor.primaryText,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (widget.itemObj['restaurant_name']?.toString().isNotEmpty == true) ...[
                          const SizedBox(height: 6),
                          Text(
                            "Quán: ${widget.itemObj['restaurant_name']}",
                            style: TextStyle(
                              color: TColor.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: List.generate(5, (index) {
                                    return Icon(
                                      Icons.star,
                                      color: index < 4
                                          ? TColor.primary
                                          : TColor.placeholder,
                                      size: 16,
                                    );
                                  }),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '4 Sao Đánh giá',
                                  style: TextStyle(
                                    color: TColor.primary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'đ ${_unitPrice.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: TColor.primaryText,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '/ phần',
                                  style: TextStyle(
                                    color: TColor.secondaryText,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Mô tả',
                          style: TextStyle(
                            color: TColor.primaryText,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.itemObj['description']?.isNotEmpty == true
                              ? widget.itemObj['description']!
                              : 'Đến với hương vị đích thực, sự mềm mại của gà hòa quyện với phong cách nướng Tandoori chuẩn vị, rắc thêm chút phô mai dai và đế bánh nướng giòn tan trên mọi nẻo đường ẩm thực.',
                          style: TextStyle(
                            color: TColor.secondaryText,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 25),
                        Text(
                          'Tùy chỉnh Đơn hàng',
                          style: TextStyle(
                            color: TColor.primaryText,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 15),
                        _greyRow('- Chọn cỡ phần ăn -'),
                        const SizedBox(height: 15),
                        _greyRow('- Chọn nguyên liệu -'),
                        const SizedBox(height: 25),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Số lượng',
                              style: TextStyle(
                                color: TColor.primaryText,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Row(
                              children: [
                                _qtyCircle(
                                  icon: Icons.remove,
                                  onTap: () {
                                    if (_quantity > 1) {
                                      setState(() => _quantity--);
                                    }
                                  },
                                ),
                                const SizedBox(width: 15),
                                Text(
                                  '$_quantity',
                                  style: TextStyle(
                                    color: TColor.primaryText,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                _qtyCircle(
                                  icon: Icons.add,
                                  onTap: () => setState(() => _quantity++),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          AddToCartBottomBar(
            lineTotalFormatted: lineTotal,
            onAddToCart: _addToCart,
            onOpenCart: () => openAppCart(context),
          ),
        ],
      ),
    );
  }

  Widget _greyRow(String label) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: TColor.textfield,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: TColor.primaryText)),
          Icon(Icons.keyboard_arrow_down, color: TColor.secondaryText),
        ],
      ),
    );
  }

  Widget _qtyCircle({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 35,
        height: 35,
        decoration: BoxDecoration(
          color: TColor.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
