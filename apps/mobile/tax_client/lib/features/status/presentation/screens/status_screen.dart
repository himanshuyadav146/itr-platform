import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:tax_client/core/common/widgets/core_scaffold.dart';
import 'package:tax_client/core/config/strings/app_strings.dart';
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

  @override
  void initState() {
    super.initState();

    // ref.read(statusViewModelProvider.notifier).fetchDetailedStatus("ORD1768674190EF3248");

    // Fetch detailed status if data is available
    // Fetch detailed status if data is available
    // Fetch detailed status if data is available
    // Fetch detailed status if data is available
    final idToFetch = widget.itrData?.id ?? widget.orderId;
    if (idToFetch != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(statusViewModelProvider.notifier).fetchDetailedStatus(
          widget.itrData?.id ?? '',
          widget.itrData?.itrId ?? '',
            );
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
      'pan', 'name', 'address', 'aadhar', 'aadhaar', 'email',
      'mobile', 'phone', 'dob', 'date of birth', 'personal',
    ];
    final isPersonalInfo =
        personalInfoKeywords.any((kw) => lower.contains(kw));

    if (isPersonalInfo) {
      context.push('/personal_info', extra: widget.itrData);
    } else {
      context.push('/document_upload');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final statusState = ref.watch(statusViewModelProvider);

    return CoreScaffold(
      title: AppStrings.trackProgress,
      showBackButton: true,
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      },
      centered: false,
      useScrollView: true,
      backgroundColor: scheme.surface,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID / Context
            if (widget.itrData != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: scheme.outlineVariant.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: scheme.primary,
                      radius: 20,
                      child: const Icon(Icons.description,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tracking ITR for',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '${widget.itrData!.firstName} ${widget.itrData!.lastName}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.itrData!.financialYear,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              AppStrings.realtimeUpdates,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),

            // Timeline or Loading/Error
            statusState.when(
              initial: () => const SizedBox.shrink(),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (message) => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Text(message, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          final idToFetch = widget.itrData?.id ?? widget.orderId;
                          if (idToFetch != null) {
                            ref
                                .read(statusViewModelProvider.notifier)
                                .fetchDetailedStatus(
                              widget.itrData?.id ?? '',
                                  widget.itrData?.itrId ?? '',
                                );
                          }
                        },
                        child: const Text(AppStrings.retry),
                      ),
                    ],
                  ),
                ),
              ),
              loaded: (detailedStatus) {
                final itrStatus = detailedStatus.itrStatus;
                final steps = itrStatus?.steps ?? [];
                final currentStep = itrStatus?.currentStep ?? 0;
                
                // If currentStep is 5 (or >= steps.length), it means all steps are done
                final allDone = (currentStep >= steps.length && steps.isNotEmpty) || 
                                itrStatus?.overallStatus == 'completed';
                
                if (allDone && !_controller.isAnimating && !_controller.isCompleted) {
                  _controller.forward();
                }

                return Column(
                  children: [
                    if (steps.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Text('No status updates available'),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: steps.length,
                        itemBuilder: (context, index) {
                          final step = steps[index];
                          
                          // Determine subtitle based on step key
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
                                subtitle = 'ITR Acknowledgement generated';
                                break;
                            }
                          }

                          final Animation<double> animation = CurvedAnimation(
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
                        },
                      ),
                    const SizedBox(height: 32),
                    if (allDone)
                      ScaleTransition(
                        scale: _scale,
                        child: _SuccessCard(scheme: scheme, theme: theme),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessCard extends StatelessWidget {
  final ColorScheme scheme;
  final ThemeData theme;

  const _SuccessCard({required this.scheme, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            scheme.primary.withOpacity(0.15),
            scheme.surfaceContainerHigh,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: scheme.primary.withOpacity(0.25),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 6),
            color: scheme.primary.withOpacity(0.08),
          ),
        ],
      ),
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
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.filedSuccessfully,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: scheme.onSurface.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 16,
            ),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              AppStrings.ackMailSent,
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
