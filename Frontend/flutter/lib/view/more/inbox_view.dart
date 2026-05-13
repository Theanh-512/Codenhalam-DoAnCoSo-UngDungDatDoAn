import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter/material.dart';

class InboxView extends StatelessWidget {
  const InboxView({super.key});

  static final _messages = [
    _Msg('FastBite', 'Cảm ơn bạn đã đặt hàng! Đánh giá trải nghiệm giúp chúng tôi cải thiện.', 'T2'),
    _Msg('CSKH', 'Yêu cầu của bạn #8821 đã được tiếp nhận.', 'CN'),
    _Msg('Khuyến mãi', 'Tuần mới — bộ sưu tập món chay mới đã có mặt.', 'T6'),
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
          'Hộp thư',
          style: TextStyle(
            color: TColor.primaryText,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _messages.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final m = _messages[i];
          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              leading: const CircleAvatar(
                child: Icon(Icons.mail_outline_rounded),
              ),
              title: Text(
                m.from,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: TColor.primaryText,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  m.preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: TColor.secondaryText),
                ),
              ),
              trailing: Text(
                m.day,
                style: TextStyle(fontSize: 12, color: TColor.placeholder),
              ),
              onTap: () {
                showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  builder: (ctx) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.from,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: TColor.primaryText,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          m.preview,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.4,
                            color: TColor.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _Msg {
  _Msg(this.from, this.preview, this.day);
  final String from;
  final String preview;
  final String day;
}
