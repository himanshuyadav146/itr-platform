import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:tax_client/core/common/widgets/custom_card.dart';
import 'package:tax_client/core/common/widgets/core_scaffold.dart';
import 'package:tax_client/core/common/widgets/primary_button.dart';
import 'package:tax_client/core/config/strings/app_strings.dart';
import 'package:tax_client/core/config/theme/app_colors.dart';
import 'package:tax_client/core/config/theme/app_spacing.dart';
import 'package:tax_client/features/personal_info/data/models/itr_personal_detail_model.dart';

import 'package:tax_client/features/status/presentation/viewmodel/status_view_model.dart';
import 'package:tax_client/features/status/presentation/widgets/status_timeline_tile.dart';

class StatusScreen extends ConsumerStatefulWidget {
  final ItrPersonalDetailModel? itrData;
  final String? orderId;
  const StatusScreen({super.key, this.itrData, this.orderId});

  @override
  ConsumerState<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends ConsumerState<StatusScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late AnimationController _listController;

  String get _statusOrderId => widget.itrData?.id ?? widget.orderId ?? '';
  String get _statusItrId => widget.itrData?.itrId ?? '';

  void _loadStatus() {
    if (_statusOrderId.isEmpty) {
      return;
    }
    ref
        .read(statusViewModelProvider.notifier)
        .fetchDetailedStatus(_statusOrderId, _statusItrId);
  }

  @override
  void initState() {
    super.initState();
    if (_statusOrderId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadStatus();
      });
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scale = Tween<double>(
      begin: 0.75,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      _listController.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _listController.dispose();
    super.dispose();
  }

