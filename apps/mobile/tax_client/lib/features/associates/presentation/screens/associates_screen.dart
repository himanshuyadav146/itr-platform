import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tax_client/core/common/widgets/core_scaffold.dart';
import 'package:tax_client/core/config/theme/app_spacing.dart';
import 'package:tax_client/features/associates/presentation/providers/associate_providers.dart';

class AssociatesScreen extends ConsumerWidget {
  final int? serviceId;
  const AssociatesScreen({super.key, this.serviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final associates = ref.watch(associatesListProvider(serviceId));
    return CoreScaffold(
      title: 'Choose an associate',
      body: associates.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Could not load associates: $err')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No approved associates for this service yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final associate = items[index];
              final fee = associate.services.isEmpty
                  ? null
                  : associate.services.firstWhere(
                      (item) => serviceId == null || item.serviceId == serviceId,
                      orElse: () => associate.services.first,
                    );
              return ListTile(
                tileColor: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Text(associate.name),
                subtitle: Text(
                  [
                    associate.role,
                    if (associate.city.isNotEmpty) associate.city,
                    if (fee?.listedFee != null) '₹${fee!.listedFee!.toStringAsFixed(0)}',
                  ].join(' · '),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  final query = serviceId != null ? '?serviceId=$serviceId' : '';
                  context.push('/associates/${associate.id}$query');
                },
              );
            },
          );
        },
      ),
    );
  }
}
