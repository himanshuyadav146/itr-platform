import 'package:flutter/material.dart';
import 'package:tax_client/core/common/widgets/app_logo.dart';
import 'package:tax_client/core/config/theme/app_theme_extension.dart';

/// Auth flow layout — gradient and padding from global [ThemeData] only.
class AuthScaffold extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;

  const AuthScaffold({
    super.key,
    required this.child,
    this.appBar,
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
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: child,
            ),
          ),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: extras.glassCardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: extras.glassCardBorderColor),
        boxShadow: [
          BoxShadow(
            color: extras.glassCardShadowColor,
            blurRadius: 20,
            offset: const Offset(0, 10),
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
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      children: [
        AppLogo(height: logoHeight),
        const SizedBox(height: 24),
        Text(
          title,
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
