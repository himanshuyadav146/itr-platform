import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tax_client/core/network/token_storage.dart';
import 'package:tax_client/features/auth/domain/entities/user.dart';
import 'package:tax_client/features/auth/presentation/providers/auth_provider.dart';

final userProvider = FutureProvider<User?>((ref) async {
  // Watch auth state to re-trigger this provider when login/logout happens
  ref.watch(authViewModelProvider);
  
  final tokenStorage = ref.watch(tokenStorageProvider);
  final userData = await tokenStorage.getUserData();
  
  if (userData != null) {
    return User(
      id: userData['id']?.toString() ?? '',
      name: userData['name']?.toString() ?? '',
      email: userData['email']?.toString() ?? '',
      mobile: userData['mobile']?.toString() ?? '',
    );
  }
  
  return null;
});
