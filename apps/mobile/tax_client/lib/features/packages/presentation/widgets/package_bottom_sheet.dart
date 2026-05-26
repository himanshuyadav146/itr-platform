import 'package:flutter/material.dart';
import 'package:tax_client/features/packages/data/models/package_model.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tax_client/core/common/widgets/primary_button.dart';
import 'package:tax_client/core/config/theme/app_colors.dart';
import 'package:tax_client/core/config/theme/app_spacing.dart';
import 'package:tax_client/features/packages/presentation/providers/package_provider.dart';

Future<PackageModel?> showPackageBottomSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final result = await Navigator.of(context).push<PackageModel>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => const PackageSelectionScreen(),
    ),
  );

  if (result != null) {
    ref.read(selectedPackageProvider.notifier).state = result;
  }

  return result;
}

class PackageSelectionScreen extends ConsumerStatefulWidget {
  const PackageSelectionScreen({super.key});

  @override
  ConsumerState<PackageSelectionScreen> createState() =>
      _PackageSelectionScreenState();
}

class _PackageSelectionScreenState
    extends ConsumerState<PackageSelectionScreen> {
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final packagesState = ref.read(packagesProvider);
      if (!packagesState.hasValue && !packagesState.isLoading) {
        ref.read(packagesProvider.notifier).getPackages();
      }
    });
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'business_center_outlined':
        return Icons.business_center_outlined;
      case 'trending_up':
        return Icons.trending_up;
      case 'apartment':
        return Icons.apartment;
      case 'domain':
        return Icons.domain;
      case 'flight_takeoff':
        return Icons.flight_takeoff;
      case 'business':
        return Icons.business;
      case 'verified_user':
        return Icons.verified_user;
      default:
        return Icons.card_giftcard;
    }
  }

  Color _getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'blue':
        return AppColors.primary;
      case 'green':
        return AppColors.authMint;
      case 'orange':
        return AppColors.authAmber;
      case 'purple':
        return const Color(0xFF9B8AFB);
      case 'teal':
        return const Color(0xFF4FD1C5);
      case 'indigo':
        return const Color(0xFF7C8BFF);
      case 'cyan':
        return const Color(0xFF56CCF2);
      default:
        return AppColors.authMint;
    }
  }

  PackageModel? _resolveSelectedPackage(List<PackageModel> packages) {
    if (_selectedIndex != null &&
        _selectedIndex! >= 0 &&
        _selectedIndex! < packages.length) {
      return packages[_selectedIndex!];
    }

    final existingSelection = ref.read(selectedPackageProvider);
    if (existingSelection == null) {
      return null;
    }

    final matchIndex =
        packages.indexWhere((package) => package.id == existingSelection.id);
    if (matchIndex == -1) {
      return null;
    }

    return packages[matchIndex];
  }

  String _packageDescriptionHtml(String description) {
    if (description.contains(RegExp(r'<[^>]+>'))) {
      return description;
    }

    final paragraphs = description
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) => '<p>$line</p>')
        .join();

    return paragraphs.isEmpty ? '<p>$description</p>' : paragraphs;
  }

  @override
  Widget build(BuildContext context) {
    final packagesAsync = ref.watch(packagesProvider);

    return Scaffold(
      backgroundColor: AppColors.authBackground,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.authBackground, Color(0xFF11182A)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _PackageSelectionHeader(
                onClose: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: packagesAsync.when(
                  data: (packages) {
                    final selectedPackage = _resolveSelectedPackage(packages);

                    return Column(
                      children: [
                        Expanded(
                          child: CustomScrollView(
                            slivers: [
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.lg,
                                  AppSpacing.sm,
                                  AppSpacing.lg,
                                  0,
                                ),
                                sliver: SliverToBoxAdapter(
                                  child: _PackageIntroCard(
                                    packageCount: packages.length,
                                  ),
                                ),
                              ),
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.lg,
                                  AppSpacing.lg,
                                  AppSpacing.lg,
                                  0,
                                ),
                                sliver: SliverList.separated(
                                  itemCount: packages.length,
                                  itemBuilder: (context, index) {
                                    final package = packages[index];
                                    final selectedId = selectedPackage?.id;
                                    final isSelected = selectedId == package.id;

                                    return _PackagePlanCard(
                                      package: package,
                                      accent: _getColorFromString(package.color),
                                      icon: _getIconFromString(package.icon),
                                      isSelected: isSelected,
                                      descriptionHtml: _packageDescriptionHtml(
                                        package.description,
                                      ),
                                      onTap: () {
                                        setState(() {
                                          _selectedIndex = index;
                                        });
                                      },
                                    );
                                  },
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: AppSpacing.md),
                                ),
                              ),
                              const SliverPadding(
                                padding: EdgeInsets.fromLTRB(
                                  AppSpacing.lg,
                                  AppSpacing.lg,
                                  AppSpacing.lg,
                                  AppSpacing.xxxl,
                                ),
                                sliver: SliverToBoxAdapter(
                                  child: _PricingNoteCard(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _PackageSelectionFooter(
                          selectedPackage: selectedPackage,
                          onContinue: selectedPackage == null
                              ? null
                              : () => Navigator.of(context).pop(selectedPackage),
                        ),
                      ],
                    );
                  },
                  loading: () => const _PackageSelectionLoadingState(),
                  error: (error, stackTrace) => _PackageSelectionErrorState(
                    message: error.toString(),
                    onRetry: () =>
                        ref.read(packagesProvider.notifier).getPackages(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PackageSelectionHeader extends StatelessWidget {
  final VoidCallback onClose;

  const _PackageSelectionHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
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
                  'Package Selection',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.authHeading,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Choose the plan that fits your filing needs.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.authMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageIntroCard extends StatelessWidget {
  final int packageCount;

  const _PackageIntroCard({required this.packageCount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.authCardSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
        border: Border.all(color: AppColors.authCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pick the right package for your return',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppColors.authHeading,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Compare features, review pricing, and continue once you are comfortable with the plan.',
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
              _InfoChip(
                icon: Icons.layers_outlined,
                label: '$packageCount plans available',
              ),
              const _InfoChip(
                icon: Icons.lock_outline_rounded,
                label: 'Secure checkout later',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PackagePlanCard extends StatelessWidget {
  final PackageModel package;
  final Color accent;
  final IconData icon;
  final bool isSelected;
  final String descriptionHtml;
  final VoidCallback onTap;

  const _PackagePlanCard({
    required this.package,
    required this.accent,
    required this.icon,
    required this.isSelected,
    required this.descriptionHtml,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
            border: Border.all(
              color: isSelected
                  ? accent.withValues(alpha: 0.95)
                  : AppColors.borderOnDark,
              width: isSelected ? 1.5 : 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isSelected
                  ? [
                      accent.withValues(alpha: 0.18),
                      AppColors.authCardSurface,
                    ]
                  : [
                      const Color(0x14131B2E),
                      const Color(0x24131B2E),
                    ],
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? accent.withValues(alpha: 0.18)
                    : Colors.black.withValues(alpha: 0.12),
                blurRadius: isSelected ? 28 : 18,
                offset: const Offset(0, 14),
              ),
            ],
          ),
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
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                    child: Icon(icon, color: accent, size: 26),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          package.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: AppColors.authHeading,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (package.turnover != null &&
                            package.turnover!.trim().isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.sm),
                          _TurnoverChip(
                            label: 'Turnover: ${package.turnover}',
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'From',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.authMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        package.price,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Html(
                data: descriptionHtml,
                style: {
                  'html': Style(
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                  ),
                  'body': Style(
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                    color: AppColors.authMuted,
                    fontSize:
                        FontSize(theme.textTheme.bodyMedium?.fontSize ?? 14),
                    lineHeight: const LineHeight(1.5),
                  ),
                  'p': Style(
                    margin: Margins.only(bottom: AppSpacing.sm),
                  ),
                  'ul': Style(
                    margin: Margins.zero,
                    padding: HtmlPaddings.only(left: AppSpacing.md),
                  ),
                  'li': Style(
                    color: AppColors.authMuted,
                    margin: Margins.only(bottom: AppSpacing.xs),
                  ),
                  'strong': Style(
                    color: AppColors.authHeading,
                    fontWeight: FontWeight.w700,
                  ),
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accent.withValues(alpha: 0.16)
                          : AppColors.surfaceVariantDark.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    ),
                    child: Text(
                      isSelected ? 'Selected plan' : 'Tap to select',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: isSelected ? accent : AppColors.authMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.arrow_forward_rounded,
                    color: isSelected ? accent : AppColors.authMutedSoft,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PackageSelectionFooter extends StatelessWidget {
  final PackageModel? selectedPackage;
  final VoidCallback? onContinue;

  const _PackageSelectionFooter({
    required this.selectedPackage,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xF21A2236),
        border: Border(
          top: BorderSide(color: AppColors.borderOnDark),
        ),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              selectedPackage?.name ?? 'Select a package to continue',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.authHeading,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              selectedPackage == null
                  ? 'You can compare plans first and continue once one is selected.'
                  : 'Starting at ${selectedPackage!.price}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.authMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              text: selectedPackage == null ? 'SELECT A PACKAGE' : 'CONTINUE',
              onPressed: onContinue,
              minHeight: 56,
              borderRadius: AppSpacing.radiusPill,
              foregroundColor: AppColors.authButtonText,
              textStyle: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [AppColors.authMint, AppColors.authMintDark],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.authMint.withValues(alpha: 0.22),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PricingNoteCard extends StatelessWidget {
  const _PricingNoteCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.authMint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.authMint.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.authMint,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'All listed prices are starting prices and may vary depending on service complexity, additional requirements, or add-on requests.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.authMuted,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageSelectionLoadingState extends StatelessWidget {
  const _PackageSelectionLoadingState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.authMint),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Loading available packages...',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.authHeading,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Fetching the latest plans for your filing journey.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.authMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PackageSelectionErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _PackageSelectionErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.authAmber,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Unable to load packages',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.authHeading,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.authMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              text: 'TRY AGAIN',
              onPressed: onRetry,
              borderRadius: AppSpacing.radiusPill,
              foregroundColor: AppColors.authButtonText,
              textStyle: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              gradient: const LinearGradient(
                colors: [AppColors.authMint, AppColors.authMintDark],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
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
        color: AppColors.surfaceVariantDark.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.authMint, size: 16),
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

class _TurnoverChip extends StatelessWidget {
  final String label;

  const _TurnoverChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.authAmber.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: AppColors.authAmber,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
