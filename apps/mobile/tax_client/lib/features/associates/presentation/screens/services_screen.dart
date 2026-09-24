import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tax_client/core/common/widgets/core_scaffold.dart';
import 'package:tax_client/core/config/theme/app_spacing.dart';
import 'package:tax_client/features/associates/presentation/providers/associate_providers.dart';

class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(catalogServicesProvider);
    return CoreScaffold(
      title: 'Choose a service',
      body: services.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Could not load services: $err')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No services listed yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final service = items[index];
              return ListTile(
                tileColor: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Text(service.name),
                subtitle: Text(service.description.isEmpty
                    ? 'Book a named associate at their listed fee'
                    : service.description),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ref.read(selectedCatalogServiceProvider.notifier).state = service;
                  context.push('/associates?serviceId=${service.id}');
                },
              );
            },
          );
        },
      ),
    );
  }
}
