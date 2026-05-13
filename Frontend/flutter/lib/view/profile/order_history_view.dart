import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:flutter_food_app/common/auth_store.dart';
import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter_food_app/common/globs.dart';
import 'package:flutter_food_app/model/cart_item_model.dart';

class OrderHistoryView extends StatefulWidget {
  const OrderHistoryView({super.key});

  @override
  State<OrderHistoryView> createState() => _OrderHistoryViewState();
}

class _OrderHistoryViewState extends State<OrderHistoryView> {
  List<dynamic> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final headers = await AuthStore.authHeaders(jsonContent: false);
      if (!headers.containsKey('Authorization')) {
        setState(() {
          _loading = false;
          _error = 'not_logged_in';
        });
        return;
      }
      final res = await http.get(Uri.parse(Globs.myOrdersUrl), headers: headers);
      if (!mounted) return;
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        setState(() {
          _orders = list;
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
          _error = Globs.apiErrorMessage(res.body, fallback: 'Lỗi ${res.statusCode}');
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  String _payLabel(String? code) {
    switch (code) {
      case 'ewallet':
        return 'Ví điện tử';
      case 'bank':
        return 'Chuyển khoản';
      case 'cod':
      default:
        return 'COD';
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      backgroundColor: TColor.background,
      appBar: AppBar(
        backgroundColor: TColor.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Lịch sử đơn hàng',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: TColor.primaryText,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : _error == 'not_logged_in'
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(
                        'Đăng nhập để xem đơn đã đặt và đồng bộ với tài khoản.',
                        style: TextStyle(color: TColor.secondaryText),
                      ),
                    ],
                  )
                : _error != null
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(24),
                        children: [
                          Text(_error!, style: TextStyle(color: TColor.red)),
                          TextButton(onPressed: _load, child: const Text('Thử lại')),
                        ],
                      )
                    : _orders.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(24),
                            children: [
                              Text(
                                'Chưa có đơn nào. Đặt hàng khi đã đăng nhập để lưu vào đây.',
                                style: TextStyle(color: TColor.secondaryText),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: _orders.length,
                            itemBuilder: (context, i) {
                              final o = _orders[i] as Map<String, dynamic>;
                              final id = o['id'];
                              final created = o['created_at'] != null
                                  ? DateTime.tryParse(o['created_at'].toString())
                                  : null;
                              final total = (o['total_price'] as num?)?.toDouble() ?? 0;
                              final rest = o['restaurant_name']?.toString() ?? '';
                              final rawItems = o['items'];
                              List<dynamic> itemList = [];
                              if (rawItems is List) {
                                itemList = rawItems;
                              } else if (rawItems is String) {
                                try {
                                  final dec = jsonDecode(rawItems);
                                  if (dec is List) itemList = dec;
                                } catch (_) {}
                              }

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(color: TColor.textfield),
                                ),
                                child: ExpansionTile(
                                  tilePadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  title: Text(
                                    'Đơn #$id',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: TColor.primaryText,
                                    ),
                                  ),
                                  subtitle: Text(
                                    created != null
                                        ? df.format(created.toLocal())
                                        : '',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: TColor.secondaryText,
                                    ),
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 0, 16, 12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (rest.isNotEmpty)
                                            Text(
                                              rest,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: TColor.primaryDark,
                                              ),
                                            ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Tổng: ${CartManager.formatPrice(total)} · ${_payLabel(o['payment_method']?.toString())}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: TColor.primaryText,
                                            ),
                                          ),
                                          if (o['receiver_name'] != null ||
                                              o['receiver_phone'] != null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              '${o['receiver_name'] ?? ''} · ${o['receiver_phone'] ?? ''}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: TColor.secondaryText,
                                              ),
                                            ),
                                          ],
                                          if (o['delivery_address'] != null &&
                                              o['delivery_address']
                                                  .toString()
                                                  .isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              o['delivery_address'].toString(),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: TColor.secondaryText,
                                              ),
                                            ),
                                          ],
                                          const Divider(height: 20),
                                          Text(
                                            'Món',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: TColor.secondaryText,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          ...itemList.map((it) {
                                            final m = it as Map<String, dynamic>;
                                            final name =
                                                m['name']?.toString() ?? '';
                                            final q = m['quantity'] ?? '';
                                            final lt = (m['line_total'] as num?)
                                                    ?.toDouble() ??
                                                0;
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 4),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      '$name × $q',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color:
                                                            TColor.primaryText,
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    CartManager.formatPrice(lt),
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          TColor.orangeDark,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
      ),
    );
  }
}
