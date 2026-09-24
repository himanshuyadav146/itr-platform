import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? color;
  final double borderRadius;
  final Gradient? gradient;
  final Color? foregroundColor;
  final TextStyle? textStyle;
  final double minHeight;
  final List<BoxShadow>? boxShadow;
  final EdgeInsetsGeometry? padding;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.color,
    this.borderRadius = 12,
    this.gradient,
    this.foregroundColor,
    this.textStyle,
    this.minHeight = 50,
    this.boxShadow,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final buttonTextStyle = Theme.of(context).textTheme.labelLarge;
    final isEnabled = onPressed != null && !isLoading;
    final buttonColor = color ?? colorScheme.primary;
    final fgColor = foregroundColor ?? colorScheme.onPrimary;

    return Opacity(
      opacity: isEnabled ? 1 : 0.6,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: isEnabled ? onPressed : null,
          child: Ink(
            width: double.infinity,
            padding:
                padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: gradient == null ? buttonColor : null,
              gradient: isEnabled ? gradient : null,
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: isEnabled ? boxShadow : null,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeight),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: fgColor),
                      )
                    : Text(
                        text,
                        style: (textStyle ?? buttonTextStyle)?.copyWith(color: fgColor),
                        textAlign: TextAlign.center,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
