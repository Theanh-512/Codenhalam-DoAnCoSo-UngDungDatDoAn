import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter_food_app/common/auth_store.dart';
import 'package:intl/intl.dart';
import 'package:flutter_food_app/model/restaurant_model.dart';
import 'package:flutter_food_app/view/restaurant/restaurant_detail_view.dart';

class AiMapView extends StatefulWidget {
  const AiMapView({super.key});

  @override
  State<AiMapView> createState() => _AiMapViewState();
}

enum RecMode { nearby, habits, topRated, routePlanner }

// ─────────────────────────────────────────────────────────────────────────────
// 1. S - SINGLE RESPONSIBILITY PRINCIPLE (SPATIAL MATHEMATICS SERVICE)
// ─────────────────────────────────────────────────────────────────────────────
class MapMathService {
  static double getDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295; // Math.PI / 180
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p)/2 + 
          c(lat1 * p) * c(lat2 * p) * 
          (1 - c((lon2 - lon1) * p))/2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  static double distanceToPolyline(LatLng point, List<LatLng> polyline) {
    if (polyline.isEmpty) return double.infinity;
    double minDistance = double.infinity;
    for (var p in polyline) {
      double dist = getDistanceKm(point.latitude, point.longitude, p.latitude, p.longitude);
      if (dist < minDistance) {
        minDistance = dist;
      }
    }
    return minDistance;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. D - DEPENDENCY INVERSION PRINCIPLE (ROUTING & REST NETWORK CLIENT)
// ─────────────────────────────────────────────────────────────────────────────
abstract class IMapApiService {
  Future<List<LatLng>> fetchRoutePoints(LatLng start, LatLng dest, {LatLng? stopover});
  Future<List<Map<String, dynamic>>> fetchInitialRestaurants(String backendBase);
}

class HttpMapApiService implements IMapApiService {
  @override
  Future<List<LatLng>> fetchRoutePoints(LatLng start, LatLng dest, {LatLng? stopover}) async {
    String coordinatesString = '';
    if (stopover != null) {
      coordinatesString = '${start.longitude},${start.latitude};'
                          '${stopover.longitude},${stopover.latitude};'
                          '${dest.longitude},${dest.latitude}';
    } else {
      coordinatesString = '${start.longitude},${start.latitude};'
                          '${dest.longitude},${dest.latitude}';
    }

    final url = 'https://router.project-osrm.org/route/v1/driving/'
        '$coordinatesString?overview=full&geometries=geojson';
    
    final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final routes = data['routes'] as List<dynamic>;
      if (routes.isNotEmpty) {
        final geometry = routes[0]['geometry'];
        final coordinates = geometry['coordinates'] as List<dynamic>;
        return coordinates.map((c) => LatLng(c[1] as double, c[0] as double)).toList();
      }
    }
    throw Exception("OSRM API query returned empty route");
  }

  @override
  Future<List<Map<String, dynamic>>> fetchInitialRestaurants(String backendBase) async {
    final res = await http.get(Uri.parse('$backendBase/api/Restaurants')).timeout(const Duration(seconds: 6));
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    }
    throw Exception("Supabase REST API failed");
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. O - OPEN/CLOSED PRINCIPLE (RECOMMENDATION STRATEGY PATTERN)
// ─────────────────────────────────────────────────────────────────────────────
abstract class RecommendationStrategy {
  Future<Map<String, dynamic>> fetchRecommendations({
    required LatLng userLocation,
    required List<Map<String, dynamic>> allRestaurants,
    required String aiBase,
    required String backendBase,
  });
}

// 3.1. Chiến lược Gần nhất (Nearby Strategy)
class NearbyStrategy implements RecommendationStrategy {
  @override
  Future<Map<String, dynamic>> fetchRecommendations({
    required LatLng userLocation,
    required List<Map<String, dynamic>> allRestaurants,
    required String aiBase,
    required String backendBase,
  }) async {
    final endpoint = '$backendBase/api/Restaurants/map/nearby';
    final queryParams = {'lat': userLocation.latitude.toString(), 'lng': userLocation.longitude.toString()};
    final uri = Uri.parse(endpoint).replace(queryParameters: queryParams);
    
    final res = await http.get(uri).timeout(const Duration(seconds: 8));
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return {
        'restaurants': list.cast<Map<String, dynamic>>(),
        'reason': "Các quán ăn gần bạn nhất trong bán kính 10km.",
      };
    }
    throw Exception("Nearby REST endpoint failed");
  }
}

