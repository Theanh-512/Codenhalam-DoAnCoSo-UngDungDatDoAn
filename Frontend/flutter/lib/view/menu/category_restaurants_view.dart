import 'package:flutter/material.dart';
import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter_food_app/common/smart_image.dart';
import 'package:flutter_food_app/model/restaurant_model.dart';
import 'package:flutter_food_app/view/restaurant/restaurant_detail_view.dart';

class CategoryRestaurantsView extends StatefulWidget {
  final String categoryName;
  const CategoryRestaurantsView({super.key, required this.categoryName});

  @override
  State<CategoryRestaurantsView> createState() => _CategoryRestaurantsViewState();
}

class _CategoryRestaurantsViewState extends State<CategoryRestaurantsView> {
  List<RestaurantModel> restaurants = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    final res = await RestaurantModel.fetchByCategory(widget.categoryName);
    if (mounted) {
      setState(() {
        restaurants = res;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: TColor.primaryText),
        ),
        title: Text(
          widget.categoryName,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: TColor.primaryText,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : restaurants.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant_menu_rounded, size: 60, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        "Không tìm thấy nhà hàng nào\nbán món thuộc danh mục này",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: TColor.secondaryText, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  itemCount: restaurants.length,
                  itemBuilder: (context, index) {
                    final r = restaurants[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RestaurantDetailView(
                              restaurant: r,
                              initialCategoryName: widget.categoryName,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                              child: SmartImage(
                                r.imageUrl,
                                width: double.infinity,
                                height: 180,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(15),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.name,
                                    style: TextStyle(
                                      color: TColor.primaryText,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.star, color: TColor.primary, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${r.rating} (${r.reviewCount} đánh giá)",
                                        style: TextStyle(color: TColor.primary, fontSize: 12),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "•",
                                        style: TextStyle(color: TColor.secondaryText, fontSize: 12),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        r.type1,
                                        style: TextStyle(color: TColor.secondaryText, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    r.type2,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: TColor.placeholder, fontSize: 13),
                                  ),
                                ],
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
}
