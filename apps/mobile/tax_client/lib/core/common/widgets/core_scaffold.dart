import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tax_client/core/common/widgets/core_app_bar.dart';
import 'package:tax_client/core/common/widgets/side_drawer.dart';

class CoreScaffold extends StatelessWidget {
  final Widget body;

  // AppBar configuration
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final bool? showBackButton; // null => auto
  final VoidCallback? onBack;
  final bool centerTitle;
  final Color? appBarColor;
  final double appBarElevation;
  final PreferredSizeWidget? appBarBottom;
  final Widget? appBarLeading;
  final bool includeAppBar;

  // Scaffold configuration
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final bool includeDrawer;

  // Layout configuration
  final EdgeInsetsGeometry? padding;
  final bool useScrollView;
  final bool centered;
  final bool useSafeArea;
  final bool useResponsiveMaxWidth;
  final double responsiveBreakpoint;
  final double maxContentWidth;
  final bool adjustPaddingForKeyboard;
  final double keyboardPaddingExtra;

  const CoreScaffold({
    super.key,
    required this.body,
    // AppBar config
    this.title,
    this.titleWidget,
    this.actions,
    this.showBackButton,
    this.onBack,
    this.centerTitle = true,
    this.appBarColor,
    this.appBarElevation = 0,
    this.appBarBottom,
    this.appBarLeading,
    this.includeAppBar = true,
    // Scaffold config
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.drawer,
    this.includeDrawer = false,
    // Layout config
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
    this.useScrollView = true,
    this.centered = true,
    this.useSafeArea = true,
    this.useResponsiveMaxWidth = false,
    this.responsiveBreakpoint = 600,
    this.maxContentWidth = 480,
    this.adjustPaddingForKeyboard = true,
    this.keyboardPaddingExtra = 24,
  });

  @override
  Widget build(BuildContext context) {
    final scaffoldBody = _buildBody(context);
    
    // Check if we can pop (for back button handling)
    final canPop = _canPop(context);
    
    // Wrap with PopScope to handle system back button
    Widget scaffold = Scaffold(
      appBar: includeAppBar
          ? CoreAppBar(
              title: title,
              titleWidget: titleWidget,
              actions: actions,
              showBackButton: showBackButton,
              onBack: onBack,
              centerTitle: centerTitle,
              backgroundColor: appBarColor,
              elevation: appBarElevation,
              bottom: appBarBottom,
              leading: appBarLeading,
            )
          : null,
      backgroundColor:
          backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      drawer: includeDrawer ? (drawer ?? const SideDrawer()) : null,
      body: useSafeArea ? SafeArea(child: scaffoldBody) : scaffoldBody,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
    );
    
    // Wrap with PopScope to handle system back button properly
    return PopScope(
      canPop: canPop,
      onPopInvoked: (didPop) {
        // If pop was invoked but didn't happen (canPop was false), handle it
        if (!didPop) {
          _handleBack(context, onBack);
        }
      },
      child: scaffold,
    );
  }
  
  bool _canPop(BuildContext context) {
    try {
      return GoRouter.of(context).canPop();
    } catch (_) {
      return Navigator.of(context).canPop();
    }
  }
  
  void _handleBack(BuildContext context, VoidCallback? onBack) {
    if (onBack != null) {
      onBack.call();
      return;
    }
    
    // If we can pop, do it
    if (_canPop(context)) {
      try {
        context.pop();
      } catch (_) {
        Navigator.of(context).maybePop();
      }
    } else {
      // If we can't pop, try to navigate to home to prevent app closure
      try {
        final router = GoRouter.of(context);
        final currentLocation = router.routerDelegate.currentConfiguration.uri.path;
        if (currentLocation != '/' && currentLocation != '/login') {
          router.go('/');
        }
      } catch (_) {
        // If GoRouter fails, do nothing to prevent app closure
      }
    }
  }

  Widget _buildBody(BuildContext context) {
    final basePadding = padding ?? EdgeInsets.zero;

    if (useScrollView) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > responsiveBreakpoint;
          final bottomInset = adjustPaddingForKeyboard
              ? MediaQuery.viewInsetsOf(context).bottom
              : 0.0;

          final effectivePadding = basePadding.add(
            EdgeInsets.only(
              bottom: bottomInset > 0 ? bottomInset + keyboardPaddingExtra : 0,
            ),
          );

          Widget content = body;

          if (useResponsiveMaxWidth) {
            content = ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isWide ? maxContentWidth : double.infinity,
              ),
              child: content,
            );
          }

          if (centered) {
            content = Align(alignment: Alignment.topCenter, child: content);
          }

          return SingleChildScrollView(
            padding: effectivePadding,
            child: content,
          );
        },
      );
    }

    // Non-scroll layout — use [body] inside LayoutBuilder, never the outer wrapper.
    if (useResponsiveMaxWidth) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > responsiveBreakpoint;
          Widget inner = ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isWide ? maxContentWidth : double.infinity,
            ),
            child: body,
          );
          if (centered) {
            inner = Align(alignment: Alignment.topCenter, child: inner);
          }
          return Padding(padding: basePadding, child: inner);
        },
      );
    }

    Widget inner = body;
    if (centered) {
      inner = Align(alignment: Alignment.topCenter, child: inner);
    }
    return Padding(padding: basePadding, child: inner);
  }
}