// 3.2. Chiến lược Đỉnh cao (Top Rated Strategy)
class TopRatedStrategy implements RecommendationStrategy {
  @override
  Future<Map<String, dynamic>> fetchRecommendations({
    required LatLng userLocation,
    required List<Map<String, dynamic>> allRestaurants,
    required String aiBase,
    required String backendBase,
  }) async {
    final endpoint = '$backendBase/api/Restaurants/map/top-rated';
    final queryParams = {'lat': userLocation.latitude.toString(), 'lng': userLocation.longitude.toString()};
    final uri = Uri.parse(endpoint).replace(queryParameters: queryParams);
    
    final res = await http.get(uri).timeout(const Duration(seconds: 8));
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return {
        'restaurants': list.cast<Map<String, dynamic>>(),
        'reason': "Những quán ăn được đánh giá cao nhất bạn nên thử.",
      };
    }
    throw Exception("Top-rated REST endpoint failed");
  }
}

// 3.3. Chiến lược Thói quen thông minh (AI Habits Strategy)
class HabitsStrategy implements RecommendationStrategy {
  @override
  Future<Map<String, dynamic>> fetchRecommendations({
    required LatLng userLocation,
    required List<Map<String, dynamic>> allRestaurants,
    required String aiBase,
    required String backendBase,
  }) async {
    final now = DateTime.now();
    final timeStr = DateFormat('HH:mm').format(now);
    final token = await AuthStore.getToken();
    int userId = 1;
    if (token != null && token.isNotEmpty) {
      try {
        final parts = token.split('.');
        if (parts.length == 3) {
          final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
          userId = int.tryParse(jsonDecode(payload)['nameid']?.toString() ?? '1') ?? 1;
        }
      } catch (_) {}
    }
    final body = jsonEncode({
      'user_id': userId,
      'lat': userLocation.latitude,
      'lng': userLocation.longitude,
      'time': timeStr,
      'day_of_week': now.weekday - 1
    });
    
    final res = await http.post(
      Uri.parse('$aiBase/api/ai/recommend-poi'),
      headers: {'Content-Type': 'application/json'},
      body: body
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final recIds = (data['restaurant_ids'] as List).cast<int>();
      final recScores = (data['confidence_scores'] as List).map((e) {
        double val = (e as num).toDouble();
        return val > 1.0 ? val / 5.0 : val;
      }).toList();
      final reason = data['reason'] ?? '';
      
      final List<Map<String, dynamic>> recommended = [];
      for (var id in recIds) {
        final found = allRestaurants.firstWhere((r) => r['id'] == id, orElse: () => {});
        if (found.isNotEmpty) recommended.add(found);
      }
      return {
        'restaurants': recommended,
        'scores': recScores,
        'ids': recIds,
        'reason': reason,
      };
    }
    
    // Gọi fallback theo ngữ cảnh nếu API AI chính bị lỗi
    return await _fetchContextualFallback(userLocation, backendBase);
  }

  Future<Map<String, dynamic>> _fetchContextualFallback(LatLng userLocation, String backendBase) async {
    final uri = Uri.parse('$backendBase/api/Restaurants/map/contextual').replace(queryParameters: {
      'lat': userLocation.latitude.toString(),
      'lng': userLocation.longitude.toString(),
      'userId': '1'
    });
    final res = await http.get(uri).timeout(const Duration(seconds: 5));
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List<dynamic>;
      final cast = list.cast<Map<String, dynamic>>();
      return {
        'restaurants': cast,
        'reason': "Gợi ý dựa trên khung giờ và địa điểm phổ biến.",
      };
    }
    throw Exception("Contextual Fallback failed");
  }
}

class _AiMapViewState extends State<AiMapView> with TickerProviderStateMixin {
  static const String _aiBase = 'http://127.0.0.1:8000';
  static const String _backendBase = 'http://127.0.0.1:5149';

  // 🏛️ Đăng ký các dịch vụ chuẩn SOLID
  final IMapApiService _mapApiService = HttpMapApiService();
  
  // Đăng ký Strategy Pattern Map (Dễ dàng mở rộng OCP)
  final Map<RecMode, RecommendationStrategy> _strategies = {
    RecMode.nearby: NearbyStrategy(),
    RecMode.topRated: TopRatedStrategy(),
    RecMode.habits: HabitsStrategy(),
  };

  final MapController _mapController = MapController();
  LatLng _center = const LatLng(10.7769, 106.7009); 

  bool _loadingGps   = false;
  bool _loadingAi    = false;
  bool _aiReady      = false;
  RecMode _currentMode = RecMode.habits;

  List<int>    _recIds      = [];
  List<double> _recScores   = [];
  String       _aiReason    = '';
  List<Map<String, dynamic>> _allRestaurants = [];
  List<Map<String, dynamic>> _filteredRestaurants = [];

