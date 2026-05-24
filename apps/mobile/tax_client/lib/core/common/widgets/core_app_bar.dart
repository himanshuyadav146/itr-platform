import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CoreAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final bool? showBackButton; // null => auto
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final bool centerTitle;
  final Color? backgroundColor;
  final double elevation;
  final PreferredSizeWidget? bottom;
  final Widget? leading; // overrides back button

  const CoreAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.showBackButton,
    this.onBack,
    this.actions,
    this.centerTitle = true,
    this.backgroundColor,
    this.elevation = 0,
    this.bottom,
    this.leading,
  });

  bool _canPop(BuildContext context) {
    // Prefer GoRouter's stack awareness if available
    try {
      return GoRouter.of(context).canPop();
    } catch (_) {
      return Navigator.of(context).canPop();
    }
  }

  void _handleBack(BuildContext context) {
    if (onBack != null) {
      onBack!.call();
      return;
    }
    // Default: pop via GoRouter if available, else Navigator
    // Use maybePop to prevent app closure if nothing to pop
    try {
      if (GoRouter.of(context).canPop()) {
        context.pop();
      } else {
        // If can't pop, try to go to home or login
        final router = GoRouter.of(context);
        final currentLocation = router.routerDelegate.currentConfiguration.uri.path;
        if (currentLocation != '/' && currentLocation != '/login') {
          router.go('/');
        }
      }
    } catch (_) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).maybePop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final autoShowBack = _canPop(context);
    final shouldShowBack = showBackButton ?? autoShowBack;

    return AppBar(
      title: titleWidget ?? (title != null ? Text(title!) : null),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor,
      elevation: elevation,
      bottom: bottom,
      leading:
          leading ??
          (shouldShowBack
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => _handleBack(context),
                )
              : null),
      actions: actions,
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}
