import 'package:flutter/material.dart';
import 'package:flutter_food_app/common/auth_store.dart';
import 'package:flutter_food_app/common/cart_nav.dart';
import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter_food_app/view/admin/admin_home_view.dart';
import 'package:flutter_food_app/view/more/about_view.dart';
import 'package:flutter_food_app/view/more/inbox_view.dart';
import 'package:flutter_food_app/view/more/notifications_view.dart';
import 'package:flutter_food_app/view/profile/order_history_view.dart';
import 'package:flutter_food_app/view/profile/payment_methods_view.dart';
import 'package:flutter_food_app/view/shipper/shipper_home_view.dart';

/// Tab "Khác" — menu phụ.
class MoreView extends StatefulWidget {
  const MoreView({super.key});

  @override
  State<MoreView> createState() => _MoreViewState();
}

class _MoreViewState extends State<MoreView> {
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final a = await AuthStore.isAdmin();
    if (mounted) setState(() => _isAdmin = a);
  }

  @override
  Widget build(BuildContext context) {
    final badge = NotificationsView.badgeCount.toString();
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Khác',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: TColor.primaryText,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    color: TColor.primaryText,
                    onPressed: () => openAppCart(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadRole,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                  if (_isAdmin) ...[
                    _MoreTile(
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'Quản trị',
                      onTap: () {
                        Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const AdminHomeView(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  _MoreTile(
                    icon: Icons.payments_outlined,
                    title: 'Chi tiết thanh toán',
                    onTap: () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const PaymentMethodsView(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _MoreTile(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Đơn hàng của tôi',
                    onTap: () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const OrderHistoryView(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _MoreTile(
                    icon: Icons.notifications_outlined,
                    title: 'Thông báo',
                    trailingBadge: badge,
                    onTap: () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const NotificationsView(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _MoreTile(
                    icon: Icons.mail_outline_rounded,
                    title: 'Hộp thư',
                    onTap: () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const InboxView(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _MoreTile(
                    icon: Icons.delivery_dining_outlined,
                    title: 'Kênh Người giao hàng',
                    onTap: () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const ShipperHomeView(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _MoreTile(
                    icon: Icons.info_outline_rounded,
                    title: 'Về chúng tôi',
                    onTap: () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const AboutView(),
                        ),
                      );
                    },
                  ),
                ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailingBadge,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String? trailingBadge;

  @override
  Widget build(BuildContext context) {
    final count = trailingBadge == null ? 0 : int.tryParse(trailingBadge!) ?? 0;
    final showBadge = count > 0;
    final badgeText = count > 99 ? '99+' : '$count';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: TColor.primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: TColor.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: TColor.primaryText,
                    ),
                  ),
                ),
                if (showBadge) ...[
                  Container(
                    constraints:
                        const BoxConstraints(minWidth: 26, minHeight: 26),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xffE53935),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      badgeText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Icon(
                  Icons.chevron_right_rounded,
                  color: TColor.placeholder,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
