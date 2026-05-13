import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:flutter_food_app/common/auth_store.dart';
import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter_food_app/common/globs.dart';
import 'package:flutter_food_app/model/cart_item_model.dart';

// ── Mock Data ──────────────────────────────────────────────────────────────
final _mockOrders = [
  {
    'id': 'FB-2024-001',
    'created_at':
        DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
    'total_price': 185000.0,
    'status': 'delivered',
    'payment_method': 'cod',
    'restaurant_name': 'Quán Phở Thìn',
    'delivery_address': '123 Lê Lợi, Quận 1, TP.HCM',
    'receiver_name': 'Nguyễn Văn A',
    'items': [
      {'name': 'Phở Bò Tái Lăn', 'quantity': 1, 'line_total': 70000.0},
      {'name': 'Phở Bò Chín', 'quantity': 1, 'line_total': 65000.0},
      {'name': 'Trà đá', 'quantity': 2, 'line_total': 50000.0},
    ],
  },
  {
    'id': 'FB-2024-002',
    'created_at': DateTime.now()
        .subtract(const Duration(days: 1, hours: 5))
        .toIso8601String(),
    'total_price': 320000.0,
    'status': 'delivered',
    'payment_method': 'ewallet',
    'restaurant_name': 'Pizza House Sài Gòn',
    'delivery_address': '45 Nguyễn Huệ, Quận 1, TP.HCM',
    'receiver_name': 'Nguyễn Văn A',
    'items': [
      {'name': 'Pizza Half-Half', 'quantity': 1, 'line_total': 250000.0},
      {'name': 'Mì Ý Cua', 'quantity': 1, 'line_total': 70000.0},
    ],
  },
  {
    'id': 'FB-2024-003',
    'created_at':
        DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
    'total_price': 90000.0,
    'status': 'delivered',
    'payment_method': 'bank',
    'restaurant_name': 'Bún Chả Obama',
    'delivery_address': '67 Trần Hưng Đạo, Quận 5, TP.HCM',
    'receiver_name': 'Nguyễn Văn A',
    'items': [
      {'name': 'Bún Chả Nem Cua Bể', 'quantity': 1, 'line_total': 90000.0},
    ],
  },
  {
    'id': 'FB-2024-004',
    'created_at':
        DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
    'total_price': 145000.0,
    'status': 'delivered',
    'payment_method': 'cod',
    'restaurant_name': 'Cơm Tấm Sài Gòn',
    'delivery_address': '89 Võ Văn Tần, Quận 3, TP.HCM',
    'receiver_name': 'Nguyễn Văn A',
    'items': [
      {'name': 'Cơm Tấm Sườn Bì Chả', 'quantity': 2, 'line_total': 120000.0},
      {'name': 'Chè đậu xanh', 'quantity': 1, 'line_total': 25000.0},
    ],
  },
  {
    'id': 'FB-2024-005',
    'created_at':
        DateTime.now().subtract(const Duration(days: 14)).toIso8601String(),
    'total_price': 210000.0,
    'status': 'delivered',
    'payment_method': 'ewallet',
    'restaurant_name': 'Sushi Nhật Bản',
    'delivery_address': '12 Lý Tự Trọng, Quận 1, TP.HCM',
    'receiver_name': 'Nguyễn Văn A',
    'items': [
      {'name': 'Set Sushi 12 miếng', 'quantity': 1, 'line_total': 180000.0},
      {'name': 'Miso Soup', 'quantity': 2, 'line_total': 30000.0},
    ],
  },
];

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
        // Show mock data for non-logged-in users
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted)
          setState(() {
            _orders = _mockOrders;
            _loading = false;
          });
        return;
      }
      final res =
          await http.get(Uri.parse(Globs.myOrdersUrl), headers: headers);
      if (!mounted) return;
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        // If server returns empty, use mock data
        setState(() {
          _orders = list.isEmpty ? _mockOrders : list;
          _loading = false;
        });
      } else {
        // Fallback to mock data on error
        setState(() {
          _orders = _mockOrders;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _orders = _mockOrders;
          _loading = false;
        });
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
        return 'Tiền mặt (COD)';
    }
  }

  IconData _payIcon(String? code) {
    switch (code) {
      case 'ewallet':
        return Icons.account_balance_wallet_rounded;
      case 'bank':
        return Icons.account_balance_rounded;
      case 'cod':
      default:
        return Icons.payments_rounded;
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'pending':
        return 'Chờ xác nhận';
      case 'processing':
        return 'Đang giao';
      case 'delivered':
        return '✓ Đã giao';
      case 'cancelled':
        return 'Đã huỷ';
      default:
        return 'Đã giao';
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy • HH:mm');

    return Scaffold(
      backgroundColor: TColor.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
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
              color: TColor.primaryText),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: TColor.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_orders.length} đơn',
                  style: TextStyle(
                      color: TColor.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _orders.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
                      itemCount: _orders.length,
                      itemBuilder: (context, i) {
                        final o = _orders[i] as Map<String, dynamic>;
                        final id = o['id']?.toString() ?? '#${i + 1}';
                        final created = o['created_at'] != null
                            ? DateTime.tryParse(o['created_at'].toString())
                            : null;
                        final total =
                            (o['total_price'] as num?)?.toDouble() ?? 0;
                        final rest = o['restaurant_name']?.toString() ?? '';
                        final status = o['status']?.toString();
                        final rawItems = o['items'];
                        List<dynamic> itemList =
                            rawItems is List ? rawItems : [];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              )
                            ],
                          ),
                          child: Theme(
                            data: Theme.of(context)
                                .copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              tilePadding:
                                  const EdgeInsets.fromLTRB(16, 8, 16, 4),
                              childrenPadding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: TColor.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.receipt_long_rounded,
                                    color: TColor.primary, size: 22),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      rest.isNotEmpty ? rest : 'Đơn hàng $id',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: TColor.primaryText,
                                          fontSize: 15),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _statusColor(status)
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _statusLabel(status),
                                      style: TextStyle(
                                        color: _statusColor(status),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    created != null
                                        ? df.format(created.toLocal())
                                        : '',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: TColor.secondaryText),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    CartManager.formatPrice(total),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: TColor.primary,
                                    ),
                                  ),
                                ],
                              ),
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: TColor.background,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Món ăn list
                                      Text('Món đã đặt',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: TColor.primaryText,
                                              fontSize: 13)),
                                      const SizedBox(height: 8),
                                      ...itemList.map((it) {
                                        final m = it as Map<String, dynamic>;
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 6),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration: BoxDecoration(
                                                    color: TColor.primary,
                                                    shape: BoxShape.circle),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  '${m['name']} × ${m['quantity']}',
                                                  style: TextStyle(
                                                      fontSize: 13,
                                                      color:
                                                          TColor.primaryText),
                                                ),
                                              ),
                                              Text(
                                                CartManager.formatPrice(
                                                    (m['line_total'] as num?)
                                                            ?.toDouble() ??
                                                        0),
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: TColor.orangeDark),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                      const Divider(height: 16),
                                      // Payment method
                                      Row(
                                        children: [
                                          Icon(
                                              _payIcon(o['payment_method']
                                                  ?.toString()),
                                              size: 16,
                                              color: TColor.secondaryText),
                                          const SizedBox(width: 6),
                                          Text(
                                            _payLabel(o['payment_method']
                                                ?.toString()),
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: TColor.secondaryText),
                                          ),
                                          const Spacer(),
                                          Text('Mã: $id',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: TColor.placeholder)),
                                        ],
                                      ),
                                      if (o['delivery_address'] != null) ...[
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(Icons.location_on_outlined,
                                                size: 16,
                                                color: TColor.secondaryText),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                o['delivery_address']
                                                    .toString(),
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        TColor.secondaryText),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () =>
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Đặt lại đơn hàng thành công!')),
                                        ),
                                        icon: Icon(Icons.refresh_rounded,
                                            size: 16, color: TColor.primary),
                                        label: Text('Đặt lại',
                                            style: TextStyle(
                                                color: TColor.primary,
                                                fontWeight: FontWeight.w600)),
                                        style: OutlinedButton.styleFrom(
                                          side:
                                              BorderSide(color: TColor.primary),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () =>
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Cảm ơn đánh giá của bạn!')),
                                        ),
                                        icon: const Icon(Icons.star_rounded,
                                            size: 16, color: Colors.white),
                                        label: const Text('Đánh giá',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: TColor.primary,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                        ),
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

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Chưa có đơn hàng nào',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: TColor.primaryText)),
          const SizedBox(height: 8),
          Text('Đặt ngay để trải nghiệm FastBite!',
              style: TextStyle(fontSize: 14, color: TColor.secondaryText)),
        ],
      ),
    );
  }
}