  // AI Lộ Trình & OSRM Routing
  LatLng? _destinationCoord;
  String _destinationName = 'Landmark 81';
  bool _loadingRoute = false;
  List<LatLng> _routePoints = [];
  List<LatLng> _directRoutePoints = [];

  final List<Map<String, dynamic>> _quickDestinations = [
    {'name': 'Landmark 81', 'icon': '🏢', 'coord': const LatLng(10.7916, 106.7218)},
    {'name': 'Chợ Bến Thành', 'icon': '🛍️', 'coord': const LatLng(10.7725, 106.6980)},
    {'name': 'Nhà Thờ Đức Bà', 'icon': '⛪', 'coord': const LatLng(10.7798, 106.6990)},
  ];

  Map<String, dynamic>? _selectedRestaurant;

  // AI Route Planner - Món ăn ưa thích
  String _selectedFood = 'Tất cả';
  final List<Map<String, String>> _favoriteFoods = [
    {'name': 'Tất cả', 'icon': '🍽️'},
    {'name': 'Cơm tấm', 'icon': '🍛'},
    {'name': 'Phở', 'icon': '🍜'},
    {'name': 'Bánh mì', 'icon': '🥖'},
    {'name': 'Cà phê', 'icon': '☕'},
    {'name': 'Lẩu', 'icon': '🍲'},
    {'name': 'Trà sữa', 'icon': '🧋'},
  ];

  // AI HUD & Tab Customization
  bool _hudExpanded = true;
  int _routeSubTab = 0; // 0: Điểm đến, 1: Món thèm ăn

  bool _panelExpanded = true;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    
    // Mặc định điểm đến của Route Planner là Landmark 81
    _destinationCoord = _quickDestinations[0]['coord'];
    _destinationName = _quickDestinations[0]['name'];

