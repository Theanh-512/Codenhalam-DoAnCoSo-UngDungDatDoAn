import 'dart:convert';
import 'dart:async';
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

enum RecMode { nearby, habits, topRated }

class _AiMapViewState extends State<AiMapView> with TickerProviderStateMixin {
  static const String _aiBase = 'http://127.0.0.1:8000';
  static const String _backendBase = 'http://127.0.0.1:5149';

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

  bool _panelExpanded = true;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
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
    _fetchModeData();
  }

  Future<void> _tryGps() async {
    if (mounted) setState(() => _loadingGps = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      LatLng defaultPos = const LatLng(10.7769, 106.7009);
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        setState(() => _center = defaultPos);
        _mapController.move(_center, 14);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)).timeout(const Duration(seconds: 5));
      if (mounted) {
        setState(() => _center = LatLng(pos.latitude, pos.longitude));
        _mapController.move(_center, 14);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _center = const LatLng(10.7769, 106.7009));
        _mapController.move(_center, 14);
      }
    } finally {
      if (mounted) setState(() => _loadingGps = false);
    }
  }

  Future<void> _fetchInitialData() async {
    try {
      final res = await http.get(Uri.parse('$_backendBase/api/Restaurants')).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        if (mounted) setState(() => _allRestaurants = list.cast<Map<String, dynamic>>());
      }
    } catch (_) {}
  }

  Future<void> _fetchModeData() async {
    if (mounted) setState(() { _loadingAi = true; _aiReady = false; });
    try {
      String endpoint = '';
      Map<String, String> queryParams = {'lat': _center.latitude.toString(), 'lng': _center.longitude.toString()};
      if (_currentMode == RecMode.nearby) {
        endpoint = '$_backendBase/api/Restaurants/map/nearby';
      } else if (_currentMode == RecMode.topRated) {
        endpoint = '$_backendBase/api/Restaurants/map/top-rated';
      } else {
        await _callAIHabits();
        return;
      }
      final uri = Uri.parse(endpoint).replace(queryParameters: queryParams);
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        if (mounted) {
          setState(() {
            _filteredRestaurants = list.cast<Map<String, dynamic>>();
            if (_filteredRestaurants.isEmpty) _filteredRestaurants = _allRestaurants.take(10).toList();
            _recIds = _filteredRestaurants.map((e) => (e['id'] as num).toInt()).toList();
            _recScores = List.generate(_recIds.length, (index) => 0.95 - (index * 0.05));
            _aiReason = _currentMode == RecMode.nearby ? "Các quán ăn gần bạn nhất trong bán kính 10km." : "Những quán ăn được đánh giá cao nhất bạn nên thử.";
            _aiReady = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() { _filteredRestaurants = _allRestaurants.take(10).toList(); _aiReady = true; });
      }
    } finally {
      if (mounted) setState(() => _loadingAi = false);
    }
  }

  Future<void> _callAIHabits() async {
    try {
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
      final body = jsonEncode({'user_id': userId, 'lat': _center.latitude, 'lng': _center.longitude, 'time': timeStr, 'day_of_week': now.weekday - 1});
      final res = await http.post(Uri.parse('$_aiBase/api/ai/recommend-poi'), headers: {'Content-Type': 'application/json'}, body: body).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _recIds = (data['restaurant_ids'] as List).cast<int>();
            _recScores = (data['confidence_scores'] as List).map((e) => (e as num).toDouble()).toList();
            _aiReason = data['reason'] ?? '';
            _filteredRestaurants = [];
            for (var id in _recIds) {
              final found = _allRestaurants.firstWhere((r) => r['id'] == id, orElse: () => {});
              if (found.isNotEmpty) _filteredRestaurants.add(found);
            }
            if (_filteredRestaurants.isEmpty) _filteredRestaurants = _allRestaurants.take(5).toList();
            _aiReady = true;
          });
        }
      } else { await _fetchContextualFallback(); }
    } catch (e) { await _fetchContextualFallback(); }
    finally { if (mounted) setState(() => _loadingAi = false); }
  }

  Future<void> _fetchContextualFallback() async {
    try {
      final uri = Uri.parse('$_backendBase/api/Restaurants/map/contextual').replace(queryParameters: {'lat': _center.latitude.toString(), 'lng': _center.longitude.toString(), 'userId': '1'});
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        setState(() {
          _filteredRestaurants = list.cast<Map<String, dynamic>>();
          _recIds = _filteredRestaurants.map((e) => (e['id'] as num).toInt()).toList();
          _recScores = List.generate(_recIds.length, (index) => 0.9 - (index * 0.05));
          _aiReason = "Gợi ý dựa trên khung giờ và địa điểm phổ biến.";
          _aiReady = true;
        });
      }
    } catch (_) {}
  }

  List<Map<String, dynamic>> get _recommended {
    final result = <Map<String, dynamic>>[];
    for (int i = 0; i < _filteredRestaurants.length; i++) {
      result.add({..._filteredRestaurants[i], '_score': _recScores.length > i ? _recScores[i] : 0.8, '_rank': i + 1});
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final recList = _recommended;
    return Scaffold(
      body: Stack(children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(initialCenter: _center, initialZoom: 14),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.appfood'),
            if (recList.isNotEmpty) PolylineLayer(polylines: recList.take(3).map((r) => Polyline(points: [_center, LatLng(r['latitude'], r['longitude'])], color: r['_rank'] == 1 ? Colors.amber.withOpacity(0.6) : TColor.primary.withOpacity(0.4), strokeWidth: r['_rank'] == 1 ? 5 : 3)).toList()),
            MarkerLayer(markers: [
              Marker(point: _center, width: 50, height: 50, child: ScaleTransition(scale: _pulse, child: Container(decoration: BoxDecoration(color: TColor.primary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: [BoxShadow(color: TColor.primary.withOpacity(0.5), blurRadius: 12)]), child: const Icon(Icons.person_pin_rounded, color: Colors.white, size: 26)))),
              ..._filteredRestaurants.map((r) {
                final recItem = recList.firstWhere((rec) => rec['id'].toString() == r['id'].toString(), orElse: () => {});
                final isRec = recItem.isNotEmpty;
                final isTop = isRec && recItem['_rank'] == 1;
                return Marker(point: LatLng(r['latitude'], r['longitude']), width: isTop ? 65 : (isRec ? 55 : 44), height: isTop ? 65 : (isRec ? 55 : 44), child: GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantDetailView(restaurant: RestaurantModel.fromJson(r)))), child: AnimatedContainer(duration: const Duration(milliseconds: 300), decoration: BoxDecoration(color: isTop ? Colors.amber : (isRec ? TColor.primary : Colors.white), shape: BoxShape.circle, border: Border.all(color: isRec ? Colors.white : TColor.primary.withOpacity(0.3), width: isRec ? 3 : 1), boxShadow: [BoxShadow(color: isTop ? Colors.amber.withOpacity(0.6) : Colors.black12, blurRadius: isRec ? 12 : 4)]), child: Center(child: Text(_currentMode == RecMode.topRated ? '🏆' : (_currentMode == RecMode.nearby ? '📍' : '✨'), style: TextStyle(fontSize: isTop ? 28 : (isRec ? 22 : 16)))))));
              })
            ])
          ],
        ),
        Positioned(top: 0, left: 0, right: 0, child: SafeArea(child: Column(children: [
          Padding(padding: const EdgeInsets.all(16), child: Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]), child: Row(children: [const Text('🧠', style: TextStyle(fontSize: 18)), const SizedBox(width: 8), Text('SCR AI Map', style: TextStyle(fontWeight: FontWeight.w800, color: TColor.primaryText)), if (_loadingAi) const Padding(padding: EdgeInsets.only(left: 8), child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)))])),
            const Spacer(), _mapBtn(Icons.refresh, _fetchModeData), const SizedBox(width: 8), _mapBtn(Icons.my_location, _tryGps, loading: _loadingGps)
          ])),
          SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [_buildModeChip(RecMode.nearby, '📍 Gần nhất', ''), _buildModeChip(RecMode.habits, '✨ AI Habits', ''), _buildModeChip(RecMode.topRated, '🏆 Đỉnh cao', '')]))
        ]))),
        AnimatedPositioned(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut, bottom: _panelExpanded ? 0 : -350, left: 0, right: 0, child: Container(height: 400, decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(30)), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)]), child: Column(children: [GestureDetector(onTap: () => setState(() => _panelExpanded = !_panelExpanded), child: Container(width: double.infinity, height: 40, color: Colors.transparent, child: Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(3)))))), Expanded(child: _buildPanelContent(recList))]))),
        if (!_panelExpanded) Positioned(bottom: 20, right: 20, child: FloatingActionButton(backgroundColor: TColor.primary, onPressed: () => setState(() => _panelExpanded = true), child: const Icon(Icons.auto_awesome, color: Colors.white)))
      ]),
    );
  }

  Widget _buildModeChip(RecMode mode, String label, String sub) {
    bool selected = _currentMode == mode;
    return GestureDetector(onTap: () { setState(() => _currentMode = mode); _fetchModeData(); }, child: Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: selected ? TColor.primary : Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [if (!selected) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]), child: Text(label, style: TextStyle(color: selected ? Colors.white : TColor.primaryText, fontWeight: FontWeight.bold, fontSize: 13))));
  }

  Widget _mapBtn(IconData icon, VoidCallback tap, {bool loading = false}) {
    return GestureDetector(onTap: tap, child: Container(width: 44, height: 44, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)]), child: loading ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)) : Icon(icon, color: TColor.primary)));
  }

  Widget _buildPanelContent(List<Map<String, dynamic>> recList) {
    return Column(children: [
      if (_aiReason.isNotEmpty) Padding(padding: const EdgeInsets.all(16), child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: TColor.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(15)), child: Row(children: [const Text('🧠'), const SizedBox(width: 10), Expanded(child: Text(_aiReason, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)))]))),
      Expanded(child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: recList.length, itemBuilder: (ctx, i) {
        final r = recList[i];
        return Card(margin: const EdgeInsets.only(bottom: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), child: ListTile(leading: CircleAvatar(backgroundColor: r['_rank'] == 1 ? Colors.amber : TColor.primary, child: Text('${r['_rank']}', style: const TextStyle(color: Colors.white))), title: Text(r['name'], style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('Đánh giá: ${r['rating'] ?? 5} ⭐ | ${(r['_score'] * 100).round()}% phù hợp'), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantDetailView(restaurant: RestaurantModel.fromJson(r))))));
      }))
    ]);
  }
}
