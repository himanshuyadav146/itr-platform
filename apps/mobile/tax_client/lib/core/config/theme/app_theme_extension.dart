import 'package:flutter/material.dart';
import 'package:tax_client/core/config/theme/app_colors.dart';

/// App-specific tokens via [ThemeExtension] (Flutter theming docs).
/// Access: `Theme.of(context).extension<AppThemeExtension>()`
@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({
    required this.authBackgroundGradient,
    required this.glassCardColor,
    required this.glassCardBorderColor,
    required this.glassCardShadowColor,
  });

  final Gradient authBackgroundGradient;
  final Color glassCardColor;
  final Color glassCardBorderColor;
  final Color glassCardShadowColor;

  static const dark = AppThemeExtension(
    authBackgroundGradient: AppColors.authGradient,
    glassCardColor: AppColors.authCardFill,
    glassCardBorderColor: AppColors.authCardBorder,
    glassCardShadowColor: Color(0x33000000),
  );

  @override
  AppThemeExtension copyWith({
    Gradient? authBackgroundGradient,
    Color? glassCardColor,
    Color? glassCardBorderColor,
    Color? glassCardShadowColor,
  }) {
    return AppThemeExtension(
      authBackgroundGradient:
          authBackgroundGradient ?? this.authBackgroundGradient,
      glassCardColor: glassCardColor ?? this.glassCardColor,
      glassCardBorderColor: glassCardBorderColor ?? this.glassCardBorderColor,
      glassCardShadowColor: glassCardShadowColor ?? this.glassCardShadowColor,
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      authBackgroundGradient: LinearGradient.lerp(
            authBackgroundGradient as LinearGradient,
            other.authBackgroundGradient as LinearGradient,
            t,
          ) ??
          authBackgroundGradient,
      glassCardColor: Color.lerp(glassCardColor, other.glassCardColor, t)!,
      glassCardBorderColor:
          Color.lerp(glassCardBorderColor, other.glassCardBorderColor, t)!,
      glassCardShadowColor:
          Color.lerp(glassCardShadowColor, other.glassCardShadowColor, t)!,
    );
  }
}

extension AppThemeExtensionContext on BuildContext {
  AppThemeExtension get appExtras =>
      Theme.of(this).extension<AppThemeExtension>()!;
}
