import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tax_client/core/config/app_router.dart';
import 'package:tax_client/core/config/theme/app_theme.dart';

import 'package:tax_client/core/network/no_internet_notifier.dart';
import 'package:tax_client/core/network/logout_notifier.dart';
import 'package:tax_client/core/common/widgets/no_internet_sheet.dart';

import 'package:tax_client/core/config/router_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import 'package:tax_client/core/network/token_storage.dart';
import 'package:tax_client/core/services/push_notification/push_notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Analytics must never block or crash app startup.
  try {
    await FirebaseAnalytics.instance
        .setAnalyticsCollectionEnabled(true)
        .timeout(const Duration(seconds: 2));
  } catch (e) {
    debugPrint('Analytics enable skipped: $e');
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final container = ProviderContainer();

  final tokenStorage = container.read(tokenStorageProvider);
  await PushNotificationService.init(tokenStorage);

  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(UncontrolledProviderScope(container: container, child: const MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    ref.listen<DateTime?>(noInternetNotifierProvider, (prev, next) {
      if (next == null) return;
      // Defer to after this frame so we never present UI during listen/build,
      // and always use the router navigator (never MyApp's parent context).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final navContext = AppRouter.navigatorKey.currentContext;
        if (navContext == null || !navContext.mounted) return;
        showNoInternetSheet(navContext);
      });
    });

    ref.listen<bool>(logoutNotifierProvider, (prev, next) {
      if (next) {
        final currentRouter = AppRouter.router;
        if (currentRouter != null) {
          currentRouter.go('/login');
        }
        ref.read(logoutNotifierProvider.notifier).reset();
      }
    });

    return MaterialApp.router(
      title: 'Flutter Tax Client',
      theme: AppTheme.theme,
      routerConfig: router,
    );
  }
}
