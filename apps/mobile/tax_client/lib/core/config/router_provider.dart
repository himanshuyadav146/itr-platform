import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tax_client/core/config/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // We can't easily get the 'loggedIn' state here without it being a state itself,
  // but for the initialLocation, we can just use '/splash' and let it handle redirects
  // or use a simpler approach.
  return AppRouter.buildRouter(initialLocation: '/splash');
});
