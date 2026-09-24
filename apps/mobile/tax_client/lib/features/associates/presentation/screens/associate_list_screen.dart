import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tax_client/core/common/widgets/core_scaffold.dart';
import 'package:tax_client/core/config/theme/app_colors.dart';
import 'package:tax_client/core/config/theme/app_spacing.dart';
import 'package:tax_client/features/associates/presentation/providers/associate_provider.dart';

class AssociateListScreen extends ConsumerWidget {
  final int? serviceId;

  const AssociateListScreen({super.key, this.serviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final associates = ref.watch(associatesListProvider(serviceId));

    return CoreScaffold(
      title: 'Verified associates',
      backgroundColor: AppColors.authBackground,
      appBarColor: AppColors.authBackground,
      useScrollView: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      body: associates.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Text(
          error.toString(),
          style: const TextStyle(color: Colors.white70),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Text(
              'No associates are listed for this service yet.',
              style: TextStyle(color: Colors.white70),
            );
          }
          return Column(
            children: items
                .map(
                  (associate) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      tileColor: AppColors.authCardSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: Text(
                        associate.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${associate.role} · ${associate.yearsExperience} yrs · ${associate.city.isEmpty ? 'India' : associate.city}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: Text(
                        associate.listedFee != null
                            ? '₹${associate.listedFee!.toStringAsFixed(0)}'
                            : '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () {
                        final query = serviceId != null ? '?serviceId=$serviceId' : '';
                        context.push('/associates/${associate.id}$query');
                      },
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}
