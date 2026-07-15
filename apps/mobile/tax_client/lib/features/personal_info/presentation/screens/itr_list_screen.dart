import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tax_client/core/common/enums/journey_type.dart';
import 'package:tax_client/core/common/widgets/core_scaffold.dart';
import 'package:tax_client/core/common/widgets/custom_card.dart';
import 'package:tax_client/core/common/widgets/primary_button.dart';
import 'package:tax_client/core/config/strings/app_strings.dart';
import 'package:tax_client/core/config/theme/app_colors.dart';
import 'package:tax_client/core/config/theme/app_spacing.dart';
import 'package:tax_client/core/network/token_storage.dart';
import 'package:tax_client/features/packages/data/models/package_model.dart';
import 'package:tax_client/features/packages/presentation/providers/package_provider.dart';
import 'package:tax_client/features/packages/presentation/widgets/package_bottom_sheet.dart';
import 'package:tax_client/features/personal_info/data/models/itr_personal_detail_model.dart';
import 'package:tax_client/features/personal_info/presentation/providers/personal_info_provider.dart';
import 'package:tax_client/features/personal_info/presentation/providers/personal_info_state.dart';

class ItrListScreen extends ConsumerStatefulWidget {
  const ItrListScreen({super.key});

  @override
  ConsumerState<ItrListScreen> createState() => _ItrListScreenState();
}

class _ItrListScreenState extends ConsumerState<ItrListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentState = ref.read(personalInfoViewModelProvider);
      if (currentState is! ItrListLoaded && currentState is! ItrListLoading) {
        _loadItrList();
      }
    });
  }

  Future<void> _loadItrList() async {
    final tokenStorage = ref.read(tokenStorageProvider);
    final userId = await tokenStorage.getUserId();

    if (userId != null && userId.isNotEmpty) {
      ref.read(personalInfoViewModelProvider.notifier).getItrByUser(userId);
    }
  }

  Future<void> _handleContinue(ItrPersonalDetailModel itrItem) async {
    ref.read(journeyTypeProvider.notifier).state = JourneyType.ITR;
    final selectedPackage = await _ensurePackageSelected(itrItem: itrItem);
    if (selectedPackage == null || !mounted) {
      return;
    }

    final tokenStorage = ref.read(tokenStorageProvider);
    await tokenStorage.savePanNumber(itrItem.panNumber);

    if (mounted) {
      context.push('/personal_info', extra: itrItem);
    }
  }

  Future<void> _handleAddNewItr() async {
    ref.read(journeyTypeProvider.notifier).state = JourneyType.ITR;
    final selectedPackage = await _ensurePackageSelected();
    if (selectedPackage == null || !mounted) {
      return;
    }

    context.push('/personal_info');
  }

  Future<PackageModel?> _ensurePackageSelected({
    ItrPersonalDetailModel? itrItem,
  }) async {
    // Prefill selection from this ITR (if any) so the sheet highlights it.
    if (itrItem != null) {
      await _syncSelectedPackageFromItr(itrItem);
    }

    if (!mounted) {
      return null;
    }

    // Always show package selection so the user can confirm or change package.
    return showPackageBottomSheet(context, ref);
  }

  Future<PackageModel?> _syncSelectedPackageFromItr(
    ItrPersonalDetailModel itrItem,
  ) async {
    final packageId = itrItem.packageId;
    if (packageId == null) {
      return null;
    }

    var packagesState = ref.read(packagesProvider);
    if (!packagesState.hasValue && !packagesState.isLoading) {
      await ref.read(packagesProvider.notifier).getPackages();
      packagesState = ref.read(packagesProvider);
    }

    final packages = packagesState.valueOrNull;
    if (packages == null) {
      return null;
    }

    PackageModel? matchedPackage;
    for (final package in packages) {
      if (package.id == packageId.toString()) {
        matchedPackage = package;
        break;
      }
    }

    if (matchedPackage != null) {
      ref.read(selectedPackageProvider.notifier).state = matchedPackage;
    }

    return matchedPackage;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(personalInfoViewModelProvider);
    final recordsCount = state is ItrListLoaded ? state.itrList.length : null;

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
        112,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleAddNewItr,
        tooltip: 'Add New ITR',
        backgroundColor: AppColors.authMint,
        foregroundColor: AppColors.authButtonText,
        elevation: 8,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add New ITR',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ItrListHeader(),
          const SizedBox(height: AppSpacing.xl),
          _ItrListHeroCard(recordsCount: recordsCount),
          const SizedBox(height: AppSpacing.xl),
          _buildBody(context, state),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, PersonalInfoState state) {
    if (state is ItrListLoading) {
      return const _ItrListLoadingState();
    }

    if (state is PersonalInfoSuccess || state is PersonalInfoLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadItrList();
      });
      return const _ItrListLoadingState();
    }

    if (state is ItrListError) {
      return _ItrListMessageCard(
        icon: Icons.error_outline_rounded,
        iconColor: AppColors.authAmber,
        title: 'Unable to load records',
        description: state.message,
        child: PrimaryButton(
          text: AppStrings.retry.toUpperCase(),
          onPressed: _loadItrList,
          borderRadius: AppSpacing.radiusPill,
          foregroundColor: AppColors.authButtonText,
          gradient: const LinearGradient(
            colors: [AppColors.authMint, AppColors.authMintDark],
          ),
        ),
      );
    }

    if (state is ItrListLoaded && state.itrList.isEmpty) {
      return _ItrListMessageCard(
        icon: Icons.inbox_outlined,
        iconColor: AppColors.authMuted,
        title: AppStrings.noItrRecordsFound,
        description:
            'Start by creating your first return record and we will carry you through the filing flow.',
        child: PrimaryButton(
          text: AppStrings.fileNewItr.toUpperCase(),
          onPressed: _handleAddNewItr,
          borderRadius: AppSpacing.radiusPill,
          foregroundColor: AppColors.authButtonText,
          gradient: const LinearGradient(
            colors: [AppColors.authMint, AppColors.authMintDark],
          ),
        ),
      );
    }

    if (state is ItrListLoaded) {
      return Column(
        children: [
          for (var index = 0; index < state.itrList.length; index++) ...[
            _ItrListItem(
              itrItem: state.itrList[index] as ItrPersonalDetailModel,
              onContinue: () => _handleContinue(
                state.itrList[index] as ItrPersonalDetailModel,
              ),
            ),
            if (index != state.itrList.length - 1)
              const SizedBox(height: AppSpacing.md),
          ],
        ],
      );
    }

    return const _ItrListLoadingState();
  }
}

