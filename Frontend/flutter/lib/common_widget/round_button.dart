import 'package:flutter/material.dart';
import '../common/color_extension.dart';

class RoundButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String title;
  final double fontSize;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isDisabled;

  const RoundButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.fontSize = 18,
    this.backgroundColor,
    this.textColor,
    this.isDisabled = false,
  });

  @override
  State<RoundButton> createState() => _RoundButtonState();
}

class _RoundButtonState extends State<RoundButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDisabled
        ? Colors.grey.shade300
        : widget.backgroundColor ?? TColor.primaryDark;

    final txtColor = widget.isDisabled
        ? Colors.grey
        : widget.textColor ?? Colors.white;

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: widget.isDisabled ? null : widget.onPressed,
          onHighlightChanged: (v) {
            setState(() => _pressed = v);
          },
          splashColor: Colors.white.withValues(alpha: 0.2),
          highlightColor: Colors.white.withValues(alpha: 0.1),
          child: Container(
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(28),
              boxShadow: widget.isDisabled
                  ? []
                  : [
                      BoxShadow(
                        color: bgColor.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Text(
              widget.title,
              style: TextStyle(
                color: txtColor,
                fontSize: widget.fontSize,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
