import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tax_client/core/common/widgets/bottom_nav_bar.dart';
// Removed drawer per new navigation design
import 'package:tax_client/core/common/widgets/core_scaffold.dart';
import 'package:tax_client/core/config/strings/app_strings.dart';
import 'package:tax_client/core/common/enums/journey_type.dart';
import 'package:tax_client/core/network/token_storage.dart';
import 'package:tax_client/core/utils/error_handler.dart';
import 'package:tax_client/features/personal_info/presentation/providers/personal_info_provider.dart';
import 'package:tax_client/features/personal_info/presentation/providers/personal_info_state.dart';
import 'package:tax_client/features/packages/presentation/providers/package_provider.dart';
import 'package:tax_client/features/packages/presentation/widgets/package_bottom_sheet.dart';
import 'package:tax_client/features/packages/data/models/package_model.dart';
import 'package:tax_client/core/config/theme/app_colors.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load packages when home screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(packagesProvider.notifier).getPackages();
    });
  }

  Future<void> _handleFileItr(BuildContext context, JourneyType journeyType) async {
    // Set the journey type
    ref.read(journeyTypeProvider.notifier).state = journeyType;

    final tokenStorage = ref.read(tokenStorageProvider);
    final userId = await tokenStorage.getUserId();
    
    if (userId == null || userId.isEmpty) {
      if (context.mounted) {
        ErrorHandler.showError(context, AppStrings.userIdNotFound);
      }
      return;
    }

    // Check if we need to skip package selection for specific journeys
    PackageModel? selectedPackage;

    if (journeyType == JourneyType.EVerify) {
      // For E-Verification, auto-select the package with ID "7"
      final packagesState = ref.read(packagesProvider);
      if (packagesState.hasValue && packagesState.value != null) {
        try {
          selectedPackage = packagesState.value!.firstWhere((pkg) => pkg.id == "7");
        } catch (_) {
          // Package not found, fallback to manual selection
        }
      }
    }

    // If not auto-selected, show package bottom sheet
    if (selectedPackage == null) {
      if (!context.mounted) return;
      selectedPackage = await showPackageBottomSheet(context, ref);
    }
    
    if (selectedPackage == null) {
      // User cancelled package selection
      return;
    }
    
    // Store selected package
    ref.read(selectedPackageProvider.notifier).state = selectedPackage;
    
    if (!context.mounted) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Call API to get ITR list
    await ref.read(personalInfoViewModelProvider.notifier).getItrByUser(userId);
    
    // Dismiss loading dialog
    if (context.mounted) {
      Navigator.of(context).pop();
    }
    
    // Check the state and navigate accordingly
    final state = ref.read(personalInfoViewModelProvider);
    
    if (!context.mounted) return;
    
    if (state is ItrListLoaded) {
      // If count is 0, user has no personal details - navigate to personal info page
      if (state.count == 0) {
        context.push('/personal_info');
      } else {
        // User has ITR data - navigate to ITR list screen
        context.push('/itr_list');
      }
    } else if (state is ItrListError) {
      ErrorHandler.showError(context, state.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final services = [
      {
        'title': AppStrings.fileItr,
        'icon': Icons.receipt_long,
        'color': AppColors.primary,
      },
      {
        'title': AppStrings.itrVerification,
        'icon': Icons.verified_user,
        'color': AppColors.success,
      },
      // {
      //   'title': AppStrings.gstFiling,
      //   'icon': Icons.request_page,
      //   'color': Colors.orangeAccent,
      // },
      // {
      //   'title': AppStrings.getLoan,
      //   'icon': Icons.account_balance,
      //   'color': Colors.purpleAccent,
      // },
      {
        'title': AppStrings.packages,
        'icon': Icons.grid_view_rounded,
        'color': AppColors.info,
      },
    ];


    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        SystemNavigator.pop();
      },
      child: CoreScaffold(
      title: AppStrings.homeTitle,
      // actions: [
      //   // IconButton(
      //   //   icon: const Icon(Icons.brightness_6),
      //   //   onPressed: () {
      //   //     ref.read(themeProvider.notifier).toggleTheme();
      //   //   },
      //   // ),
      // ],
      includeDrawer: false,
      useScrollView: true,
      centered: false,
      padding: EdgeInsets.zero,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SizedBox(height: 120, child: _OffersCarousel()),
            // const SizedBox(height: 16),
            Text(
              AppStrings.selectService,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            /// Grid of service cards
            Column(
              children: List.generate((services.length / 2).ceil(), (index) {
                final int firstIndex = index * 2;
                final int secondIndex = firstIndex + 1;
                final bool hasSecond = secondIndex < services.length;

                Widget buildServiceItem(int i, {double? customIconSize}) {
                  final service = services[i];
                  return _ServiceCard(
                    title: service['title'] as String,
                    icon: service['icon'] as IconData,
                    color: service['color'] as Color,
                    iconSize: customIconSize,
                    onTap: () async {
                      if (service['title'] == AppStrings.fileItr) {
                        await _handleFileItr(context, JourneyType.ITR);
                      } else if (service['title'] == AppStrings.itrVerification) {
                        await _handleFileItr(context, JourneyType.EVerify);
                      } else if (service['title'] == AppStrings.packages) {
                        await showPackageBottomSheet(context, ref);
                      }

                      // Show snackbar for non-ITR related services (except Packages)
                      if (service['title'] != AppStrings.fileItr &&
                          service['title'] != AppStrings.itrVerification &&
                          service['title'] != AppStrings.packages) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${service['title']} ${AppStrings.serviceSelected}',
                              ),
                            ),
                          );
                        }
                      }
                    },
                  );
                }

                if (hasSecond) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: AspectRatio(
                            aspectRatio: 1.0,
                            child: buildServiceItem(firstIndex),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AspectRatio(
                            aspectRatio: 1.0,
                            child: buildServiceItem(secondIndex),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return AspectRatio(
                    aspectRatio: 2.1,
                    child: buildServiceItem(firstIndex, customIconSize: 48),
                  );
                }
              }),
            ),
            const SizedBox(height: 20),
            // Text(
            //   AppStrings.taxExperts,
            //   style: theme.textTheme.titleLarge?.copyWith(
            //     fontWeight: FontWeight.w700,
            //   ),
            // ),
            // const SizedBox(height: 12),
            // SizedBox(
            //   height: 130,
            //   child: ListView.separated(
            //     scrollDirection: Axis.horizontal,
            //     itemCount: 6,
            //     separatorBuilder: (_, __) => const SizedBox(width: 12),
            //     itemBuilder: (context, idx) {
            //       return _ExpertCard(index: idx);
            //     },
            //   ),
            // ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(),
    ));
  }
}

