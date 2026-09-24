import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tax_client/core/network/api_client.dart';
import 'package:tax_client/features/packages/data/datasources/package_remote_data_source.dart';
import 'package:tax_client/features/packages/data/models/package_model.dart';

// Remote data source provider
final packageRemoteDataSourceProvider = Provider<PackageRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PackageRemoteDataSourceImpl(apiClient);
});

// Packages state notifier
class PackagesNotifier extends StateNotifier<AsyncValue<List<PackageModel>>> {
  final PackageRemoteDataSource remoteDataSource;

  PackagesNotifier(this.remoteDataSource) : super(const AsyncValue.loading());

  Future<void> getPackages() async {
    // Keep previous packages on screen while refreshing (avoids blank sheet).
    state = const AsyncValue<List<PackageModel>>.loading().copyWithPrevious(
      state,
    );
    try {
      final packages = await remoteDataSource.getPackages();
      state = AsyncValue.data(packages);
    } catch (e, stackTrace) {
      state = AsyncValue<List<PackageModel>>.error(
        e,
        stackTrace,
      ).copyWithPrevious(state);
    }
  }
}

// Packages provider
final packagesProvider = StateNotifierProvider<PackagesNotifier, AsyncValue<List<PackageModel>>>((ref) {
  final remoteDataSource = ref.watch(packageRemoteDataSourceProvider);
  return PackagesNotifier(remoteDataSource);
});

// Selected package provider
final selectedPackageProvider = StateProvider<PackageModel?>((ref) => null);
