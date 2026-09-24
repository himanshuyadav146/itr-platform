import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tax_client/features/associates/data/datasources/associate_remote_data_source.dart';
import 'package:tax_client/features/associates/data/models/associate_models.dart';

final catalogServicesProvider =
    FutureProvider<List<CatalogService>>((ref) async {
  return ref.watch(associateRemoteDataSourceProvider).getServices();
});

final associatesListProvider =
    FutureProvider.family<List<AssociateModel>, int?>((ref, serviceId) async {
  return ref.watch(associateRemoteDataSourceProvider).listAssociates(
        serviceId: serviceId,
      );
});

final associateDetailProvider =
    FutureProvider.family<AssociateModel, int>((ref, id) async {
  return ref.watch(associateRemoteDataSourceProvider).getAssociate(id);
});

final selectedServiceProvider = StateProvider<CatalogService?>((ref) => null);

final selectedAssociateProvider = StateProvider<AssociateSelection?>((ref) => null);
