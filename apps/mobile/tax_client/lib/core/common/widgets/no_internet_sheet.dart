import 'package:flutter/material.dart';
import 'package:tax_client/core/common/widgets/core_bottom_sheet.dart';

Future<void> showNoInternetSheet(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return showCoreBottomSheet<void>(
    context,
    title: 'No Internet Connection',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.wifi_off, color: scheme.error),
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
}
