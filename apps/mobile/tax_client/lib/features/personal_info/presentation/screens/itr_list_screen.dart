import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tax_client/core/common/widgets/core_scaffold.dart';
import 'package:tax_client/core/common/widgets/primary_button.dart';
import 'package:tax_client/core/config/strings/app_strings.dart';
import 'package:tax_client/core/network/token_storage.dart';
import 'package:tax_client/features/personal_info/data/models/itr_personal_detail_model.dart';
import 'package:tax_client/features/personal_info/presentation/providers/personal_info_provider.dart';
import 'package:tax_client/features/personal_info/presentation/providers/personal_info_state.dart';
import 'package:tax_client/core/common/enums/journey_type.dart';
import '../../../../core/common/widgets/custom_card.dart';

class ItrListScreen extends ConsumerStatefulWidget {
  const ItrListScreen({super.key});

  @override
  ConsumerState<ItrListScreen> createState() => _ItrListScreenState();
}

class _ItrListScreenState extends ConsumerState<ItrListScreen> {
  Future<void> _loadItrList() async {
    final tokenStorage = ref.read(tokenStorageProvider);
    final userId = await tokenStorage.getUserId();
    
    if (userId != null && userId.isNotEmpty) {
      ref.read(personalInfoViewModelProvider.notifier).getItrByUser(userId);
    }
  }

  void _handleContinue(ItrPersonalDetailModel itrItem) async {
    final tokenStorage = ref.read(tokenStorageProvider);
    
    // Save PAN number for the selected ITR
    await tokenStorage.savePanNumber(itrItem.panNumber);
    
    // Navigate to personal information page with ITR data
    if (mounted) {
      context.push('/personal_info', extra: itrItem);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(personalInfoViewModelProvider);
    final theme = Theme.of(context);

    return CoreScaffold(
      title: AppStrings.myItrRecords,
      useScrollView: false,
      body: _buildBody(context, state, theme),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ref.read(journeyTypeProvider.notifier).state = JourneyType.ITR;
          context.push('/personal_info');
        },
        label: const Text('Add New ITR'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(BuildContext context, PersonalInfoState state, ThemeData theme) {
    if (state is ItrListLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state is ItrListError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              state.message,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: AppStrings.retry,
              onPressed: _loadItrList,
            ),
          ],
        ),
      );
    }

    if (state is ItrListLoaded) {
      if (state.itrList.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 64,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.noItrRecordsFound,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.startByFilingNewItr,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: AppStrings.fileNewItr,
                onPressed: () {
                  ref.read(journeyTypeProvider.notifier).state = JourneyType.ITR;
                  context.push('/personal_info');
                },
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        itemCount: state.itrList.length,
        itemBuilder: (context, index) {
          final itrItem = state.itrList[index] as ItrPersonalDetailModel;
          return _ItrListItem(
            itrItem: itrItem,
            onContinue: () => _handleContinue(itrItem),
          );
        },
      );
    }

    if (state is PersonalInfoSuccess || state is PersonalInfoLoaded) {
      // If we returned to this screen but state is from Personal Info operations,
      // reload the list to show fresh data and correct UI.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadItrList();
      });
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return const SizedBox.shrink();
  }
}

class _ItrListItem extends StatelessWidget {
  final ItrPersonalDetailModel itrItem;
  final VoidCallback onContinue;

  const _ItrListItem({
    required this.itrItem,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    
    final fullName = '${itrItem.firstName} ${itrItem.middleName ?? ''} ${itrItem.lastName}'.trim();

    return CustomCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(0), // Reset padding as InkWell handles it
      // decoration removed as it's inside CustomCard
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30), // Match CustomCard radius
          onTap: onContinue,
          child: Padding(
            padding: const EdgeInsets.all(20), // Match CustomCard default padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with name and financial year
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              itrItem.financialYear,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Package Name Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.description,
                            size: 14,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            itrItem.packageName ?? 'Package',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Info cards
                Row(
                  children: [
                    Expanded(
                      child: _InfoCard(
                        icon: Icons.phone,
                        label: AppStrings.mobile,
                        value: itrItem.mobileNumber,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InfoCard(
                        icon: Icons.badge,
                        label: AppStrings.pan,
                        value: itrItem.panNumber,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Continue button
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    text: AppStrings.continue_,
                    onPressed: onContinue,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
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

