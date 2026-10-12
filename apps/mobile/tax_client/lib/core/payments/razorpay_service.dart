import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:tax_client/features/payment/data/models/payment_info_data.dart';
import 'package:tax_client/features/payment/data/models/payment_initiate_response.dart';

typedef PaymentResult = Future<void> Function(Map<String, dynamic> response);

class RazorpayService {
  static final Razorpay _razorpay = Razorpay();

  static void openCheckout({
    required PaymentInfoData paymentInfo,
    required PaymentInitiateResponse initiateResponse,
    required PaymentResult onSuccess,
    required PaymentResult onError,
  }) {
    // Extract gateway key ID from paymentInfo
    final keyId = paymentInfo.gatewayDetails.mid;
    final effectiveKey =
        (keyId.startsWith('rzp_test_') || keyId.startsWith('rzp_live_'))
        ? keyId
        : 'rzp_test_RitzIiBaMb6qnZ';
    
    // Extract amount from paymentInfo (grand_total)
    final grandTotal = paymentInfo.paymentSummary
        .firstWhere((item) => item.type == 'grand_total');
    final amountPaise = (grandTotal.amount * 100).toInt();
    
    // Extract user details from paymentInfo
    final userName = paymentInfo.orderDetails.name;
    final userEmail = paymentInfo.orderDetails.email;
    final userPhone = paymentInfo.orderDetails.phone;
    
    // Build Razorpay options with data from paymentInfo
    final options = {
      'key': effectiveKey,
      'amount': amountPaise,
      'name': userName,
      'description': 'ITR Filing Payment',
      'currency': 'INR',
      'prefill': {
        'contact': userPhone,
        'email': userEmail,
      },
      'theme': {'color': '#1F6FEB'},
    };

    // Clear existing listeners to prevent multiple registrations
    _razorpay.clear();

    // Handle payment success - capture response data
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) {
      final responseData = {
        'payment_id': response.paymentId,
        'order_id': response.orderId,
        'signature': response.signature,
        'status': 'success',
      };
      // Call async callback without awaiting to avoid blocking
      onSuccess(responseData);
    });

    // Handle payment error - capture response data
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
      final responseData = {
        'code': response.code?.toString(),
        'message': response.message,
        'status': 'failed',
      };
      // Call async callback without awaiting to avoid blocking
      onError(responseData);
    });

    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse response) {
      // Handle external wallet if needed
    });

    _razorpay.open(options);
  }

  static void dispose() {
    _razorpay.clear();
  }
}
