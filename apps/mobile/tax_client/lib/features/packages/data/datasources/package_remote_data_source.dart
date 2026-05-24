import 'dart:io';
import 'package:tax_client/core/constant/api_constants.dart';
import 'package:tax_client/core/network/api_client.dart';
import 'package:tax_client/core/network/exceptions.dart';
import 'package:tax_client/features/packages/data/models/package_model.dart';

abstract class PackageRemoteDataSource {
  Future<List<PackageModel>> getPackages();
}

class PackageRemoteDataSourceImpl implements PackageRemoteDataSource {
  final ApiClient apiClient;

  PackageRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<PackageModel>> getPackages() async {
    try {
      // Use ApiClient to make the request with proper authentication
      final response = await apiClient.get<PackagesData>(
        ApiConstants.packageGetPackages,
        (json) => PackagesData.fromJson(json),
      );
      
      // Extract packages from the response data
      return response.data.packages;
    } on SocketException {
      throw ApiException('No internet connection. Please check your network.');
    } on HttpException {
      throw ApiException('Failed to communicate with server.');
    } on FormatException {
      throw ApiException('Invalid response format from server.');
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Failed to load packages: ${e.toString()}');
    }
  }
}
