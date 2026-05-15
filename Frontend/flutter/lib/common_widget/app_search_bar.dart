import 'package:flutter/material.dart';
import 'package:flutter_food_app/common/color_extension.dart';
import 'package:flutter_food_app/view/search/search_view.dart';

/// Thanh tìm kiếm thống nhất toàn app.
/// - [AppSearchBar.tap]: chạm mở [SearchView] (Trang chủ, Thực đơn).
/// - [AppSearchBar.inline]: lọc tại chỗ (chi tiết nhà hàng, danh sách món).
class AppSearchBar extends StatelessWidget {
  static const String defaultHint = 'Tìm món ăn, nhà hàng...';
  static const double barHeight = 48;
  static const double borderRadius = 24;

  final bool tapToOpenSearch;
  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final VoidCallback? onClear;
  final bool autofocus;
  final TextInputAction textInputAction;

  const AppSearchBar.tap({
    super.key,
    this.hintText = defaultHint,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: barHeight,
      decoration: BoxDecoration(
        color: TColor.textfield,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: tapToOpenSearch ? _buildTap(context) : _buildInline(),
    );
  }

  Widget _buildTap(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => openSearch(context),
        borderRadius: BorderRadius.circular(borderRadius),
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
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInline() {
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
