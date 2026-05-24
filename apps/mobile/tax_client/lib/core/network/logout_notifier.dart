import 'package:flutter_riverpod/flutter_riverpod.dart';

final logoutNotifierProvider =
    StateNotifierProvider<LogoutNotifier, bool>(
      (ref) => LogoutNotifier(),
    );

class LogoutNotifier extends StateNotifier<bool> {
  LogoutNotifier() : super(false);
  
  void trigger() {
    state = true;
  }
  
  void reset() {
    state = false;
  }
}

