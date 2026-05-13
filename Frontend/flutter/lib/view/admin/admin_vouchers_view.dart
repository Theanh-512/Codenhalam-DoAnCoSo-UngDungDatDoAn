import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_food_app/common/auth_store.dart';
import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter_food_app/common/globs.dart';

const _rules = ['FREESHIP', 'GIAM20K', 'MONKEY10'];

class AdminVouchersView extends StatefulWidget {
  const AdminVouchersView({super.key});

  @override
  State<AdminVouchersView> createState() => _AdminVouchersViewState();
}

class _AdminVouchersViewState extends State<AdminVouchersView> {
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
      final h = await AuthStore.authHeaders(jsonContent: false);
      final res = await http.get(Uri.parse(Globs.adminVouchersUrl), headers: h);
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

  Future<void> _delete(String code) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa voucher?'),
        content: Text('Mã: $code'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final h = await AuthStore.authHeaders(jsonContent: false);
      final res = await http.delete(
        Uri.parse(Globs.adminVoucherDetailUrl(code)),
        headers: h,
      );
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
    final codeCtrl = TextEditingController(text: existing?['code']?.toString() ?? '');
    var rule = (existing?['rule'] ?? 'FREESHIP').toString().toUpperCase();
    if (!_rules.contains(rule)) rule = 'FREESHIP';
    final titleCtrl = TextEditingController(text: existing?['title']?.toString() ?? '');
    final descCtrl = TextEditingController(text: existing?['description']?.toString() ?? '');
    var active = existing?['is_active'] != false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text(existing == null ? 'Thêm voucher' : 'Sửa voucher'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(labelText: 'Mã (VD: SUMMER50)'),
                  enabled: existing == null,
                  textCapitalization: TextCapitalization.characters,
                ),
                DropdownButton<String>(
                  value: rule,
                  isExpanded: true,
                  hint: const Text('Loại ưu đãi (logic)'),
                  items: _rules
                      .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                      .toList(),
                  onChanged: (v) => setSt(() => rule = v ?? 'FREESHIP'),
                ),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Tiêu đề hiển thị'),
                ),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Mô tả'),
                  maxLines: 2,
                ),
                SwitchListTile(
                  title: const Text('Đang bật'),
                  value: active,
                  onChanged: (v) => setSt(() => active = v),
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
    if (saved != true) return;

    final code = codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thiếu mã')),
        );
      }
      return;
    }

    try {
      final h = await AuthStore.authHeaders(jsonContent: true);
      http.Response res;
      if (existing == null) {
        res = await http.post(
          Uri.parse(Globs.adminVouchersUrl),
          headers: h,
          body: jsonEncode({
            'code': code,
            'rule': rule,
            'title': titleCtrl.text.trim(),
            'description': descCtrl.text.trim(),
            'is_active': active,
          }),
        );
      } else {
        res = await http.put(
          Uri.parse(Globs.adminVoucherDetailUrl(code)),
          headers: h,
          body: jsonEncode({
            'rule': rule,
            'title': titleCtrl.text.trim(),
            'description': descCtrl.text.trim(),
            'is_active': active,
          }),
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
        title: const Text('Voucher'),
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
                      final code = r['code']?.toString() ?? '';
                      final active = r['is_active'] == true;
                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                          title: Text(
                            code,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: TColor.primaryText,
                            ),
                          ),
                          subtitle: Text(
                            '${r['rule'] ?? ''} · ${r['title'] ?? ''}\n${r['description'] ?? ''}',
                            style: TextStyle(color: TColor.secondaryText, fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                active ? 'Bật' : 'Tắt',
                                style: TextStyle(
                                  color: active ? Colors.green : TColor.placeholder,
                                  fontSize: 12,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _editOrCreate(Map<String, dynamic>.from(r)),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline, color: TColor.primary),
                                onPressed: () => _delete(code),
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
