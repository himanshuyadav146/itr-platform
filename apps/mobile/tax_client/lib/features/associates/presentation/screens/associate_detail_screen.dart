import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tax_client/core/common/widgets/core_scaffold.dart';
import 'package:tax_client/core/common/widgets/primary_button.dart';
import 'package:tax_client/core/config/theme/app_spacing.dart';
import 'package:tax_client/features/associates/presentation/providers/associate_providers.dart';

class AssociateDetailScreen extends ConsumerWidget {
  final int associateId;
  final int? serviceId;

  const AssociateDetailScreen({
    super.key,
    required this.associateId,
    this.serviceId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(associateDetailProvider(associateId));
    return CoreScaffold(
      title: 'Associate',
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Could not load profile: $err')),
        data: (associate) {
          final fee = associate.services.isEmpty
              ? null
              : associate.services.firstWhere(
                  (item) => serviceId == null || item.serviceId == serviceId,
                  orElse: () => associate.services.first,
                );
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(associate.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text('${associate.role}${associate.city.isNotEmpty ? ' · ${associate.city}' : ''}'),
              if (associate.icaiMembershipNo.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text('ICAI: ${associate.icaiMembershipNo}'),
                ),
              const SizedBox(height: AppSpacing.lg),
              Text(associate.bio.isEmpty ? 'Experienced tax professional.' : associate.bio),
              const SizedBox(height: AppSpacing.xl),
              Text('Listed fees', style: Theme.of(context).textTheme.titleMedium),
              ...associate.services.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.serviceName),
                  trailing: Text(item.listedFee == null ? '—' : '₹${item.listedFee!.toStringAsFixed(0)}'),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (fee != null)
                Text(
                  'You pay this associate ₹${fee.listedFee?.toStringAsFixed(0) ?? '—'} plus GST and filing charges.',
                ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                text: 'Book this associate',
                onPressed: fee == null
                    ? null
                    : () {
                        ref.read(selectedAssociateProvider.notifier).state = associate;
                        final catalog = ref.read(selectedCatalogServiceProvider);
                        if (catalog == null && serviceId != null) {
                          ref.read(selectedCatalogServiceProvider.notifier).state = catalog;
                        }
                        context.push('/personal_info');
                      },
              ),
            ],
          );
        },
      ),
    );
  }
}
