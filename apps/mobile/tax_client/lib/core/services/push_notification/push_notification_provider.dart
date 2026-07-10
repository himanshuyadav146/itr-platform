import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tax_client/core/network/token_storage.dart';
import 'package:tax_client/core/services/push_notification/fcm_sync_coordinator.dart';
import 'package:tax_client/core/services/push_notification/push_notification_service.dart';
import 'package:tax_client/features/auth/data/repositories/auth_repository_impl.dart';

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  final service = PushNotificationService(ref.read(tokenStorageProvider));
  ref.onDispose(service.dispose);
  return service;
});

final fcmSyncCoordinatorProvider = Provider<FcmSyncCoordinator>((ref) {
  final coordinator = FcmSyncCoordinator(
    authRepository: ref.read(authRepositoryProvider),
    tokenStorage: ref.read(tokenStorageProvider),
  );
  ref.onDispose(coordinator.dispose);
  return coordinator;
});

/// One-shot bootstrap: wire FCM token stream → backend sync coordinator.
final pushNotificationBootstrapProvider = FutureProvider<void>((ref) async {
  final pushService = ref.read(pushNotificationServiceProvider);
  final coordinator = ref.read(fcmSyncCoordinatorProvider);

  coordinator.bindTokenStream(pushService.onTokenUpdated);
  await pushService.initialize();
  await coordinator.syncStoredTokenIfAuthenticated();
});
