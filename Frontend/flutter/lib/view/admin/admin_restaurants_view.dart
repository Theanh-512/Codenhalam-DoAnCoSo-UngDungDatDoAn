import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
    final imgCtrl = TextEditingController(text: existing?['image']?.toString() ?? '');
    final latCtrl = TextEditingController(
      text: existing != null && existing['lat'] != null ? '${existing['lat']}' : '',
    );
    final lngCtrl = TextEditingController(
      text: existing != null && existing['lng'] != null ? '${existing['lng']}' : '',
    );

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
              TextField(controller: imgCtrl, decoration: const InputDecoration(labelText: 'URL ảnh')),
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
        'type1': t1Ctrl.text.trim(),
        'type2': t2Ctrl.text.trim(),
        'image': imgCtrl.text.trim(),
        'distance_km': 0,
        'lat': la,
        'lng': lo,
      };
      if (existing == null) {
        body['rating'] = '4.8';
        body['review_count'] = '0';
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
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _rows.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final r = _rows[i] as Map<String, dynamic>;
                      final id = r['id']?.toString() ?? '';
                      final img = r['image']?.toString() ?? '';
                      final tags = RestaurantModel.formatTypeTagsDisplay(
                        r['type1']?.toString(),
                        r['type2']?.toString(),
                      );
                      final subtitle = tags.isEmpty ? id : '$id\n$tags';
                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
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
    );
  }
}
