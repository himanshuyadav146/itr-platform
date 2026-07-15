import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tax_client/core/common/enums/journey_type.dart';
import 'package:tax_client/core/common/widgets/bottom_nav_bar.dart';
import 'package:tax_client/core/common/widgets/core_scaffold.dart';
import 'package:tax_client/core/common/widgets/custom_card.dart';
import 'package:tax_client/core/common/widgets/primary_button.dart';
import 'package:tax_client/core/common/widgets/responsive_grid.dart';
import 'package:tax_client/core/config/strings/app_strings.dart';
import 'package:tax_client/core/config/theme/app_colors.dart';
import 'package:tax_client/core/config/theme/app_spacing.dart';
import 'package:tax_client/core/constant/api_constants.dart';
import 'package:tax_client/core/config/app_router.dart';
import 'package:tax_client/core/network/token_storage.dart';
import 'package:tax_client/core/services/analytics/analytics_service.dart';
import 'package:tax_client/core/utils/error_handler.dart';
import 'package:tax_client/core/utils/web_content_navigation.dart';
import 'package:tax_client/features/home/domain/dashboard_mode.dart';
import 'package:tax_client/features/home/presentation/providers/home_dashboard_provider.dart';
import 'package:tax_client/features/packages/data/models/package_model.dart';
import 'package:tax_client/features/packages/presentation/providers/package_provider.dart';
import 'package:tax_client/features/packages/presentation/widgets/package_bottom_sheet.dart';
import 'package:tax_client/features/personal_info/data/models/itr_personal_detail_model.dart';
import 'package:tax_client/features/personal_info/presentation/providers/personal_info_provider.dart';
import 'package:tax_client/features/personal_info/presentation/providers/personal_info_state.dart';
import 'package:tax_client/features/status/data/models/itr_detailed_status_model.dart';

