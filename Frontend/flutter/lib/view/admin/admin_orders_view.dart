import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:flutter_food_app/common/auth_store.dart';
import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter_food_app/common/globs.dart';

const _statuses = [
  'pending',
  'confirmed',
  'preparing',
  'delivering',
  'completed',
  'cancelled',
];

class AdminOrdersView extends StatefulWidget {
  const AdminOrdersView({super.key});

  @override
  State<AdminOrdersView> createState() => _AdminOrdersViewState();
}

String? _coordString(dynamic v) {
  if (v == null) return null;
  final n = v is num ? v.toDouble() : double.tryParse('$v');
  if (n == null || n.isNaN) return null;
  return n.toStringAsFixed(6);
}

class _AdminOrdersViewState extends State<AdminOrdersView> {
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
      final res = await http.get(Uri.parse(Globs.adminOrdersUrl), headers: h);
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

  Future<void> _patchStatus(int id, String status) async {
    try {
      final h = await AuthStore.authHeaders(jsonContent: true);
      final res = await http.patch(
        Uri.parse(Globs.adminOrderPatchUrl(id)),
        headers: h,
        body: jsonEncode({'status': status}),
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      appBar: AppBar(
        title: const Text('Đơn hàng'),
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
              ? Center(child: Text(_err!, textAlign: TextAlign.center))
              : _rows.isEmpty
                  ? const Center(child: Text('Chưa có đơn'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _rows.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final o = _rows[i] as Map<String, dynamic>;
                          final items = o['items'];
                          final lines = <String>[];
                          if (items is List) {
                            for (final it in items) {
                              if (it is Map) {
                                lines.add(
                                  '${it['name'] ?? ''} × ${it['quantity'] ?? ''}',
                                );
                              }
                            }
                          }
                          final created = o['created_at'];
                          DateTime? dt;
                          if (created is String) {
                            dt = DateTime.tryParse(created);
                          }
                          final status = (o['status'] ?? '').toString();
                          final rawOrderId = o['id'];
                          final orderId = rawOrderId is int
                              ? rawOrderId
                              : int.tryParse('$rawOrderId') ?? 0;

                          return Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Đơn #$orderId',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: TColor.primaryText,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        NumberFormat.currency(
                                                locale: 'vi_VN', symbol: 'đ')
                                            .format((o['total_price'] is num)
                                                ? o['total_price'] as num
                                                : double.tryParse(
                                                        '${o['total_price']}') ??
                                                    0),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: TColor.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (dt != null)
                                    Text(
                                      df.format(dt.toLocal()),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: TColor.secondaryText,
                                      ),
                                    ),
                                  const SizedBox(height: 6),
                                  Text(
                                    o['restaurant_name']?.toString() ?? '',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: TColor.primaryText,
                                    ),
                                  ),
                                  Text(
                                    '${o['receiver_name'] ?? ''} · ${o['receiver_phone'] ?? ''}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: TColor.secondaryText,
                                    ),
                                  ),
                                  if ((o['delivery_address'] ?? '')
                                      .toString()
                                      .trim()
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          size: 16,
                                          color: TColor.primary,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            o['delivery_address']!.toString(),
                                            style: TextStyle(
                                              fontSize: 13,
                                              height: 1.35,
                                              color: TColor.primaryText,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  Builder(
                                    builder: (context) {
                                      final latStr =
                                          _coordString(o['delivery_lat']);
                                      final lngStr =
                                          _coordString(o['delivery_lng']);
                                      if (latStr == null || lngStr == null) {
                                        return const SizedBox.shrink();
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              Icons.my_location_outlined,
                                              size: 16,
                                              color: TColor.secondaryText,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                'Tọa độ: $latStr, $lngStr',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: TColor.secondaryText,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  if (lines.isNotEmpty)
                                    Text(
                                      lines.join('\n'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: TColor.secondaryText,
                                      ),
                                    ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Text(
                                        'Trạng thái:',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: TColor.secondaryText,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: DropdownButton<String>(
                                          isExpanded: true,
                                          value: _statuses.contains(status)
                                              ? status
                                              : 'pending',
                                          items: _statuses
                                              .map(
                                                (s) => DropdownMenuItem(
                                                  value: s,
                                                  child: Text(s),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (v) {
                                            if (v != null && orderId > 0) {
                                              _patchStatus(orderId, v);
                                            }
                                          },
                                        ),
                                      ),
                                    ],
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
