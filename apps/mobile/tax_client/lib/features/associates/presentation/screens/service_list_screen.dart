import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tax_client/core/common/widgets/core_scaffold.dart';
import 'package:tax_client/core/config/theme/app_colors.dart';
import 'package:tax_client/core/config/theme/app_spacing.dart';
import 'package:tax_client/features/associates/presentation/providers/associate_provider.dart';

class ServiceListScreen extends ConsumerWidget {
  const ServiceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(catalogServicesProvider);

    return CoreScaffold(
      title: 'Choose a service',
      backgroundColor: AppColors.authBackground,
      appBarColor: AppColors.authBackground,
      useScrollView: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      body: services.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Text(
          error.toString(),
          style: const TextStyle(color: Colors.white70),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Text(
              'No services are available yet.',
              style: TextStyle(color: Colors.white70),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pick a service, then choose a verified associate.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              ...items.map(
                (service) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    tileColor: AppColors.authCardSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Text(
                      service.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      service.description,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Colors.white),
                    onTap: () {
                      ref.read(selectedServiceProvider.notifier).state = service;
                      context.push('/associates?serviceId=${service.id}');
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
