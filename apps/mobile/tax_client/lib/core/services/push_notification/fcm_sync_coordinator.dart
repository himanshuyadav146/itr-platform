import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tax_client/core/error/failures.dart';
import 'package:tax_client/core/network/token_storage.dart';
import 'package:tax_client/core/utils/device_platform.dart';
import 'package:tax_client/features/auth/domain/repositories/auth_repository.dart';

/// Orchestrates FCM backend registration when a device token is available
/// and the user has an authenticated session.
class FcmSyncCoordinator {
  FcmSyncCoordinator({
    required AuthRepository authRepository,
    required TokenStorage tokenStorage,
  })  : _authRepository = authRepository,
        _tokenStorage = tokenStorage;

  final AuthRepository _authRepository;
  final TokenStorage _tokenStorage;
  StreamSubscription<String>? _subscription;

  void bindTokenStream(Stream<String> tokenStream) {
    _subscription?.cancel();
    _subscription = tokenStream.listen(_onTokenUpdated);
  }

  Future<void> syncStoredTokenIfAuthenticated() async {
    final fcmToken = await _tokenStorage.getFcmToken();
    if (fcmToken == null || fcmToken.isEmpty) return;
    await _onTokenUpdated(fcmToken);
  }

  Future<void> _onTokenUpdated(String fcmToken) async {
    if (fcmToken.isEmpty) return;

    final authToken = await _tokenStorage.getToken();
    if (authToken == null || authToken.isEmpty) return;

    final result = await _authRepository.registerFcm(
      fcmToken,
      getDevicePlatform(),
    );

    result.fold(
      (failure) => debugPrint(
        'FCM backend registration failed: ${failure is ServerFailure ? failure.message : failure}',
      ),
      (_) => debugPrint('FCM token registered with backend.'),
    );
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
