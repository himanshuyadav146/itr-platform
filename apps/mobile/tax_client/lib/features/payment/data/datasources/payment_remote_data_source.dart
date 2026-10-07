import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tax_client/core/constant/api_constants.dart';
import 'package:tax_client/core/network/api_client.dart';
import 'package:tax_client/features/payment/data/models/payment_info_data.dart';
import 'package:tax_client/features/payment/data/models/payment_initiate_response.dart';

final paymentRemoteDataSourceProvider =
    Provider<PaymentRemoteDataSource>((ref) {
  return PaymentRemoteDataSourceImpl(ref.read(apiClientProvider));
});

abstract class PaymentRemoteDataSource {
  Future<PaymentInfoData> getPaymentInfo({
    int? packageId,
    int? associateId,
    int? serviceId,
    String? panNumber,
  });
  Future<PaymentInitiateResponse> initiatePayment({
    int? packageId,
    int? associateId,
    int? serviceId,
    String? panNumber,
  });
  Future<Map<String, dynamic>> getPaymentStatus({
    String? paymentId,
    String? orderId,
  });
  Future<Map<String, dynamic>> verifyPayment({
    required String orderId,
    required String paymentStatus,
    String? transactionId,
    String? paymentMethod,
    String? gatewayName,
    String? failureReason,
    Map<String, dynamic>? gatewayResponse,
  });
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  final ApiClient apiClient;

  PaymentRemoteDataSourceImpl(this.apiClient);

  @override
  Future<PaymentInfoData> getPaymentInfo({
    int? packageId,
    int? associateId,
    int? serviceId,
    String? panNumber,
  }) async {
    final params = <String>[];
    if (packageId != null) params.add('packageId=$packageId');
    if (associateId != null) params.add('associateId=$associateId');
    if (serviceId != null) params.add('serviceId=$serviceId');
    if (panNumber != null && panNumber.isNotEmpty) params.add('panNumber=$panNumber');
    final query = params.isEmpty ? '' : '?${params.join('&')}';
    final response = await apiClient.get(
      '${ApiConstants.paymentGetPaymentInfo}$query',
      (json) => PaymentInfoData.fromJson(json),
    );

    return response.data;
  }

  @override
  Future<PaymentInitiateResponse> initiatePayment({
    int? packageId,
    int? associateId,
    int? serviceId,
    String? panNumber,
  }) async {
    final requestBody = <String, dynamic>{};
    if (packageId != null) {
      requestBody['packageId'] = packageId;
    }
    if (associateId != null) {
      requestBody['associateId'] = associateId;
    }
    if (serviceId != null) {
      requestBody['serviceId'] = serviceId;
    }
    
    if (panNumber != null && panNumber.isNotEmpty) {
      requestBody['panNumber'] = panNumber;
    }

    final response = await apiClient.post(
      ApiConstants.paymentInitiatePayment,
      requestBody,
      (json) => PaymentInitiateResponse.fromJson(json),
    );

    return response.data;
  }

  @override
  Future<Map<String, dynamic>> getPaymentStatus({
    String? paymentId,
    String? orderId,
  }) async {
    String queryParams = '';
    if (paymentId != null) {
      queryParams = '?paymentId=$paymentId';
    } else if (orderId != null) {
      queryParams = '?orderId=$orderId';
    } else {
      throw Exception('Either paymentId or orderId must be provided');
    }

    final response = await apiClient.get(
      '${ApiConstants.paymentGetPaymentStatus}$queryParams',
      (json) => json as Map<String, dynamic>,
    );

    return response.data;
  }

  @override
  Future<Map<String, dynamic>> verifyPayment({
    required String orderId,
    required String paymentStatus,
    String? transactionId,
    String? paymentMethod,
    String? gatewayName,
    String? failureReason,
    Map<String, dynamic>? gatewayResponse,
  }) async {
    final requestBody = <String, dynamic>{
      'orderId': orderId,
      'paymentStatus': paymentStatus,
    };

    // Add optional fields if provided
    if (transactionId != null) {
      requestBody['transactionId'] = transactionId;
    }
    if (paymentMethod != null) {
      requestBody['paymentMethod'] = paymentMethod;
    }
    if (gatewayName != null) {
      requestBody['gatewayName'] = gatewayName;
    }
    if (failureReason != null) {
      requestBody['failureReason'] = failureReason;
    }
    if (gatewayResponse != null) {
      requestBody['gatewayResponse'] = gatewayResponse;
    }

    final response = await apiClient.post(
      ApiConstants.paymentVerifyPayment,
      requestBody,
      (json) => json as Map<String, dynamic>,
    );

    return response.data;
  }
}

