import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter_food_app/model/restaurant_model.dart';
import 'package:flutter_food_app/view/restaurant/restaurant_detail_view.dart';
import 'package:flutter_food_app/view/home/widget/restaurant_cell.dart';
import 'package:flutter_food_app/view/home/widget/banner_slider.dart';
import 'package:flutter_food_app/view/map/map_picker_view.dart';
import 'package:flutter_food_app/common_widget/app_search_bar.dart';
import 'package:flutter_food_app/common/cart_nav.dart';
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  List<RestaurantModel> _restaurants = [];
  String _currentAddress = "Vị trí hiện tại";
  /// Điểm giao hàng / vị trí tính khoảng cách đến nhà hàng.
  LatLng? _userLatLng;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load(refreshGps: true);
  }

  Future<void> _tryGps() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      ).timeout(const Duration(seconds: 10));
      if (!mounted) return;
      _userLatLng = LatLng(p.latitude, p.longitude);
    } catch (_) {}
  }

  /// [refreshGps]: chỉ lần đầu / F5 — không ghi đè vị trí đã chọn trên bản đồ.
  Future<void> _load({bool refreshGps = false}) async {
    setState(() => _isLoading = true);
    if (refreshGps) await _tryGps();
    final resData = await RestaurantModel.fetchAll(
      userLat: _userLatLng?.latitude,
      userLng: _userLatLng?.longitude,
    );

    if (mounted) {
      setState(() {
        _restaurants = resData;
        _isLoading = false;
      });
    }
  }

  Future<void> _openMap() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerView(initialPosition: _userLatLng),
      ),
    );
    if (result != null) {
      setState(() {
        _currentAddress = (result["address"] as String?) ?? _currentAddress;
        final lat = result['lat'];
        final lng = result['lng'];
        if (lat is num && lng is num) {
          _userLatLng = LatLng(lat.toDouble(), lng.toDouble());
        }
      });
      await _load(refreshGps: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.background,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SafeArea(
          child: SingleChildScrollView(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Header with Location & Cart
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Giao hàng đến",
                            style: TextStyle(color: TColor.placeholder, fontSize: 12),
                          ),
                          GestureDetector(
                            onTap: _openMap,
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    _currentAddress.length > 25 ? "${_currentAddress.substring(0, 25)}..." : _currentAddress,
                                    style: TextStyle(
                                      color: TColor.secondaryText,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Icon(Icons.keyboard_arrow_down, color: TColor.primary),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => openAppCart(context),
                      icon: Icon(Icons.shopping_cart_outlined, size: 28, color: TColor.primaryText),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const AppSearchBar.tap(),
              ),
              const SizedBox(height: 30),

              // Services Grid (Super App Style)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  mainAxisSpacing: 15,
                  crossAxisSpacing: 15,
                  childAspectRatio: 0.85,
                  children: [
                    _buildServiceItem(Icons.restaurant, "Đồ ăn", Colors.orange, () {}),
                    _buildServiceItem(Icons.auto_awesome, "AI Camera", Colors.deepOrange, () {
                      AppSearchBar.openImageSearch(context);
                    }),
                    _buildServiceItem(Icons.motorcycle, "Xe máy", Colors.green, () {}),
                    _buildServiceItem(Icons.more_horiz, "Thêm", Colors.grey, () {}),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              const BannerSlider(),
              const SizedBox(height: 10),

              // Popular Restaurants Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Nhà hàng Phổ biến",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: TColor.primaryText,
                      ),
                    ),
                    Text(
                      "Xem tất cả",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: TColor.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),

              // Restaurant Vertical List
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _restaurants.length,
                itemBuilder: (context, index) {
                  return RestaurantCell(
                    restaurant: _restaurants[index],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RestaurantDetailView(
                            restaurant: _restaurants[index],
                          ),
                        ),
                      );
                    },
                  );
                }
              ),
              
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildServiceItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: TColor.primaryText,
            ),
          ),
        ],
      ),
    );
  }
}
