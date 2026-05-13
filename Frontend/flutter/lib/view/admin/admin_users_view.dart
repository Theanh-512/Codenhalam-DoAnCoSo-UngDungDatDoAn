import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_food_app/common/auth_store.dart';
import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter_food_app/common/globs.dart';

class AdminUsersView extends StatefulWidget {
  const AdminUsersView({super.key});

  @override
  State<AdminUsersView> createState() => _AdminUsersViewState();
}

class _AdminUsersViewState extends State<AdminUsersView> {
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
      final res = await http.get(Uri.parse(Globs.adminUsersUrl), headers: h);
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

  Future<void> _edit(Map<String, dynamic> u) async {
    final id = u['id'];
    final nameCtrl = TextEditingController(text: u['fullname']?.toString() ?? '');
    final phoneCtrl = TextEditingController(text: u['phone']?.toString() ?? '');
    final addrCtrl = TextEditingController(text: u['address']?.toString() ?? '');
    var role = (u['role'] ?? 'user').toString().toLowerCase();
    if (role != 'admin') role = 'user';
    var active = u['is_active'] != false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text('Người dùng #${id ?? ''}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  u['email']?.toString() ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: TColor.primaryText,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Họ tên'),
                ),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'SĐT'),
                ),
                TextField(
                  controller: addrCtrl,
                  decoration: const InputDecoration(labelText: 'Địa chỉ'),
                  maxLines: 2,
                ),
                DropdownButton<String>(
                  value: role,
                  isExpanded: true,
                  hint: const Text('Vai trò'),
                  items: const [
                    DropdownMenuItem(value: 'user', child: Text('Khách hàng')),
                    DropdownMenuItem(value: 'admin', child: Text('Quản trị')),
                  ],
                  onChanged: (v) => setSt(() => role = v ?? 'user'),
                ),
                SwitchListTile(
                  title: const Text('Tài khoản hoạt động'),
                  subtitle: const Text('Tắt = không đăng nhập được'),
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

    final uid = id is int ? id : int.tryParse('$id') ?? 0;
    if (uid < 1) return;

    try {
      final h = await AuthStore.authHeaders(jsonContent: true);
      final res = await http.patch(
        Uri.parse(Globs.adminUserPatchUrl(uid)),
        headers: h,
        body: jsonEncode({
          'fullname': nameCtrl.text.trim(),
          'phone': phoneCtrl.text.trim(),
          'address': addrCtrl.text.trim(),
          'role': role,
          'is_active': active,
        }),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      appBar: AppBar(
        title: const Text('Tài khoản'),
        backgroundColor: Colors.white,
        foregroundColor: TColor.primaryText,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
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
                      final u = _rows[i] as Map<String, dynamic>;
                      final email = u['email']?.toString() ?? '';
                      final role = u['role']?.toString() ?? 'user';
                      final active = u['is_active'] != false;
                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                          onTap: () => _edit(Map<String, dynamic>.from(u)),
                          title: Text(
                            email,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: TColor.primaryText,
                            ),
                          ),
                          subtitle: Text(
                            '${u['fullname'] ?? ''} · $role${active ? '' : ' · Đã khóa'}',
                            style: TextStyle(color: TColor.secondaryText, fontSize: 12),
                          ),
                          trailing: const Icon(Icons.edit_outlined),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
