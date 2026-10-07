import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tax_client/features/associates/data/datasources/associate_remote_data_source.dart';
import 'package:tax_client/features/associates/data/models/associate_models.dart';

final selectedAssociateProvider = StateProvider<AssociateProfile?>((ref) => null);
final selectedCatalogServiceProvider = StateProvider<CatalogService?>((ref) => null);

final catalogServicesProvider = FutureProvider<List<CatalogService>>((ref) {
  return ref.read(associateRemoteDataSourceProvider).getServices();
});

final associatesListProvider = FutureProvider.family<List<AssociateProfile>, int?>((ref, serviceId) {
  return ref.read(associateRemoteDataSourceProvider).listAssociates(serviceId: serviceId);
});

final associateDetailProvider = FutureProvider.family<AssociateProfile, int>((ref, id) {
  return ref.read(associateRemoteDataSourceProvider).getAssociate(id);
});
