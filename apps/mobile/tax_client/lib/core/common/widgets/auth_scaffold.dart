import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tax_client/core/common/widgets/app_logo.dart';
import 'package:tax_client/core/config/theme/app_colors.dart';
import 'package:tax_client/core/config/theme/app_spacing.dart';
import 'package:tax_client/core/config/theme/app_theme_extension.dart';

/// Auth flow layout — gradient and padding from global [ThemeData] only.
class AuthScaffold extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final double maxContentWidth;

  const AuthScaffold({
    super.key,
    required this.child,
    this.appBar,
    this.maxContentWidth = 448,
  });

  @override
  Widget build(BuildContext context) {
    final extras = context.appExtras;

    return Scaffold(
      extendBodyBehindAppBar: appBar != null,
      appBar: appBar,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: extras.authBackgroundGradient,
        ),
        child: Stack(
          children: [
            const _AuthAtmosphere(),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Glass card on auth screens — colors from [AppThemeExtension].
class AuthFormCard extends StatelessWidget {
  final Widget child;

  const AuthFormCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final extras = context.appExtras;

    return Container(
      padding: const EdgeInsets.all(33),
      decoration: BoxDecoration(
        color: extras.glassCardColor,
        borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
        border: Border.all(color: extras.glassCardBorderColor),
        boxShadow: [
          BoxShadow(
            color: extras.glassCardShadowColor,
            blurRadius: 50,
            spreadRadius: -12,
            offset: const Offset(0, 25),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Auth screen title + subtitle using [TextTheme] / [ColorScheme].
class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final double logoHeight;

  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.logoHeight = 140,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        AppLogo(height: logoHeight),
        const SizedBox(height: AppSpacing.lg),
        Text(
          title,
          style: textTheme.headlineMedium?.copyWith(color: AppColors.authHeading),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          subtitle,
          style: textTheme.bodyLarge?.copyWith(color: AppColors.authMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class AuthFieldHeader extends StatelessWidget {
  final String label;
  final Widget? trailing;
  final TextStyle? labelStyle;

  const AuthFieldHeader({
    super.key,
    required this.label,
    this.trailing,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: labelStyle,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class AuthTrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const AuthTrustBadge({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: AppColors.authMutedSoft,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: AppColors.authMutedSoft,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class AuthFieldGroup extends StatelessWidget {
  final String label;
  final Widget child;
  final TextStyle? labelStyle;

  const AuthFieldGroup({
    super.key,
    required this.label,
    required this.child,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthFieldHeader(
          label: label,
          labelStyle: labelStyle ??
              textTheme.labelMedium?.copyWith(
                color: AppColors.authMuted,
                letterSpacing: 1.2,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}

class _AuthAtmosphere extends StatelessWidget {
  const _AuthAtmosphere();

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _BlurGlow(
              top: -88,
              left: -20,
              width: 156,
              height: 354,
              color: AppColors.authGlowMint,
              blur: 60,
            ),
            _BlurGlow(
              top: 354,
              right: -39,
              width: 137,
              height: 309,
              color: AppColors.authGlowAmber,
              blur: 50,
            ),
          ],
        ),
      ),
    );
  }
}

class _BlurGlow extends StatelessWidget {
  final double width;
  final double height;
  final double blur;
  final double? top;
  final double? left;
  final double? right;
  final Color color;

  const _BlurGlow({
    required this.width,
    required this.height,
    required this.blur,
    required this.color,
    this.top,
    this.left,
    this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
