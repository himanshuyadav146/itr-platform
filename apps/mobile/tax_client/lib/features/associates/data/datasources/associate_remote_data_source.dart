import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tax_client/core/constant/api_constants.dart';
import 'package:tax_client/core/network/api_client.dart';
import 'package:tax_client/features/associates/data/models/associate_models.dart';

abstract class AssociateRemoteDataSource {
  Future<List<CatalogService>> getServices();
  Future<List<AssociateModel>> listAssociates({int? serviceId});
  Future<AssociateModel> getAssociate(int id);
}

class AssociateRemoteDataSourceImpl implements AssociateRemoteDataSource {
  final ApiClient apiClient;

  AssociateRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<CatalogService>> getServices() async {
    final response = await apiClient.get<Map<String, dynamic>>(
      ApiConstants.associateServices,
      (json) => json,
    );
    final list = response.data['services'] as List? ?? [];
    return list
        .map((item) => CatalogService.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<AssociateModel>> listAssociates({int? serviceId}) async {
    final query = serviceId != null ? '?serviceId=$serviceId' : '';
    final response = await apiClient.get<Map<String, dynamic>>(
      '${ApiConstants.associateList}$query',
      (json) => json,
    );
    final list = response.data['associates'] as List? ?? [];
    return list
        .map((item) => AssociateModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<AssociateModel> getAssociate(int id) async {
    final response = await apiClient.get<Map<String, dynamic>>(
      '${ApiConstants.associateDetail}?id=$id',
      (json) => json,
    );
    final data = response.data['associate'] as Map<String, dynamic>? ?? response.data;
    return AssociateModel.fromJson(data);
  }
}

final associateRemoteDataSourceProvider = Provider<AssociateRemoteDataSource>((ref) {
  return AssociateRemoteDataSourceImpl(ref.watch(apiClientProvider));
});
