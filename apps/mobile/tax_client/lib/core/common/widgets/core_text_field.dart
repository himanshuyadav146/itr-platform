import 'package:flutter/material.dart';

class CoreTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int? minLines;
  final int? maxLines;
  final TextInputAction? textInputAction;
  final bool useInlineLabel;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final Color? fillColor;
  final Color? enabledBorderColor;
  final Color? focusedBorderColor;
  final double? borderRadius;
  final EdgeInsetsGeometry? contentPadding;

  const CoreTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.minLines,
    this.maxLines = 1,
    this.textInputAction,
    this.useInlineLabel = true,
    this.textStyle,
    this.hintStyle,
    this.fillColor,
    this.enabledBorderColor,
    this.focusedBorderColor,
    this.borderRadius,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final style = textStyle ?? theme.textTheme.bodyLarge;
    final radius = borderRadius ?? 12;

    final decoration = InputDecoration(
      labelText: useInlineLabel ? label : null,
      hintText: hintText,
      hintStyle: hintStyle,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: fillColor != null ? true : null,
      fillColor: fillColor,
      contentPadding: contentPadding,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(
          color: enabledBorderColor ?? colorScheme.outlineVariant,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(
          color: enabledBorderColor ?? colorScheme.outlineVariant,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(
          color: focusedBorderColor ?? colorScheme.primary,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: colorScheme.error),
      ),
    );

    if (validator != null) {
      return TextFormField(
        controller: controller,
        style: style,
        obscureText: obscureText,
        keyboardType: keyboardType,
        minLines: minLines,
        maxLines: maxLines,
        textInputAction: textInputAction,
        onChanged: onChanged,
        validator: validator,
        decoration: decoration,
      );
    }

    return TextField(
      controller: controller,
      style: style,
      obscureText: obscureText,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      textInputAction: textInputAction,
      onChanged: onChanged,
      decoration: decoration,
    );
  }
}
