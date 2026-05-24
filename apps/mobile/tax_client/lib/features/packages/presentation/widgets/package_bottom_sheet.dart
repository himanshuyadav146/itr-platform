import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tax_client/features/packages/data/models/package_model.dart';
import 'package:tax_client/features/packages/presentation/providers/package_provider.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../../../core/common/widgets/custom_card.dart';

Future<PackageModel?> showPackageBottomSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final result = await showModalBottomSheet<PackageModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const PackageBottomSheet(),
  );
  return result;
}

class PackageBottomSheet extends ConsumerStatefulWidget {
  const PackageBottomSheet({super.key});

  @override
  ConsumerState<PackageBottomSheet> createState() => _PackageBottomSheetState();
}

class _PackageBottomSheetState extends ConsumerState<PackageBottomSheet> {
  int? _selectedIndex;

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'business_center_outlined':
        return Icons.business_center_outlined;
      case 'trending_up':
        return Icons.trending_up;
      case 'apartment':
        return Icons.apartment;
      case 'domain':
        return Icons.domain;
      case 'flight_takeoff':
        return Icons.flight_takeoff;
      case 'business':
        return Icons.business;
      case 'verified_user':
        return Icons.verified_user;
      default:
        return Icons.card_giftcard;
    }
  }

  Color _getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'teal':
        return Colors.teal;
      case 'indigo':
        return Colors.indigo;
      case 'cyan':
        return Colors.cyan;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final packagesAsync = ref.watch(packagesProvider);

    return SafeArea(
      bottom: true,
      top: false,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Expanded(
              child: packagesAsync.when(
                data: (packages) => _buildPackagesList(packages, theme, isDark),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load packages',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackagesList(List<PackageModel> packages, ThemeData theme, bool isDark) {
    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Text(
                  'Our Pricing Plans',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose the perfect plan for your needs',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SliverToBoxAdapter(
          child: Divider(height: 1),
        ),
        
        // Packages List
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final package = packages[index];
                final isSelected = _selectedIndex == index;
                final color = _getColorFromString(package.color);
                final icon = _getIconFromString(package.icon);
                
                return CustomCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  backgroundColor: isSelected
                        ? color.withOpacity(isDark ? 0.2 : 0.1)
                        : theme.colorScheme.surface,
                  border: Border.all(
                    color: isSelected
                        ? color
                        : theme.colorScheme.outlineVariant,
                    width: isSelected ? 2 : 1,
                  ),
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                    // Close bottom sheet and return selected package
                    Navigator.of(context).pop(package);
                  },
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          color: color,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              package.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Html(
                              data: package.description.contains(RegExp(r'<[^>]+>')) 
                                  ? package.description 
                                  : package.description.replaceAll('\n', '<br/>'),
                              style: {
                                "body": Style(
                                  margin: Margins.zero,
                                  padding: HtmlPaddings.zero,
                                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                                  fontSize: FontSize(theme.textTheme.bodySmall?.fontSize ?? 12.0),
                                  fontWeight: theme.textTheme.bodySmall?.fontWeight,
                                ),
                              },
                            ),
                            if (package.turnover != null && package.turnover!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Turnover: ${package.turnover}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSecondaryContainer,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      // Price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            package.price,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          if (isSelected)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Selected',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
              childCount: packages.length,
            ),
          ),
        ),
        
        // Note
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'NOTE: All prices listed are starting prices and may increase based on additional services, complexity, or extended requirements.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}