class _OffersCarousel extends StatefulWidget {
  @override
  State<_OffersCarousel> createState() => _OffersCarouselState();
}

class _OffersCarouselState extends State<_OffersCarousel> {
  final PageController _controller = PageController(viewportFraction: 0.9);
  int _index = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      while (mounted) {
        await Future.delayed(const Duration(seconds: 3));
        _index = (_index + 1) % 3;
        _controller.animateToPage(
          _index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PageView.builder(
      controller: _controller,
      itemCount: 3,
      itemBuilder: (context, idx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  scheme.primary.withOpacity(0.12),
                  scheme.surfaceContainerHigh,
                ],
              ),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Center(
              child: Text(
                '${AppStrings.offers} ${idx + 1}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ExpertCard extends StatelessWidget {
  final int index;
  const _ExpertCard({required this.index});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(radius: 28, child: Icon(Icons.person)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Expert ${index + 1}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text('ITR, GST', style: Theme.of(context).textTheme.bodySmall),
                Text(
                  'Experience: ${3 + index} yrs',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Single service tile widget
class _ServiceCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double? iconSize;

  const _ServiceCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: onSurface, size: iconSize ?? 40),
            const SizedBox(height: 10),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(color: onSurface),
            ),
          ],
        ),
      ),
    );
  }
}
