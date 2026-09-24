import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tax_client/core/common/widgets/core_scaffold.dart';
import 'package:tax_client/core/common/widgets/primary_button.dart';
import 'package:tax_client/core/config/theme/app_colors.dart';
import 'package:tax_client/core/config/theme/app_spacing.dart';
import 'package:tax_client/core/network/token_storage.dart';
import 'package:tax_client/core/utils/error_handler.dart';
import 'package:tax_client/features/associates/data/models/associate_models.dart';
import 'package:tax_client/features/associates/presentation/providers/associate_provider.dart';
import 'package:tax_client/features/packages/presentation/providers/package_provider.dart';
import 'package:tax_client/features/personal_info/presentation/providers/personal_info_provider.dart';
import 'package:tax_client/features/personal_info/presentation/providers/personal_info_state.dart';

class AssociateDetailScreen extends ConsumerStatefulWidget {
  final int associateId;
  final int? serviceId;

  const AssociateDetailScreen({
    super.key,
    required this.associateId,
    this.serviceId,
  });

  @override
  ConsumerState<AssociateDetailScreen> createState() =>
      _AssociateDetailScreenState();
}

class _AssociateDetailScreenState extends ConsumerState<AssociateDetailScreen> {
  int? _selectedServiceId;
  bool _selecting = false;

  Future<void> _select(AssociateModel associate, AssociateServiceFee fee) async {
    setState(() => _selecting = true);
    ref.read(selectedAssociateProvider.notifier).state = AssociateSelection(
      associateId: associate.id,
      associateName: associate.name,
      role: associate.role,
      serviceId: fee.serviceId,
      serviceName: fee.serviceName,
      quotedFee: fee.fee,
      city: associate.city,
      yearsExperience: associate.yearsExperience,
    );
    ref.read(selectedPackageProvider.notifier).state = null;

    final tokenStorage = ref.read(tokenStorageProvider);
    final userId = await tokenStorage.getUserId();
    if (userId == null || userId.isEmpty) {
      if (mounted) {
        ErrorHandler.showError(context, 'Please login again');
        setState(() => _selecting = false);
      }
      return;
    }

    await ref.read(personalInfoViewModelProvider.notifier).getItrByUser(userId);
    if (!mounted) return;
    setState(() => _selecting = false);

    final state = ref.read(personalInfoViewModelProvider);
    if (state is ItrListLoaded && state.count > 0) {
      context.push('/itr_list');
    } else {
      context.push('/personal_info');
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncAssociate = ref.watch(associateDetailProvider(widget.associateId));

    return CoreScaffold(
      title: 'Associate',
      backgroundColor: AppColors.authBackground,
      appBarColor: AppColors.authBackground,
      useScrollView: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      body: asyncAssociate.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Text(
          error.toString(),
          style: const TextStyle(color: Colors.white70),
        ),
        data: (associate) {
          final services = associate.services;
          final selectedId = _selectedServiceId ??
              widget.serviceId ??
              (services.isNotEmpty ? services.first.serviceId : null);
          final matches = services.where((item) => item.serviceId == selectedId);
          final selectedFee = matches.isNotEmpty
              ? matches.first
              : (services.isNotEmpty ? services.first : null);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                associate.role,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Text(
                associate.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${associate.yearsExperience} years · ${associate.city.isEmpty ? 'India' : associate.city}',
                style: const TextStyle(color: Colors.white70),
              ),
              if (associate.bio.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  associate.bio,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
              const SizedBox(height: 24),
              const Text(
                'Services and fees',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              ...services.map(
                (fee) => RadioListTile<int>(
                  value: fee.serviceId,
                  groupValue: selectedId,
                  onChanged: (value) => setState(() => _selectedServiceId = value),
                  activeColor: AppColors.authMint,
                  title: Text(
                    fee.serviceName,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    '₹${fee.fee.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                text: _selecting ? 'Selecting…' : 'Select associate',
                isLoading: _selecting,
                onPressed: selectedFee == null || _selecting
                    ? null
                    : () => _select(associate, selectedFee),
              ),
            ],
          );
        },
      ),
    );
  }
}