/// Horizontal + bottom padding for dashboard body. Top inset comes from [CoreScaffold] SafeArea.
const _homeDashboardPadding = EdgeInsets.fromLTRB(
  AppSpacing.lg,
  AppSpacing.lg,
  AppSpacing.lg,
  AppSpacing.xxl,
);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with RouteAware {
  bool _isRouteAwareSubscribed = false;

  void _refreshDashboardData() {
    ref.invalidate(homeDashboardSnapshotProvider);
    ref.read(packagesProvider.notifier).getPackages();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshDashboardData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (!_isRouteAwareSubscribed && route is PageRoute) {
      AppRouter.routeObserver.subscribe(this, route);
      _isRouteAwareSubscribed = true;
    }
  }

  @override
  void dispose() {
    if (_isRouteAwareSubscribed) {
      AppRouter.routeObserver.unsubscribe(this);
    }
    super.dispose();
  }

  @override
  void didPush() {
    _refreshDashboardData();
  }

  @override
  void didPopNext() {
    _refreshDashboardData();
  }

  Future<void> _handleFileItr(
    BuildContext context,
    JourneyType journeyType,
  ) async {
    AnalyticsService.logCtaClick(
      ctaName: journeyType == JourneyType.EVerify
          ? AnalyticsService.ctaHomeEVerify
          : AnalyticsService.ctaHomeFileItr,
      screenName: 'home',
    );

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
          selectedPackage = packagesState.value!.firstWhere(
            (pkg) => pkg.id == "7",
          );
          ref.read(selectedPackageProvider.notifier).state = selectedPackage;
        } catch (_) {
          // Keep whatever is already selected for sheet pre-highlight.
        }
      }

      // E-Verify still lets the user confirm/change package.
      if (!context.mounted) return;
      selectedPackage = await showPackageBottomSheet(context, ref);
      if (selectedPackage == null) {
        return;
      }
      ref.read(selectedPackageProvider.notifier).state = selectedPackage;
    }
    // File ITR: skip package sheet — go straight to ITR list / new filing.

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
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

  void _openContactUs(BuildContext context) {
    AnalyticsService.logCtaClick(
      ctaName: AnalyticsService.ctaHomeContactSupport,
      screenName: 'home',
    );
    openWebContent(
      context,
      path: ApiConstants.itrContactUS,
      title: AppStrings.contactSupport,
    );
  }

  void _openOrders(BuildContext context) {
    AnalyticsService.logCtaClick(
      ctaName: AnalyticsService.ctaHomeOrders,
      screenName: 'home',
    );
    context.go('/orders');
  }

  void _openTaxCalculator(BuildContext context) {
    AnalyticsService.logCtaClick(
      ctaName: AnalyticsService.ctaHomeTaxCalculator,
      screenName: 'home',
    );
    context.push('/tax_calculator');
  }

  void _openStatus(BuildContext context, HomeDashboardSnapshot snapshot) {
    AnalyticsService.logCtaClick(
      ctaName: AnalyticsService.ctaHomeStatus,
      screenName: 'home',
    );
    final focusItr = snapshot.focusItr;
    if (focusItr != null) {
      final focusOrder = snapshot.focusOrder;
      final orderId = (focusOrder?.orderId ?? '').trim();
      final itrId = (focusItr.itrId ?? '').trim().isNotEmpty
          ? focusItr.itrId!.trim()
          : (focusOrder?.itrId?.toString() ?? '').trim().isNotEmpty
          ? focusOrder!.itrId!.toString()
          : focusItr.id.trim();
      final statusItrData = ItrPersonalDetailModel(
        // Keep orderId separate from ITR id; never send numeric ITR row id as orderId.
        id: orderId,
        itrId: itrId,
        userId: focusItr.userId,
        panNumber: focusItr.panNumber,
        firstName: focusItr.firstName,
        middleName: focusItr.middleName,
        lastName: focusItr.lastName,
        email: focusItr.email,
        mobileNumber: focusItr.mobileNumber,
        aadharCardNumber: focusItr.aadharCardNumber,
        gender: focusItr.gender,
        dateOfBirth: focusItr.dateOfBirth,
        financialYear: focusItr.financialYear,
        address: focusItr.address,
        country: focusItr.country,
        isActive: focusItr.isActive,
        createdAt: focusItr.createdAt,
        createdBy: focusItr.createdBy,
        updatedAt: focusItr.updatedAt,
        updatedBy: focusItr.updatedBy,
        documents: focusItr.documents,
        documentCount: focusItr.documentCount,
        packageId: focusItr.packageId,
        packageName: focusItr.packageName,
        paymentStatus: focusItr.paymentStatus,
        itrStatus: focusItr.itrStatus,
        statusDisplayText: focusItr.statusDisplayText,
      );
      context.push('/status', extra: statusItrData);
      return;
    }

    context.go('/orders');
  }

  Future<void> _openPersonalInfoForFocus(
    BuildContext context,
    HomeDashboardSnapshot snapshot,
    AsyncValue<List<PackageModel>> packagesAsync,
  ) async {
    final focusItr = snapshot.focusItr;
    if (focusItr == null) {
      await _handleFileItr(context, JourneyType.ITR);
      return;
    }

    await _syncPackageFromItr(focusItr, packagesAsync);
    final tokenStorage = ref.read(tokenStorageProvider);
    await tokenStorage.savePanNumber(focusItr.panNumber.trim());

    if (!context.mounted) return;
    context.push('/personal_info', extra: focusItr);
  }

  Future<void> _openPaymentForFocus(
    BuildContext context,
    HomeDashboardSnapshot snapshot,
    AsyncValue<List<PackageModel>> packagesAsync,
  ) async {
    final focusItr = snapshot.focusItr;
    if (focusItr == null) {
      if (context.mounted) {
        ErrorHandler.showError(
          context,
          'No active ITR found. Please start filing first.',
        );
      }
      return;
    }

    ref.read(journeyTypeProvider.notifier).state = JourneyType.ITR;

    final pan = focusItr.panNumber.trim();
    if (pan.isEmpty) {
      if (context.mounted) {
        ErrorHandler.showError(
          context,
          'PAN is required before payment. Please complete personal information.',
        );
        context.push('/personal_info', extra: focusItr);
      }
      return;
    }

    await ref.read(tokenStorageProvider).savePanNumber(pan);
    await _syncPackageFromItr(focusItr, packagesAsync);

    // Always allow confirming/changing package before payment.
    if (!context.mounted) return;
    final picked = await showPackageBottomSheet(context, ref);
    if (picked == null || !context.mounted) return;

    final packageId = int.tryParse(picked.id);
    if (packageId == null) {
      ErrorHandler.showError(
        context,
        'Please select a package to continue to payment.',
      );
      return;
    }

    AnalyticsService.logCtaClick(
      ctaName: AnalyticsService.ctaHomePayment,
      screenName: 'home',
    );
    context.push('/payment?packageId=$packageId');
  }

  Future<void> _resolveDashboardAction(
    BuildContext context,
    HomeDashboardSnapshot snapshot,
    AsyncValue<List<PackageModel>> packagesAsync,
    DashboardActionItem action,
  ) async {
    switch (action.type) {
      case DashboardActionType.informationRequired:
        await _openPersonalInfoForFocus(context, snapshot, packagesAsync);
        break;
      case DashboardActionType.documentRequired:
        await _openDocuments(context, snapshot, packagesAsync);
        break;
      case DashboardActionType.clarificationRequired:
      case DashboardActionType.general:
        if (snapshot.focusItr != null) {
          _openStatus(context, snapshot);
        } else {
          await _openDocuments(context, snapshot, packagesAsync);
        }
        break;
    }
  }

  Future<void> _openDocuments(
    BuildContext context,
    HomeDashboardSnapshot snapshot,
    AsyncValue<List<PackageModel>> packagesAsync,
  ) async {
    final latestFiling = snapshot.documentVaultItr;
    if (latestFiling == null) {
      if (context.mounted) {
        ErrorHandler.showError(
          context,
          'PAN not found. Please complete personal information first.',
        );
      }
      return;
    }

    final tokenStorage = ref.read(tokenStorageProvider);
    await tokenStorage.savePanNumber(latestFiling.panNumber.trim());
    await _syncPackageFromItr(latestFiling, packagesAsync);

    if (!context.mounted) return;
    AnalyticsService.logCtaClick(
      ctaName: AnalyticsService.ctaHomeDocuments,
      screenName: 'home',
    );
    context.push('/document_upload');
  }

  Future<void> _syncPackageFromItr(
    ItrPersonalDetailModel itrItem,
    AsyncValue<List<PackageModel>> packagesAsync,
  ) async {
    final packageId = itrItem.packageId;
    if (packageId == null) {
      return;
    }

    var packages = packagesAsync.valueOrNull;
    if (packages == null) {
      await ref.read(packagesProvider.notifier).getPackages();
      packages = ref.read(packagesProvider).valueOrNull;
    }
    if (packages == null) {
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
        onTap: () async {
          AnalyticsService.logCtaClick(
            ctaName: AnalyticsService.ctaHomePackages,
            screenName: 'home',
          );
          await showPackageBottomSheet(context, ref);
        },
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
        backgroundColor: AppColors.authBackground,
        useScrollView: true,
        centered: true,
        useResponsiveMaxWidth: true,
        maxContentWidth: 560,
        padding: EdgeInsets.zero,
        body: dashboardAsync.when(
          loading: () => Padding(
            padding: _homeDashboardPadding,
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
            padding: _homeDashboardPadding,
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
              padding: _homeDashboardPadding,
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
                      onCompletePayment: () => _openPaymentForFocus(
                        context,
                        snapshot,
                        packagesAsync,
                      ),
                      onOpenTaxCalculator: () => _openTaxCalculator(context),
                      onOpenDocuments: () =>
                          _openDocuments(context, snapshot, packagesAsync),
                      onOpenOrders: () => _openOrders(context),
                      onContactSupport: () {
                        _openContactUs(context);
                      },
                      onResolveAction: (action) => _resolveDashboardAction(
                        context,
                        snapshot,
                        packagesAsync,
                        action,
                      ),
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
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = ResponsiveLayout.horizontalCardWidth(
              constraints.maxWidth,
            );
            return SizedBox(
              height: 248,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: setupCards.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.md),
                itemBuilder: (context, index) => SizedBox(
                  width: cardWidth,
                  child: _SetupProgressCard(data: setupCards[index]),
                ),
              ),
            );
          },
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
      ],
    );
  }
}

