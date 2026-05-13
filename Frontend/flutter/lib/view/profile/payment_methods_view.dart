import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter/material.dart';

/// Phương thức thanh toán lưu cho đơn hàng (demo: chọn mặc định, không gọi API).
class PaymentMethodsView extends StatefulWidget {
  const PaymentMethodsView({super.key});

  @override
  State<PaymentMethodsView> createState() => _PaymentMethodsViewState();
}

class _PaymentMethodsViewState extends State<PaymentMethodsView> {
  int _selected = 0;

  static const _methods = [
    (icon: Icons.payments_outlined, title: 'Tiền mặt khi nhận hàng (COD)', subtitle: 'Thanh toán trực tiếp cho shipper'),
    (icon: Icons.account_balance_outlined, title: 'Chuyển khoản ngân hàng', subtitle: 'Nội dung CK: số điện thoại đặt hàng'),
    (icon: Icons.credit_card_outlined, title: 'Thẻ (Visa / Master)', subtitle: 'Tích hợp cổng thanh toán — bản demo chỉ hiển thị'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.background,
      appBar: AppBar(
        backgroundColor: TColor.white,
        elevation: 0,
        iconTheme: IconThemeData(color: TColor.primaryText),
        title: Text(
          'Phương thức thanh toán',
          style: TextStyle(
            color: TColor.primaryText,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _methods.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final m = _methods[i];
          final selected = _selected == i;
          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () => setState(() => _selected = i),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(m.icon, color: TColor.primary, size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: TColor.primaryText,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            m.subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: TColor.secondaryText,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      selected ? Icons.check_circle : Icons.circle_outlined,
                      color: selected ? TColor.primary : TColor.placeholder,
                      size: 26,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
