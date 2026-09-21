export const baseUrl = import.meta.env.DEV ? '/api' : 'https://allindiaitr.in/api';

export const apiUrl = {
  // Auth
  signup: `${baseUrl}/auth/signup.php`,
  login: `${baseUrl}/auth/login.php`,
  forgetPassword: `${baseUrl}/auth/forget_password.php`,
  refreshToken: `${baseUrl}/auth/refresh_token.php`,
  registerFcm: `${baseUrl}/auth/register_fcm.php`,
  deleteAccount: `${baseUrl}/auth/delete_account.php`,

  // Packages
  getPackages: `${baseUrl}/package/getPackages.php`,

  // Personal details / ITR
  addPersonalDetails: `${baseUrl}/itrdetails/add_personal_details.php`,
  getPersonalDetail: `${baseUrl}/itrdetails/get_personal_detail.php`,
  getItrByUser: `${baseUrl}/get_itrbyuser.php`,

  // Documents
  uploadDocument: `${baseUrl}/itrdetails/add_documents.php`,
  saveDocuments: `${baseUrl}/itrdetails/save_documents.php`,
  getDocuments: `${baseUrl}/itrdetails/get_documents.php`,
  deleteDocument: `${baseUrl}/itrdetails/delete_document.php`,

  // Payment
  getPaymentInfo: `${baseUrl}/payment/get_payment_info.php`,
  initiatePayment: `${baseUrl}/payment/initiate_payment.php`,
  getPaymentStatus: `${baseUrl}/payment/get_payment_status.php`,
  getPaymentHistory: `${baseUrl}/payment/get_payment_history.php`,
  verifyPayment: `${baseUrl}/payment/verify_payment.php`,

  // Status & orders
  getDetailedStatus: `${baseUrl}/itr_status/get_detailed_status.php`,
  getUserOrders: `${baseUrl}/itr_status/get_user_orders.php`,
};

export const PUBLIC_API_PATHS = [
  apiUrl.login,
  apiUrl.signup,
  apiUrl.forgetPassword,
  apiUrl.getPackages,
];
