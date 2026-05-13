import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_food_app/common/auth_store.dart';
import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter_food_app/common/globs.dart';
import 'package:flutter_food_app/common/smart_image.dart';

class AdminCategoriesView extends StatefulWidget {
  const AdminCategoriesView({super.key});

  @override
  State<AdminCategoriesView> createState() => _AdminCategoriesViewState();
}

class _AdminCategoriesViewState extends State<AdminCategoriesView> {
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
      final res = await http.get(Uri.parse(Globs.categoriesUrl));
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
        title: const Text('Xóa danh mục?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final h = await AuthStore.authHeaders(jsonContent: false);
      final res = await http.delete(Uri.parse(Globs.adminCategoryUrl(id)), headers: h);
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
    final imgCtrl = TextEditingController(text: existing?['image']?.toString() ?? '');
    final cntCtrl = TextEditingController(text: existing?['items_count']?.toString() ?? '0');

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Thêm danh mục' : 'Sửa danh mục'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idCtrl,
                decoration: const InputDecoration(labelText: 'ID (vd: c5)'),
                enabled: existing == null,
              ),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên')),
              TextField(controller: imgCtrl, decoration: const InputDecoration(labelText: 'URL ảnh')),
              TextField(controller: cntCtrl, decoration: const InputDecoration(labelText: 'Số món (hiển thị)')),
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

    final cid = idCtrl.text.trim();
    if (cid.isEmpty || nameCtrl.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thiếu id hoặc tên')),
        );
      }
      return;
    }

    try {
      final h = await AuthStore.authHeaders(jsonContent: true);
      final body = {
        'id': cid,
        'name': nameCtrl.text.trim(),
        'image': imgCtrl.text.trim(),
        'items_count': cntCtrl.text.trim(),
      };
      http.Response res;
      if (existing == null) {
        res = await http.post(
          Uri.parse(Globs.adminCategoriesUrl),
          headers: h,
          body: jsonEncode(body),
        );
      } else {
        res = await http.put(
          Uri.parse(Globs.adminCategoryUrl(cid)),
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
        title: const Text('Danh mục'),
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
                                    : 'https://picsum.photos/seed/cat_$id/200/200',
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const ColoredBox(
                                  color: Color(0xffeeeeee),
                                  child: Icon(Icons.category_outlined),
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
                          subtitle: Text(id, style: TextStyle(color: TColor.secondaryText, fontSize: 12)),
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
