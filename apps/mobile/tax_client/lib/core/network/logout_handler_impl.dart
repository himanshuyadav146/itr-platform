import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tax_client/core/network/logout_handler.dart';
import 'package:tax_client/core/network/logout_notifier.dart';
import 'package:tax_client/core/network/token_storage.dart';
import 'package:tax_client/core/network/api_client.dart';

/// Implementation of LogoutHandler using Riverpod's LogoutNotifier
class LogoutHandlerImpl implements LogoutHandler {
  final Ref ref;

  LogoutHandlerImpl(this.ref);

  @override
  void triggerLogout() {
    // Perform logout asynchronously (fire-and-forget)
    // This ensures all data is cleared while not blocking the current execution
    _performLogout().catchError((error) {
      // Log error if logout fails, but don't block execution
      // The logout notifier will still trigger to navigate to login
    });
  }

  /// Perform full logout: clear all preferences and trigger logout notifier
  Future<void> _performLogout() async {
    final tokenStorage = ref.read(tokenStorageProvider);
    final apiClient = ref.read(apiClientProvider);
    
    // Clear all local preferences storage (including logged_in flag, tokens, user data, PAN, etc.)
    await tokenStorage.clearAllPreferences();
    
    // Clear token from API client memory
    apiClient.clearAuthToken();
    
    // Trigger logout notifier to navigate to login
    ref.read(logoutNotifierProvider.notifier).trigger();
  }
}

/// Provider for LogoutHandler
final logoutHandlerProvider = Provider<LogoutHandler>((ref) {
  return LogoutHandlerImpl(ref);
});

