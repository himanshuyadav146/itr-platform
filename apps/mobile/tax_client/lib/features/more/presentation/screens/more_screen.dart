import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tax_client/core/common/widgets/bottom_nav_bar.dart';
import 'package:tax_client/core/common/widgets/core_scaffold.dart';
import 'package:tax_client/core/common/widgets/custom_card.dart';
import 'package:tax_client/core/common/widgets/primary_button.dart';
import 'package:tax_client/core/config/strings/app_strings.dart';
import 'package:tax_client/core/config/theme/app_colors.dart';
import 'package:tax_client/core/config/theme/app_spacing.dart';
import 'package:tax_client/core/network/token_storage.dart';
import 'package:tax_client/core/utils/error_handler.dart';
import 'package:tax_client/core/utils/external_link_launcher.dart';
import 'package:tax_client/features/auth/presentation/providers/auth_provider.dart';
import 'package:tax_client/features/auth/presentation/providers/auth_state.dart';
import 'package:tax_client/features/auth/presentation/providers/user_provider.dart';

import '../../../../core/constant/api_constants.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.finapp.com';
  static const String appStoreUrl = 'https://apps.apple.com/app/id0000000000';

  Future<void> _shareApp() async {
    final url = Platform.isIOS ? appStoreUrl : playStoreUrl;
    await Share.share('Try Tax Client: $url');
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final tokenStorage = ref.read(tokenStorageProvider);
    await tokenStorage.clearAllPreferences();
    if (context.mounted) {
      context.go('/login');
    }
  }

  Future<void> _showDeleteSuccessBottomSheet(
    BuildContext context,
    WidgetRef ref,
    String message,
  ) async {
    final theme = Theme.of(context);

    await showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.authBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => PopScope(
        canPop: false,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.flag_rounded,
                    color: AppColors.error,
                    size: 42,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Account Deleted',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: AppColors.authHeading,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Text(
                    message,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.authHeading,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: PrimaryButton(
                    text: 'OK',
                    onPressed: () {
                      Navigator.pop(context);
                      _logout(context, ref);
                    },
                    borderRadius: AppSpacing.radiusPill,
                    foregroundColor: AppColors.authButtonText,
                    gradient: const LinearGradient(
                      colors: [AppColors.authMint, AppColors.authMintDark],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final theme = Theme.of(context);
    final userAsync = ref.read(userProvider);

    final userId = userAsync.maybeWhen(
      data: (user) => user?.id,
      orElse: () => null,
    );

    if (userId == null) {
      ErrorHandler.showError(
        context,
        'User information not found. Please try again.',
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.authBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.confirmDeleteAccountTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.authHeading,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                AppStrings.confirmDeleteAccountWarning,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.authHeading,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLg,
                          ),
                          side: const BorderSide(color: AppColors.borderOnDark),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: PrimaryButton(
                        text: 'Delete Account',
                        onPressed: () async {
                          Navigator.pop(context);
                          await ref
                              .read(authViewModelProvider.notifier)
                              .deleteAccount(userId);
                        },
                        color: AppColors.error,
                        foregroundColor: AppColors.textOnDark,
                        borderRadius: AppSpacing.radiusLg,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      if (next is AuthError && previous is AuthLoading) {
        ErrorHandler.showError(context, next.message);
      } else if (next is AuthDeleteSuccess) {
        _showDeleteSuccessBottomSheet(context, ref, next.message);
      } else if (next is AuthInitial && previous is AuthLoading) {
        context.go('/login');
      }
    });

    return CoreScaffold(
      includeAppBar: false,
      backgroundColor: AppColors.authBackground,
      useScrollView: true,
      centered: true,
      useResponsiveMaxWidth: true,
      maxContentWidth: 560,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      bottomNavigationBar: const BottomNavBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MoreHeader(
            onBack: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          userAsync.when(
            data: (user) => _MoreProfileCard(
              name: (user?.name != null && user!.name.trim().isNotEmpty)
                  ? user.name
                  : 'Guest User',
              email: user?.email ?? '',
              mobile: user?.mobile ?? '',
            ),
            loading: () => const _MoreLoadingCard(),
            error: (err, _) =>
                _MoreErrorCard(message: 'Error loading user: $err'),
          ),
          const SizedBox(height: AppSpacing.xl),
          _MoreSectionTitle(
            title: 'Support & information',
            subtitle: 'Quick links for app details, policies, and support.',
          ),
          const SizedBox(height: AppSpacing.md),
          _MoreTile(
            icon: Icons.share_rounded,
            label: AppStrings.shareApp,
            subtitle: 'Send the app link to friends or family.',
            onTap: _shareApp,
          ),
          _MoreTile(
            icon: Icons.info_outline_rounded,
            label: AppStrings.aboutUs,
            subtitle: 'Learn more about the ITR platform and team.',
            onTap: () =>
                ExternalLinkLauncher.openPage(context, ApiConstants.itrAboutUS),
          ),
          _MoreTile(
            icon: Icons.privacy_tip_outlined,
            label: AppStrings.privacyPolicy,
            subtitle: 'Read how your information is protected.',
            onTap: () => ExternalLinkLauncher.openPage(
              context,
              ApiConstants.itrPrivacyPolicy,
            ),
          ),
          _MoreTile(
            icon: Icons.support_agent_rounded,
            label: AppStrings.contactSupport,
            subtitle: 'Reach the team if you need help with filing.',
            onTap: () => ExternalLinkLauncher.openPage(
              context,
              ApiConstants.itrContactUS,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _MoreSectionTitle(
            title: 'Account actions',
            subtitle: 'Manage your session and account-level preferences.',
          ),
          const SizedBox(height: AppSpacing.md),
          _MoreTile(
            icon: Icons.person_remove_rounded,
            label: AppStrings.deleteAccountPermanently,
            subtitle: 'Permanently remove your account and associated data.',
            danger: true,
            onTap: () => _showDeleteConfirmation(context, ref),
          ),
          _MoreTile(
            icon: Icons.logout_rounded,
            label: AppStrings.logout,
            subtitle: 'Sign out from this device.',
            danger: true,
            onTap: () => _logout(context, ref),
          ),
          const SizedBox(height: 88),
        ],
      ),
    );
  }
}

class _MoreHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _MoreHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surfaceVariantDark,
            foregroundColor: AppColors.authHeading,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.more,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.authHeading,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Manage support links, account settings, and session actions.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.authMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MoreProfileCard extends StatelessWidget {
  final String name;
  final String email;
  final String mobile;

  const _MoreProfileCard({
    required this.name,
    required this.email,
    required this.mobile,
  });

  String _initials(String value) {
    final parts = value
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'GU';
    if (parts.length == 1) {
      final single = parts.first;
      return single.substring(0, single.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
        gradient: AppColors.profileCardGradient(theme.colorScheme),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _initials(name),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.textOnDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.textOnDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (email.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    email,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textOnDarkMuted,
                    ),
                  ),
                ],
                if (mobile.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    mobile,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textOnDarkMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreLoadingCard extends StatelessWidget {
  const _MoreLoadingCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomCard(
      backgroundColor: AppColors.authCardSurface,
      border: Border.all(color: AppColors.authCardBorder),
      child: Column(
        children: [
          const CircularProgressIndicator(color: AppColors.authMint),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Loading your profile...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.authHeading,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreErrorCard extends StatelessWidget {
  final String message;

  const _MoreErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomCard(
      backgroundColor: const Color(0x08FFFFFF),
      border: Border.all(color: AppColors.borderOnDark),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.authMuted,
          height: 1.45,
        ),
      ),
    );
  }
}

class _MoreSectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _MoreSectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppColors.authHeading,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.authMuted,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _MoreTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  const _MoreTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = danger ? AppColors.error : AppColors.authMint;

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.zero,
      backgroundColor: const Color(0x08FFFFFF),
      border: Border.all(color: AppColors.borderOnDark),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Icon(icon, color: accent),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: danger
                              ? AppColors.error
                              : AppColors.authHeading,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.authMuted,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: danger ? AppColors.error : AppColors.authMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
