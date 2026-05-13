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

/// Màn hình AI Map — Bản đồ + Gợi ý món ăn / quán ăn từ SCR-Multimodal
class AiMapView extends StatefulWidget {
  const AiMapView({super.key});

  @override
  State<AiMapView> createState() => _AiMapViewState();
}

class _AiMapViewState extends State<AiMapView> with TickerProviderStateMixin {
  static const String _aiBase = 'http://127.0.0.1:8000';
  static const String _backendBase = 'http://127.0.0.1:5149';

  final MapController _mapController = MapController();
  LatLng _center = const LatLng(10.7769, 106.7009); // HCM default

  bool _loadingGps   = false;
  bool _loadingAi    = false;
  bool _aiReady      = false;

  // AI Results
  List<int>    _recIds      = [];
  List<double> _recScores   = [];
  String       _aiReason    = '';
  Map<String, dynamic> _analysis = {};

  // Restaurants from backend
  List<Map<String, dynamic>> _restaurants = [];

  // Panel
  bool _showPanel = false;

  // Animation
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
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
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      ).timeout(const Duration(seconds: 8));
      if (mounted) {
        setState(() => _center = LatLng(pos.latitude, pos.longitude));
        _mapController.move(_center, 14);
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingGps = false);
  }

  Future<void> _fetchRestaurants() async {
    try {
      final res = await http.get(
        Uri.parse('$_backendBase/api/Restaurants'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        if (mounted) {
          setState(() {
            _restaurants = list.cast<Map<String, dynamic>>();
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _callAI() async {
    setState(() { _loadingAi = true; _aiReady = false; });
    try {
      final now = DateTime.now();
      final timeStr = DateFormat('HH:mm').format(now);
      final dow = now.weekday - 1; // 0=Mon

      // Lấy userId từ token
      final token = await AuthStore.getToken();
      int userId = 1;
      if (token != null && token.isNotEmpty) {
        try {
          final parts = token.split('.');
          if (parts.length == 3) {
            final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
            final m = jsonDecode(payload) as Map<String, dynamic>;
            userId = int.tryParse(m['nameid']?.toString() ?? '1') ?? 1;
          }
        } catch (_) {}
      }

      final body = jsonEncode({
        'user_id': userId,
        'lat': _center.latitude,
        'lng': _center.longitude,
        'time': timeStr,
        'day_of_week': dow,
      });

      final res = await http.post(
        Uri.parse('$_aiBase/api/ai/recommend-poi'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _recIds    = (data['restaurant_ids'] as List<dynamic>).cast<int>();
            _recScores = (data['confidence_scores'] as List<dynamic>).map((e) => (e as num).toDouble()).toList();
            _aiReason  = data['reason'] as String? ?? '';
            _analysis  = (data['analysis'] as Map<String, dynamic>?) ?? {};
            _aiReady   = true;
            _showPanel = true;
          });
        }
      }
    } catch (e) {
      // AI service offline — fallback mock
      if (mounted) {
        setState(() {
          _recIds    = [1, 2, 3];
          _recScores = [0.91, 0.85, 0.78];
          _aiReason  = 'Gợi ý từ thói quen ăn uống của bạn vào khung giờ hiện tại.';
          _analysis  = {'short_term_impact': 0.45, 'long_term_impact': 0.35, 'visual_impact': 0.20};
          _aiReady   = true;
          _showPanel = true;
        });
      }
    }
    if (mounted) setState(() => _loadingAi = false);
  }

  List<Map<String, dynamic>> get _recommended {
    if (_restaurants.isEmpty) return [];
    // Map recIds → restaurant. Nếu không khớp, lấy n đầu tiên
    final result = <Map<String, dynamic>>[];
    for (int i = 0; i < _recIds.length && i < _recScores.length; i++) {
      final idx = _recIds[i] % _restaurants.length;
      result.add({
        ..._restaurants[idx],
        '_score': _recScores[i],
        '_rank': i + 1,
      });
    }
    return result;
  }

  // Fake markers xung quanh vị trí
  List<LatLng> get _markerPositions {
    final base = _center;
    return [
      base,
      LatLng(base.latitude + 0.003, base.longitude + 0.004),
      LatLng(base.latitude - 0.002, base.longitude + 0.006),
      LatLng(base.latitude + 0.005, base.longitude - 0.003),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── BẢN ĐỒ ─────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.appfood',
              ),
              // Markers
              MarkerLayer(
                markers: [
                  // User location
                  Marker(
                    point: _center,
                    width: 50,
                    height: 50,
                    child: ScaleTransition(
                      scale: _pulse,
                      child: Container(
                        decoration: BoxDecoration(
                          color: TColor.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [BoxShadow(color: TColor.primary.withValues(alpha: 0.5), blurRadius: 12)],
                        ),
                        child: const Icon(Icons.person_pin_rounded, color: Colors.white, size: 26),
                      ),
                    ),
                  ),
                  // Restaurant markers
                  ..._markerPositions.skip(1).toList().asMap().entries.map((e) {
                    final rank = e.key + 1;
                    return Marker(
                      point: e.value,
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        onTap: () => setState(() => _showPanel = true),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: TColor.primary, width: 2.5),
                            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
                          ),
                          child: Center(
                            child: Text('🍜',
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // ── TOP BAR ────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    // AI Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 10)],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🧠', style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Text('SCR AI Map',
                            style: TextStyle(fontWeight: FontWeight.w800, color: TColor.primaryText, fontSize: 14),
                          ),
                          if (_loadingAi) ...[
                            const SizedBox(width: 8),
                            SizedBox(width: 14, height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: TColor.primary)),
                          ] else if (_aiReady) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(color: TColor.primary, shape: BoxShape.circle),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Refresh button
                    GestureDetector(
                      onTap: _callAI,
                      child: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
                        ),
                        child: Icon(Icons.refresh_rounded, color: TColor.primary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // GPS button
                    GestureDetector(
                      onTap: _tryGps,
                      child: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
                        ),
                        child: _loadingGps
                          ? const Center(child: SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2)))
                          : Icon(Icons.my_location_rounded, color: TColor.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── BOTTOM PANEL ──────────────────────────────────
          if (_showPanel)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, -4))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    const SizedBox(height: 12),
                    Container(width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 14),

                    // AI Reason Banner
                    if (_aiReason.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: TColor.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: TColor.primary.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Text('🧠', style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 10),
                              Expanded(child: Text(_aiReason,
                                style: TextStyle(fontSize: 12, color: TColor.primaryDark, fontStyle: FontStyle.italic))),
                            ],
                          ),
                        ),
                      ),

                    // Attention Weights
                    if (_analysis.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            _weightChip('⚡ Ngắn hạn', _analysis['short_term_impact'] ?? 0.33),
                            const SizedBox(width: 8),
                            _weightChip('📅 Dài hạn', _analysis['long_term_impact'] ?? 0.33),
                            const SizedBox(width: 8),
                            _weightChip('📸 Hình ảnh', _analysis['visual_impact'] ?? 0.33),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Text('Gợi ý AI cho bạn',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: TColor.primaryText)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: TColor.primary, borderRadius: BorderRadius.circular(10)),
                            child: Text('${_recommended.length} quán',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Restaurant Cards
                    Flexible(
                      child: _loadingAi
                        ? const Center(child: CircularProgressIndicator())
                        : _recommended.isEmpty
                          ? _buildOfflineMock()
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              itemCount: _recommended.length,
                              itemBuilder: (ctx, i) => _buildRestCard(_recommended[i], i),
                            ),
                    ),
                  ],
                ),
              ),
            ),

          // Collapsed toggle
          if (!_showPanel)
            Positioned(
              bottom: 24, left: 0, right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => setState(() => _showPanel = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: TColor.primary,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [BoxShadow(color: TColor.primary.withValues(alpha: 0.4), blurRadius: 12)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        const Text('Xem gợi ý AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _weightChip(String label, dynamic val) {
    final double v = (val as num).toDouble();
    final pct = (v * 100).round();
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: TColor.primary.withValues(alpha: 0.06 + v * 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: TColor.primary.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: TColor.secondaryText), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text('$pct%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: TColor.primary)),
          ],
        ),
      ),
    );
  }

  Widget _buildRestCard(Map<String, dynamic> r, int idx) {
    final score = ((r['_score'] as double? ?? 0.9) * 100).round();
    final imgUrl = r['imageUrl'] as String? ?? r['image_url'] as String? ?? '';
    final name = r['name'] as String? ?? 'Quán ăn #${idx + 1}';
    final addr = r['address'] as String? ?? r['location'] as String? ?? 'TP.HCM';
    final rank = r['_rank'] as int? ?? idx + 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: rank == 1 ? Border.all(color: TColor.primary, width: 1.5) : null,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: imgUrl.startsWith('http')
              ? Image.network(imgUrl, width: 72, height: 72, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder())
              : _placeholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (rank == 1) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(6)),
                        child: const Text('🏆 #1', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: TColor.primaryText),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(addr, style: TextStyle(fontSize: 12, color: TColor.secondaryText), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 14, color: TColor.primary),
                    const SizedBox(width: 4),
                    Text('AI: $score% phù hợp', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: TColor.primary)),
                    const Spacer(),
                    Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                    Text(' 4.8', style: TextStyle(fontSize: 12, color: TColor.secondaryText)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineMock() {
    // Hiển thị kết quả AI mock khi không kết nối được backend
    final mocks = [
      {'name': 'Phở Thìn Bờ Hồ', 'addr': '13 Lò Đúc, Hà Nội', 'score': 91, 'emoji': '🍜'},
      {'name': 'Pizza 4Ps Saigon', 'addr': '8/15 Lê Thánh Tôn, Q.1', 'score': 85, 'emoji': '🍕'},
      {'name': 'Bún Chả Hương Liên', 'addr': '24 Lê Văn Hưu, HN', 'score': 78, 'emoji': '🥢'},
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: mocks.asMap().entries.map((e) {
        final i = e.key;
        final m = e.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: i == 0 ? Border.all(color: TColor.primary, width: 1.5) : null,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Row(
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: TColor.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Text(m['emoji'] as String, style: const TextStyle(fontSize: 36))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (i == 0) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(6)),
                            child: const Text('🏆 #1', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(child: Text(m['name'] as String,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: TColor.primaryText),
                          maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(m['addr'] as String, style: TextStyle(fontSize: 12, color: TColor.secondaryText)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, size: 14, color: TColor.primary),
                        const SizedBox(width: 4),
                        Text('AI: ${m['score']}% phù hợp',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: TColor.primary)),
                        const Spacer(),
                        const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                        Text(' 4.8', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _placeholder() => Container(
    width: 72, height: 72,
    decoration: BoxDecoration(color: TColor.textfield, borderRadius: BorderRadius.circular(10)),
    child: const Center(child: Text('🍽️', style: TextStyle(fontSize: 30))),
  );
}
