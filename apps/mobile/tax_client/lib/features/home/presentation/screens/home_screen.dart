import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tax_client/core/common/enums/journey_type.dart';
import 'package:tax_client/core/common/widgets/bottom_nav_bar.dart';
import 'package:tax_client/core/common/widgets/core_scaffold.dart';
import 'package:tax_client/core/common/widgets/custom_card.dart';
import 'package:tax_client/core/common/widgets/primary_button.dart';
import 'package:tax_client/core/config/strings/app_strings.dart';
import 'package:tax_client/core/config/theme/app_colors.dart';
import 'package:tax_client/core/config/theme/app_spacing.dart';
import 'package:tax_client/core/constant/api_constants.dart';
import 'package:tax_client/core/network/token_storage.dart';
import 'package:tax_client/core/utils/error_handler.dart';
import 'package:tax_client/features/home/presentation/providers/home_dashboard_provider.dart';
import 'package:tax_client/features/packages/data/models/package_model.dart';
import 'package:tax_client/features/packages/presentation/providers/package_provider.dart';
import 'package:tax_client/features/packages/presentation/widgets/package_bottom_sheet.dart';
import 'package:tax_client/features/personal_info/presentation/providers/personal_info_provider.dart';
import 'package:tax_client/features/personal_info/presentation/providers/personal_info_state.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(homeDashboardSnapshotProvider);
      ref.read(packagesProvider.notifier).getPackages();
    });
  }

  Future<void> _handleFileItr(
    BuildContext context,
    JourneyType journeyType,
  ) async {
    ref.read(journeyTypeProvider.notifier).state = journeyType;

    final tokenStorage = ref.read(tokenStorageProvider);
    final userId = await tokenStorage.getUserId();

    if (userId == null || userId.isEmpty) {
      if (context.mounted) {
        ErrorHandler.showError(context, AppStrings.userIdNotFound);
      }
      return;
    }

    PackageModel? selectedPackage = ref.read(selectedPackageProvider);

    if (journeyType == JourneyType.EVerify) {
      final packagesState = ref.read(packagesProvider);
      if (packagesState.hasValue && packagesState.value != null) {
        try {
          selectedPackage =
              packagesState.value!.firstWhere((pkg) => pkg.id == "7");
        } catch (_) {
          selectedPackage = null;
        }
      }
    }

    if (selectedPackage == null) {
      if (!context.mounted) return;
      selectedPackage = await showPackageBottomSheet(context, ref);
    }

    if (selectedPackage == null) {
      return;
    }

    ref.read(selectedPackageProvider.notifier).state = selectedPackage;

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    await ref.read(personalInfoViewModelProvider.notifier).getItrByUser(userId);

    if (context.mounted) {
      Navigator.of(context).pop();
    }

    final state = ref.read(personalInfoViewModelProvider);

    if (!context.mounted) return;

    if (state is ItrListLoaded) {
      if (state.count == 0) {
        context.push('/personal_info');
      } else {
        context.push('/itr_list');
      }
    } else if (state is ItrListError) {
      ErrorHandler.showError(context, state.message);
    }
  }

  Future<void> _openContactUs() async {
    final uri = Uri.parse(ApiConstants.baseUrl + ApiConstants.itrContactUS);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _openOrders(BuildContext context) {
    context.go('/orders');
  }

  void _openStatus(BuildContext context, HomeDashboardSnapshot snapshot) {
    final activeDraft = snapshot.activeDraft;
    if (activeDraft != null) {
      context.push('/status', extra: activeDraft);
      return;
    }

    context.go('/orders');
  }

  void _openDocuments(
    BuildContext context,
    HomeDashboardSnapshot snapshot,
    AsyncValue<List<PackageModel>> packagesAsync,
  ) {
    _syncSelectedPackage(snapshot, packagesAsync);
    context.push('/document_upload');
  }

  void _syncSelectedPackage(
    HomeDashboardSnapshot snapshot,
    AsyncValue<List<PackageModel>> packagesAsync,
  ) {
    final currentSelection = ref.read(selectedPackageProvider);
    if (currentSelection != null) {
      return;
    }

    final packageId = snapshot.activeDraft?.packageId;
    final packages = packagesAsync.valueOrNull;
    if (packageId == null || packages == null) {
      return;
    }

    for (final package in packages) {
      if (package.id == packageId.toString()) {
        ref.read(selectedPackageProvider.notifier).state = package;
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final packagesAsync = ref.watch(packagesProvider);
    final packagesCount = packagesAsync.maybeWhen(
      data: (packages) => packages.length,
      orElse: () => null,
    );
    final selectedPackage = ref.watch(selectedPackageProvider);
    final dashboardAsync = ref.watch(homeDashboardSnapshotProvider);

    final setupCards = [
      _SetupCardData(
        title: 'Complete Profile',
        description:
            'Start your filing journey by entering your personal and tax details.',
        icon: Icons.person_outline_rounded,
        accent: AppColors.authMint,
        progress: 0.35,
        actionLabel: 'Start Filing',
        onTap: () async => _handleFileItr(context, JourneyType.ITR),
      ),
      _SetupCardData(
        title: 'E-Verify Return',
        description:
            'Fast-track e-verification for your return using the existing secure flow.',
        icon: Icons.verified_user_outlined,
        accent: AppColors.authAmber,
        progress: 0.15,
        actionLabel: 'Verify Now',
        onTap: () async => _handleFileItr(context, JourneyType.EVerify),
      ),
      _SetupCardData(
        title: 'Explore Packages',
        description: packagesCount == null
            ? 'Choose from available filing plans tailored to your needs.'
            : '$packagesCount filing plans are available for your next return.',
        icon: Icons.inventory_2_outlined,
        accent: AppColors.authHeading,
        progress: packagesCount == null ? 0.2 : 0.8,
        actionLabel: 'Pick a Package',
        onTap: () async => showPackageBottomSheet(context, ref),
      ),
    ];

    final whyCards = const [
      _WhyCardData(
        title: 'Expert Assistance',
        description:
            'Direct access to experienced tax experts who help you file with confidence.',
        icon: Icons.support_agent_rounded,
        accent: AppColors.authMint,
      ),
      _WhyCardData(
        title: 'Max Refund',
        description:
            'Structured filing guidance helps reduce mistakes and surface eligible deductions.',
        icon: Icons.savings_outlined,
        accent: AppColors.authAmber,
      ),
      _WhyCardData(
        title: 'Secure & Private',
        description:
            'Your financial details and uploaded documents stay protected through every step.',
        icon: Icons.lock_outline_rounded,
        accent: AppColors.authHeading,
      ),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        SystemNavigator.pop();
      },
      child: CoreScaffold(
        includeAppBar: false,
        includeDrawer: false,
        useScrollView: true,
        centered: false,
        padding: EdgeInsets.zero,
        body: dashboardAsync.when(
          loading: () => Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              96,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HomeTopBar(
                  title: selectedPackage == null
                      ? 'Welcome to FinApp'
                      : 'Preparing your workspace',
                  subtitle: selectedPackage == null
                      ? 'Setting up your dashboard...'
                      : 'Loading your latest filing data.',
                  packagesCount: packagesCount,
                  onPackagesTap: () => showPackageBottomSheet(context, ref),
                ),
                const SizedBox(height: AppSpacing.xxl),
                const _DashboardLoadingState(),
              ],
            ),
          ),
          error: (error, stackTrace) => Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              96,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HomeTopBar(
                  title: 'Welcome to FinApp',
                  subtitle: 'Your dashboard is temporarily unavailable.',
                  packagesCount: packagesCount,
                  onPackagesTap: () => showPackageBottomSheet(context, ref),
                ),
                const SizedBox(height: AppSpacing.xxl),
                _DashboardErrorState(
                  onRetry: () => ref.invalidate(homeDashboardSnapshotProvider),
                ),
              ],
            ),
          ),
          data: (snapshot) {
            final showActiveDashboard =
                selectedPackage != null || snapshot.hasWorkspace;

            return Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                96,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HomeTopBar(
                    title: showActiveDashboard
                        ? 'Your filing workspace'
                        : 'Welcome to FinApp',
                    subtitle: showActiveDashboard
                        ? _workspaceSubtitle(snapshot, selectedPackage)
                        : 'Choose a package and begin your filing journey.',
                    packagesCount: packagesCount,
                    onPackagesTap: () => showPackageBottomSheet(context, ref),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (showActiveDashboard)
                    _ActiveDashboardView(
                      snapshot: snapshot,
                      selectedPackage: selectedPackage,
                      onContinueFiling: () =>
                          _handleFileItr(context, JourneyType.ITR),
                      onTrackStatus: () => _openStatus(context, snapshot),
                      onOpenDocuments: () =>
                          _openDocuments(context, snapshot, packagesAsync),
                      onOpenOrders: () => _openOrders(context),
                      onContactSupport: () {
                        _openContactUs();
                      },
                    )
                  else
                    _WelcomeDashboardView(
                      setupCards: setupCards,
                      whyCards: whyCards,
                      packagesCount: packagesCount,
                      onPickPackage: () => showPackageBottomSheet(context, ref),
                    ),
                ],
              ),
            );
          },
        ),
        bottomNavigationBar: const BottomNavBar(),
      ),
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final int? packagesCount;
  final VoidCallback onPackagesTap;

  const _HomeTopBar({
    required this.title,
    required this.subtitle,
    required this.packagesCount,
    required this.onPackagesTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.surfaceVariantDark,
          child: Text(
            'F',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.authHeading,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.authHeading,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.authMuted,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onPackagesTap,
          icon: const Icon(Icons.inventory_2_outlined),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surfaceVariantDark,
            foregroundColor: AppColors.authMuted,
          ),
          tooltip: packagesCount == null
              ? 'Packages'
              : '$packagesCount packages available',
        ),
      ],
    );
  }
}

