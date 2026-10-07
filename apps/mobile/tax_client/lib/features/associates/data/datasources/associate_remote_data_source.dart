import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tax_client/core/constant/api_constants.dart';
import 'package:tax_client/core/network/api_client.dart';
import 'package:tax_client/features/associates/data/models/associate_models.dart';

final associateRemoteDataSourceProvider = Provider<AssociateRemoteDataSource>((ref) {
  return AssociateRemoteDataSource(ref.read(apiClientProvider));
});

class AssociateRemoteDataSource {
  final ApiClient apiClient;

  AssociateRemoteDataSource(this.apiClient);

  Future<List<CatalogService>> getServices() async {
    final response = await apiClient.get(
      ApiConstants.associateServices,
      (json) => json,
    );
    final data = response.data;
    final list = data is Map ? data['services'] : null;
    if (list is! List) return [];
    return list
        .whereType<Map>()
        .map((item) => CatalogService.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<AssociateProfile>> listAssociates({int? serviceId}) async {
    final query = serviceId != null ? '?serviceId=$serviceId' : '';
    final response = await apiClient.get(
      '${ApiConstants.associateList}$query',
      (json) => json,
    );
    final data = response.data;
    final list = data is Map ? data['associates'] : null;
    if (list is! List) return [];
    return list
        .whereType<Map>()
        .map((item) => AssociateProfile.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<AssociateProfile> getAssociate(int id) async {
    final response = await apiClient.get(
      '${ApiConstants.associateDetail}?id=$id',
      (json) => json,
    );
    final data = response.data;
    final associate = data is Map ? data['associate'] : data;
    return AssociateProfile.fromJson(Map<String, dynamic>.from(associate as Map));
  }
}
