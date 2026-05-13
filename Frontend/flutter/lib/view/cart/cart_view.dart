import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_food_app/common/auth_store.dart';
import 'package:flutter_food_app/common/checkout_prefs.dart';
import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter_food_app/common/globs.dart';
import 'package:flutter_food_app/common/smart_image.dart';
import 'package:flutter_food_app/model/cart_item_model.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_food_app/view/map/map_picker_view.dart';

class CartView extends StatefulWidget {
  const CartView({super.key});

  @override
  State<CartView> createState() => _CartViewState();
}

class _CartViewState extends State<CartView> {
  final CartManager _cart = CartManager();
  final TextEditingController _receiverName = TextEditingController();
  final TextEditingController _receiverPhone = TextEditingController();
  String _deliveryAddress = "";
  LatLng? _deliveryLatLng;
  /// cod | ewallet | bank
  String _paymentMethod = 'cod';
  bool _isCheckingOut = false;

  // Voucher áp dụng cho đơn (demo: hardcode 3 mã).
  final TextEditingController _voucherCodeController = TextEditingController();
  String _appliedVoucherCode = ''; // FREESHIP | GIAM20K | MONKEY10

  @override
  void initState() {
    super.initState();
    _cart.addListener(_rebuild);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedCheckoutInfo();
      _loadVouchersFromApi();
    });
  }

  Future<void> _loadVouchersFromApi() async {
    try {
      final res = await http.get(Uri.parse(Globs.publicVouchersUrl));
      if (!mounted || res.statusCode != 200) return;
      final list = jsonDecode(res.body) as List;
      final codes = <String>{};
      final map = <String, String>{};
      for (final e in list) {
        if (e is Map) {
          final c = (e['code'] ?? '').toString().toUpperCase().trim();
          final r = (e['rule'] ?? '').toString().toUpperCase().trim();
          if (c.isEmpty) continue;
          codes.add(c);
          map[c] = r;
        }
      }
      if (codes.isEmpty) return;
      setState(() {
        _allowedVoucherCodes = codes;
        _codeToRule = map;
      });
    } catch (_) {}
  }

  Future<void> _loadSavedCheckoutInfo() async {
    final m = await CheckoutPrefs.load();
    if (!mounted) return;
    setState(() {
      _receiverName.text = (m['name'] as String?) ?? '';
      _receiverPhone.text = (m['phone'] as String?) ?? '';
      _deliveryAddress = (m['address'] as String?) ?? '';
      final lat = m['lat'] as double?;
      final lng = m['lng'] as double?;
      if (lat != null && lng != null) {
        _deliveryLatLng = LatLng(lat, lng);
      }
    });
    await _prefillFromProfileIfNeeded();
  }

  Future<void> _prefillFromProfileIfNeeded() async {
    if (_receiverName.text.trim().isNotEmpty &&
        _receiverPhone.text.trim().length >= 9) {
      return;
    }
    final token = await AuthStore.getToken();
    if (token == null || token.isEmpty) return;
    try {
      final r = await http.get(
        Uri.parse(Globs.profileUrl),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (!mounted || r.statusCode != 200) return;
      final u = jsonDecode(r.body) as Map<String, dynamic>;
      final fn = (u['fullname'] ?? '').toString().trim();
      final ph = (u['phone'] ?? '')
          .toString()
          .trim()
          .replaceAll(RegExp(r'\s+'), '');
      if (!mounted) return;
      setState(() {
        if (_receiverName.text.trim().isEmpty && fn.isNotEmpty) {
          _receiverName.text = fn;
        }
        if (_receiverPhone.text.trim().length < 9 && ph.length >= 9) {
          _receiverPhone.text = ph;
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _receiverName.dispose();
    _receiverPhone.dispose();
    _voucherCodeController.dispose();
    _cart.removeListener(_rebuild);
    super.dispose();
  }

  String _paymentMethodLabel(String code) {
    switch (code) {
      case 'ewallet':
        return 'Ví điện tử (MoMo, ZaloPay, …)';
      case 'bank':
        return 'Chuyển khoản ngân hàng';
      case 'cod':
      default:
        return 'Thanh toán khi nhận hàng (COD)';
    }
  }

  // ── VOUCHER (danh sách từ API; fallback 3 mã cũ) ──
  static const Set<String> _fallbackVoucherCodes = {
    'FREESHIP',
    'GIAM20K',
    'MONKEY10',
  };
  static const Map<String, String> _fallbackCodeToRule = {
    'FREESHIP': 'FREESHIP',
    'GIAM20K': 'GIAM20K',
    'MONKEY10': 'MONKEY10',
  };

  Set<String> _allowedVoucherCodes = Set<String>.from(_fallbackVoucherCodes);
  Map<String, String> _codeToRule = Map<String, String>.from(_fallbackCodeToRule);

  String _normalizeVoucher(String? code) {
    return (code ?? '').trim().toUpperCase();
  }

  bool _isVoucherAllowed(String code) => _allowedVoucherCodes.contains(code);

  /// Rule logic khớp backend (FREESHIP / GIAM20K / MONKEY10).
  String get _appliedRule => _appliedVoucherCode.isEmpty
      ? ''
      : (_codeToRule[_appliedVoucherCode] ?? '');

  double _voucherDeliveryFee() {
    if (_appliedRule == 'FREESHIP') return 0;
    return _cart.deliveryFee;
  }

  double _voucherDiscountAmount() {
    final rule = _appliedRule;
    if (rule == 'GIAM20K') {
      final totalBeforeDiscount = _cart.subtotal + _cart.deliveryFee;
      return totalBeforeDiscount <= 0
          ? 0.0
          : (totalBeforeDiscount >= 20000 ? 20000.0 : totalBeforeDiscount);
    }
    if (rule == 'MONKEY10') {
      final totalBeforeDiscount = _cart.subtotal + _cart.deliveryFee;
      final d = _cart.subtotal * 0.1;
      final capped = d > 30000.0 ? 30000.0 : d;
      return totalBeforeDiscount <= 0
          ? 0.0
          : (capped >= totalBeforeDiscount
              ? totalBeforeDiscount
              : capped);
    }
    return 0.0;
  }

  double _voucherTotalPrice() {
    final deliveryFee = _voucherDeliveryFee();
    final discount = _voucherDiscountAmount();
    final total = _cart.subtotal + deliveryFee - discount;
    return total < 0 ? 0 : total;
  }

  void _rebuild() => setState(() {});
  Future<void> _openMapPicker() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerView(initialPosition: _deliveryLatLng),
      ),
    );
    if (result != null) {
      setState(() {
        _deliveryAddress = result["address"] as String;
        _deliveryLatLng = LatLng(
          result["lat"] as double,
          result["lng"] as double,
        );
      });
    }
  }

  Future<void> _handleCheckout() async {
    if (_cart.isEmpty) return;
    if (_cart.hasMultipleRestaurants) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Giỏ có món từ nhiều nhà hàng. Vui lòng xóa món ở nhà hàng khác — mỗi đơn chỉ một nhà hàng.',
          ),
        ),
      );
      return;
    }
    final name = _receiverName.text.trim();
    final phone = _receiverPhone.text.trim().replaceAll(RegExp(r'\s+'), '');
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập họ tên người nhận.')),
      );
      return;
    }
    if (phone.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập số điện thoại người nhận hợp lệ.'),
        ),
      );
      return;
    }
    if (_deliveryAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn địa chỉ giao hàng trước khi thanh toán.'),
        ),
      );
      return;
    }

    // Validate voucher code from input (demo: hardcode 3 mã).
    final inputVoucher = _normalizeVoucher(_voucherCodeController.text);
    if (inputVoucher.isNotEmpty) {
      if (!_isVoucherAllowed(inputVoucher)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mã ưu đãi không hợp lệ')),
        );
        return;
      }
      _appliedVoucherCode = inputVoucher;
    } else {
      _appliedVoucherCode = '';
    }

    setState(() => _isCheckingOut = true);
    try {
      final url = Uri.parse(Globs.checkoutUrl);
      final body = jsonEncode({
        'total_price': _voucherTotalPrice(),
        'delivery_address': _deliveryAddress,
        if (_deliveryLatLng != null) 'delivery_lat': _deliveryLatLng!.latitude,
        if (_deliveryLatLng != null) 'delivery_lng': _deliveryLatLng!.longitude,
        'receiver_name': name,
        'receiver_phone': phone,
        'payment_method': _paymentMethod,
        if (_appliedVoucherCode.isNotEmpty) 'voucher_code': _appliedVoucherCode,
        'items': _cart.items
            .map(
              (e) => {
                'menuItemId': e.item.id,
                'restaurantId': e.item.restaurantId,
                'name': e.item.name,
                'quantity': e.quantity,
                'price': e.item.price,
              },
            )
            .toList(),
      });

      final headers = await AuthStore.authHeaders(jsonContent: true);
      final response = await http.post(url, headers: headers, body: body);

      if (!mounted) return;

      if (response.statusCode == 201) {
        Object? orderId;
        try {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic>) {
            orderId = data['orderId'];
          }
        } catch (_) {}
        final paidLabel = _paymentMethodLabel(_paymentMethod);
        await CheckoutPrefs.save(
          name: name,
          phone: phone,
          address: _deliveryAddress,
          lat: _deliveryLatLng?.latitude,
          lng: _deliveryLatLng?.longitude,
        );
        if (!mounted) return;
        _cart.clear();
        setState(() {
          _paymentMethod = 'cod';
          _appliedVoucherCode = '';
          _voucherCodeController.clear();
        });
        await showDialog<void>(
          context: context,
          builder: (ctx) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: TColor.background,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Padding(
              padding: const EdgeInsets.only(top: 32, bottom: 24, left: 24, right: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                      size: 80,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Đặt hàng thành công!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: TColor.primaryText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (orderId != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: TColor.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Mã đơn: #$orderId',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: TColor.primaryDark,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    orderId != null
                        ? '$paidLabel\n\nCảm ơn bạn! Đơn đang được xử lý.\nDự kiến giao: 20–30 phút.'
                        : 'Cảm ơn bạn! Đơn hàng đang được xử lý.\nThời gian giao dự kiến: 20–30 phút.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: TColor.secondaryText,
                      fontSize: 15,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TColor.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Đóng',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        if (mounted) Navigator.of(context).maybePop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Globs.apiErrorMessage(
                response.body,
                fallback: 'Thanh toán thất bại (${response.statusCode})',
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi kết nối: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCheckingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.background,
      appBar: AppBar(
        backgroundColor: TColor.background,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
        ),
        title: Text(
          "Giỏ hàng",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: TColor.primaryText,
          ),
        ),
        actions: [
          if (!_cart.isEmpty)
            TextButton(
              onPressed: _showClearDialog,
              child: Text(
                "Xoá tất cả",
                style: TextStyle(color: TColor.red, fontSize: 13),
              ),
            ),
        ],
      ),
      body: _cart.isEmpty ? _buildEmpty() : _buildCartContent(context),
    );
  }

  // ── RỖng ──
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("🛒", style: TextStyle(fontSize: 72)),
          const SizedBox(height: 16),
          Text(
            "Giỏ hàng trống",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: TColor.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Hãy thêm món ăn yêu thích của bạn",
            style: TextStyle(fontSize: 14, color: TColor.secondaryText),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: TColor.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Text(
                "Xem nhà hàng",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── NỘI DUNG GIỎ HÀNG ──
  Widget _buildCartContent(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: TColor.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.storefront_rounded,
                        color: TColor.primaryDark, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _cart.restaurantName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: TColor.primaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _checkoutSectionTitle('Danh sách món'),
              const SizedBox(height: 10),
              ..._cart.items.map(_buildCartItem),
              const SizedBox(height: 20),
              _checkoutSectionTitle('Thông tin người nhận'),
              const SizedBox(height: 10),
              _buildRecipientSection(),
              const SizedBox(height: 20),
              _checkoutSectionTitle('Phương thức thanh toán'),
              const SizedBox(height: 10),
              _buildPaymentMethodSection(),
              const SizedBox(height: 20),
              _checkoutSectionTitle('Ưu đãi & Khuyến mãi'),
              const SizedBox(height: 10),
              _buildVoucherSection(),
              const SizedBox(height: 20),
              _checkoutSectionTitle('Chi tiết thanh toán'),
              const SizedBox(height: 10),
              _buildPaymentDetails(),
            ],
          ),
        ),
        _buildBottomSticky(),
      ],
    );
  }

  Widget _checkoutSectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: TColor.primaryText,
      ),
    );
  }

  Widget _buildRecipientSection() {
    InputDecoration deco(String hint) {
      return InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: TColor.placeholder, fontSize: 14),
        filled: true,
        fillColor: TColor.textfield,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _receiverName,
          textCapitalization: TextCapitalization.words,
          decoration: deco('Họ và tên'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _receiverPhone,
          keyboardType: TextInputType.phone,
          decoration: deco('Số điện thoại'),
        ),
        const SizedBox(height: 10),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openMapPicker,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: TColor.textfield,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _deliveryAddress.isEmpty
                      ? TColor.placeholder
                      : TColor.primary,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    color: _deliveryAddress.isEmpty
                        ? TColor.placeholder
                        : TColor.red,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _deliveryAddress.isEmpty
                          ? 'Địa chỉ giao hàng (chạm để chọn trên bản đồ)'
                          : _deliveryAddress,
                      style: TextStyle(
                        fontSize: 14,
                        color: _deliveryAddress.isEmpty
                            ? TColor.placeholder
                            : TColor.primaryText,
                        fontWeight: _deliveryAddress.isEmpty
                            ? FontWeight.w400
                            : FontWeight.w600,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.map_outlined,
                      color: TColor.secondaryText, size: 22),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSection() {
    Widget tile(String value, String title, IconData icon) {
      final sel = _paymentMethod == value;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _paymentMethod = value),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: sel
                    ? TColor.primary.withValues(alpha: 0.12)
                    : TColor.textfield,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: sel ? TColor.primary : TColor.textfield,
                  width: sel ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(icon,
                      color: sel ? TColor.primaryDark : TColor.secondaryText,
                      size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: TColor.primaryText,
                      ),
                    ),
                  ),
                  Icon(
                    sel ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: sel ? TColor.primary : TColor.placeholder,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        tile('cod', 'Thanh toán khi nhận hàng (COD)', Icons.payments_outlined),
        tile('ewallet', 'Ví điện tử (MoMo, ZaloPay, …)',
            Icons.account_balance_wallet_outlined),
        tile('bank', 'Chuyển khoản ngân hàng',
            Icons.account_balance_outlined),
      ],
    );
  }

  // ── CART ITEM ROW ──
  Widget _buildCartItem(CartItem cartItem) {
    final item = cartItem.item;
    final shopSub = _cart.hasMultipleRestaurants
        ? _cart.labelForRestaurant(item.restaurantId)
        : null;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TColor.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TColor.textfield, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 72,
              height: 72,
              color: TColor.textfield,
              child: item.imageUrl.trim().isNotEmpty
                  ? SmartImage(
                      item.imageUrl.trim(),
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Text(
                          item.emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        item.emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Tên + giá
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: TColor.primaryText,
                  ),
                ),
                if (shopSub != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    shopSub,
                    style: TextStyle(
                      fontSize: 11,
                      color: TColor.secondaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '${CartManager.formatPrice(item.price)} × ${cartItem.quantity}',
                  style: TextStyle(
                    fontSize: 12,
                    color: TColor.secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Thành tiền: ${CartManager.formatPrice(cartItem.subtotal)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: TColor.orangeDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // Số lượng
          Row(
            children: [
              _circleBtn(
                icon: Icons.remove_rounded,
                onTap: () => _cart.decreaseItem(item.id),
                filled: false,
              ),
              SizedBox(
                width: 28,
                child: Center(
                  child: Text(
                    "${cartItem.quantity}",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: TColor.primaryText,
                    ),
                  ),
                ),
              ),
              _circleBtn(
                icon: Icons.add_rounded,
                onTap: () => _cart.increaseItem(item.id),
                filled: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circleBtn({
    required IconData icon,
    required VoidCallback onTap,
    required bool filled,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: filled ? TColor.primary : Colors.transparent,
          border: filled ? null : Border.all(color: TColor.primary),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: filled ? Colors.white : TColor.primary,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildVoucherSection() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: TColor.textfield,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: TColor.textfield, width: 1.5),
            ),
            child: TextField(
              controller: _voucherCodeController,
              textCapitalization: TextCapitalization.characters,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: TColor.primaryText,
              ),
              decoration: InputDecoration(
                hintText: 'Nhập mã giảm giá...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: TColor.placeholder,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: () {
              final code = _normalizeVoucher(_voucherCodeController.text);
              if (code.isEmpty) {
                setState(() => _appliedVoucherCode = '');
                return;
              }
              if (!_isVoucherAllowed(code)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mã ưu đãi không hợp lệ')),
                );
                return;
              }
              setState(() => _appliedVoucherCode = code);
              FocusScope.of(context).unfocus();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã áp mã ưu đãi thành công 🎉')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: TColor.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Áp dụng',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentDetails() {
    final deliveryFee = _voucherDeliveryFee();
    final discount = _voucherDiscountAmount();
    return Column(
      children: [
        _summaryRow("Tạm tính", CartManager.formatPrice(_cart.subtotal)),
        const SizedBox(height: 8),
        _summaryRow(
          "Phí giao hàng",
          CartManager.formatPrice(deliveryFee),
          hint: _appliedRule == 'FREESHIP'
              ? "Miễn phí theo voucher"
              : (_cart.subtotal >= 150000 ? "Miễn phí từ 150k" : null),
        ),
        if (_appliedVoucherCode.isNotEmpty && discount > 0) ...[
          const SizedBox(height: 8),
          _summaryRow(
            "Giảm giá",
            '-${CartManager.formatPrice(discount)}',
          ),
        ],
      ],
    );
  }

  // ── BOTTOM STICKY AREA ──
  Widget _buildBottomSticky() {
    final blockedMulti = _cart.hasMultipleRestaurants;
    final total = _voucherTotalPrice();
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: TColor.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (blockedMulti) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Text(
                'Giỏ đang có món từ nhiều nhà hàng. Thanh toán chỉ cho một nhà hàng — hãy xóa món không thuộc "${_cart.restaurantName}" hoặc xóa giỏ và thêm lại.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: Colors.orange.shade900,
                ),
              ),
            ),
          ],
          _summaryRow(
            "Tổng cộng",
            CartManager.formatPrice(total),
            isBold: true,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: (_isCheckingOut || blockedMulti) ? null : _handleCheckout,
              style: FilledButton.styleFrom(
                backgroundColor: TColor.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: TColor.placeholder,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                elevation: 0,
              ),
              child: _isCheckingOut
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Xác nhận thanh toán',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool isBold = false,
    String? hint,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: isBold ? 15 : 14,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
                color: TColor.secondaryText,
              ),
            ),
            if (hint != null)
              Text(
                hint,
                style: TextStyle(fontSize: 11, color: Colors.green.shade600),
              ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 17 : 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            color: isBold ? TColor.orangeDark : TColor.primaryText,
          ),
        ),
      ],
    );
  }

  void _showClearDialog() {
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Xoá giỏ hàng?"),
        content: const Text("Tất cả món ăn sẽ bị xoá."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text("Huỷ", style: TextStyle(color: TColor.secondaryText)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _cart.clear();
            },
            child: Text("Xoá", style: TextStyle(color: TColor.red)),
          ),
        ],
      ),
    );
  }
}
