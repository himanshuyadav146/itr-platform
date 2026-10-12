import 'package:flutter/material.dart';

/// Design tokens for the tax_client app.
/// Figma source: https://www.figma.com/design/7PMVY5IZeTIPhFazfBGoY7/tax_app
/// When Figma MCP access is restored, sync values from Figma variables and update this file.
class AppColors {
  AppColors._();

  // Brand — navy (auth/splash; aligned with native splash #1E1E2C)
  static const brandNavy = Color(0xFF1E1E2C);
  static const brandNavyLight = Color(0xFF2D2D44);
  static const brandNavyMuted = Color(0xFF3D3D5C);

  // Brand — accent
  static const primary = Color(0xFF448AFF); // Material blueAccent; used on auth CTAs
  static const primaryDark = Color(0xFF2962FF);
  static const secondary = Color(0xFFFF7D2E);

  // Auth refactor (latest premium login treatment)
  static const authBackground = Color(0xFF0B1326);
  static const authCardSurface = Color(0x99131B2E);
  static const authHeading = Color(0xFFDAE2FD);
  static const authMuted = Color(0xFFBBCABF);
  static const authMutedSoft = Color(0x66BBCABF);
  static const authInputFill = Color(0xFFFFFFFF);
  static const authInputText = Color(0xFF0B1326);
  static const authInputBorder = Color(0xFF6B7280);
  static const authMint = Color(0xFF4EDEA3);
  static const authMintDark = Color(0xFF10B981);
  static const authAmber = Color(0xFFFFB95F);
  static const authButtonText = Color(0xFF003824);
  static const authCheckboxFill = Color(0xFF2D3449);
  static const authCheckboxBorder = Color(0xFF3C4A42);
  static const authGlowMint = Color(0x0D4EDEA3);
  static const authGlowAmber = Color(0x0DFFB95F);
  static const authPlaceholder = Color(0x4DBBCABF);

  // Surfaces — light mode (main app)
  static const background = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF0F3F9);

  // Surfaces — dark mode (Figma tax_app: navy shell + elevated cards)
  static const backgroundDark = brandNavy; // #1E1E2C scaffold
  static const surfaceDark = brandNavyLight; // #2D2D44 elevated cards

  /// Bottom tab bar shell (Figma Welcome Dashboard — `Nav` gradient).
  static const navBarBackground = Color(0xFF0B1326);
  static const navBarGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.45, 1.0],
    colors: [
      Color(0x000B1326),
      Color(0xCC0B1326),
      navBarBackground,
    ],
  );
  static const surfaceVariantDark = brandNavyMuted; // #3D3D5C inputs / chips

  // Text
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textOnDark = Color(0xFFFFFFFF);
  static const textOnDarkMuted = Color(0xB3FFFFFF); // white70
  static const textOnDarkSubtle = Color(0x4DFFFFFF); // white30

  // Borders & dividers
  static const border = Color(0xFFE2E8F0);
  static const borderDark = Color(0xFF374151);
  static const borderOnDark = Color(0x1AFFFFFF); // white10

  // Auth glass card
  static const authCardFill = authCardSurface;
  static const authCardBorder = Color(0x0DFFFFFF); // white @ 5%

  // Status
  static const success = Color(0xFF22C55E);
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF3B82F6);

  // Semantic status backgrounds (orders, badges)
  static const successSurface = Color(0xFFDCFCE7);
  static const warningSurface = Color(0xFFFFEDD5);
  static const errorSurface = Color(0xFFFEE2E2);

  /// Auth screens gradient (login, signup, forgot password).
  static const authGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [authBackground, authBackground],
  );

  /// Home / More profile card gradient.
  static LinearGradient profileCardGradient(ColorScheme scheme) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          scheme.primary,
          scheme.primary.withValues(alpha: 0.75),
        ],
      );
}
