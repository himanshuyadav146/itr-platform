import 'package:flutter/material.dart';

Future<T?> showCoreBottomSheet<T>(
  BuildContext context, {
  String? title,
  required Widget child,
  List<Widget>? actions,
}) {
  if (!context.mounted) {
    return Future<T?>.value();
  }

  final navigator = Navigator.maybeOf(context, rootNavigator: true);
  if (navigator == null) {
    return Future<T?>.value();
  }

  final scheme = Theme.of(context).colorScheme;
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: scheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).maybePop(),
                      ),
                    ],
                  ),
                ),
              // Do not use Flexible here — Column is mainAxisSize.min (unbounded)
              // and Flexible would throw a layout error.
              child,
              if (actions != null && actions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(children: actions),
                ),
            ],
          ),
        ),
      );
    },
  );
}