class _ActiveDashboardView extends StatelessWidget {
  final HomeDashboardSnapshot snapshot;
  final PackageModel? selectedPackage;
  final VoidCallback onContinueFiling;
  final VoidCallback onTrackStatus;
  final VoidCallback onCompletePayment;
  final VoidCallback onOpenTaxCalculator;
  final VoidCallback onOpenDocuments;
  final VoidCallback onOpenOrders;
  final VoidCallback onContactSupport;
  final void Function(DashboardActionItem action) onResolveAction;

  const _ActiveDashboardView({
    required this.snapshot,
    required this.selectedPackage,
    required this.onContinueFiling,
    required this.onTrackStatus,
    required this.onCompletePayment,
    required this.onOpenTaxCalculator,
    required this.onOpenDocuments,
    required this.onOpenOrders,
    required this.onContactSupport,
    required this.onResolveAction,
  });

  @override
  Widget build(BuildContext context) {
    final pendingActions = snapshot.pendingActions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (snapshot.showPendingPayment) ...[
          _PendingPaymentCard(
            snapshot: snapshot,
            selectedPackage: selectedPackage,
            onCompletePayment: onCompletePayment,
          ),
        ] else if (snapshot.showLiveTracking) ...[
          _WorkspaceHeroCard(
            title: _workspaceHeadline(snapshot, selectedPackage),
            description: _workspaceDescription(snapshot, selectedPackage),
            stageLabel: _workspaceStageLabel(snapshot, selectedPackage),
            primaryActionText: 'Track Status',
            secondaryActionText: 'View Orders',
            onPrimaryAction: onTrackStatus,
            onSecondaryAction: onOpenOrders,
          ),
          const SizedBox(height: AppSpacing.xxl),
          _SectionHeader(
            title: 'Live Tracking',
            trailing: _liveTrackingHeaderLabel(snapshot),
          ),
          const SizedBox(height: AppSpacing.lg),
          _WorkspaceOverviewCard(
            snapshot: snapshot,
            selectedPackage: selectedPackage,
          ),
          if (snapshot.showCriticalActions) ...[
            const SizedBox(height: AppSpacing.xxl),
            _SectionHeader(
              title: 'Critical Actions',
              trailing: '${pendingActions.length} OPEN',
            ),
            const SizedBox(height: AppSpacing.lg),
            ...pendingActions.map(
              (action) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _CriticalActionCard(
                  title: action.title,
                  description: action.message,
                  requestedBy: action.requestedBy,
                  createdAt: action.createdAt,
                  accent: AppColors.authAmber,
                  icon: _iconForActionType(action.type),
                  actionLabel: 'Resolve Now',
                  onTap: () => onResolveAction(action),
                ),
              ),
            ),
          ],
        ] else ...[
          _WorkspaceHeroCard(
            title: _workspaceHeadline(snapshot, selectedPackage),
            description: _workspaceDescription(snapshot, selectedPackage),
            stageLabel: _workspaceStageLabel(snapshot, selectedPackage),
            primaryActionText: 'Start Filing',
            secondaryActionText: 'View Orders',
            onPrimaryAction: onContinueFiling,
            onSecondaryAction: onOpenOrders,
          ),
        ],
        const SizedBox(height: AppSpacing.xxxl),
        const _SectionHeadingBlock(
          title: 'Quick Tools',
          subtitle: 'Jump straight into the next part of your filing workflow.',
        ),
        const SizedBox(height: AppSpacing.xl),
        ResponsiveWrapGrid(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          matchRowHeights: true,
          children: [
            _QuickToolCard(
              icon: Icons.description_outlined,
              title: 'File ITR',
              description:
                  'Start a filing, reopen an ITR record, and continue with your saved flow.',
              accent: AppColors.authMint,
              onTap: onContinueFiling,
            ),
            _QuickToolCard(
              icon: Icons.calculate_outlined,
              title: 'Tax Calculator',
              description:
                  'Estimate tax with the latest slab logic and regime comparison.',
              accent: AppColors.authAmber,
              onTap: onOpenTaxCalculator,
            ),
            if (snapshot.hasDocumentVaultAccess)
              _QuickToolCard(
                icon: Icons.folder_open_outlined,
                title: 'Document Vault',
                description:
                    'Upload or review the files needed for your return.',
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

IconData _iconForActionType(DashboardActionType type) {
  switch (type) {
    case DashboardActionType.documentRequired:
      return Icons.folder_open_outlined;
    case DashboardActionType.informationRequired:
      return Icons.person_outline_rounded;
    case DashboardActionType.clarificationRequired:
      return Icons.help_outline_rounded;
    case DashboardActionType.general:
      return Icons.warning_amber_rounded;
  }
}

class _PendingPaymentCard extends StatelessWidget {
  final HomeDashboardSnapshot snapshot;
  final PackageModel? selectedPackage;
  final VoidCallback onCompletePayment;

  const _PendingPaymentCard({
    required this.snapshot,
    required this.selectedPackage,
    required this.onCompletePayment,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final focus = snapshot.focusItr;
    final fy = focus?.financialYear ?? 'current year';
    final packageName =
        focus?.packageName ?? selectedPackage?.name ?? 'Not selected';
    final statusText = _pendingPaymentDescription(focus, fy);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        color: const Color(0x12FFB95F),
        border: Border.all(color: AppColors.authAmber.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.authAmber.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
                child: Text(
                  'PENDING PAYMENT',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.authAmber,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Payment required',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppColors.authHeading,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            statusText,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.authMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Package: $packageName',
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.authHeading,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            text: 'Complete Payment',
            onPressed: onCompletePayment,
            minHeight: 56,
            borderRadius: AppSpacing.radiusPill,
            gradient: const LinearGradient(
              colors: [AppColors.authAmber, Color(0xFFE89A2E)],
            ),
            foregroundColor: AppColors.authButtonText,
            textStyle: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.authButtonText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

String _pendingPaymentDescription(ItrPersonalDetailModel? focus, String fy) {
  final display = focus?.statusDisplayText?.trim();
  if (display != null &&
      display.isNotEmpty &&
      display.toLowerCase() != 'pending_payment') {
    return display;
  }

  return 'Complete payment for FY $fy to unlock live tracking and expert processing.';
}

class _WorkspaceStageBadge extends StatelessWidget {
  final String label;

  const _WorkspaceStageBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.authMint.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        label,
        maxLines: 2,
        textAlign: TextAlign.center,
        style: theme.textTheme.labelLarge?.copyWith(
          color: AppColors.authMint,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          fontSize: 11,
        ),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: AppColors.authHeading,
                        fontSize: 34,
                        height: 1.08,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _WorkspaceStageBadge(label: stageLabel),
                ],
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

  const _SectionHeader({required this.title, required this.trailing});

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
  final HomeDashboardSnapshot snapshot;
  final PackageModel? selectedPackage;

  const _WorkspaceOverviewCard({
    required this.snapshot,
    required this.selectedPackage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusInfo = snapshot.activeStatus?.itrStatus;
    final steps = statusInfo?.steps ?? const <ItrStatusStepModel>[];
    final currentStepNumber = (statusInfo?.currentStep ?? 1)
        .clamp(1, steps.isEmpty ? 1 : steps.length)
        .toInt();
    final currentIndex = steps.isEmpty ? 0 : currentStepNumber - 1;
    final activeStep = steps.isEmpty ? null : steps[currentIndex];
    final progress = _workspaceProgress(snapshot, selectedPackage);
    final progressPercent = (progress * 100).round();
    final stageTitle = activeStep?.title?.trim().isNotEmpty == true
        ? activeStep!.title!
        : _progressSummary(snapshot, selectedPackage);
    final stageDetail = activeStep?.notes?.trim().isNotEmpty == true
        ? activeStep!.notes!
        : _statusDescription(snapshot, selectedPackage);
    final packageName =
        selectedPackage?.name ??
        snapshot.focusItr?.packageName ??
        snapshot.focusOrder?.packageName ??
        'Not selected';
    final paymentStatus =
        snapshot.focusItr?.paymentStatus ?? snapshot.focusOrder?.status;
    final assignmentName = _expertSummaryLabel(snapshot);
    final orderId =
        snapshot.focusOrder?.orderId ?? snapshot.activeStatus?.orderId ?? '—';

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Stage',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.authMuted,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      stageTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppColors.authHeading,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.authMint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
                child: Text(
                  '$progressPercent% Done',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.authMint,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            stageDetail,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.authMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text(
                  _progressSummary(snapshot, selectedPackage),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.authHeading,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                _workspaceStatusBadgeLabel(snapshot),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.authMint,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceVariantDark,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.authMint,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (steps.isNotEmpty) ...[
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: List.generate(steps.length, (index) {
                final step = steps[index];
                final isCurrent = index == currentIndex;
                final isCompleted = step.isCompleted ?? false;
                return _TrackingStepPill(
                  label: step.title?.trim().isNotEmpty == true
                      ? step.title!
                      : _toCaps(step.step ?? 'Stage'),
                  isCurrent: isCurrent,
                  isCompleted: isCompleted,
                  hasConcern: step.hasConcern ?? false,
                );
              }),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _TrackingHighlightCard(
                label: 'Package',
                value: packageName,
                accent: AppColors.authMint,
                icon: Icons.inventory_2_outlined,
              ),
              _TrackingHighlightCard(
                label: 'Payment',
                value: paymentStatus == null || paymentStatus.trim().isEmpty
                    ? 'Pending'
                    : _toCaps(paymentStatus),
                accent: AppColors.authAmber,
                icon: Icons.payments_outlined,
              ),
              _TrackingHighlightCard(
                label: 'Expert',
                value: assignmentName,
                accent: AppColors.authHeading,
                icon: Icons.support_agent_rounded,
              ),
              _TrackingHighlightCard(
                label: 'Order ID',
                value: orderId,
                accent: AppColors.authMintDark,
                icon: Icons.receipt_long_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrackingStepPill extends StatelessWidget {
  final String label;
  final bool isCurrent;
  final bool isCompleted;
  final bool hasConcern;

  const _TrackingStepPill({
    required this.label,
    required this.isCurrent,
    required this.isCompleted,
    required this.hasConcern,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = hasConcern
        ? AppColors.authAmber
        : isCurrent
        ? AppColors.authMint
        : isCompleted
        ? AppColors.authHeading
        : AppColors.authMutedSoft;

    return Container(
      constraints: const BoxConstraints(minWidth: 110),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isCurrent ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(
          color: accent.withValues(alpha: isCurrent ? 0.5 : 0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCompleted
                ? Icons.check_circle_rounded
                : isCurrent
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: accent,
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isCurrent ? AppColors.authHeading : accent,
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingHighlightCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final IconData icon;

  const _TrackingHighlightCard({
    required this.label,
    required this.value,
    required this.accent,
    required this.icon,
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
        border: Border.all(color: accent.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, color: accent, size: 18),
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.authHeading,
                    fontWeight: FontWeight.w700,
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

class _SectionHeadingBlock extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeadingBlock({required this.title, required this.subtitle});

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
  final String? requestedBy;
  final String? createdAt;
  final Color accent;
  final IconData icon;
  final String actionLabel;
  final VoidCallback onTap;

  const _CriticalActionCard({
    required this.title,
    required this.description,
    this.requestedBy,
    this.createdAt,
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
                    if (requestedBy != null &&
                        requestedBy!.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Requested by: $requestedBy',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.authMuted,
                        ),
                      ),
                    ],
                    if (createdAt != null && createdAt!.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Requested on ${_formatActionDate(createdAt!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.authMuted,
                        ),
                      ),
                    ],
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Ink(
          height: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0x08FFFFFF),
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(color: AppColors.borderOnDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
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
              Expanded(
                child: Text(
                  description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.authMuted,
                    height: 1.45,
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

class _SetupProgressCard extends StatelessWidget {
  final _SetupCardData data;

  const _SetupProgressCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomCard(
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
            child: Icon(data.icon, color: data.accent, size: 18),
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
            style: theme.textTheme.labelLarge?.copyWith(color: data.accent),
          ),
        ],
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
        border: Border.all(color: AppColors.authAmber.withValues(alpha: 0.24)),
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
        border: Border(top: BorderSide(color: data.accent, width: 4)),
        color: const Color(0x08FFFFFF),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(data.icon, color: data.accent, size: 28),
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

String _formatActionDate(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) {
    return raw;
  }
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
}

String _workspaceSubtitle(
  HomeDashboardSnapshot snapshot,
  PackageModel? selectedPackage,
) {
  if (snapshot.showPendingPayment) {
    return 'Complete payment for your latest ITR to unlock live tracking.';
  }

  if (selectedPackage != null && snapshot.focusItr == null) {
    return '${selectedPackage.name} selected. Complete your setup to begin.';
  }

  if (snapshot.activeStatus?.itrStatus?.overallStatus != null) {
    return _toCaps(snapshot.activeStatus!.itrStatus!.overallStatus!);
  }

  if (snapshot.focusItr?.statusDisplayText != null &&
      snapshot.focusItr!.statusDisplayText!.trim().isNotEmpty) {
    return snapshot.focusItr!.statusDisplayText!;
  }

  return 'Resume the latest filing tasks and monitor progress.';
}

String _workspaceHeadline(
  HomeDashboardSnapshot snapshot,
  PackageModel? selectedPackage,
) {
  if (snapshot.showPendingPayment) {
    return 'Your latest ITR is\nwaiting for payment.';
  }

  if (selectedPackage != null && snapshot.focusItr == null) {
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

  if (snapshot.focusItr?.statusDisplayText != null &&
      snapshot.focusItr!.statusDisplayText!.trim().isNotEmpty) {
    return snapshot.focusItr!.statusDisplayText!;
  }

  return 'Review your live progress, clear pending tasks, and jump back into the parts of the workflow that need attention.';
}

String _workspaceStageLabel(
  HomeDashboardSnapshot snapshot,
  PackageModel? selectedPackage,
) {
  if (snapshot.showPendingPayment) {
    return 'PAYMENT PENDING';
  }

  if (selectedPackage != null && snapshot.focusItr == null) {
    return 'PACKAGE SELECTED';
  }

  final status = snapshot.activeStatus?.itrStatus;
  if (status?.currentStep != null &&
      status?.totalSteps != null &&
      status!.totalSteps! > 0) {
    return '${status.currentStep}/${status.totalSteps} STEPS';
  }

  final overall = snapshot.activeStatus?.itrStatus?.overallStatus;
  if (overall != null && overall.trim().isNotEmpty) {
    return _toCaps(overall);
  }

  return 'IN PROGRESS';
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

  if (snapshot.showPendingPayment) {
    return 0.1;
  }

  if (selectedPackage != null && snapshot.focusItr == null) {
    return 0.25;
  }

  if (snapshot.focusItr != null) {
    return 0.45;
  }

  if (snapshot.focusOrder != null) {
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

  if (selectedPackage != null && snapshot.focusItr == null) {
    return 'Package selected and ready to start';
  }

  if (snapshot.focusItr?.statusDisplayText != null &&
      snapshot.focusItr!.statusDisplayText!.trim().isNotEmpty) {
    return snapshot.focusItr!.statusDisplayText!;
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

  if (selectedPackage != null && snapshot.focusItr == null) {
    return 'Complete your profile details and upload documents so we can create your active return.';
  }

  if (snapshot.focusOrder?.status != null &&
      snapshot.focusOrder!.status!.trim().isNotEmpty) {
    return 'Latest order status: ${_toCaps(snapshot.focusOrder!.status!)}';
  }

  return 'Your filing workspace is open and ready for the next action.';
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

bool _isWorkflowCompleted(HomeDashboardSnapshot snapshot) {
  final status = snapshot.activeStatus?.itrStatus;
  if (status == null) {
    return false;
  }

  if ((status.overallStatus ?? '').trim().toLowerCase() == 'completed') {
    return true;
  }

  final steps = status.steps ?? const <ItrStatusStepModel>[];
  if (steps.isNotEmpty && steps.every((step) => step.isCompleted == true)) {
    return true;
  }

  final currentStep = status.currentStep ?? 0;
  final totalSteps = status.totalSteps ?? 0;
  if (totalSteps > 0 && currentStep >= totalSteps) {
    return true;
  }

  return false;
}

String _liveTrackingHeaderLabel(HomeDashboardSnapshot snapshot) {
  if (_isWorkflowCompleted(snapshot)) {
    return 'ITR FILED';
  }

  final overall = snapshot.activeStatus?.itrStatus?.overallStatus;
  if (overall != null && overall.trim().isNotEmpty) {
    return _toCaps(overall);
  }

  return 'IN PROGRESS';
}

String _workspaceStatusBadgeLabel(HomeDashboardSnapshot snapshot) {
  if (_isWorkflowCompleted(snapshot)) {
    return 'ITR Filed';
  }

  final overall = snapshot.activeStatus?.itrStatus?.overallStatus;
  if (overall != null && overall.trim().isNotEmpty) {
    return _toCaps(overall);
  }

  return 'In Progress';
}

String _expertSummaryLabel(HomeDashboardSnapshot snapshot) {
  final assigned = snapshot.activeStatus?.assignmentStatus?.professionalName;
  if (assigned != null && assigned.trim().isNotEmpty) {
    return assigned.trim();
  }

  if (_isWorkflowCompleted(snapshot)) {
    return 'Expert Assigned';
  }

  return 'Assigning soon';
}
