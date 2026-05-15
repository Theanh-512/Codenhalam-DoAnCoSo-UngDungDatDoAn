import 'package:flutter/material.dart';
import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter_food_app/view/admin/admin_categories_view.dart';
import 'package:flutter_food_app/view/admin/admin_menu_items_view.dart';
import 'package:flutter_food_app/view/admin/admin_orders_view.dart';
import 'package:flutter_food_app/view/admin/admin_restaurants_view.dart';
import 'package:flutter_food_app/view/admin/admin_users_view.dart';
import 'package:flutter_food_app/view/admin/admin_vouchers_view.dart';

/// Trung tâm quản trị — mở từ tab Khác khi tài khoản có quyền admin.
class AdminHomeView extends StatelessWidget {
  const AdminHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      appBar: AppBar(
        title: const Text('Quản trị'),
        backgroundColor: Colors.white,
        foregroundColor: TColor.primaryText,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Quản lý vận hành, cửa hàng, ưu đãi và người dùng',
            style: TextStyle(
              fontSize: 14,
              color: TColor.secondaryText,
            ),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Vận hành'),
          _AdminCard(
            icon: Icons.receipt_long_outlined,
            title: 'Đơn hàng',
            subtitle: 'Xem đơn, đổi trạng thái',
            onTap: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                    builder: (_) => const AdminOrdersView()),
              );
            },
          ),
          const SizedBox(height: 12),
          const _SectionLabel('Cửa hàng & menu'),
          _AdminCard(
            icon: Icons.storefront_outlined,
            title: 'Nhà hàng',
            subtitle: 'Thêm / sửa / xóa nhà hàng',
            onTap: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                    builder: (_) => const AdminRestaurantsView()),
              );
            },
          ),
          const SizedBox(height: 12),
          _AdminCard(
            icon: Icons.category_outlined,
            title: 'Danh mục',
            subtitle: 'Danh mục trang chủ',
            onTap: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                    builder: (_) => const AdminCategoriesView()),
              );
            },
          ),
          const SizedBox(height: 12),
          _AdminCard(
            icon: Icons.restaurant_menu_outlined,
            title: 'Món ăn',
            subtitle: 'Menu theo nhà hàng',
            onTap: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                    builder: (_) => const AdminMenuItemsView()),
              );
            },
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Marketing'),
          _AdminCard(
            icon: Icons.local_offer_outlined,
            title: 'Voucher',
            subtitle:
                'Mã giảm giá — bật/tắt, loại FREESHIP / GIAM20K / MONKEY10',
            onTap: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                    builder: (_) => const AdminVouchersView()),
              );
            },
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Tài khoản'),
          _AdminCard(
            icon: Icons.people_outline_rounded,
            title: 'Người dùng',
            subtitle: 'Vai trò, khóa tài khoản, thông tin',
            onTap: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(builder: (_) => const AdminUsersView()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: TColor.secondaryText,
        ),
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AdminCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: TColor.primary, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: TColor.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: TColor.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: TColor.placeholder),
            ],
          ),
        ),
      ),
    );
  }
}
