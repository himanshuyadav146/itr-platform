import 'package:flutter/material.dart';
import 'package:tax_client/core/common/widgets/core_bottom_sheet.dart';

/// Shows the offline sheet. Never throws — failures are ignored so API flows
/// are not blocked by UI presentation errors.
Future<void> showNoInternetSheet(BuildContext context) async {
  try {
    if (!context.mounted) return;

    final navigator = Navigator.maybeOf(context, rootNavigator: true);
    if (navigator == null) return;

    await showCoreBottomSheet<void>(
      context,
      title: 'No Internet Connection',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.wifi_off,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Please check your network and try again.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  } catch (e, st) {
    debugPrint('showNoInternetSheet ignored: $e\n$st');
  }
}
