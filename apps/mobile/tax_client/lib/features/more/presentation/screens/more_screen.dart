import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:tax_client/core/common/widgets/core_scaffold.dart';
import 'package:tax_client/core/config/strings/app_strings.dart';
import 'package:tax_client/core/common/widgets/bottom_nav_bar.dart';
import 'package:tax_client/core/network/token_storage.dart';
import 'package:tax_client/features/auth/presentation/providers/user_provider.dart';

import 'package:tax_client/features/auth/presentation/providers/auth_provider.dart';
import 'package:tax_client/core/utils/error_handler.dart';
import 'package:tax_client/features/auth/presentation/providers/auth_state.dart';

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

  Future<void> _rateUs(BuildContext context) async {
    final url = Platform.isIOS ? appStoreUrl : playStoreUrl;
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }


  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse(ApiConstants.baseUrl + ApiConstants.itrPrivacyPolicy);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openContactUs() async {
    final uri = Uri.parse(ApiConstants.baseUrl + ApiConstants.itrContactUS);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openAboutUS() async {
    final uri = Uri.parse(ApiConstants.baseUrl + ApiConstants.itrAboutUS);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final tokenStorage = ref.read(tokenStorageProvider);
    await tokenStorage.clearAllPreferences();
    if (context.mounted) {
      context.go('/login');
    }
  }

  Future<void> _showDeleteSuccessBottomSheet(BuildContext context, WidgetRef ref, String message) async {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    await showModalBottomSheet(
      context: context,
      isDismissible: false, // Prevent dismissal by tapping outside
      enableDrag: false, // Prevent dismissal by dragging
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => PopScope(
        canPop: false, // Prevent back button dismissal
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Red flag icon with animation effect
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.red.shade200,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.flag_rounded,
                    color: Colors.red.shade700,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Title
                Text(
                  'Account Deleted',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Success message
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.shade100,
                    ),
                  ),
                  child: Text(
                    message,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.red.shade900,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                
                // OK button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _logout(context, ref);
                    },
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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

  Future<void> _showDeleteConfirmation(BuildContext context, WidgetRef ref) async {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final userAsync = ref.read(userProvider);
    
    final userId = userAsync.maybeWhen(
      data: (user) => user?.id,
      orElse: () => null,
    );

    if (userId == null) {
      ErrorHandler.showError(context, 'User information not found. Please try again.');
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.confirmDeleteAccountTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppStrings.confirmDeleteAccountWarning,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.red.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: scheme.error,
                        foregroundColor: scheme.onError,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        await ref.read(authViewModelProvider.notifier).deleteAccount(userId);
                      },
                      child: const Text('Delete Account'),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final userAsync = ref.watch(userProvider);

    ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      if (next is AuthError) {
        ErrorHandler.showError(context, next.message);
      } else if (next is AuthDeleteSuccess) {
        // Show success message in beautiful bottom sheet
        _showDeleteSuccessBottomSheet(context, ref, next.message);
      } else if (next is AuthInitial && previous is AuthLoading) {
        // If it returns to AuthInitial from loading, it means logout was successful
        // Handling navigation to login
        context.go('/login');
      }
    });

    return CoreScaffold(
      title: AppStrings.more,
      showBackButton: true,
      onBack: () => context.go('/dashboard'),
      useScrollView: true,
      centered: false,
      padding: const EdgeInsets.all(18),
      bottomNavigationBar: const BottomNavBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// User Card Modern
          userAsync.when(
            data: (user) => Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    scheme.primary.withOpacity(0.15),
                    scheme.surfaceContainerHigh,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: scheme.outlineVariant),
              ),
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: scheme.primary.withOpacity(0.20),
                    child: Icon(
                      Icons.person_rounded,
                      size: 34,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (user?.name != null && user!.name.trim().isNotEmpty)
                              ? user.name
                              : 'Guest User',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${user?.email ?? ''}\n${user?.mobile ?? ''}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface.withOpacity(0.7),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error loading user: $err')),
          ),

          const SizedBox(height: 20),

          /// Modern Tiles
          // _MoreTile(
          //   icon: Icons.help_outline_rounded,
          //   label: AppStrings.faqs,
          //   onTap: () {},
          // ),
          _MoreTile(
            icon: Icons.share_rounded,
            label: AppStrings.shareApp,
            onTap: _shareApp,
          ),
          // _MoreTile(
          //   icon: Icons.payment_rounded,
          //   label: AppStrings.customPayment,
          //   onTap: () {},
          // ),
          // _MoreTile(
          //   icon: Icons.star_border_rounded,
          //   label: AppStrings.rateUs,
          //   onTap: () => _rateUs(context),
          // ),
          _MoreTile(
            icon: Icons.info_outline_rounded,
            label: AppStrings.aboutUs,
            onTap: _openAboutUS,
          ),
          _MoreTile(
            icon: Icons.privacy_tip_outlined,
            label: AppStrings.privacyPolicy,
            onTap: _openPrivacyPolicy,
          ),
          _MoreTile(
            icon: Icons.support_agent_rounded,
            label: AppStrings.contactSupport,
            onTap: _openContactUs,
          ),
          _MoreTile(
            icon: Icons.person_remove_rounded,
            label: AppStrings.deleteAccountPermanently,
            danger: true,
            onTap: () => _showDeleteConfirmation(context, ref),
          ),
          _MoreTile(
            icon: Icons.logout_rounded,
            label: AppStrings.logout,
            danger: true,
            onTap: () => _logout(context, ref),
          ),
        ],
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  const _MoreTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: scheme.surfaceContainerLow,
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 28,
                  color: danger ? scheme.error : scheme.primary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: danger ? scheme.error : scheme.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: danger
                      ? scheme.error
                      : scheme.onSurface.withOpacity(0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