class _WelcomeDashboardView extends StatelessWidget {
  final List<_SetupCardData> setupCards;
  final List<_WhyCardData> whyCards;
  final int? packagesCount;
  final VoidCallback onPickPackage;

  const _WelcomeDashboardView({
    required this.setupCards,
    required this.whyCards,
    required this.packagesCount,
    required this.onPickPackage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeroCard(onPickPackage: onPickPackage),
        const SizedBox(height: AppSpacing.xxl),
        _SectionHeader(
          title: 'Setup Progress',
          trailing: packagesCount == null
              ? 'LOADING PACKAGES'
              : '${setupCards.length} TASKS READY',
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          height: 248,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: setupCards.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) => _SetupProgressCard(
              data: setupCards[index],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxxl),
        const _SectionHeadingBlock(
          title: 'Why FinApp?',
          subtitle: 'The next generation of fiscal intelligence.',
        ),
        const SizedBox(height: AppSpacing.xl),
        ...whyCards.map(
          (card) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: _WhyCard(data: card),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const _TrustPanel(),
      ],
    );
  }
}

class _ActiveDashboardView extends StatelessWidget {
  final HomeDashboardSnapshot snapshot;
  final PackageModel? selectedPackage;
  final VoidCallback onContinueFiling;
  final VoidCallback onTrackStatus;
  final VoidCallback onOpenDocuments;
  final VoidCallback onOpenOrders;
  final VoidCallback onContactSupport;

