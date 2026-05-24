/// Abstract interface for logout handling
/// This allows the repository to trigger logout without depending on Riverpod
abstract class LogoutHandler {
  void triggerLogout();
}

