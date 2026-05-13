import 'package:flutter/material.dart';
import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter_food_app/view/home/home_view.dart';
import 'package:flutter_food_app/view/menu/menu_view.dart';
import 'package:flutter_food_app/view/map/ai_map_view.dart';
import 'package:flutter_food_app/view/order/order_view.dart';
import 'package:flutter_food_app/view/profile/profile_view.dart';
import 'package:flutter_food_app/view/more/more_view.dart';

class MainTabView extends StatefulWidget {
  const MainTabView({super.key});

  @override
  State<MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends State<MainTabView> {
  int _currentIndex = 2; // Default to Home (Center)

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  Widget _buildNavigator(int index, Widget rootWidget) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(builder: (context) => rootWidget);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildNavigator(0, const MenuView()),
          _buildNavigator(1, const AiMapView()),
          _buildNavigator(2, const HomeView()),
          _buildNavigator(3, const ProfileView()),
          _buildNavigator(4, const MoreView()),
        ],
      ),
      backgroundColor: const Color(0xfff5f5f5),
      bottomNavigationBar: BottomAppBar(
        color: TColor.white,
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTabItem(0, Icons.grid_view_rounded, "Thực đơn"),
              _buildTabItem(1, Icons.auto_awesome_rounded, "AI Map"),
              _buildTabItem(2, Icons.home_rounded, "Trang chủ"),
              _buildTabItem(3, Icons.person_outline_rounded, "Hồ sơ"),
              _buildTabItem(4, Icons.more_horiz_rounded, "Khác"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, IconData icon, String label) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        if (_currentIndex != index) {
          setState(() {
            _currentIndex = index;
          });
        } else {
          _navigatorKeys[index].currentState?.popUntil(
            (route) => route.isFirst,
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? TColor.primary : TColor.placeholder,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? TColor.primary : TColor.placeholder,
            ),
          ),
        ],
      ),
    );
  }
}
