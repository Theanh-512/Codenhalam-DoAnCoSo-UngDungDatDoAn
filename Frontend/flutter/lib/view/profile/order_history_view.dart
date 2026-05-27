import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:flutter_food_app/common/auth_store.dart';
import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter_food_app/common/globs.dart';
import 'package:flutter_food_app/model/cart_item_model.dart';
import 'package:flutter_food_app/model/menu_item_model.dart';
import 'package:flutter_food_app/view/cart/cart_view.dart';

// ── Mock Data: chỉ hiển thị cho khách chưa đăng nhập (showcase UI). ───────────
// Khi đã đăng nhập + chưa có đơn nào → màn empty, KHÔNG fallback mock.
final List<Map<String, dynamic>> _guestPreviewOrders = [
  {
    'id': 'DEMO-001',
    'orderDate':
        DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
    'totalAmount': 185000.0,
    'status': 'Completed',
    'paymentMethod': 'cod',
    'restaurantName': 'Quán Phở Thìn (mẫu)',
    'deliveryAddress': '123 Lê Lợi, Quận 1, TP.HCM',
    'receiverName': 'Khách chưa đăng nhập',
    'orderItems': [
      {
        'name': 'Phở Bò Tái Lăn',
        'quantity': 1,
        'unitPrice': 70000.0,
        'lineTotal': 70000.0
      },
      {
        'name': 'Phở Bò Chín',
        'quantity': 1,
        'unitPrice': 65000.0,
        'lineTotal': 65000.0
      },
      {
        'name': 'Trà đá',
        'quantity': 2,
        'unitPrice': 25000.0,
        'lineTotal': 50000.0
      },
    ],
  },
  {
    'id': 'DEMO-002',
    'orderDate': DateTime.now()
        .subtract(const Duration(days: 1, hours: 5))
        .toIso8601String(),
    'totalAmount': 320000.0,
    'status': 'Completed',
    'paymentMethod': 'ewallet',
    'restaurantName': 'Pizza House Sài Gòn (mẫu)',
    'deliveryAddress': 'Nhận tại quán: Pizza House Sài Gòn (mẫu)',
    'receiverName': 'Khách chưa đăng nhập',
    'orderItems': [
      {
        'name': 'Pizza Half-Half',
        'quantity': 1,
        'unitPrice': 250000.0,
        'lineTotal': 250000.0
      },
      {
        'name': 'Mì Ý Cua',
        'quantity': 1,
        'unitPrice': 70000.0,
        'lineTotal': 70000.0
      },
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
  bool _isGuestPreview = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _isGuestPreview = false;
    });
    try {
      final headers = await AuthStore.authHeaders(jsonContent: false);
      if (!headers.containsKey('Authorization')) {
        // Khách: hiện sample để showcase UI (đính rõ "mẫu").
        await Future.delayed(const Duration(milliseconds: 400));
        if (!mounted) return;
        setState(() {
          _orders = _guestPreviewOrders;
          _isGuestPreview = true;
          _loading = false;
        });
        return;
      }

      final res = await http
          .get(Uri.parse(Globs.myOrdersUrl), headers: headers)
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        setState(() {
          _orders = list;
          _loading = false;
        });
      } else {
        setState(() {
          _orders = [];
          _loading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                Globs.apiErrorMessage(
                  res.body,
                  fallback:
                      'Không tải được lịch sử đơn (HTTP ${res.statusCode})',
                ),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _orders = [];
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi kết nối: $e')),
      );
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

  /// Trả về key chuẩn hoá cho status (Pending/Confirmed/.../delivered).
  /// Chấp nhận cả PascalCase backend lẫn lowercase legacy.
  String _statusKey(String? raw) {
    final s = (raw ?? '').toLowerCase();
    if (s.isEmpty) return 'pending';
    switch (s) {
      case 'pending':
        return 'pending';
      case 'confirmed':
      case 'preparing':
        return 'processing';
      case 'delivering':
      case 'processing':
        return 'delivering';
      case 'completed':
      case 'delivered':
        return 'delivered';
      case 'cancelled':
        return 'cancelled';
      default:
        return 'pending';
    }
  }

  Color _statusColor(String? status) {
    switch (_statusKey(status)) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blueGrey;
      case 'delivering':
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
    switch (_statusKey(status)) {
      case 'pending':
        return 'Chờ xác nhận';
      case 'processing':
        return 'Đang chuẩn bị';
      case 'delivering':
        return 'Đang giao';
      case 'delivered':
        return '✓ Hoàn tất';
      case 'cancelled':
        return 'Đã huỷ';
      default:
        return 'Chờ xử lý';
    }
  }

  /// Order được tạo ở chế độ Nhận tại quán nếu address bắt đầu bằng prefix
  /// mà CartView đã chèn vào lúc thanh toán.
  bool _isPickupOrder(Map<String, dynamic> o) {
    final addr = (o['deliveryAddress'] ?? '').toString();
    return addr.startsWith('Nhận tại quán');
  }

  Future<void> _handleReorder(Map<String, dynamic> o) async {
    final isGuest = _isGuestPreview;
    if (isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng nhập để dùng "Đặt lại".')),
      );
      return;
    }

    final restaurantId = (o['restaurantId'] ?? '').toString();
    final restaurantName = (o['restaurantName'] ?? '').toString();
    final rawItems = o['orderItems'];
    if (rawItems is! List || rawItems.isEmpty || restaurantId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đơn này không có dữ liệu để đặt lại.')),
      );
      return;
    }

    // Tải danh sách món còn bán của nhà hàng để build MenuItemModel chuẩn
    // (cart cần price + imageUrl + tên đầy đủ). Nếu FoodItemId của order
    // không còn trong menu hiện tại (món đã ẩn / xoá) → bỏ qua món đó.
    final menu = await MenuItemModel.fetchByRestaurant(restaurantId);
    if (!mounted) return;
    if (menu.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tải được thực đơn nhà hàng.')),
      );
      return;
    }

    final cart = CartManager();
    cart.clear();

    int added = 0;
    int skipped = 0;
    for (final raw in rawItems) {
      if (raw is! Map) continue;
      final foodItemId = (raw['foodItemId'] ?? '').toString();
      final qty = (raw['quantity'] as num?)?.toInt() ?? 1;
      MenuItemModel? match;
      for (final m in menu) {
        if (m.id == foodItemId) {
          match = m;
          break;
        }
      }
      if (match == null) {
        skipped++;
        continue;
      }
      cart.addItem(match, restaurantId, restaurantName, quantity: qty);
      added++;
    }

    if (!mounted) return;
    if (added == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tất cả món trong đơn đã ngừng bán.'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(skipped == 0
            ? 'Đã thêm $added món vào giỏ.'
            : 'Đã thêm $added món (bỏ qua $skipped món đã ngừng bán).'),
      ),
    );
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CartView()),
    );
  }

  Future<void> _handleRate(Map<String, dynamic> o) async {
    if (_isGuestPreview) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng nhập để gửi đánh giá.')),
      );
      return;
    }

    final restaurantId = (o['restaurantId'] is num)
        ? (o['restaurantId'] as num).toInt()
        : int.tryParse(o['restaurantId']?.toString() ?? '') ?? 0;
    if (restaurantId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đơn này thiếu mã nhà hàng.')),
      );
      return;
    }
    final restaurantName = (o['restaurantName'] ?? 'Nhà hàng').toString();
    final orderId = (o['id'] is num) ? (o['id'] as num).toInt() : null;

    int rating = 5;
    final controller = TextEditingController();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                'Đánh giá $restaurantName',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final star = i + 1;
                      return IconButton(
                        onPressed: () => setLocal(() => rating = star),
                        icon: Icon(
                          star <= rating ? Icons.star_rounded : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 32,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Chia sẻ cảm nhận (tuỳ chọn)…',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Huỷ'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColor.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Gửi'),
                ),
              ],
            );
          },
        );
      },
    );

    if (submitted != true || !mounted) return;

    try {
      final headers = await AuthStore.authHeaders(jsonContent: true);
      final body = jsonEncode({
        'restaurantId': restaurantId,
        if (orderId != null) 'orderId': orderId,
        'rating': rating,
        'comment': controller.text.trim(),
      });
      final res = await http
          .post(Uri.parse('${Globs.baseUrl}/api/Reviews'),
              headers: headers, body: body)
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      if (res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cảm ơn đánh giá của bạn! 🎉')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Globs.apiErrorMessage(res.body,
                fallback: 'Gửi đánh giá thất bại (${res.statusCode})')),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi kết nối: $e')),
      );
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
                  ? ListView(
                      // Cần ListView (kể cả empty) để RefreshIndicator hoạt động.
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.7,
                          child: _buildEmpty(),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
                      itemCount:
                          _orders.length + (_isGuestPreview ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (_isGuestPreview && i == 0) {
                          return _buildGuestBanner();
                        }
                        final idx = _isGuestPreview ? i - 1 : i;
                        final o = Map<String, dynamic>.from(_orders[idx] as Map);
                        return _buildOrderCard(o, df);
                      },
                    ),
            ),
    );
  }

  Widget _buildGuestBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              color: Colors.amber.shade800, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Bạn đang xem dữ liệu mẫu. Đăng nhập để xem đơn hàng thật của bạn.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.amber.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> o, DateFormat df) {
    final id = o['id']?.toString() ?? '?';
    final createdRaw = o['orderDate'];
    final created =
        createdRaw != null ? DateTime.tryParse(createdRaw.toString()) : null;
    final total = (o['totalAmount'] as num?)?.toDouble() ?? 0;
    final rest = (o['restaurantName'] ?? '').toString();
    final status = o['status']?.toString();
    final isPickup = _isPickupOrder(o);
    final rawItems = o['orderItems'];
    final itemList = rawItems is List ? rawItems : [];

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
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (isPickup ? Colors.deepPurple : TColor.primary)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPickup
                  ? Icons.store_mall_directory_rounded
                  : Icons.delivery_dining_rounded,
              color: isPickup ? Colors.deepPurple : TColor.primary,
              size: 22,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  rest.isNotEmpty ? rest : 'Đơn #$id',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: TColor.primaryText,
                      fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor(status).withValues(alpha: 0.12),
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
              Row(
                children: [
                  if (isPickup) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'NHẬN TẠI QUÁN',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      created != null ? df.format(created.toLocal()) : '',
                      style: TextStyle(
                          fontSize: 12, color: TColor.secondaryText),
                    ),
                  ),
                ],
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Món đã đặt',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: TColor.primaryText,
                          fontSize: 13)),
                  const SizedBox(height: 8),
                  ...itemList.map((it) {
                    final m = it is Map
                        ? Map<String, dynamic>.from(it)
                        : <String, dynamic>{};
                    final lineTotal =
                        (m['lineTotal'] as num?)?.toDouble() ??
                            (((m['unitPrice'] as num?)?.toDouble() ?? 0) *
                                ((m['quantity'] as num?)?.toInt() ?? 0));
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
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
                              '${m['name'] ?? '(món)'} × ${m['quantity'] ?? 0}',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: TColor.primaryText),
                            ),
                          ),
                          Text(
                            CartManager.formatPrice(lineTotal),
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
                  Row(
                    children: [
                      Icon(_payIcon(o['paymentMethod']?.toString()),
                          size: 16, color: TColor.secondaryText),
                      const SizedBox(width: 6),
                      Text(
                        _payLabel(o['paymentMethod']?.toString()),
                        style: TextStyle(
                            fontSize: 12, color: TColor.secondaryText),
                      ),
                      const Spacer(),
                      Text('Mã: #$id',
                          style: TextStyle(
                              fontSize: 11, color: TColor.placeholder)),
                    ],
                  ),
                  if (o['deliveryAddress'] != null &&
                      o['deliveryAddress'].toString().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isPickup
                              ? Icons.storefront_outlined
                              : Icons.location_on_outlined,
                          size: 16,
                          color: TColor.secondaryText,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            o['deliveryAddress'].toString(),
                            style: TextStyle(
                                fontSize: 12,
                                color: TColor.secondaryText),
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
                    onPressed: () => _handleReorder(o),
                    icon: Icon(Icons.refresh_rounded,
                        size: 16, color: TColor.primary),
                    label: Text('Đặt lại',
                        style: TextStyle(
                            color: TColor.primary,
                            fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: TColor.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleRate(o),
                    icon: const Icon(Icons.star_rounded,
                        size: 16, color: Colors.white),
                    label: const Text('Đánh giá',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TColor.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
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