    _init();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _tryGps();
    await _fetchInitialData();
    await _fetchModeData();
  }

  Future<void> _tryGps() async {
    if (mounted) setState(() => _loadingGps = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      LatLng defaultPos = const LatLng(10.7769, 106.7009);
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        setState(() => _center = defaultPos);
        _mapController.move(_center, 14.5);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)).timeout(const Duration(seconds: 5));
      if (mounted) {
        setState(() => _center = LatLng(pos.latitude, pos.longitude));
        _mapController.move(_center, 14.5);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _center = const LatLng(10.7769, 106.7009));
        _mapController.move(_center, 14.5);
      }
    } finally {
      if (mounted) setState(() => _loadingGps = false);
    }
  }

  Future<void> _fetchInitialData() async {
    try {
      final list = await _mapApiService.fetchInitialRestaurants(_backendBase);
      if (mounted) setState(() => _allRestaurants = list);
    } catch (_) {}
  }

  // ─── CÔNG CỤ TÍNH TOÁN KHOẢNG CÁCH DỌC ĐƯỜNG ĐI (DELEGATED TO MapMathService) ─────────────
  double _getDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    return MapMathService.getDistanceKm(lat1, lon1, lat2, lon2);
  }

  double _distanceToPolyline(LatLng point, List<LatLng> polyline) {
    return MapMathService.distanceToPolyline(point, polyline);
  }

  // ─── ĐƯỜNG ĐI ROUTING OSRM ĐA ĐIỂM (DELEGATED TO IMapApiService) ───────────
  Future<void> _fetchRoute(LatLng destination, {LatLng? stopover}) async {
    if (mounted) setState(() => _loadingRoute = true);
    try {
      final points = await _mapApiService.fetchRoutePoints(_center, destination, stopover: stopover);
      if (mounted) {
        setState(() {
          _routePoints = points;
          // Nếu vẽ trực tiếp từ A -> B lần đầu (không dừng chân), lưu lại làm buffer
          if (stopover == null && _currentMode == RecMode.routePlanner) {
            _directRoutePoints = points;
          }
          _loadingRoute = false;
        });
        // Tự động căn chỉnh toàn cảnh bản đồ sau khi tính toán xong
        Future.delayed(const Duration(milliseconds: 100), () {
          _fitRouteBounds();
        });
      }
      return;
    } catch (e) {
      print("❌ Lỗi lấy đường đi từ OSRM: $e");
    }
    
    // Fallback: Vẽ đường thẳng nếu API OSRM lỗi hoặc timeout
    if (mounted) {
      setState(() {
        _routePoints = stopover != null 
            ? [_center, stopover, destination] 
            : [_center, destination];
        _loadingRoute = false;
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        _fitRouteBounds();
      });
    }
  }

  // ─── THUẬT TOÁN GỢI Ý THAY THẾ BẰNG STRATEGY PATTERN ───────────────────────
  Future<void> _fetchModeData() async {
    if (mounted) setState(() { _loadingAi = true; _aiReady = false; _routePoints = []; _selectedRestaurant = null; });
    try {
      if (_currentMode == RecMode.routePlanner) {
        await _calculateRoutePlannerRecommendations();
        return;
      }

      final strategy = _strategies[_currentMode];
      if (strategy != null) {
        final result = await strategy.fetchRecommendations(
          userLocation: _center,
          allRestaurants: _allRestaurants,
          aiBase: _aiBase,
          backendBase: _backendBase,
        );

        if (mounted) {
          setState(() {
            _filteredRestaurants = result['restaurants'] as List<Map<String, dynamic>>;
            if (_filteredRestaurants.isEmpty) _filteredRestaurants = _allRestaurants.take(10).toList();
            
            _aiReason = result['reason'] as String;
            if (result.containsKey('scores')) {
              _recScores = (result['scores'] as List).cast<double>();
              _recIds = (result['ids'] as List).cast<int>();
            } else {
              _recIds = _filteredRestaurants.map((e) => (e['id'] as num).toInt()).toList();
              _recScores = List.generate(_recIds.length, (index) => 0.95 - (index * 0.05));
            }
            _aiReady = true;
          });
          
          if (_filteredRestaurants.isNotEmpty) {
            _selectRestaurant(_filteredRestaurants[0]);
          }
        }
      }
    } catch (e) {
      print("❌ Lỗi SOLID Strategy Mode: $e");
      if (mounted) {
        setState(() {
          _filteredRestaurants = _allRestaurants.take(10).toList();
          _recIds = _filteredRestaurants.map((e) => (e['id'] as num).toInt()).toList();
          _recScores = List.generate(_recIds.length, (index) => 0.95 - (index * 0.05));
          _aiReason = "Gợi ý dựa trên các quán ăn phổ biến xung quanh.";
          _aiReady = true;
        });
        if (_filteredRestaurants.isNotEmpty) {
          _selectRestaurant(_filteredRestaurants[0]);
        }
      }
    } finally {
      if (mounted) setState(() => _loadingAi = false);
    }
  }

  bool _matchesFood(Map<String, dynamic> r, String food) {
    if (food == 'Tất cả') return true;
    final String name = (r['name'] ?? r['Name'] ?? '').toString().toLowerCase();
    final String desc = (r['description'] ?? r['Description'] ?? '').toString().toLowerCase();
    final String cat = (r['category'] ?? r['Category'] ?? r['type1'] ?? r['Type1'] ?? r['type2'] ?? r['Type2'] ?? '').toString().toLowerCase();
    final String foodLower = food.toLowerCase();
    return name.contains(foodLower) || desc.contains(foodLower) || cat.contains(foodLower);
  }

  // ─── XỬ LÝ LỘ TRÌNH ĐA ĐIỂM DỌC TUYẾN ĐƯỜNG (AI ROUTE PLANNER) ───────────────
  Future<void> _calculateRoutePlannerRecommendations() async {
    if (_destinationCoord == null) return;
    
    // Bước 1: Lấy tuyến đường thẳng A -> B trước để làm cơ sở tính Buffer
    await _fetchRoute(_destinationCoord!);
    
    // Chờ 200ms để tuyến đường _directRoutePoints cập nhật hoàn tất
    await Future.delayed(const Duration(milliseconds: 200));

    if (_directRoutePoints.isEmpty) {
      _directRoutePoints = [_center, _destinationCoord!];
    }

    // Bước 2: Lọc các quán ăn nằm trong Vùng đệm 1.5km dọc tuyến đường và khớp món ăn ưa thích
    final List<Map<String, dynamic>> candidates = [];
    for (var r in _allRestaurants) {
      if (!_matchesFood(r, _selectedFood)) continue;
      final double rLat = (r['latitude'] ?? r['Latitude'] ?? 10.7769) as double;
      final double rLng = (r['longitude'] ?? r['Longitude'] ?? 106.7009) as double;
      double dist = _distanceToPolyline(LatLng(rLat, rLng), _directRoutePoints);
      if (dist <= 1.5) {
        candidates.add({...r, '_dist_to_route': dist});
      }
    }

    // Nếu không tìm thấy quán nào, tăng bán kính vùng đệm lên 3.5km làm dự phòng
    if (candidates.isEmpty) {
      for (var r in _allRestaurants) {
        if (!_matchesFood(r, _selectedFood)) continue;
        final double rLat = (r['latitude'] ?? r['Latitude'] ?? 10.7769) as double;
        final double rLng = (r['longitude'] ?? r['Longitude'] ?? 106.7009) as double;
        double dist = _distanceToPolyline(LatLng(rLat, rLng), _directRoutePoints);
        if (dist <= 3.5) {
          candidates.add({...r, '_dist_to_route': dist});
        }
      }
    }

    // Sắp xếp các quán ứng viên dựa trên độ nổi tiếng và độ gần lộ trình
    candidates.sort((a, b) {
      double scoreA = (a['rating'] ?? 4.0) / (1.0 + a['_dist_to_route']);
      double scoreB = (b['rating'] ?? 4.0) / (1.0 + b['_dist_to_route']);
      return scoreB.compareTo(scoreA); // Xếp cao xuống thấp
    });

    final displayList = candidates.take(5).toList();

    if (mounted) {
      setState(() {
        _filteredRestaurants = displayList;
        _recIds = _filteredRestaurants.map<int>((e) => ((e['id'] ?? e['Id'] ?? 0) as num).toInt()).toList();
        _recScores = List.generate(_recIds.length, (index) => 0.92 - (index * 0.04));
        _aiReason = _selectedFood == 'Tất cả'
            ? "AI đã quét vùng đệm 1.5km dọc tuyến đường từ bạn tới $_destinationName để đề xuất những điểm dừng chân hoàn hảo nhất!"
            : "AI đã định vị các quán ăn phục vụ món '$_selectedFood' dọc lộ trình di chuyển tới $_destinationName để đề xuất cho bạn!";
        _aiReady = true;
      });

      // Tự động chọn và vẽ lộ trình đa điểm (A -> Quán 1 -> B)
      if (_filteredRestaurants.isNotEmpty) {
        _selectRestaurant(_filteredRestaurants[0]);
      }
    }
  }

  void _selectRestaurant(Map<String, dynamic> restaurant) {
    setState(() {
      _selectedRestaurant = restaurant;
    });

    final double rLat = (restaurant['latitude'] ?? restaurant['Latitude'] ?? 10.7769) as double;
    final double rLng = (restaurant['longitude'] ?? restaurant['Longitude'] ?? 106.7009) as double;

    if (_currentMode == RecMode.routePlanner && _destinationCoord != null) {
      // Nếu ở chế độ Lộ trình: Vẽ tuyến đường đi đa điểm (A -> Quán ăn -> B)
      _fetchRoute(_destinationCoord!, stopover: LatLng(rLat, rLng));
    } else {
      // Chế độ thường: Chỉ vẽ đường đi từ A -> Quán ăn
      _fetchRoute(LatLng(rLat, rLng));
    }
  }

  List<Map<String, dynamic>> get _recommended {
    final result = <Map<String, dynamic>>[];
    for (int i = 0; i < _filteredRestaurants.length; i++) {
      result.add({..._filteredRestaurants[i], '_score': _recScores.length > i ? _recScores[i] : 0.8, '_rank': i + 1});
    }
    return result;
  }

  void _fitRouteBounds() {
    List<LatLng> points = [];
    points.add(_center);
    if (_destinationCoord != null && _currentMode == RecMode.routePlanner) {
      points.add(_destinationCoord!);
    }
    if (_selectedRestaurant != null) {
      final double rLat = (_selectedRestaurant!['latitude'] ?? _selectedRestaurant!['Latitude'] ?? 10.7769) as double;
      final double rLng = (_selectedRestaurant!['longitude'] ?? _selectedRestaurant!['Longitude'] ?? 106.7009) as double;
      points.add(LatLng(rLat, rLng));
    }
    if (_routePoints.isNotEmpty) {
      points.addAll(_routePoints);
    }

    if (points.length < 2) return;

    try {
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.only(top: 100, bottom: 250, left: 60, right: 60),
        ),
      );
    } catch (_) {
      // Fallback manual center/zoom
      double minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;
      for (var p in points) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLng) minLng = p.longitude;
        if (p.longitude > maxLng) maxLng = p.longitude;
      }
      LatLng center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
      _mapController.move(center, 12.8);
    }
  }

  Widget _buildControlHub() {
    if (!_hudExpanded) {
      // Khi HUD bị thu gọn: Hiển thị một nút nổi bo tròn cực kỳ nhỏ gọn và tinh tế
      return Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GestureDetector(
            onTap: () => setState(() => _hudExpanded = true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 12, offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🧠', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    'Điều Khiển AI',
                    style: TextStyle(fontWeight: FontWeight.w800, color: TColor.primaryText, fontSize: 13),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.settings, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Khi HUD được mở rộng: Hiển thị bảng điều khiển AI tích hợp cao cấp
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề + Nút refresh, GPS & Nút thu gọn
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('🧠', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  _currentMode == RecMode.routePlanner ? 'AI Route Planner' : 'SCR AI Map',
                  style: TextStyle(fontWeight: FontWeight.w900, color: TColor.primaryText, fontSize: 15),
                ),
                if (_loadingAi)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                const Spacer(),
                _mapBtn(Icons.refresh, _fetchModeData),
                const SizedBox(width: 6),
                _mapBtn(Icons.my_location, _tryGps, loading: _loadingGps),
                const SizedBox(width: 6),
                _mapBtn(Icons.zoom_out_map, _fitRouteBounds),
                const SizedBox(width: 12),
                // Nút Thu Gọn
                GestureDetector(
                  onTap: () => setState(() => _hudExpanded = false),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.keyboard_arrow_up, color: Colors.grey, size: 18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Slider chế độ gợi ý chính (4 chế độ)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildModeChip(RecMode.habits, '✨ AI Habits'),
                _buildModeChip(RecMode.routePlanner, '🧭 AI Lộ trình'),
                _buildModeChip(RecMode.nearby, '📍 Gần nhất'),
                _buildModeChip(RecMode.topRated, '🏆 Đỉnh cao'),
              ],
            ),
          ),

          // NẾU Ở CHẾ ĐỘ ROUTE PLANNER, HIỂN THỊ SEGMENTED TAB ĐỂ CHỌN MÓN/ĐIỂM ĐẾN
          if (_currentMode == RecMode.routePlanner) ...[
            const SizedBox(height: 10),
            // Segmented Tab Bar cực kỳ đẹp
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _routeSubTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _routeSubTab == 0 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _routeSubTab == 0
                              ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)]
                              : [],
                        ),
                        child: Center(
                          child: Text(
                            '🏢 Chọn Điểm Đến B',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: _routeSubTab == 0 ? Colors.deepPurpleAccent : TColor.secondaryText,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _routeSubTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _routeSubTab == 1 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _routeSubTab == 1
                              ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)]
                              : [],
                        ),
                        child: Center(
                          child: Text(
                            '🍜 Món Thèm Ăn',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: _routeSubTab == 1 ? Colors.amber : TColor.secondaryText,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // NỘI DUNG PHÂN TAB:
            if (_routeSubTab == 0)
              // Tab 1: Landmark Destinations
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _quickDestinations.length,
                  itemBuilder: (ctx, index) {
                    final dest = _quickDestinations[index];
                    bool isDestSelected = _destinationName == dest['name'];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _destinationCoord = dest['coord'];
                          _destinationName = dest['name'];
                          _selectedRestaurant = null;
                          _routePoints = [];
                          _directRoutePoints = [];
                        });
                        _calculateRoutePlannerRecommendations();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: isDestSelected ? Colors.deepPurpleAccent : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 5, offset: const Offset(0, 2))
                          ],
                        ),
                        child: Row(
                          children: [
                            Text(dest['icon'] ?? '🏢', style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(
                              dest['name'] ?? '',
                              style: TextStyle(
                                color: isDestSelected ? Colors.white : TColor.primaryText,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              // Tab 2: Favorite Foods
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _favoriteFoods.length,
                  itemBuilder: (ctx, index) {
                    final food = _favoriteFoods[index];
                    bool isFoodSelected = _selectedFood == food['name'];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedFood = food['name']!;
                          _selectedRestaurant = null;
                          _routePoints = [];
                        });
                        _calculateRoutePlannerRecommendations();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: isFoodSelected ? Colors.amber : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isFoodSelected ? Colors.transparent : Colors.black12,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))
                          ],
                        ),
                        child: Row(
                          children: [
                            Text(food['icon'] ?? '🍽️', style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(
                              food['name'] ?? '',
                              style: TextStyle(
                                color: isFoodSelected ? Colors.white : TColor.primaryText,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recList = _recommended;
    return Scaffold(
      body: Stack(children: [
        // Bản đồ Google Maps Standard representation (sử dụng TileLayer chính thức của Google)
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _center, 
            initialZoom: 14.2,
            onTap: (tapPosition, point) {
              if (_currentMode == RecMode.routePlanner) {
                setState(() {
                  _destinationCoord = point;
                  _destinationName = 'Điểm đã chọn trên bản đồ';
                  _selectedRestaurant = null;
                  _routePoints = [];
                  _directRoutePoints = [];
                });
                _calculateRoutePlannerRecommendations();
              }
            },
          ),
          children: [
            // URL Google Maps Standard Tiles (không cần API key, cực kỳ mượt và chuẩn chỉ)
            TileLayer(
              urlTemplate: 'https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
              subdomains: const ['0', '1', '2', '3'],
              userAgentPackageName: 'com.example.appfood',
            ),
            

            // LỚP VẼ ĐƯỜNG ĐI ĐẾN QUÁN GỢI Ý THỰC TẾ (OSRM HIGHWAY MULTI-STOP LINE)
            if (_routePoints.isNotEmpty)
              PolylineLayer<Object>(
                polylines: [
                  // Lớp nền phát sáng (Neon glow effect)
                  Polyline(
                    points: _routePoints,
                    color: _currentMode == RecMode.routePlanner 
                        ? Colors.deepPurpleAccent.withOpacity(0.25)
                        : TColor.primary.withOpacity(0.3),
                    strokeWidth: 9.0,
                  ),
                  // Đường đi chính (GPS Route core)
                  Polyline(
                    points: _routePoints,
                    color: _currentMode == RecMode.routePlanner 
                        ? Colors.deepPurpleAccent 
                        : TColor.primary,
                    strokeWidth: 5.0,
                  ),
                ],
              ),
              
            MarkerLayer(markers: [
              // Ghim vị trí hiện tại của Người dùng (User GPS Locator Pin - Điểm A)
              Marker(
                point: _center,
                width: 50,
                height: 50,
                child: ScaleTransition(
                  scale: _pulse,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(color: Colors.blueAccent.withOpacity(0.5), blurRadius: 15, spreadRadius: 2)
                      ],
                    ),
                    child: const Icon(Icons.my_location, color: Colors.white, size: 22),
                  ),
                ),
              ),

              // Ghim vị trí Điểm Đến Cuối (Destination Marker - Điểm B) - Chỉ hiển thị ở Route Planner
              if (_currentMode == RecMode.routePlanner && _destinationCoord != null)
                Marker(
                  point: _destinationCoord!,
                  width: 55,
                  height: 55,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(color: Colors.redAccent.withOpacity(0.5), blurRadius: 15, spreadRadius: 2)
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _destinationName.contains('Ben') ? '🛍️' : (_destinationName.contains('Đức Bà') ? '⛪' : '🏢'),
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                ),
              
              // Ghim vị trí các nhà hàng gợi ý (Restaurant Location Markers)
              ..._filteredRestaurants.map((r) {
                final rId = (r['id'] ?? r['Id'] ?? 0).toString();
                final recItem = recList.firstWhere(
                  (rec) => (rec['id'] ?? rec['Id'] ?? 0).toString() == rId,
                  orElse: () => {},
                );
                final isRec = recItem.isNotEmpty;
                final isTop = isRec && recItem['_rank'] == 1;
                final isSelected = _selectedRestaurant != null &&
                    (_selectedRestaurant!['id'] ?? _selectedRestaurant!['Id'] ?? -1).toString() == rId;
                
                final double rLat = (r['latitude'] ?? r['Latitude'] ?? 10.7769) as double;
                final double rLng = (r['longitude'] ?? r['Longitude'] ?? 106.7009) as double;
                
                return Marker(
                  point: LatLng(rLat, rLng),
                  width: isSelected ? 65 : (isTop ? 55 : 44),
                  height: isSelected ? 65 : (isTop ? 55 : 44),
                  child: GestureDetector(
                    onTap: () {
                      _selectRestaurant(r);
                      _mapController.move(LatLng(rLat, rLng), 14.5);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? Colors.amber 
                            : (isTop ? TColor.primary : Colors.white),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected 
                              ? Colors.white 
                              : (isRec 
                                  ? (_currentMode == RecMode.routePlanner ? Colors.deepPurpleAccent : TColor.primary) 
                                  : Colors.grey),
                          width: isSelected ? 4 : 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected ? Colors.amber.withOpacity(0.6) : Colors.black12,
                            blurRadius: isSelected ? 16 : 6,
                          )
                        ],
                      ),
                      child: Center(
                        child: Text(
                          isSelected 
                              ? '📍' 
                              : (isTop 
                                  ? '🏆' 
                                  : (_currentMode == RecMode.routePlanner ? '🌟' : '✨')),
                          style: TextStyle(fontSize: isSelected ? 26 : 18),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ]),
          ],
        ),
        
        // BẢNG ĐIỀU KHIỂN AI TÍCH HỢP FLOATING COLLAPSIBLE CONTROL HUB (HUD)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _buildControlHub(),
            ),
          ),
        ),
        
        // PANEL DƯỚI CUỘC (INTERACTIVE BOTTOM PANEL LIST)
        AnimatedPositioned(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          bottom: _panelExpanded ? 0 : -350,
          left: 0,
          right: 0,
          child: Container(
            height: 400,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, offset: const Offset(0, -4))],
            ),
            child: Column(children: [
              GestureDetector(
                onTap: () => setState(() => _panelExpanded = !_panelExpanded),
                child: Container(
                  width: double.infinity,
                  height: 40,
                  color: Colors.transparent,
                  child: Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(3)),
                    ),
                  ),
                ),
              ),
              Expanded(child: _buildPanelContent(recList)),
            ]),
          ),
        ),
        
        // NÚT MỞ RỘNG PANEL AI
        if (!_panelExpanded)
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: _currentMode == RecMode.routePlanner ? Colors.deepPurpleAccent : TColor.primary,
              onPressed: () => setState(() => _panelExpanded = true),
              child: const Icon(Icons.auto_awesome, color: Colors.white),
            ),
          )
      ]),
    );
  }

  Widget _buildModeChip(RecMode mode, String label) {
    bool selected = _currentMode == mode;
    Color activeColor = mode == RecMode.routePlanner ? Colors.deepPurpleAccent : TColor.primary;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentMode = mode;
        });
        _fetchModeData();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (!selected) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : TColor.primaryText,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _mapBtn(IconData icon, VoidCallback tap, {bool loading = false}) {
    return GestureDetector(
      onTap: tap,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))]),
        child: loading
            ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(icon, color: _currentMode == RecMode.routePlanner ? Colors.deepPurpleAccent : TColor.primary),
      ),
    );
  }

  Widget _buildPanelContent(List<Map<String, dynamic>> recList) {
    return Column(children: [
      if (_aiReason.isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (_currentMode == RecMode.routePlanner ? Colors.deepPurpleAccent : TColor.primary).withOpacity(0.08), 
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(children: [
              const Text('🧠', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _aiReason,
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: TColor.primaryText),
                ),
              ),
            ]),
          ),
        ),
      
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: recList.length,
          itemBuilder: (ctx, i) {
            final r = recList[i];
            final isSelected = _selectedRestaurant != null && _selectedRestaurant!['id'].toString() == r['id'].toString();
            
            // Tính toán khoảng cách rẽ (Detour distance) từ lộ trình đến quán để giảng viên trầm trồ
            double detourDist = r['_dist_to_route'] != null 
                ? (r['_dist_to_route'] as double) 
                : 0.1;
            
            String detourText = detourDist < 0.1 
                ? "Ngay sát tuyến đường" 
                : "Cách lộ trình ${detourDist.toStringAsFixed(1)} km";
            
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected 
                      ? (_currentMode == RecMode.routePlanner ? Colors.deepPurpleAccent : TColor.primary) 
                      : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected 
                        ? (_currentMode == RecMode.routePlanner ? Colors.deepPurpleAccent : TColor.primary).withOpacity(0.1) 
                        : Colors.black.withOpacity(0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Card(
                elevation: 0,
                color: isSelected 
                    ? (_currentMode == RecMode.routePlanner ? Colors.deepPurpleAccent : TColor.primary).withOpacity(0.05) 
                    : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isSelected 
                        ? Colors.amber 
                        : (r['_rank'] == 1 ? Colors.amber : (_currentMode == RecMode.routePlanner ? Colors.deepPurpleAccent : TColor.primary)),
                    child: Text('${r['_rank']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(
                    r['name'],
                    style: TextStyle(fontWeight: FontWeight.bold, color: TColor.primaryText),
                  ),
                  subtitle: Text(
                    _currentMode == RecMode.routePlanner 
                        ? '$detourText | ${(r['_score'] * 100).round()}% phù hợp'
                        : 'Đánh giá: ${r['rating'] ?? 4.5} ⭐ | ${(r['_score'] * 100).round()}% phù hợp',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _currentMode == RecMode.routePlanner ? Colors.deepPurpleAccent : TColor.primary, 
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('Thêm dừng', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () {
                    // Chạm lần 1: Chọn quán và vẽ tuyến đi đa điểm đi qua quán đó
                    if (!isSelected) {
                      _selectRestaurant(r);
                      _mapController.move(LatLng(r['latitude'], r['longitude']), 14.2);
                    } else {
                      // Chạm lần 2 hoặc nhấn chevron: Đi vào chi tiết quán
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RestaurantDetailView(restaurant: RestaurantModel.fromJson(r)),
                        ),
                      );
                    }
                  },
                ),
              ),
            );
          },
        ),
      )
    ]);
  }
}
