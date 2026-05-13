import 'package:flutter/material.dart';
import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter_food_app/common/smart_image.dart';
import 'package:flutter_food_app/model/menu_item_model.dart';
import 'package:flutter_food_app/view/menu/item_detail_view.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class SearchView extends StatefulWidget {
  final bool autofocus;
  const SearchView({super.key, this.autofocus = true});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _txtSearch = TextEditingController();
  List<MenuItemModel> _searchResults = [];
  Timer? _debounce;
  bool _isLoading = false;

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
        _searchResults = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final results = await MenuItemModel.search(q);

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    }
  }

  void _clearSearch() {
    _debounce?.cancel();
    _txtSearch.clear();
    setState(() {
      _searchResults = [];
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
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: TColor.textfield,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          Icon(Icons.search, color: TColor.placeholder),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _txtSearch,
                              autofocus: widget.autofocus,
                              keyboardType: TextInputType.text,
                              textCapitalization: TextCapitalization.none,
                              textInputAction: TextInputAction.search,
                              // iOS: spell check / smart punctuation hay cắt ngang bước gõ Telex–VNI.
                              spellCheckConfiguration:
                                  const SpellCheckConfiguration.disabled(),
                              smartDashesType: SmartDashesType.disabled,
                              smartQuotesType: SmartQuotesType.disabled,
                              autocorrect: true,
                              enableSuggestions: true,
                              onChanged: (_) => _scheduleSearch(),
                              decoration: InputDecoration(
                                hintText: "Tìm kiếm món ăn, danh mục...",
                                hintStyle: TextStyle(color: TColor.placeholder, fontSize: 14),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _txtSearch,
                            builder: (context, value, _) {
                              if (value.text.isEmpty) return const SizedBox.shrink();
                              return IconButton(
                                onPressed: _clearSearch,
                                icon: Icon(Icons.close, color: TColor.primary),
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
            
            // Results List
            Expanded(
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _txtSearch,
                builder: (context, queryVal, _) {
                  final queryEmpty = queryVal.text.trim().isEmpty;
                  if (queryEmpty) {
                    return Center(
                      child: Text(
                        "Nhập tên món ăn để tìm kiếm",
                        style: TextStyle(color: TColor.placeholder, fontSize: 16),
                      ),
                    );
                  }
                  if (_isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (_searchResults.isEmpty) {
                    return Center(
                      child: Text(
                        "Không tìm thấy món nào",
                        style: TextStyle(color: TColor.primaryText, fontSize: 16),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: _searchResults.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _searchResults[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: SmartImage(
                              item.imageUrl.trim().isNotEmpty
                                  ? item.imageUrl.trim()
                                  : 'https://picsum.photos/seed/${item.id}/200/200',
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => ColoredBox(
                                color: TColor.textfield,
                                child: Center(
                                  child: Text(
                                    item.emoji,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          item.name,
                          style: TextStyle(
                            color: TColor.primaryText,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          item.category,
                          style: TextStyle(color: TColor.secondaryText, fontSize: 13),
                        ),
                        trailing: Text(
                          currencyFormatter.format(item.price),
                          style: TextStyle(
                            color: TColor.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ItemDetailView(
                                itemObj: {
                                  "id": item.id,
                                  "restaurant_id": item.restaurantId,
                                  "restaurant_name": "",
                                  "name": item.name,
                                  "price": item.price.toStringAsFixed(0),
                                  "image": item.imageUrl.isNotEmpty
                                      ? item.imageUrl
                                      : 'https://picsum.photos/seed/${item.id}/400/400',
                                  "category": item.category,
                                  "emoji": item.emoji,
                                  "description": item.description,
                                  "type": item.category,
                                  "food_type": item.category,
                                  "rate": "4.9",
                                  "rating": "124",
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
