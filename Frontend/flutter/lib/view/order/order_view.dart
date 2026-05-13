import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_food_app/common/cart_nav.dart';
import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter_food_app/model/restaurant_model.dart';
import 'package:flutter_food_app/common/smart_image.dart';
import 'package:flutter_food_app/view/restaurant/restaurant_detail_view.dart';

class OrderView extends StatefulWidget {
  const OrderView({super.key});

  @override
  State<OrderView> createState() => _OrderViewState();
}

class _OrderViewState extends State<OrderView> {
  List<RestaurantModel> _offerItems = [];
  bool _isLoading = true;
  static const List<String> _promoCodes = <String>[
    'FREESHIP',
    'GIAM20K',
    'MONKEY10',
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    final resData = await RestaurantModel.fetchAllWithBestEffortLocation();
    if (mounted) {
      setState(() {
        _offerItems = resData;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Siêu Ưu Đãi Hôm Nay",
                        style: TextStyle(
                          color: TColor.primaryText,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      IconButton(
                        onPressed: () => openAppCart(context),
                        icon: Icon(Icons.shopping_cart_outlined,
                            color: TColor.primaryText, size: 28),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Tìm kiếm siêu ưu đãi, các bữa ăn đặc biệt\nvà hơn thế nữa!",
                    style: TextStyle(
                      color: TColor.secondaryText,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const SizedBox.shrink(),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // List of Offers
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 20, top: 5),
                physics: const BouncingScrollPhysics(),
                itemCount: _offerItems.length,
                itemBuilder: (context, index) {
                  var restaurant = _offerItems[index];
                  final promoCode = _promoCodes[index % _promoCodes.length];

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              RestaurantDetailView(restaurant: restaurant),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image with rounded top corners and Stack for Badge
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                child: SmartImage(
                                  restaurant.imageUrl,
                                  width: double.infinity,
                                  height: 180,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: double.infinity,
                                    height: 180,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.restaurant, color: Colors.grey, size: 40),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xffFF4B4B),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xffFF4B4B)
                                            .withValues(alpha: 0.4),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.local_offer_rounded, color: Colors.white, size: 14),
                                      SizedBox(width: 4),
                                      Text(
                                        "Giảm 30%",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Details text below
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  restaurant.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: TColor.primaryText,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.star_rounded, color: TColor.primary, size: 16),
                                              const SizedBox(width: 4),
                                              Text(
                                                "${restaurant.rating}",
                                                style: TextStyle(
                                                  color: TColor.primaryText,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                "(${restaurant.reviewCount} đánh giá)",
                                                style: TextStyle(
                                                  color: TColor.secondaryText,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (restaurant.typeTagsDisplayLine.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Text(
                                              restaurant.typeTagsDisplayLine,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: TColor.secondaryText,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    // Action Button
                                    GestureDetector(
                                      onTap: () {
                                        Clipboard.setData(
                                          ClipboardData(text: promoCode),
                                        );
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Đã lấy mã $promoCode',
                                            ),
                                            duration:
                                                const Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: TColor.primary,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Text(
                                          "Lấy mã",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
