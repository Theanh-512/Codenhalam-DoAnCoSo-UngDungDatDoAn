import 'package:flutter/material.dart';
import 'package:flutter_food_app/common/cart_nav.dart';
import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter_food_app/view/menu/category_restaurants_view.dart';
import 'package:flutter_food_app/view/menu/menu_items_view.dart';
import 'package:flutter_food_app/view/search/search_view.dart';
import 'package:flutter_food_app/model/category_model.dart';
import 'package:flutter_food_app/common/smart_image.dart';

class MenuView extends StatefulWidget {
  const MenuView({super.key});

  @override
  State<MenuView> createState() => _MenuViewState();
}

class _MenuViewState extends State<MenuView> {
  List<CategoryModel> menuArr = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    final res = await CategoryModel.fetchAll();
    if (mounted) {
      setState(() {
        menuArr = res;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Thực đơn",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: TColor.primaryText,
                    ),
                  ),
                  IconButton(
                    onPressed: () => openAppCart(context),
                    icon: Icon(
                      Icons.shopping_cart_outlined,
                      size: 28,
                      color: TColor.primaryText,
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchView()));
                },
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xfff2f2f2),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 15),
                      Icon(Icons.search, color: TColor.secondaryText),
                      const SizedBox(width: 10),
                      Text(
                        "Search food",
                        style: TextStyle(color: TColor.placeholder, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Stack for the Orange BG and the List
            Expanded(
              child: Stack(
                children: [
                  // Orange Backing
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 90, 
                    child: Container(
                      decoration: BoxDecoration(
                        color: TColor.primary,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(45),
                          bottomRight: Radius.circular(45),
                        ),
                      ),
                    ),
                  ),

                  // Menu List
                  ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    itemCount: menuArr.length,
                    itemBuilder: (context, index) {
                      var data = menuArr[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CategoryRestaurantsView(categoryName: data.name),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 25),
                          child: Stack(
                            alignment: Alignment.centerLeft,
                            clipBehavior: Clip.none,
                            children: [
                              // The White Card
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(left: 60, right: 30),
                                padding: const EdgeInsets.only(left: 60, top: 25, bottom: 25, right: 20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(50),
                                    bottomLeft: Radius.circular(50),
                                    topRight: Radius.circular(15),
                                    bottomRight: Radius.circular(15),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      data.name,
                                      style: TextStyle(
                                        color: TColor.primaryText,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "${data.itemsCount} Items",
                                      style: TextStyle(
                                        color: TColor.secondaryText,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // The Circular Image Overlapping on the left
                              Positioned(
                                left: 20,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      )
                                    ]
                                  ),
                                  child: ClipOval(
                                    child: SmartImage(
                                      data.imageUrl,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),

                              // The Arrow button intersecting the right
                              Positioned(
                                right: 12,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.08),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: TColor.primary,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
