import 'package:flutter/material.dart';
import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter_food_app/features/home/food_recognition_screen.dart';
import 'package:flutter_food_app/view/search/search_view.dart';

/// Thanh tìm kiếm thống nhất toàn app.
/// - [AppSearchBar.tap]: chạm mở [SearchView] (Trang chủ, Thực đơn); có nút camera bên phải.
/// - [AppSearchBar.inline]: lọc tại chỗ (chi tiết nhà hàng, danh sách món).
class AppSearchBar extends StatelessWidget {
  static const String defaultHint = 'Tìm món ăn, nhà hàng...';
  static const double barHeight = 48;
  static const double borderRadius = 24;

  final bool tapToOpenSearch;
  final String hintText;
  final bool showImageSearch;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final VoidCallback? onClear;
  final ValueChanged<String>? onImageSearchResult;
  final bool autofocus;
  final TextInputAction textInputAction;

  const AppSearchBar.tap({
    super.key,
    this.hintText = defaultHint,
    this.showImageSearch = true,
    this.onImageSearchResult,
  })  : tapToOpenSearch = true,
        controller = null,
        onChanged = null,
        onSubmitted = null,
        onClear = null,
        autofocus = false,
        textInputAction = TextInputAction.search;

  const AppSearchBar.inline({
    super.key,
    required this.controller,
    this.hintText = defaultHint,
    this.showImageSearch = false,
    this.onImageSearchResult,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
    this.textInputAction = TextInputAction.search,
  }) : tapToOpenSearch = false;

  /// Mở màn tìm kiếm toàn cục (món + nhà hàng).
  static Future<void> openSearch(
    BuildContext context, {
    String? initialQuery,
    bool autofocus = true,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchView(
          initialQuery: initialQuery,
          autofocus: autofocus,
        ),
      ),
    );
  }

  /// Mở camera AI → chuyển kết quả sang màn tìm kiếm.
  static Future<void> openImageSearch(BuildContext context) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const FoodRecognitionScreen()),
    );
    if (context.mounted && result != null && result.isNotEmpty) {
      await openSearch(context, initialQuery: result, autofocus: false);
    }
  }

  Future<void> _handleImageSearch(BuildContext context) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const FoodRecognitionScreen()),
    );
    if (!context.mounted || result == null || result.isEmpty) return;
    if (onImageSearchResult != null) {
      onImageSearchResult!(result);
    } else {
      await openSearch(context, initialQuery: result, autofocus: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: barHeight,
      decoration: BoxDecoration(
        color: TColor.textfield,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: tapToOpenSearch ? _buildTap(context) : _buildInline(context),
    );
  }

  Widget _buildTap(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => openSearch(context),
              borderRadius: BorderRadius.horizontal(
                left: const Radius.circular(borderRadius),
                right: Radius.circular(showImageSearch ? 0 : borderRadius),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Icon(Icons.search, color: TColor.secondaryText, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hintText,
                      style: TextStyle(color: TColor.placeholder, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
        if (showImageSearch) ...[
          Container(
            width: 1,
            height: 28,
            color: TColor.placeholder.withValues(alpha: 0.35),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _handleImageSearch(context),
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(borderRadius),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Icon(
                  Icons.camera_alt_rounded,
                  color: TColor.primary,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInline(BuildContext context) {
    final ctrl = controller!;
    return Row(
      children: [
        const SizedBox(width: 16),
        Icon(Icons.search, color: TColor.secondaryText, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: ctrl,
            autofocus: autofocus,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.none,
            textInputAction: textInputAction,
            spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
            smartDashesType: SmartDashesType.disabled,
            smartQuotesType: SmartQuotesType.disabled,
            autocorrect: false,
            enableSuggestions: false,
            onChanged: onChanged,
            onSubmitted: onSubmitted != null ? (_) => onSubmitted!() : null,
            style: TextStyle(color: TColor.primaryText, fontSize: 14),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: TColor.placeholder, fontSize: 14),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        if (showImageSearch) ...[
          Container(
            width: 1,
            height: 28,
            color: TColor.placeholder.withValues(alpha: 0.35),
          ),
          IconButton(
            onPressed: () => _handleImageSearch(context),
            icon: Icon(Icons.camera_alt_rounded, color: TColor.primary, size: 24),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
        ] else
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: ctrl,
            builder: (context, value, _) {
              if (value.text.isEmpty) return const SizedBox(width: 8);
              return IconButton(
                onPressed: () {
                  ctrl.clear();
                  onClear?.call();
                  onChanged?.call('');
                },
                icon: Icon(Icons.close_rounded, color: TColor.primary, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              );
            },
          ),
      ],
    );
  }
}
