import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter/material.dart';

class HelpCenterView extends StatelessWidget {
  const HelpCenterView({super.key});

  static const _faqs = [
    ('Làm sao để đổi địa chỉ giao hàng?', 'Vào Trang chủ → chọn dòng địa chỉ trên cùng → chọn vị trí trên bản đồ hoặc nhập tay khi thanh toán.'),
    ('Đơn bị sai món thì sao?', 'Liên hệ hotline hoặc chat trong vòng 15 phút kể từ lúc nhận hàng. Bộ phận CSKH sẽ xử lý theo chính sách shop.'),
    ('Voucher áp dụng thế nào?', 'Chọn voucher tại bước thanh toán (bản demo: mục Voucher hiển thị mã, có thể áp dụng khi app mở rộng checkout).'),
    ('Quên mật khẩu?', 'Màn Đăng nhập → Quên mật khẩu → nhập email → nhập mã OTP → đặt mật khẩu mới.'),
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
          'Trung tâm hỗ trợ',
          style: TextStyle(
            color: TColor.primaryText,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TColor.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.support_agent_rounded, color: TColor.primary, size: 40),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cần hỗ trợ nhanh?',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: TColor.primaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Email: support@mealmonkey.demo\nHotline: 1900 0000 (demo)',
                        style: TextStyle(
                          fontSize: 13,
                          color: TColor.secondaryText,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Câu hỏi thường gặp',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: TColor.primaryText,
            ),
          ),
          const SizedBox(height: 12),
          ..._faqs.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: Text(
                      e.$1,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: TColor.primaryText,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            e.$2,
                            style: TextStyle(
                              fontSize: 14,
                              color: TColor.secondaryText,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