  /// Determines the destination page from the update message text.
  /// Keywords related to personal information go to /personal_info;
  /// everything else (documents, forms, uploads) goes to /document_upload.
  void _navigateFromUpdateMessage(String message) {
    final lower = message.toLowerCase();
    const personalInfoKeywords = [
      'pan',
      'name',
      'address',
      'aadhar',
      'aadhaar',
      'email',
      'mobile',
      'phone',
      'dob',
      'date of birth',
      'personal',
    ];
    final isPersonalInfo = personalInfoKeywords.any((kw) => lower.contains(kw));

    if (isPersonalInfo) {
      context.push('/personal_info', extra: widget.itrData);
    } else {
      context.push('/document_upload');
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusState = ref.watch(statusViewModelProvider);
    final currentName = widget.itrData != null
        ? '${widget.itrData!.firstName} ${widget.itrData!.lastName}'.trim()
        : 'Active order';

    return CoreScaffold(
      includeAppBar: false,
      useScrollView: true,
      centered: true,
      useResponsiveMaxWidth: true,
      maxContentWidth: 560,
      backgroundColor: AppColors.authBackground,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusHeader(
            onBack: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          _StatusHeroCard(
            currentName: currentName,
            financialYear: widget.itrData?.financialYear,
            orderId: _statusOrderId,
          ),
          const SizedBox(height: AppSpacing.xl),
          statusState.when(
            initial: () => const _StatusLoadingState(),
            loading: () => const _StatusLoadingState(),
            error: (message) =>
                _StatusErrorState(message: message, onRetry: _loadStatus),
            loaded: (detailedStatus) {
              final itrStatus = detailedStatus.itrStatus;
              final steps = itrStatus?.steps ?? [];
              final currentStep = itrStatus?.currentStep ?? 0;
              final overallStatus = (itrStatus?.overallStatus ?? '')
                  .toLowerCase();
              final allDone =
                  (currentStep >= steps.length && steps.isNotEmpty) ||
                  overallStatus == 'completed';

              if (allDone &&
                  !_controller.isAnimating &&
                  !_controller.isCompleted) {
                _controller.forward();
              }

              if (steps.isEmpty) {
                return const _StatusEmptyState();
              }

              return Column(
                children: [
                  _StatusOverviewCard(
                    progressPercentage: itrStatus?.progressPercentage ?? 0,
                    totalSteps: itrStatus?.totalSteps ?? steps.length,
                    completedSteps: steps
                        .where((step) => step.isCompleted ?? false)
                        .length,
                    overallStatus: overallStatus.isEmpty
                        ? 'in progress'
                        : overallStatus,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ...List.generate(steps.length, (index) {
                    final step = steps[index];
                    String subtitle = step.notes ?? '';
                    if (subtitle.isEmpty) {
                      switch (step.step) {
                        case 'payment_success':
                          subtitle = 'Payment confirmed';
                          break;
                        case 'expert_assigned':
                          subtitle = 'Expert reviewing your case';
                          break;
                        case 'documents_verified':
                          subtitle = 'Verifying uploaded documents';
                          break;
                        case 'filing_itr':
                          subtitle = 'Filing process in progress';
                          break;
                        case 'acknowledgement_generated':
                          subtitle = 'ITR acknowledgement generated';
                          break;
                      }
                    }

                    final animation = CurvedAnimation(
                      parent: _listController,
                      curve: Interval(
                        (index / steps.length) * 0.5,
                        1.0,
                        curve: Curves.easeOutQuart,
                      ),
                    );

                    return StatusTimelineTile(
                      title: step.title ?? '',
                      subtitle: subtitle,
                      isCompleted: step.isCompleted ?? false,
                      isActive: index == currentStep,
                      isLast: index == steps.length - 1,
                      index: index,
                      animation: animation,
                      statusUpdates: step.step == 'documents_verified'
                          ? detailedStatus.statusUpdates
                          : null,
                      expertInfo: step.step == 'expert_assigned'
                          ? detailedStatus.assignmentStatus
                          : null,
                      onActionTap: step.step == 'documents_verified'
                          ? _navigateFromUpdateMessage
                          : null,
                    );
                  }),
                  if (allDone) ...[
                    const SizedBox(height: AppSpacing.lg),
                    ScaleTransition(scale: _scale, child: const _SuccessCard()),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _StatusHeader({required this.onBack});

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
                AppStrings.trackProgress,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.authHeading,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                AppStrings.realtimeUpdates,
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

class _StatusHeroCard extends StatelessWidget {
  final String currentName;
  final String? financialYear;
  final String orderId;

  const _StatusHeroCard({
    required this.currentName,
    required this.financialYear,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomCard(
      backgroundColor: AppColors.authCardSurface,
      border: Border.all(color: AppColors.authCardBorder),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Track your filing journey live',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppColors.authHeading,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'See the current step, review updates, and act quickly on anything that still needs your attention.',
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
              _StatusChip(
                icon: Icons.person_outline_rounded,
                label: currentName,
                accent: AppColors.authMint,
              ),
              if (financialYear != null && financialYear!.trim().isNotEmpty)
                _StatusChip(
                  icon: Icons.calendar_today_outlined,
                  label: financialYear!,
                  accent: AppColors.authAmber,
                ),
              if (orderId.trim().isNotEmpty)
                _StatusChip(
                  icon: Icons.receipt_long_outlined,
                  label: orderId,
                  accent: AppColors.authHeading,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;

  const _StatusChip({
    required this.icon,
    required this.label,
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
          Icon(icon, size: 16, color: accent),
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

class _StatusOverviewCard extends StatelessWidget {
  final int progressPercentage;
  final int totalSteps;
  final int completedSteps;
  final String overallStatus;

  const _StatusOverviewCard({
    required this.progressPercentage,
    required this.totalSteps,
    required this.completedSteps,
    required this.overallStatus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clampedProgress = progressPercentage.clamp(0, 100);

    return CustomCard(
      backgroundColor: const Color(0x08FFFFFF),
      border: Border.all(color: AppColors.borderOnDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Filing overview',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.authHeading,
                    fontWeight: FontWeight.w700,
                  ),
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
                  '${clampedProgress.toInt()}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.authMint,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$completedSteps of $totalSteps workflow steps completed. Current status: $overallStatus.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.authMuted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            child: LinearProgressIndicator(
              value: clampedProgress / 100,
              minHeight: 10,
              backgroundColor: AppColors.surfaceVariantDark.withValues(
                alpha: 0.35,
              ),
              color: AppColors.authMint,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusLoadingState extends StatelessWidget {
  const _StatusLoadingState();

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
            'Loading status updates...',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.authHeading,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Fetching the latest filing progress.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.authMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _StatusErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: CustomCard(
        backgroundColor: const Color(0x08FFFFFF),
        border: Border.all(color: AppColors.borderOnDark),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.authAmber.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppColors.authAmber,
                size: 30,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Unable to load status',
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
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                text: AppStrings.retry.toUpperCase(),
                onPressed: onRetry,
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
    );
  }
}

class _StatusEmptyState extends StatelessWidget {
  const _StatusEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: CustomCard(
        backgroundColor: const Color(0x08FFFFFF),
        border: Border.all(color: AppColors.borderOnDark),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.authMuted.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.timeline_outlined,
                color: AppColors.authMuted,
                size: 30,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No status updates available',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.authHeading,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'We will show each filing stage here once processing starts.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.authMuted,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessCard extends StatelessWidget {
  const _SuccessCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomCard(
      backgroundColor: AppColors.authCardSurface,
      border: Border.all(color: AppColors.authCardBorder),
      child: Column(
        children: [
          SizedBox(
            height: 120,
            child: Lottie.asset(
              'assets/animations/success.json',
              repeat: false,
            ),
          ),
          Text(
            AppStrings.congratulations,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.authMint,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppStrings.filedSuccessfully,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.authMuted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm,
              horizontal: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariantDark.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Text(
              AppStrings.ackMailSent,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 12,
                color: AppColors.authHeading,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
