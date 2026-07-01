class ApiConstants {
  ApiConstants._();

  /// Base URL for all API requests (production).
  /// For local dev (emulator): use `http://10.0.2.2` instead.
  static const String baseUrl = 'https://allindiaitr.in';
  static const String api = '/api';

  //https://allindiaitr.in/privacy-policy

  // Auth Endpoints
  static const String authLogin = '$api/auth/login.php';
  static const String authSignup = '$api/auth/signup.php';
  static const String authForgetPassword = '$api/auth/forget_password.php';
  static const String authRefreshToken = '$api/auth/refresh_token.php';
  static const String authDeleteAccount = '$api/auth/delete_account.php'; // Placeholder
  static const String authRegisterFcm = '$api/auth/register_fcm.php';

  // ITR Details Endpoints
  static const String itrDetailsAddPersonalDetails = '$api/itrdetails/add_personal_details.php';
  static const String itrDetailsGetPersonalDetails = '$api/itrdetails/get_personal_detail.php';
  static const String itrGetItrByUser = '$api/get_itrbyuser.php';
  static const String itrGetDetailedStatus = '$api/itr_status/get_detailed_status.php';
  static const String itrGetOrders = '$api/itr_status/get_user_orders.php';
  static const String itrDetailsAddDocuments = '$api/itrdetails/add_documents.php';
  static const String itrDetailsSaveDocuments = '$api/itrdetails/save_documents.php';
  static const String itrDetailsDeleteDocument = '$api/itrdetails/delete_document.php';
  static const String itrDetailsGetDocuments = '$api/itrdetails/get_documents.php';
  static const String itrPrivacyPolicy = '/privacy-policy';
  static const String itrContactUS = '/contact-us';
  static const String itrAboutUS = '/about-us';
  static const String itrTermsAndConditions = '/terms-and-condition';

  /// Full HTTPS URL for a public marketing or policy page path.
  static String publicPageUrl(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '$baseUrl$normalizedPath';
  }

  // Package Endpoints
  static const String packageGetPackages = '$api/package/getPackages.php';

  // Payment Endpoints
  static const String paymentGetPaymentInfo = '$api/payment/get_payment_info.php';
  static const String paymentInitiatePayment = '$api/payment/initiate_payment.php';
  static const String paymentGetPaymentStatus = '$api/payment/get_payment_status.php';
  static const String paymentVerifyPayment = '$api/payment/verify_payment.php';
}
