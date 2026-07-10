import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tax_client/core/common/widgets/no_internet_sheet.dart';
import 'package:tax_client/core/config/app_router.dart';
import 'package:tax_client/core/config/router_provider.dart';
import 'package:tax_client/core/config/theme/app_theme.dart';
import 'package:tax_client/core/network/logout_notifier.dart';
import 'package:tax_client/core/network/no_internet_notifier.dart';
import 'package:tax_client/core/services/push_notification/push_notification_provider.dart';

class AppRoot extends ConsumerWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(pushNotificationBootstrapProvider);

    final router = ref.watch(routerProvider);

    ref.listen<DateTime?>(noInternetNotifierProvider, (prev, next) {
      if (next != null) {
        showNoInternetSheet(context);
      }
    });

    ref.listen<bool>(logoutNotifierProvider, (prev, next) {
      if (next) {
        final currentRouter = AppRouter.router;
        if (currentRouter != null) {
          currentRouter.go('/login');
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(logoutNotifierProvider.notifier).reset();
        });
      }
    });

    return MaterialApp.router(
      title: 'Flutter Tax Client',
      theme: AppTheme.theme,
      routerConfig: router,
    );
  }
}
