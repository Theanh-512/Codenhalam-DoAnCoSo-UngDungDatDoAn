import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_food_app/common/auth_store.dart';
import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter_food_app/common/globs.dart';
import 'package:flutter_food_app/common/smart_image.dart';

class AdminMenuItemsView extends StatefulWidget {
  const AdminMenuItemsView({super.key});

  @override
  State<AdminMenuItemsView> createState() => _AdminMenuItemsViewState();
}

class _AdminMenuItemsViewState extends State<AdminMenuItemsView> {
  List<dynamic> _restaurants = [];
  List<dynamic> _items = [];
  String? _filterRestaurantId;
  bool _loading = true;
  String? _err;

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
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
      _restaurants = list is List ? list : [];
      _filterRestaurantId ??=
          _restaurants.isNotEmpty ? (_restaurants.first as Map)['id']?.toString() : null;
      await _loadItems();
    } catch (e) {
      setState(() {
        _err = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _loadItems() async {
    try {
      final url = _filterRestaurantId != null && _filterRestaurantId!.isNotEmpty
          ? '${Globs.itemsUrl}?restaurantId=${Uri.encodeQueryComponent(_filterRestaurantId!)}'
          : Globs.itemsUrl;
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) {
        setState(() {
          _err = Globs.apiErrorMessage(res.body);
          _loading = false;
        });
        return;
      }
      final list = jsonDecode(res.body);
      setState(() {
        _items = list is List ? list : [];
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
        title: const Text('Xóa món?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final h = await AuthStore.authHeaders(jsonContent: false);
      final res = await http.delete(Uri.parse(Globs.adminItemUrl(id)), headers: h);
      if (!mounted) return;
      if (res.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Globs.apiErrorMessage(res.body))),
        );
        return;
      }
      await _loadItems();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _editOrCreate([Map<String, dynamic>? existing]) async {
    final idCtrl = TextEditingController(text: existing?['id']?.toString() ?? '');
    final ridCtrl = TextEditingController(
      text: existing?['restaurant_id']?.toString() ?? _filterRestaurantId ?? '',
    );
    final nameCtrl = TextEditingController(text: existing?['name']?.toString() ?? '');
    final descCtrl = TextEditingController(text: existing?['description']?.toString() ?? '');
    final priceCtrl = TextEditingController(text: existing?['price']?.toString() ?? '0');
    final catCtrl = TextEditingController(text: existing?['category']?.toString() ?? '');
    final emojiCtrl = TextEditingController(text: existing?['emoji']?.toString() ?? '🍽️');
    final imgCtrl = TextEditingController(text: existing?['image']?.toString() ?? '');
    var best = existing?['is_best_seller'] == true;

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text(existing == null ? 'Thêm món' : 'Sửa món'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: idCtrl,
                  decoration: const InputDecoration(labelText: 'ID món (vd: m99)'),
                  enabled: existing == null,
                ),
                TextField(
                  controller: ridCtrl,
                  decoration: const InputDecoration(labelText: 'ID nhà hàng (vd: r1)'),
                ),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên')),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Mô tả'),
                  maxLines: 2,
                ),
                TextField(
                  controller: priceCtrl,
                  decoration: const InputDecoration(labelText: 'Giá (VNĐ)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(controller: catCtrl, decoration: const InputDecoration(labelText: 'Danh mục món')),
                TextField(controller: emojiCtrl, decoration: const InputDecoration(labelText: 'Emoji')),
                TextField(controller: imgCtrl, decoration: const InputDecoration(labelText: 'URL ảnh (tuỳ chọn)')),
                CheckboxListTile(
                  title: const Text('Bán chạy'),
                  value: best,
                  onChanged: (v) => setSt(() => best = v ?? false),
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

    final mid = idCtrl.text.trim();
    final rid = ridCtrl.text.trim();
    if (mid.isEmpty || rid.isEmpty || nameCtrl.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thiếu id, nhà hàng hoặc tên')),
        );
      }
      return;
    }

    try {
      final h = await AuthStore.authHeaders(jsonContent: true);
      final body = {
        'id': mid,
        'restaurant_id': rid,
        'name': nameCtrl.text.trim(),
        'description': descCtrl.text.trim(),
        'price': double.tryParse(priceCtrl.text.trim()) ?? 0,
        'category': catCtrl.text.trim(),
        'emoji': emojiCtrl.text.trim(),
        'image': imgCtrl.text.trim(),
        'is_best_seller': best,
      };
      http.Response res;
      if (existing == null) {
        res = await http.post(
          Uri.parse(Globs.adminItemsUrl),
          headers: h,
          body: jsonEncode(body),
        );
      } else {
        res = await http.put(
          Uri.parse(Globs.adminItemUrl(mid)),
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
      await _loadItems();
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
        title: const Text('Món ăn'),
        backgroundColor: Colors.white,
        foregroundColor: TColor.primaryText,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadRestaurants),
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Lọc theo nhà hàng',
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        value: _filterRestaurantId != null &&
                                _restaurants.any(
                                  (e) => (e as Map)['id']?.toString() == _filterRestaurantId,
                                )
                            ? _filterRestaurantId
                            : null,
                        items: _restaurants.map((e) {
                          final m = e as Map<String, dynamic>;
                          final id = m['id']?.toString() ?? '';
                          return DropdownMenuItem(
                            value: id,
                            child: Text(m['name']?.toString() ?? id),
                          );
                        }).toList(),
                        onChanged: (v) {
                          setState(() {
                            _filterRestaurantId = v;
                          });
                          _loadItems();
                        },
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadItems,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final r = _items[i] as Map<String, dynamic>;
                            final id = r['id']?.toString() ?? '';
                            final img = r['image']?.toString() ?? '';
                            return Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              child: ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: SmartImage(
                                      img.trim().isNotEmpty
                                          ? img.trim()
                                          : 'https://picsum.photos/seed/$id/200/200',
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Center(
                                        child: Text(
                                          r['emoji']?.toString() ?? '🍽️',
                                          style: const TextStyle(fontSize: 22),
                                        ),
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
                                  '${r['price']} đ · ${r['category'] ?? ''}',
                                  style: TextStyle(color: TColor.secondaryText, fontSize: 12),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined),
                                      onPressed: () =>
                                          _editOrCreate(Map<String, dynamic>.from(r)),
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
