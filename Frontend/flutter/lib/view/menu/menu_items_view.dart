import 'package:flutter/material.dart';
import 'package:flutter_food_app/common/cart_nav.dart';
import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter_food_app/view/menu/item_detail_view.dart';

import 'package:flutter_food_app/model/menu_item_model.dart';

class MenuItemsView extends StatefulWidget {
  final Map<String, String> mObj;
  const MenuItemsView({super.key, required this.mObj});

  @override
  State<MenuItemsView> createState() => _MenuItemsViewState();
}

class _MenuItemsViewState extends State<MenuItemsView> {
  List<MenuItemModel> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  void _fetchItems() async {
    final catName = widget.mObj["name"] ?? "";
    final data = await MenuItemModel.fetchByCategory(catName);
    if (mounted) {
      setState(() {
        _items = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: TColor.primaryText),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.mObj["name"] ?? "Danh mục",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: TColor.primaryText,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => openAppCart(context),
                    icon: Icon(Icons.shopping_cart_outlined,
                        size: 28, color: TColor.primaryText),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: TColor.textfield,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 15),
                    Icon(Icons.search, color: TColor.secondaryText),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Tìm kiếm món ăn",
                          hintStyle: TextStyle(color: TColor.placeholder, fontSize: 14),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),

            // List View
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                  ? const Center(child: Text("Danh mục này chưa có món ăn"))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        var iter = _items[index];
                        String imgUrl = iter.imageUrl.isNotEmpty
                            ? iter.imageUrl
                            : 'https://picsum.photos/seed/${iter.id}/400/400';
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ItemDetailView(itemObj: {
                                  "id": iter.id,
                                  "restaurant_id": iter.restaurantId,
                                  "restaurant_name": "",
                                  "name": iter.name,
                                  "price": iter.price.toStringAsFixed(0),
                                  "image": imgUrl,
                                  "category": iter.category,
                                  "emoji": iter.emoji,
                                  "description": iter.description,
                                  "rate": "4.9",
                                  "food_type": iter.category,
                                }),
                              ),
                            );
                          },
                          child: Container(
                            height: 200,
                            margin: const EdgeInsets.only(bottom: 2),
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: imgUrl.startsWith('http') 
                                      ? NetworkImage(imgUrl) as ImageProvider 
                                      : AssetImage(imgUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Container(
                              // Dark Gradient Overlay from bottom
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withValues(alpha: 0.8),
                                    Colors.transparent,
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                              ),
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    iter.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Icon(Icons.star, color: TColor.primary, size: 14),
                                      const SizedBox(width: 5),
                                      Text(
                                        "4.9 Đánh giá · ${iter.category}",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
