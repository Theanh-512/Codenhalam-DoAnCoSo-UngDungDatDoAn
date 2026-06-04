import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_food_app/common/auth_store.dart';
import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter_food_app/common/globs.dart';
import 'package:flutter_food_app/common/smart_image.dart';

class AdminMenuItemsView extends StatefulWidget {
  final String? restaurantId;
  final String? restaurantName;

  const AdminMenuItemsView({super.key, this.restaurantId, this.restaurantName});

  @override
  State<AdminMenuItemsView> createState() => _AdminMenuItemsViewState();
}

class _AdminMenuItemsViewState extends State<AdminMenuItemsView> {
  List<dynamic> _restaurants = [];
  List<dynamic> _items = [];
  String? _filterRestaurantId;
  bool _loading = true;
  String? _err;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _filterRestaurantId = widget.restaurantId;
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
      
      // If we don't have a passed restaurantId, pick the first one
      if (_filterRestaurantId == null && _restaurants.isNotEmpty) {
        _filterRestaurantId = (_restaurants.first as Map)['id']?.toString();
      }
      
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
          ? '${Globs.adminItemsUrl}?restaurantId=${Uri.encodeQueryComponent(_filterRestaurantId!)}'
          : Globs.adminItemsUrl;
      final h = await AuthStore.authHeaders(jsonContent: false);
      final res = await http.get(Uri.parse(url), headers: h);
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
      if (res.statusCode != 200 && res.statusCode != 204) {
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
    final idCtrl = TextEditingController(text: existing?['id']?.toString() ?? '0');
    final ridCtrl = TextEditingController(
      text: existing?['restaurantId']?.toString() ?? _filterRestaurantId ?? '',
    );
    final nameCtrl = TextEditingController(text: existing?['name']?.toString() ?? '');
    final descCtrl = TextEditingController(text: existing?['description']?.toString() ?? '');
    final priceCtrl = TextEditingController(text: existing?['price']?.toString() ?? '0');
    final catIdCtrl = TextEditingController(text: existing?['categoryId']?.toString() ?? '1');
    
    final initialImg = existing?['imageUrl']?.toString() ?? '';
    String? pickedBase64;
    final imgCtrl = TextEditingController();
    if (initialImg.startsWith('data:image')) {
      pickedBase64 = initialImg;
      imgCtrl.text = '[Ảnh thiết bị]';
    } else {
      imgCtrl.text = initialImg;
    }
    
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
                  decoration: const InputDecoration(labelText: 'ID (Tự động nếu là 0)'),
                  enabled: false,
                ),
                TextField(
                  controller: ridCtrl,
                  decoration: const InputDecoration(labelText: 'ID nhà hàng'),
                  enabled: false,
                ),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên món')),
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
                TextField(
                  controller: catIdCtrl, 
                  decoration: const InputDecoration(labelText: 'ID danh mục (vd: 1-Phở, 2-Pizza)'),
                  keyboardType: TextInputType.number,
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

    final rid = int.tryParse(ridCtrl.text) ?? 0;
    if (nameCtrl.text.trim().isEmpty || rid == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập tên món và ID nhà hàng hợp lệ')),
        );
      }
      return;
    }

    try {
      final body = {
        'id': int.tryParse(idCtrl.text) ?? 0,
        'restaurantId': rid,
        'categoryId': int.tryParse(catIdCtrl.text) ?? 1,
        'name': nameCtrl.text.trim(),
        'description': descCtrl.text.trim(),
        'price': double.tryParse(priceCtrl.text.trim()) ?? 0,
        'imageUrl': pickedBase64 ?? imgCtrl.text.trim(),
        'rating': existing?['rating'] ?? 5.0,
        'isAvailable': true,
      };
      
      http.Response res;
      final h = await AuthStore.authHeaders(jsonContent: true);
      if (existing == null) {
        res = await http.post(
          Uri.parse(Globs.adminItemsUrl),
          headers: h,
          body: jsonEncode(body),
        );
      } else {
        res = await http.put(
          Uri.parse(Globs.adminItemUrl(idCtrl.text)),
          headers: h,
          body: jsonEncode(body),
        );
      }
      
      if (!mounted) return;
      if (res.statusCode != 200 && res.statusCode != 201 && res.statusCode != 204) {
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
    final filtered = _items.where((item) {
      final name = (item['name'] ?? '').toString().toLowerCase();
      final desc = (item['description'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || desc.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      appBar: AppBar(
        title: Text(widget.restaurantName != null ? 'Menu: ${widget.restaurantName}' : 'Món ăn'),
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
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Chọn nhà hàng để quản lý thực đơn',
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
                            child: Text(
                              m['name']?.toString() ?? id,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: TextField(
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm món ăn trong menu...',
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
                        onRefresh: _loadItems,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final r = filtered[i] as Map<String, dynamic>;
                            final id = r['id']?.toString() ?? '';
                            final img = r['imageUrl']?.toString() ?? '';
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
                                      errorBuilder: (_, __, ___) => const Center(
                                        child: Icon(Icons.restaurant, size: 24),
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
                                  '${r['price']} đ · Danh mục ID: ${r['categoryId'] ?? ''}',
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