class _ItrListHeader extends StatelessWidget {
  const _ItrListHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
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
                AppStrings.myItrRecords,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.authHeading,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Select an existing return or create a new one.',
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

class _ItrListHeroCard extends StatelessWidget {
  final int? recordsCount;

  const _ItrListHeroCard({required this.recordsCount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final countLabel = recordsCount == null
        ? 'Loading records'
        : recordsCount == 0
        ? 'No saved returns yet'
        : '$recordsCount saved return${recordsCount == 1 ? '' : 's'}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.authCardSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
        border: Border.all(color: AppColors.authCardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 28,
            spreadRadius: -10,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Continue with your saved filings',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppColors.authHeading,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Review previous ITR records, reopen one to continue, or start a fresh filing whenever you need.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.authMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _ItrListInfoChip(
                icon: Icons.folder_copy_outlined,
                label: countLabel,
              ),
              const _ItrListInfoChip(
                icon: Icons.verified_user_outlined,
                label: 'Your previous data stays reusable',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ItrListInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ItrListInfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantDark.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.authMint),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.authHeading,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItrListLoadingState extends StatelessWidget {
  const _ItrListLoadingState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.authMint),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Loading your saved ITR records...',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.authHeading,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Preparing the returns you can continue from.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.authMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItrListMessageCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final Widget child;

  const _ItrListMessageCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: const Color(0x08FFFFFF),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: AppColors.borderOnDark),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 30),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.authHeading,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.authMuted,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            child,
          ],
        ),
      ),
    );
  }
}

class _ItrListItem extends StatelessWidget {
  final ItrPersonalDetailModel itrItem;
  final VoidCallback onContinue;

  const _ItrListItem({required this.itrItem, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fullName =
        '${itrItem.firstName} ${itrItem.middleName ?? ''} ${itrItem.lastName}'
            .trim();
    final initials = _buildInitials(fullName);
    final rawStatus = itrItem.statusDisplayText?.trim();
    final statusText = (rawStatus == null || rawStatus.isEmpty)
        ? 'Ready to continue'
        : rawStatus;

    return CustomCard(
      margin: EdgeInsets.zero,
      backgroundColor: const Color(0x08FFFFFF),
      border: Border.all(color: AppColors.borderOnDark),
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          onTap: onContinue,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.authMint, AppColors.authMintDark],
                        ),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.authButtonText,
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
                            fullName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: AppColors.authHeading,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              _ItrMetaChip(
                                label: itrItem.financialYear,
                                icon: Icons.calendar_today_outlined,
                                accent: AppColors.authMint,
                              ),
                              _ItrMetaChip(
                                label: itrItem.packageName ?? 'Package pending',
                                icon: Icons.inventory_2_outlined,
                                accent: AppColors.authAmber,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 18,
                      color: AppColors.authMuted,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariantDark.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Text(
                    statusText,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.authMuted,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _InfoCard(
                        icon: Icons.phone_iphone_rounded,
                        label: AppStrings.mobile,
                        value: itrItem.mobileNumber,
                        color: AppColors.authMint,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _InfoCard(
                        icon: Icons.badge_outlined,
                        label: AppStrings.pan,
                        value: itrItem.panNumber,
                        color: AppColors.authHeading,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Open this record and continue with saved details.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.authMuted,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      AppStrings.continue_,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.authMint,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _buildInitials(String fullName) {
    final parts = fullName
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'IT';
    if (parts.length == 1) {
      final single = parts.first;
      return single.substring(0, single.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _ItrMetaChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;

  const _ItrMetaChip({
    required this.label,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.authHeading,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.authMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.authHeading,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
