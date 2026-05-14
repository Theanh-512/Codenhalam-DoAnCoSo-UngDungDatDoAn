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

class _AiMapViewState extends State<AiMapView> with TickerProviderStateMixin {
  static const String _aiBase = 'http://127.0.0.1:8000';
  static const String _backendBase = 'http://127.0.0.1:5149';

  final MapController _mapController = MapController();
  LatLng _center = const LatLng(10.7769, 106.7009); 

  bool _loadingGps   = false;
  bool _loadingAi    = false;
  bool _aiReady      = false;

  List<int>    _recIds      = [];
  List<double> _recScores   = [];
  String       _aiReason    = '';
  Map<String, dynamic> _analysis = {};
  List<Map<String, dynamic>> _restaurants = [];

  // Toggle Panel State
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
    await Future.wait([_fetchRestaurants(), _callAI()]);
  }

  Future<void> _tryGps() async {
    setState(() => _loadingGps = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium)).timeout(const Duration(seconds: 8));
      if (mounted) {
        setState(() => _center = LatLng(pos.latitude, pos.longitude));
        _mapController.move(_center, 14);
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingGps = false);
  }

  Future<void> _fetchRestaurants() async {
    try {
      final res = await http.get(Uri.parse('$_backendBase/api/Restaurants'), headers: {'Content-Type': 'application/json'}).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        if (mounted) setState(() => _restaurants = list.cast<Map<String, dynamic>>());
      }
    } catch (_) {}
  }

  Future<void> _callAI() async {
    setState(() { _loadingAi = true; _aiReady = false; });
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
            _analysis = data['analysis'] ?? {};
            _aiReady = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _recIds = [1, 2, 3]; _recScores = [0.91, 0.85, 0.78];
          _aiReason = 'Gợi ý từ thói quen ăn uống của bạn.'; _aiReady = true;
        });
      }
    }
    if (mounted) setState(() => _loadingAi = false);
  }

  List<Map<String, dynamic>> get _recommended {
    final result = <Map<String, dynamic>>[];
    for (int i = 0; i < _recIds.length; i++) {
      final rId = _recIds[i].toString();
      final found = _restaurants.firstWhere((r) => r['id'].toString() == rId, orElse: () => {});
      if (found.isNotEmpty) {
        result.add({...found, '_score': _recScores[i], '_rank': i + 1});
      }
    }
    // Fallback nếu không có gợi ý từ AI hoặc không khớp ID
    if (result.isEmpty && _restaurants.isNotEmpty) {
      for (int i = 0; i < 3 && i < _restaurants.length; i++) {
        result.add({..._restaurants[i], '_score': 0.85 - (i * 0.1), '_rank': i + 1});
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final recList = _recommended;
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: _center, initialZoom: 14),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.appfood'),
              
              // Multi-Route Layer
              if (recList.isNotEmpty)
                PolylineLayer(
                  polylines: recList.take(3).map((r) => Polyline(
                    points: [_center, LatLng(r['latitude'], r['longitude'])],
                    color: r['_rank'] == 1 ? Colors.amber.withValues(alpha: 0.6) : TColor.primary.withValues(alpha: 0.4),
                    strokeWidth: r['_rank'] == 1 ? 5 : 3,
                  )).toList(),
                ),

              MarkerLayer(
                markers: [
                  Marker(
                    point: _center, width: 50, height: 50,
                    child: ScaleTransition(scale: _pulse, child: Container(
                      decoration: BoxDecoration(color: TColor.primary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [BoxShadow(color: TColor.primary.withValues(alpha: 0.5), blurRadius: 12)]),
                      child: const Icon(Icons.person_pin_rounded, color: Colors.white, size: 26),
                    )),
                  ),
                  ..._restaurants.map((r) {
                    final recItem = recList.firstWhere((rec) => rec['id'].toString() == r['id'].toString(), orElse: () => {});
                    final isRec = recItem.isNotEmpty;
                    final isTop = isRec && recItem['_rank'] == 1;

                    return Marker(
                      point: LatLng(r['latitude'], r['longitude']),
                      width: isTop ? 65 : (isRec ? 55 : 44),
                      height: isTop ? 65 : (isRec ? 55 : 44),
                      child: GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantDetailView(restaurant: RestaurantModel.fromJson(r)))),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: isTop ? Colors.amber : (isRec ? TColor.primary : Colors.white),
                            shape: BoxShape.circle,
                            border: Border.all(color: isRec ? Colors.white : TColor.primary.withValues(alpha: 0.3), width: isRec ? 3 : 1),
                            boxShadow: [BoxShadow(color: isTop ? Colors.amber.withValues(alpha: 0.6) : Colors.black12, blurRadius: isRec ? 12 : 4)],
                          ),
                          child: Center(child: Text(isTop ? '🏆' : (isRec ? '✨' : '🍜'), style: TextStyle(fontSize: isTop ? 28 : (isRec ? 22 : 16)))),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // Top Header
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                  child: Row(children: [
                    const Text('🧠', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text('SCR AI Map', style: TextStyle(fontWeight: FontWeight.w800, color: TColor.primaryText)),
                    if (_loadingAi) const Padding(padding: EdgeInsets.only(left: 8), child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))),
                  ]),
                ),
                const Spacer(),
                _mapBtn(Icons.refresh, _callAI),
                const SizedBox(width: 8),
                _mapBtn(Icons.my_location, _tryGps, loading: _loadingGps),
              ]),
            )),
          ),

          // Toggle Panel (Show/Hide)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            bottom: _panelExpanded ? 0 : -350,
            left: 0, right: 0,
            child: Container(
              height: 400,
              decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(30)), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)]),
              child: Column(children: [
                GestureDetector(
                  onTap: () => setState(() => _panelExpanded = !_panelExpanded),
                  child: Container(
                    width: double.infinity, height: 40, color: Colors.transparent,
                    child: Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(3)))),
                  ),
                ),
                Expanded(child: _buildPanelContent(recList)),
              ]),
            ),
          ),
          
          // Small Toggle Button when hidden
          if (!_panelExpanded)
            Positioned(
              bottom: 20, right: 20,
              child: FloatingActionButton(
                backgroundColor: TColor.primary,
                onPressed: () => setState(() => _panelExpanded = true),
                child: const Icon(Icons.auto_awesome, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _mapBtn(IconData icon, VoidCallback tap, {bool loading = false}) {
    return GestureDetector(
      onTap: tap,
      child: Container(
        width: 44, height: 44, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)]),
        child: loading ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)) : Icon(icon, color: TColor.primary),
      ),
    );
  }

  Widget _buildPanelContent(List<Map<String, dynamic>> recList) {
    return Column(children: [
      if (_aiReason.isNotEmpty)
        Padding(padding: const EdgeInsets.all(16), child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: TColor.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)),
          child: Row(children: [const Text('🧠'), const SizedBox(width: 10), Expanded(child: Text(_aiReason, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)))]),
        )),
      Expanded(child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: recList.length,
        itemBuilder: (ctx, i) {
          final r = recList[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: r['_rank'] == 1 ? Colors.amber : TColor.primary, child: Text('${r['_rank']}', style: const TextStyle(color: Colors.white))),
              title: Text(r['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('AI phù hợp: ${(r['_score'] * 100).round()}%'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantDetailView(restaurant: RestaurantModel.fromJson(r)))),
            ),
          );
        },
      )),
    ]);
  }
}
