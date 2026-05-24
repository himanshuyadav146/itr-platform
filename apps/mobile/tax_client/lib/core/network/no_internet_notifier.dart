import 'package:flutter_riverpod/flutter_riverpod.dart';

final noInternetNotifierProvider =
    StateNotifierProvider<NoInternetNotifier, DateTime?>(
      (ref) => NoInternetNotifier(),
    );

class NoInternetNotifier extends StateNotifier<DateTime?> {
  NoInternetNotifier() : super(null);
  void trigger() {
    state = DateTime.now();
  }
}
