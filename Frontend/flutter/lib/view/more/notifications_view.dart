import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter/material.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  /// Dùng badge trên tab Khác (demo).
  static int get badgeCount => _items.where((e) => e.unread).length;

  static final _items = [
    _Notif(
      'Khuyến mãi',
      'Giảm 20% đơn đầu tiên hôm nay — xem mã trong mục Voucher.',
      '2 giờ trước',
      Icons.local_offer_outlined,
      unread: true,
    ),
    _Notif(
      'Đơn hàng',
      'Đơn #1042 của bạn đang được chuẩn bị.',
      'Hôm qua',
      Icons.receipt_long_outlined,
      unread: true,
    ),
    _Notif(
      'Giao hàng',
      'Shipper đang trên đường — dự kiến 10 phút nữa tới.',
      '3 ngày trước',
      Icons.delivery_dining_outlined,
      unread: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      appBar: AppBar(
        backgroundColor: TColor.background,
        elevation: 0,
        iconTheme: IconThemeData(color: TColor.primaryText),
        title: Text(
          'Thông báo',
          style: TextStyle(
            color: TColor.primaryText,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final n = _items[i];
          return Material(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white,
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: TColor.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(n.icon, color: TColor.primary, size: 22),
              ),
              title: Text(
                n.title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: TColor.primaryText,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  n.body,
                  style: TextStyle(
                    fontSize: 13,
                    color: TColor.secondaryText,
                    height: 1.35,
                  ),
                ),
              ),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (n.unread) ...[
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: TColor.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    n.time,
                    style: TextStyle(fontSize: 11, color: TColor.placeholder),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Notif {
  _Notif(
    this.title,
    this.body,
    this.time,
    this.icon, {
    required this.unread,
  });
  final String title;
  final String body;
  final String time;
  final IconData icon;
  final bool unread;
}