  const _ActiveDashboardView({
    required this.snapshot,
    required this.selectedPackage,
    required this.onContinueFiling,
    required this.onTrackStatus,
    required this.onOpenDocuments,
    required this.onOpenOrders,
    required this.onContactSupport,
  });

  @override
  Widget build(BuildContext context) {
    final urgentUpdates = snapshot.urgentUpdates;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WorkspaceHeroCard(
          title: _workspaceHeadline(snapshot, selectedPackage),
          description: _workspaceDescription(snapshot, selectedPackage),
          stageLabel: _workspaceStageLabel(snapshot, selectedPackage),
          primaryActionText: selectedPackage != null && snapshot.activeDraft == null
              ? 'Continue Filing'
              : 'Track Status',
          secondaryActionText: 'View Orders',
          onPrimaryAction: selectedPackage != null && snapshot.activeDraft == null
              ? onContinueFiling
              : onTrackStatus,
          onSecondaryAction: onOpenOrders,
        ),
        const SizedBox(height: AppSpacing.xxl),
        _SectionHeader(
          title: 'Live Tracking',
          trailing: snapshot.activeStatus?.itrStatus?.overallStatus != null
              ? _toCaps(snapshot.activeStatus!.itrStatus!.overallStatus!)
              : 'ACTIVE WORKSPACE',
        ),
        const SizedBox(height: AppSpacing.lg),
        _WorkspaceOverviewCard(
          progress: _workspaceProgress(snapshot, selectedPackage),
          progressLabel: _progressSummary(snapshot, selectedPackage),
          statusDescription: _statusDescription(snapshot, selectedPackage),
          packageName: selectedPackage?.name ??
              snapshot.activeDraft?.packageName ??
              snapshot.activeOrder?.packageName,
          orderId: snapshot.activeOrder?.orderId,
          assignmentName: snapshot.activeStatus?.assignmentStatus?.professionalName,
          paymentStatus:
              snapshot.activeDraft?.paymentStatus ?? snapshot.activeOrder?.status,
        ),
        const SizedBox(height: AppSpacing.xxl),
        _SectionHeader(
          title: 'Critical Actions',
          trailing: urgentUpdates.isEmpty
              ? 'ON TRACK'
              : '${urgentUpdates.length} OPEN',
        ),
        const SizedBox(height: AppSpacing.lg),
        if (urgentUpdates.isEmpty)
          _CriticalActionCard(
            title: _fallbackActionTitle(snapshot, selectedPackage),
            description: _fallbackActionDescription(snapshot, selectedPackage),
            accent: AppColors.authAmber,
            icon: Icons.notifications_active_outlined,
            actionLabel: selectedPackage != null && snapshot.activeDraft == null
                ? 'Continue'
                : 'Open',
            onTap: selectedPackage != null && snapshot.activeDraft == null
                ? onContinueFiling
                : onOpenDocuments,
          )
        else
          ...urgentUpdates.map(
            (update) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _CriticalActionCard(
                title: update.status == null || update.status!.trim().isEmpty
                    ? 'Action Required'
                    : _toCaps(update.status!),
                description:
                    update.message ?? 'Please review your current filing step.',
                accent: AppColors.authAmber,
                icon: Icons.warning_amber_rounded,
                actionLabel: 'Review',
                onTap: onOpenDocuments,
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.xxxl),
        const _SectionHeadingBlock(
          title: 'Quick Tools',
          subtitle: 'Jump straight into the next part of your filing workflow.',
        ),
        const SizedBox(height: AppSpacing.xl),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            _QuickToolCard(
              icon: Icons.timeline_rounded,
              title: 'Track Status',
              description: 'See your current filing stage and expert updates.',
              accent: AppColors.authMint,
              onTap: onTrackStatus,
            ),
            _QuickToolCard(
              icon: Icons.folder_open_outlined,
              title: 'Document Vault',
              description: 'Upload or review the files needed for your return.',
              accent: AppColors.authHeading,
              onTap: onOpenDocuments,
            ),
            _QuickToolCard(
              icon: Icons.receipt_long_outlined,
              title: 'Orders',
              description: 'Open your order history and payment records.',
              accent: AppColors.authAmber,
              onTap: onOpenOrders,
            ),
            _QuickToolCard(
              icon: Icons.support_agent_rounded,
              title: 'Expert Help',
              description:
                  'Reach the support team if you need help moving ahead.',
              accent: AppColors.authMintDark,
              onTap: onContactSupport,
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final VoidCallback onPickPackage;

  const _HeroCard({required this.onPickPackage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        color: const Color(0x0DFFFFFF),
        border: Border.all(color: AppColors.borderOnDark),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 40,
            spreadRadius: -12,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: Opacity(
                opacity: 0.15,
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 220,
                  color: AppColors.authMuted,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your path to\nstress-free\nfiling begins\nhere.',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppColors.authHeading,
                  fontSize: 36,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 448),
                child: Text(
                  'Choose the right tax package, complete your filing details, and track your progress with confidence.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.authMuted,
                    height: 1.55,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                text: 'Pick a Package',
                onPressed: onPickPackage,
                minHeight: 56,
                borderRadius: AppSpacing.radiusPill,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.authMint, AppColors.authMintDark],
                ),
                foregroundColor: AppColors.authButtonText,
                textStyle: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.authButtonText,
                  fontWeight: FontWeight.w700,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x334EDEA3),
                    blurRadius: 20,
                    spreadRadius: -6,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkspaceHeroCard extends StatelessWidget {
  final String title;
  final String description;
  final String stageLabel;
  final String primaryActionText;
  final String secondaryActionText;
  final VoidCallback onPrimaryAction;
  final VoidCallback onSecondaryAction;

  const _WorkspaceHeroCard({
    required this.title,
    required this.description,
    required this.stageLabel,
    required this.primaryActionText,
    required this.secondaryActionText,
    required this.onPrimaryAction,
    required this.onSecondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        color: const Color(0x0DFFFFFF),
        border: Border.all(color: AppColors.borderOnDark),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 40,
            spreadRadius: -12,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.authMint.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
              child: Text(
                stageLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.authMint,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: Opacity(
                opacity: 0.15,
                child: Icon(
                  Icons.stacked_line_chart_rounded,
                  size: 220,
                  color: AppColors.authMuted,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppColors.authHeading,
                  fontSize: 34,
                  height: 1.08,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Text(
                  description,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.authMuted,
                    height: 1.55,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      text: primaryActionText,
                      onPressed: onPrimaryAction,
                      minHeight: 56,
                      borderRadius: AppSpacing.radiusPill,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.authMint, AppColors.authMintDark],
                      ),
                      foregroundColor: AppColors.authButtonText,
                      textStyle: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.authButtonText,
                        fontWeight: FontWeight.w700,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x334EDEA3),
                          blurRadius: 20,
                          spreadRadius: -6,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  TextButton(
                    onPressed: onSecondaryAction,
                    child: Text(
                      secondaryActionText,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.authHeading,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String trailing;

  const _SectionHeader({
    required this.title,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColors.authHeading,
            ),
          ),
        ),
        Text(
          trailing,
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppColors.authMint,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _WorkspaceOverviewCard extends StatelessWidget {
  final double progress;
  final String progressLabel;
  final String statusDescription;
  final String? packageName;
  final String? orderId;
  final String? assignmentName;
  final String? paymentStatus;

  const _WorkspaceOverviewCard({
    required this.progress,
    required this.progressLabel,
    required this.statusDescription,
    this.packageName,
    this.orderId,
    this.assignmentName,
    this.paymentStatus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0x08FFFFFF),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.borderOnDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            progressLabel,
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColors.authHeading,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            statusDescription,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.authMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.surfaceVariantDark,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.authMint),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _WorkspaceMetricChip(
                label: 'Package',
                value: packageName ?? 'Not selected',
                accent: AppColors.authMint,
              ),
              _WorkspaceMetricChip(
                label: 'Payment',
                value: paymentStatus == null || paymentStatus!.trim().isEmpty
                    ? 'Pending'
                    : _toCaps(paymentStatus!),
                accent: AppColors.authAmber,
              ),
              _WorkspaceMetricChip(
                label: 'Expert',
                value: assignmentName ?? 'Assigning soon',
                accent: AppColors.authHeading,
              ),
              _WorkspaceMetricChip(
                label: 'Order ID',
                value: orderId ?? 'Will appear after payment',
                accent: AppColors.authMintDark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkspaceMetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _WorkspaceMetricChip({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(minWidth: 140, maxWidth: 220),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
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
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.authHeading,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeadingBlock extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeadingBlock({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: AppColors.authHeading,
            fontSize: 30,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          subtitle,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.authMuted,
          ),
        ),
      ],
    );
  }
}

class _CriticalActionCard extends StatelessWidget {
  final String title;
  final String description;
  final Color accent;
  final IconData icon;
  final String actionLabel;
  final VoidCallback onTap;

  const _CriticalActionCard({
    required this.title,
    required this.description,
    required this.accent,
    required this.icon,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Ink(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(color: accent.withValues(alpha: 0.28)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
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
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.authHeading,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.authMuted,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                actionLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color accent;
  final VoidCallback onTap;

  const _QuickToolCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 168,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          child: Ink(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0x08FFFFFF),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              border: Border.all(color: AppColors.borderOnDark),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Icon(icon, color: accent),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.authHeading,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.authMuted,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SetupProgressCard extends StatelessWidget {
  final _SetupCardData data;

  const _SetupProgressCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 280,
      child: CustomCard(
        onTap: data.onTap,
        backgroundColor: const Color(0x08FFFFFF),
        border: Border.all(color: AppColors.borderOnDark),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariantDark,
                borderRadius: BorderRadius.circular(AppSpacing.sm),
              ),
              child: Icon(
                data.icon,
                color: data.accent,
                size: 18,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              data.title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.authHeading,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: Text(
                data.description,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.authMuted,
                  height: 1.45,
                ),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              child: LinearProgressIndicator(
                minHeight: 4,
                value: data.progress,
                backgroundColor: AppColors.surfaceVariantDark,
                valueColor: AlwaysStoppedAnimation<Color>(data.accent),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              data.actionLabel,
              style: theme.textTheme.labelLarge?.copyWith(
                color: data.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardLoadingState extends StatelessWidget {
  const _DashboardLoadingState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxxl,
      ),
      decoration: BoxDecoration(
        color: const Color(0x08FFFFFF),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.borderOnDark),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(color: AppColors.authMint),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Loading your latest dashboard state...',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.authHeading,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Checking your filing progress, orders, and current workspace.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.authMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DashboardErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _DashboardErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.authAmber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: AppColors.authAmber.withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.authAmber,
            size: 40,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'We could not refresh your dashboard right now.',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.authHeading,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Please try again to reload your latest filing and order information.',
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
    );
  }
}

class _WhyCard extends StatelessWidget {
  final _WhyCardData data;

  const _WhyCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(32, 36, 32, 32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border(
          top: BorderSide(color: data.accent, width: 4),
        ),
        color: const Color(0x08FFFFFF),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            data.icon,
            color: data.accent,
            size: 28,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            data.title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColors.authHeading,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            data.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.authMuted,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustPanel extends StatelessWidget {
  const _TrustPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          'Trusted by users filing with confidence',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.authMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.xl,
            horizontal: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: const Color(0x08FFFFFF),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.md,
            children: const [
              _TrustWordmark(label: 'FINANCE_CO'),
              _TrustWordmark(label: 'LEDGER'),
              _TrustWordmark(label: 'STRATA'),
              _TrustWordmark(label: 'AETHER'),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrustWordmark extends StatelessWidget {
  final String label;

  const _TrustWordmark({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      label,
      style: theme.textTheme.titleMedium?.copyWith(
        color: AppColors.authMutedSoft,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
      ),
    );
  }
}

class _SetupCardData {
  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final double progress;
  final String actionLabel;
  final VoidCallback onTap;

  _SetupCardData({
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    required this.progress,
    required this.actionLabel,
    required this.onTap,
  });
}

class _WhyCardData {
  final String title;
  final String description;
  final IconData icon;
  final Color accent;

  const _WhyCardData({
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
  });
}

String _workspaceSubtitle(
  HomeDashboardSnapshot snapshot,
  PackageModel? selectedPackage,
) {
  if (selectedPackage != null && snapshot.activeDraft == null) {
    return '${selectedPackage.name} selected. Complete your setup to begin.';
  }

  if (snapshot.activeStatus?.itrStatus?.overallStatus != null) {
    return _toCaps(snapshot.activeStatus!.itrStatus!.overallStatus!);
  }

  if (snapshot.activeDraft?.statusDisplayText != null &&
      snapshot.activeDraft!.statusDisplayText!.trim().isNotEmpty) {
    return snapshot.activeDraft!.statusDisplayText!;
  }

  return 'Resume the latest filing tasks and monitor progress.';
}

String _workspaceHeadline(
  HomeDashboardSnapshot snapshot,
  PackageModel? selectedPackage,
) {
  if (selectedPackage != null && snapshot.activeDraft == null) {
    return 'Your package is selected.\nLet\'s start the filing.';
  }

  final currentStep = snapshot.activeStatus?.itrStatus?.currentStep;
  final totalSteps = snapshot.activeStatus?.itrStatus?.totalSteps;

  if (currentStep != null && totalSteps != null && totalSteps > 0) {
    return 'Your ITR is moving through\n$currentStep of $totalSteps steps.';
  }

  return 'Your active filing workspace is ready for the next step.';
}

String _workspaceDescription(
  HomeDashboardSnapshot snapshot,
  PackageModel? selectedPackage,
) {
  if (selectedPackage != null && snapshot.activeDraft == null) {
    return 'We\'ve saved ${selectedPackage.name} as your current package. Continue with personal details and documents to start expert review.';
  }

  if (snapshot.activeStatus?.assignmentStatus?.professionalName != null) {
    return 'Your filing is being handled by ${snapshot.activeStatus!.assignmentStatus!.professionalName}. Keep an eye on action items to avoid delays.';
  }

  if (snapshot.activeDraft?.statusDisplayText != null &&
      snapshot.activeDraft!.statusDisplayText!.trim().isNotEmpty) {
    return snapshot.activeDraft!.statusDisplayText!;
  }

  return 'Review your live progress, clear pending tasks, and jump back into the parts of the workflow that need attention.';
}

String _workspaceStageLabel(
  HomeDashboardSnapshot snapshot,
  PackageModel? selectedPackage,
) {
  if (selectedPackage != null && snapshot.activeDraft == null) {
    return 'PACKAGE SELECTED';
  }

  final status = snapshot.activeStatus?.itrStatus;
  if (status?.currentStep != null &&
      status?.totalSteps != null &&
      status!.totalSteps! > 0) {
    return '${status.currentStep}/${status.totalSteps} STEPS';
  }

  if (snapshot.activeDraft?.paymentStatus != null &&
      snapshot.activeDraft!.paymentStatus!.trim().isNotEmpty) {
    return 'PAYMENT ${_toCaps(snapshot.activeDraft!.paymentStatus!)}';
  }

  return 'ACTIVE WORKSPACE';
}

double _workspaceProgress(
  HomeDashboardSnapshot snapshot,
  PackageModel? selectedPackage,
) {
  final percentage = snapshot.activeStatus?.itrStatus?.progressPercentage;
  if (percentage != null) {
    final normalized = percentage / 100;
    if (normalized < 0) return 0;
    if (normalized > 1) return 1;
    return normalized;
  }

  if (selectedPackage != null && snapshot.activeDraft == null) {
    return 0.25;
  }

  if (snapshot.activeDraft != null) {
    return 0.45;
  }

  if (snapshot.activeOrder != null) {
    return 0.7;
  }

  return 0.2;
}

String _progressSummary(
  HomeDashboardSnapshot snapshot,
  PackageModel? selectedPackage,
) {
  final status = snapshot.activeStatus?.itrStatus;
  if (status?.currentStep != null &&
      status?.totalSteps != null &&
      status!.totalSteps! > 0) {
    return '${status.currentStep}/${status.totalSteps} expert stages completed';
  }

  if (selectedPackage != null && snapshot.activeDraft == null) {
    return 'Package selected and ready to start';
  }

  if (snapshot.activeDraft?.statusDisplayText != null &&
      snapshot.activeDraft!.statusDisplayText!.trim().isNotEmpty) {
    return snapshot.activeDraft!.statusDisplayText!;
  }

  return 'Continue your active workspace';
}

String _statusDescription(
  HomeDashboardSnapshot snapshot,
  PackageModel? selectedPackage,
) {
  if (snapshot.activeStatus?.itrStatus?.steps != null &&
      snapshot.activeStatus!.itrStatus!.steps!.isNotEmpty) {
    final status = snapshot.activeStatus!.itrStatus!;
    final steps = status.steps!;
    final currentStep = status.currentStep ?? 0;
    final index = currentStep <= 0
        ? 0
        : (currentStep - 1).clamp(0, steps.length - 1);
    final current = steps[index];
    if (current.title != null && current.title!.trim().isNotEmpty) {
      return current.title!;
    }
  }

  if (selectedPackage != null && snapshot.activeDraft == null) {
    return 'Complete your profile details and upload documents so we can create your active return.';
  }

  if (snapshot.activeOrder?.status != null &&
      snapshot.activeOrder!.status!.trim().isNotEmpty) {
    return 'Latest order status: ${_toCaps(snapshot.activeOrder!.status!)}';
  }

  return 'Your filing workspace is open and ready for the next action.';
}

String _fallbackActionTitle(
  HomeDashboardSnapshot snapshot,
  PackageModel? selectedPackage,
) {
  if (selectedPackage != null && snapshot.activeDraft == null) {
    return 'Complete your profile setup';
  }

  if (snapshot.activeDraft != null) {
    return 'Upload remaining documents';
  }

  return 'Review your latest order';
}

String _fallbackActionDescription(
  HomeDashboardSnapshot snapshot,
  PackageModel? selectedPackage,
) {
  if (selectedPackage != null && snapshot.activeDraft == null) {
    return 'Your package is ready. Add personal details to move from onboarding into the active filing flow.';
  }

  if (snapshot.activeDraft != null) {
    return 'Your filing has started. Open the document vault and make sure all required files are available for review.';
  }

  return 'Open your orders and latest status updates to make sure nothing is blocking progress.';
}

String _toCaps(String value) {
  return value
      .split(RegExp(r'[_\s]+'))
      .where((part) => part.isNotEmpty)
      .map((part) {
        final lower = part.toLowerCase();
        return '${lower[0].toUpperCase()}${lower.substring(1)}';
      })
      .join(' ');
}
