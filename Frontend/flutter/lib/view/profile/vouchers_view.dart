import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VouchersView extends StatelessWidget {
  const VouchersView({super.key});

  static final _items = [
    _DiscountCoupon(
      'FREESHIP',
      'Miễn phí ship',
      'Đơn từ 99.000đ',
      'Còn 7 ngày',
      const Color(0xFF2E7D32),
    ),
    _DiscountCoupon(
      'GIAM20K',
      'Giảm 20.000đ',
      'Đơn từ 150.000đ',
      'Còn 14 ngày',
      const Color(0xFF1565C0),
    ),
    _DiscountCoupon(
      'MONKEY10',
      'Giảm 10%',
      'Tối đa 30.000đ',
      'Hết hạn sau Tết',
      const Color(0xFFEF6C00),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      appBar: AppBar(
        backgroundColor: TColor.white,
        elevation: 0,
        iconTheme: IconThemeData(color: TColor.primaryText),
        title: Text(
          'Voucher của tôi',
          style: TextStyle(
            color: TColor.primaryText,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        itemBuilder: (context, i) {
          final v = _items[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Material(
              borderRadius: BorderRadius.circular(16),
              elevation: 1,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: v.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          v.code,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            color: v.accent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            v.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: TColor.primaryText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            v.rule,
                            style: TextStyle(
                              fontSize: 13,
                              color: TColor.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            v.expiry,
                            style: TextStyle(
                              fontSize: 12,
                              color: v.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: v.code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Đã sao chép mã ${v.code}')),
                        );
                      },
                      icon: Icon(Icons.copy_rounded, color: TColor.primary),
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

class _DiscountCoupon {
  const _DiscountCoupon(this.code, this.title, this.rule, this.expiry, this.accent);
  final String code;
  final String title;
  final String rule;
  final String expiry;
  final Color accent;
}
