import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter_food_app/model/restaurant_model.dart';
import 'package:flutter_food_app/view/home/widget/restaurant_cell.dart';
import 'package:flutter_food_app/view/map/map_picker_view.dart';
import 'package:flutter_food_app/view/search/search_view.dart';
import 'package:flutter_food_app/common/cart_nav.dart';
import 'package:flutter_food_app/view/restaurant/restaurant_detail_view.dart';

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
                      color: TColor.textfield,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 15),
                        Icon(Icons.search, color: TColor.secondaryText),
                        const SizedBox(width: 10),
                        Text(
                          "Tìm kiếm món ăn",
                          style: TextStyle(color: TColor.placeholder, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Promotional Banner Slider
              SizedBox(
                height: 150,
                child: PageView.builder(
                  controller: PageController(viewportFraction: 0.9),
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    final ads = [
                      "https://images.unsplash.com/photo-1504674900247-0877df9cc836?q=80&w=800&auto=format&fit=crop", 
                      "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?q=80&w=800&auto=format&fit=crop",
                      "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?q=80&w=800&auto=format&fit=crop",
                    ];
                    final titles = ["Giảm 50% Món Mới", "Món Ngon Cuối Tuần", "Giao Hàng Miễn Phí"];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        image: DecorationImage(
                          image: NetworkImage(ads[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.7),
                              Colors.transparent,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                        alignment: Alignment.bottomLeft,
                        padding: const EdgeInsets.all(15),
                        child: Text(
                          titles[index],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

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
              
              const SizedBox(height: 80), // bottom padding for FAB
            ],
          ),
        ),
      ),
    );
  }
}
