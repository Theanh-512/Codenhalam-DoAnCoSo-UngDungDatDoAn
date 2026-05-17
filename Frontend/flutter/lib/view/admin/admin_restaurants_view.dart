import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_food_app/view/admin/admin_menu_items_view.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'package:flutter_food_app/common/auth_store.dart';
import 'package:flutter_food_app/model/restaurant_model.dart';
import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter_food_app/common/globs.dart';
import 'package:flutter_food_app/common/smart_image.dart';

class AdminRestaurantsView extends StatefulWidget {
  const AdminRestaurantsView({super.key});

  @override
  State<AdminRestaurantsView> createState() => _AdminRestaurantsViewState();
}

class _AdminRestaurantsViewState extends State<AdminRestaurantsView> {
  List<dynamic> _rows = [];
  bool _loading = true;
  String? _err;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final res = await http.get(Uri.parse(Globs.restaurantsUrl));
      if (res.statusCode != 200) {
        setState(() {
          _err = Globs.apiErrorMessage(res.body);
          _loading = false;
        });
        return;
      }
      final list = jsonDecode(res.body);
      setState(() {
        _rows = list is List ? list : [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _err = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa nhà hàng?'),
        content: Text('Xóa $id (món liên quan cũng bị xóa).'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final h = await AuthStore.authHeaders(jsonContent: false);
      final res = await http.delete(Uri.parse(Globs.adminRestaurantUrl(id)), headers: h);
      if (!mounted) return;
      if (res.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Globs.apiErrorMessage(res.body))),
        );
        return;
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _editOrCreate([Map<String, dynamic>? existing]) async {
    final idCtrl = TextEditingController(text: existing?['id']?.toString() ?? '');
    final nameCtrl = TextEditingController(text: existing?['name']?.toString() ?? '');
    final t1Ctrl = TextEditingController(text: existing?['type1']?.toString() ?? '');
    final t2Ctrl = TextEditingController(text: existing?['type2']?.toString() ?? '');
    
    final initialImg = existing?['imageUrl']?.toString() ?? existing?['image']?.toString() ?? '';
    String? pickedBase64;
    final imgCtrl = TextEditingController();
    if (initialImg.startsWith('data:image')) {
      pickedBase64 = initialImg;
      imgCtrl.text = '[Ảnh thiết bị]';
    } else {
      imgCtrl.text = initialImg;
    }

    final latCtrl = TextEditingController(
      text: existing != null && existing['lat'] != null ? '${existing['lat']}' : '',
    );
    final lngCtrl = TextEditingController(
      text: existing != null && existing['lng'] != null ? '${existing['lng']}' : '',
    );

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text(existing == null ? 'Thêm nhà hàng' : 'Sửa nhà hàng'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: idCtrl,
                  decoration: const InputDecoration(labelText: 'ID (vd: r6)'),
                  enabled: existing == null,
                ),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên')),
                TextField(
                  controller: t1Ctrl,
                  decoration: const InputDecoration(
                    labelText: 'Dòng món / ẩm thực',
                    helperText: 'VD: Cơm tấm, Phở, Burger, Pizza',
                  ),
                ),
                TextField(
                  controller: t2Ctrl,
                  decoration: const InputDecoration(
                    labelText: 'Phong cách / kiểu ẩm thực',
                    helperText: 'VD: Việt, Fast food, Street food, Ý',
                  ),
                ),
                const SizedBox(height: 12),
                if (pickedBase64 != null || imgCtrl.text.trim().isNotEmpty) ...[
                  Container(
                    width: 260,
                    height: 130,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SmartImage(
                        pickedBase64 ?? imgCtrl.text.trim(),
                        width: 260,
                        height: 130,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: imgCtrl,
                        decoration: const InputDecoration(
                          labelText: 'URL ảnh',
                        ),
                        enabled: pickedBase64 == null,
                        onChanged: (_) => setSt(() {}),
                      ),
                    ),
                    if (pickedBase64 != null)
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.red),
                        onPressed: () {
                          setSt(() {
                            pickedBase64 = null;
                            imgCtrl.clear();
                          });
                        },
                      ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TColor.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      icon: const Icon(Icons.image_search, size: 18),
                      label: const Text('Chọn ảnh', style: TextStyle(fontSize: 12)),
                      onPressed: () async {
                        try {
                          final picker = ImagePicker();
                          final XFile? image = await picker.pickImage(
                            source: ImageSource.gallery,
                            maxWidth: 400,
                            maxHeight: 400,
                            imageQuality: 70,
                          );
                          if (image != null) {
                            final bytes = await image.readAsBytes();
                            final base64Str = base64Encode(bytes);
                            final ext = image.name.split('.').last.toLowerCase();
                            final mime = (ext == 'png') ? 'image/png' : 'image/jpeg';
                            setSt(() {
                              pickedBase64 = 'data:$mime;base64,$base64Str';
                              imgCtrl.text = '[Ảnh thiết bị]';
                            });
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Lỗi chọn ảnh: $e')),
                          );
                        }
                      },
                    ),
                  ],
                ),
                TextField(
                  controller: latCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Vĩ độ (lat)',
                    hintText: 'VD: 10.7769',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                TextField(
                  controller: lngCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Kinh độ (lng)',
                    hintText: 'VD: 106.7009',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lưu')),
          ],
        ),
      ),
    );
    if (created != true) return;

    final rid = idCtrl.text.trim();
    if (rid.isEmpty || nameCtrl.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thiếu id hoặc tên')),
        );
      }
      return;
    }

    final latStr = latCtrl.text.trim();
    final lngStr = lngCtrl.text.trim();
    if (latStr.isNotEmpty != lngStr.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nhập đủ vĩ độ và kinh độ, hoặc để cả hai trống.')),
        );
      }
      return;
    }

    try {
      final h = await AuthStore.authHeaders(jsonContent: true);
      double? la;
      double? lo;
      if (latStr.isNotEmpty) {
        la = double.tryParse(latStr);
        lo = double.tryParse(lngStr);
      }
      final body = <String, dynamic>{
        'id': rid,
        'name': nameCtrl.text.trim(),
        'description': existing?['description']?.toString() ?? '',
        'address': existing?['address']?.toString() ?? '',
        'openingHours': existing?['openingHours']?.toString() ?? '08:00-22:00',
        'type1': t1Ctrl.text.trim(),
        'type2': t2Ctrl.text.trim(),
        'image': pickedBase64 ?? imgCtrl.text.trim(),
        'imageUrl': pickedBase64 ?? imgCtrl.text.trim(),
        'distance_km': 0,
        'lat': la ?? 0.0,
        'lng': lo ?? 0.0,
        'latitude': la ?? 0.0,
        'longitude': lo ?? 0.0,
        'isActive': true,
      };
      if (existing == null) {
        body['rating'] = 4.8;
        body['reviewCount'] = 0;
        body['review_count'] = 0;
      } else {
        body['rating'] = existing['rating'] ?? 4.8;
        body['reviewCount'] = existing['reviewCount'] ?? existing['review_count'] ?? 0;
        body['review_count'] = existing['review_count'] ?? existing['reviewCount'] ?? 0;
      }
      http.Response res;
      if (existing == null) {
        res = await http.post(
          Uri.parse(Globs.adminRestaurantsUrl),
          headers: h,
          body: jsonEncode(body),
        );
      } else {
        res = await http.put(
          Uri.parse(Globs.adminRestaurantUrl(rid)),
          headers: h,
          body: jsonEncode(body),
        );
      }
      if (!mounted) return;
      if (res.statusCode != 200 && res.statusCode != 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Globs.apiErrorMessage(res.body))),
        );
        return;
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _rows.where((r) {
      final name = (r['name'] ?? '').toString().toLowerCase();
      final id = (r['id'] ?? '').toString().toLowerCase();
      final t1 = (r['type1'] ?? '').toString().toLowerCase();
      final t2 = (r['type2'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || id.contains(query) || t1.contains(query) || t2.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      appBar: AppBar(
        title: const Text('Nhà hàng'),
        backgroundColor: Colors.white,
        foregroundColor: TColor.primaryText,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _editOrCreate(null),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _err != null
              ? Center(child: Text(_err!))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: TextField(
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm nhà hàng...',
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.grey),
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: TColor.primary, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final r = filtered[i] as Map<String, dynamic>;
                            final id = r['id']?.toString() ?? '';
                            final img = r['imageUrl']?.toString() ?? r['image']?.toString() ?? '';
                            final tags = RestaurantModel.formatTypeTagsDisplay(
                              r['type1']?.toString(),
                              r['type2']?.toString(),
                            );
                            final subtitle = tags.isEmpty ? id : '$id\n$tags';
                            return Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              child: ListTile(
                                onTap: () {
                                  Navigator.push<void>(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) => AdminMenuItemsView(
                                        restaurantId: id,
                                        restaurantName: r['name']?.toString(),
                                      ),
                                    ),
                                  );
                                },
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 56,
                                    height: 56,
                                    child: SmartImage(
                                      img.trim().isNotEmpty
                                          ? img.trim()
                                          : 'https://picsum.photos/seed/${id}/200/200',
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const ColoredBox(
                                        color: Color(0xffeeeeee),
                                        child: Icon(Icons.store),
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  r['name']?.toString() ?? '',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: TColor.primaryText,
                                  ),
                                ),
                                subtitle: Text(
                                  subtitle,
                                  style: TextStyle(color: TColor.secondaryText, fontSize: 12),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined),
                                      onPressed: () => _editOrCreate(Map<String, dynamic>.from(r)),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete_outline, color: TColor.primary),
                                      onPressed: () => _delete(id),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
