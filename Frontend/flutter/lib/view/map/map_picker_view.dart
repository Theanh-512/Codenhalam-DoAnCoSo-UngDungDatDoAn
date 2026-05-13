import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_food_app/common/color_extension.dart';

class MapPickerView extends StatefulWidget {
  final LatLng? initialPosition;
  const MapPickerView({super.key, this.initialPosition});

  @override
  State<MapPickerView> createState() => _MapPickerViewState();
}

class _MapPickerViewState extends State<MapPickerView> {
  final MapController _mapController = MapController();
  final TextEditingController _txtSearch = TextEditingController();
  Timer? _debounce;
  List<dynamic> _searchResults = [];

  static const LatLng _defaultPosition = LatLng(10.7769, 106.7009);

  late LatLng _selectedPosition;
  String _selectedAddress = "Đang tải địa chỉ...";
  bool _isLoadingAddress = false;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialPosition ?? _defaultPosition;
    _getAddressFromLatLng(_selectedPosition);
    Future.delayed(Duration.zero, _getCurrentLocation);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _txtSearch.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnack("Cần cấp quyền vị trí");
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showSnack("Bật quyền vị trí trong Cài đặt");
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final newPos = LatLng(pos.latitude, pos.longitude);
      _mapController.move(newPos, 16);
      setState(() => _selectedPosition = newPos);
      await _getAddressFromLatLng(newPos);
    } catch (e) {
      _showSnack("Không thể lấy vị trí");
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _getAddressFromLatLng(LatLng pos) async {
    setState(() => _isLoadingAddress = true);
    try {
      final url = Uri.parse(
        "https://nominatim.openstreetmap.org/reverse"
        "?lat=${pos.latitude}&lon=${pos.longitude}"
        "&format=json&accept-language=vi",
      );
      final response = await http.get(url, headers: {
        "User-Agent": "FastBiteApp/1.0",
      });
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final addr = data["address"] as Map<String, dynamic>;
        final parts = <String>[];
        if (addr["road"] != null) parts.add(addr["road"]);
        if (addr["suburb"] != null) parts.add(addr["suburb"]);
        if (addr["city_district"] != null) parts.add(addr["city_district"]);
        if (addr["city"] != null) parts.add(addr["city"]);
        setState(() {
          _selectedAddress = parts.isNotEmpty
              ? parts.join(", ")
              : data["display_name"] ?? "Không xác định được địa chỉ";
        });
      }
    } catch (_) {
      setState(() => _selectedAddress = "Không thể xác định địa chỉ");
    } finally {
      setState(() => _isLoadingAddress = false);
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final url = Uri.parse(
        "https://nominatim.openstreetmap.org/search"
        "?q=$query&format=json&limit=5&accept-language=vi&countrycodes=vn"
      );
      try {
        final response = await http.get(url, headers: {
          "User-Agent": "FastBiteApp/1.0",
        });
        if (response.statusCode == 200) {
          if (mounted) {
            setState(() {
              _searchResults = json.decode(response.body);
            });
          }
        }
      } catch (e) {
        debugPrint("Lỗi tìm kiếm: $e");
      }
    });
  }

  void _onSelectResult(dynamic item) {
    FocusScope.of(context).unfocus();
    _txtSearch.clear();
    setState(() => _searchResults = []);
    final double lat = double.parse(item["lat"]);
    final double lon = double.parse(item["lon"]);
    final newPos = LatLng(lat, lon);
    _mapController.move(newPos, 16);
    setState(() => _selectedPosition = newPos);
    _getAddressFromLatLng(newPos);
  }

  void _confirmAddress() {
    if (_isLoadingAddress) return;
    Navigator.pop(context, {
      "address": _selectedAddress,
      "lat": _selectedPosition.latitude,
      "lng": _selectedPosition.longitude,
    });
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── BẢN ĐỒ ──
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedPosition,
              initialZoom: 15,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  _selectedPosition = position.center;
                }
              },
              onMapEvent: (event) {
                if (event is MapEventMoveEnd) {
                  _getAddressFromLatLng(_selectedPosition);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: "com.example.appfood",
              ),
            ],
          ),

          // ── PIN CỐ ĐỊNH GIỮA MÀN HÌNH ──
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_pin, color: Color(0xFF6F0706), size: 48),
                SizedBox(
                  width: 14, height: 6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.all(Radius.circular(3)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── NÚT GPS ──
          Positioned(
            right: 16, bottom: 230,
            child: _isLoadingLocation
                ? Container(
                    width: 44, height: 44,
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                    child: const Center(
                      child: SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  )
                : _mapBtn(
                    icon: Icons.my_location_rounded,
                    onTap: _getCurrentLocation,
                  ),
          ),

          // ── BOTTOM SHEET ĐỊA CHỈ ──
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -4))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                          color: TColor.placeholder,
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text("Địa chỉ giao hàng",
                      style: TextStyle(
                          fontSize: 13,
                          color: TColor.secondaryText,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_rounded, color: TColor.red, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _isLoadingAddress
                            ? Row(children: [
                                SizedBox(
                                  width: 16, height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: TColor.primary),
                                ),
                                const SizedBox(width: 8),
                                Text("Đang xác định...",
                                    style: TextStyle(
                                        color: TColor.secondaryText,
                                        fontSize: 14)),
                              ])
                            : Text(_selectedAddress,
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: TColor.primaryText)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _confirmAddress,
                    child: Container(
                      height: 54, width: double.infinity,
                      decoration: BoxDecoration(
                        color: _isLoadingAddress
                            ? TColor.placeholder
                            : TColor.primaryDark,
                        borderRadius: BorderRadius.circular(27),
                        boxShadow: _isLoadingAddress
                            ? []
                            : [
                                BoxShadow(
                                  color: TColor.primary.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                )
                              ],
                      ),
                      child: Center(
                        child: Text(
                          _isLoadingAddress
                              ? "Đang xác định..."
                              : "Xác nhận địa chỉ này 📍",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── APP BAR / SEARCH BAR TẠI TOP ──
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _mapBtn(
                          icon: Icons.arrow_back_rounded,
                          onTap: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 8)
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.search, color: TColor.placeholder),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _txtSearch,
                                    onChanged: _onSearchChanged,
                                    decoration: InputDecoration(
                                      hintText: "Tìm kiếm địa điểm...",
                                      hintStyle: TextStyle(
                                        color: TColor.placeholder,
                                        fontSize: 14,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                                if (_txtSearch.text.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      _txtSearch.clear();
                                      setState(() => _searchResults = []);
                                      FocusScope.of(context).unfocus();
                                    },
                                    child: Icon(Icons.close, color: TColor.primary),
                                  )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Hiển thị danh sách kết quả tìm kiếm
                    if (_searchResults.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 8, left: 56), // align with search bar
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 8)
                          ],
                        ),
                        constraints: const BoxConstraints(maxHeight: 250),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: _searchResults.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = _searchResults[index];
                            return ListTile(
                              leading: const Icon(Icons.location_on, color: Colors.grey),
                              title: Text(
                                item["display_name"] ?? "",
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                              ),
                              onTap: () => _onSelectResult(item),
                            );
                          },
                        ),
                      )
                  ],
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }

  Widget _mapBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
            ),
          ],
        ),
        child: Center(child: Icon(icon, color: Colors.black87, size: 22)),
      ),
    );
  }
}
