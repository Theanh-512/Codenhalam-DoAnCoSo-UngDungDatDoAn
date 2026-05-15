import 'package:flutter/material.dart';
import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter_food_app/common_widget/app_search_bar.dart';
import 'package:flutter_food_app/common/smart_image.dart';
import 'package:flutter_food_app/model/menu_item_model.dart';
import 'package:flutter_food_app/model/restaurant_model.dart';
import 'package:flutter_food_app/view/menu/item_detail_view.dart';
import 'package:flutter_food_app/view/restaurant/restaurant_detail_view.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class SearchView extends StatefulWidget {
  final bool autofocus;
  final String? initialQuery;
  const SearchView({super.key, this.autofocus = true, this.initialQuery});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  late final TextEditingController _txtSearch;
  List<MenuItemModel> _foodResults = [];
  List<RestaurantModel> _restaurantResults = [];
  Timer? _debounce;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _txtSearch = TextEditingController(text: widget.initialQuery ?? "");
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      // Delay một chút để build xong rồi gọi search
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _runSearchAfterCompose();
      });
    }
  }

  /// IME tiếng Việt đang trong bước gõ dấu — tránh gọi API/setState làm gián đoạn composition.
  bool _isComposing(TextEditingValue v) =>
      v.composing.isValid && !v.composing.isCollapsed;

  void _scheduleSearch() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), _runSearchAfterCompose);
  }

  Future<void> _runSearchAfterCompose() async {
    if (!mounted) return;
    final v = _txtSearch.value;
    if (_isComposing(v)) {
      _debounce = Timer(const Duration(milliseconds: 200), _runSearchAfterCompose);
      return;
    }

    final q = v.text.trim();
    if (q.isEmpty) {
      setState(() {
        _foodResults = [];
        _restaurantResults = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Chạy song song cả 2 search
    final results = await Future.wait([
      MenuItemModel.search(q),
      RestaurantModel.search(q),
    ]);

    if (mounted) {
      setState(() {
        _foodResults = results[0] as List<MenuItemModel>;
        _restaurantResults = results[1] as List<RestaurantModel>;
        _isLoading = false;
      });
    }
  }

  void _onClearSearch() {
    _debounce?.cancel();
    setState(() {
      _foodResults = [];
      _restaurantResults = [];
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _txtSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back_ios_new, color: TColor.primaryText),
                  ),
                  Expanded(
                    child: AppSearchBar.inline(
                      controller: _txtSearch,
                      autofocus: widget.autofocus,
                      showImageSearch: true,
                      onImageSearchResult: (q) {
                        _txtSearch.text = q;
                        _txtSearch.selection = TextSelection.collapsed(offset: q.length);
                        _runSearchAfterCompose();
                      },
                      onChanged: (_) => _scheduleSearch(),
                      onSubmitted: _runSearchAfterCompose,
                      onClear: _onClearSearch,
                    ),
                  ),
                ],
              ),
            ),
            
            // Results List
            Expanded(
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _txtSearch,
                builder: (context, queryVal, _) {
                  final queryEmpty = queryVal.text.trim().isEmpty;
                  if (queryEmpty) {
                    return Center(
                      child: Text(
                        "Nhập tên nhà hàng hoặc món ăn",
                        style: TextStyle(color: TColor.placeholder, fontSize: 16),
                      ),
                    );
                  }
                  if (_isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (_foodResults.isEmpty && _restaurantResults.isEmpty) {
                    return Center(
                      child: Text(
                        "Không tìm thấy kết quả nào",
                        style: TextStyle(color: TColor.primaryText, fontSize: 16),
                      ),
                    );
                  }
                  
                  return CustomScrollView(
                    slivers: [
                      if (_restaurantResults.isNotEmpty) ...[
                        _buildSectionHeader("Nhà hàng"),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final res = _restaurantResults[index];
                              return _buildRestaurantTile(res);
                            },
                            childCount: _restaurantResults.length,
                          ),
                        ),
                      ],
                      if (_foodResults.isNotEmpty) ...[
                        _buildSectionHeader("Món ăn"),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = _foodResults[index];
                              return _buildFoodTile(item, currencyFormatter);
                            },
                            childCount: _foodResults.length,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Text(
          title,
          style: TextStyle(
            color: TColor.primaryText,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildRestaurantTile(RestaurantModel res) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SmartImage(
          res.imageUrl.isNotEmpty ? res.imageUrl : 'https://picsum.photos/seed/${res.id}/200/200',
          width: 50, height: 50, fit: BoxFit.cover,
        ),
      ),
      title: Text(res.name, style: TextStyle(color: TColor.primaryText, fontWeight: FontWeight.w700)),
      subtitle: Text(res.type1, style: TextStyle(color: TColor.secondaryText, fontSize: 13)),
      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: TColor.placeholder),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantDetailView(restaurant: res)));
      },
    );
  }

  Widget _buildFoodTile(MenuItemModel item, NumberFormat currencyFormatter) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SmartImage(
          item.imageUrl.isNotEmpty ? item.imageUrl : 'https://picsum.photos/seed/${item.id}/200/200',
          width: 50, height: 50, fit: BoxFit.cover,
        ),
      ),
      title: Text(item.name, style: TextStyle(color: TColor.primaryText, fontWeight: FontWeight.w700)),
      subtitle: Text(item.category, style: TextStyle(color: TColor.secondaryText, fontSize: 13)),
      trailing: Text(currencyFormatter.format(item.price), style: TextStyle(color: TColor.primary, fontWeight: FontWeight.bold)),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemDetailView(
              itemObj: {
                "id": item.id,
                "restaurant_id": item.restaurantId,
                "name": item.name,
                "price": item.price.toStringAsFixed(0),
                "image": item.imageUrl,
                "description": item.description,
                "category": item.category,
              },
            ),
          ),
        );
      },
    );
  }
}
