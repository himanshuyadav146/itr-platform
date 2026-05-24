import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double height;
  final double width;
  final BoxFit fit;

  const AppLogo({
    super.key,
    this.height = 150, // Increased default size
    this.width = 150,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo/logo_dark1.png',
      height: height,
      width: width,
      fit: fit,
    );
  }
}
