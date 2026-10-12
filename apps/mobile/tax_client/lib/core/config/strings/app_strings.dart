class AppStrings {
  static const appTitle = 'Flutter Tax Client';

  // Auth
  static const loginTitle = 'Login';
  static const loginWelcome = 'Welcome 👋';
  static const loginSubtitle = 'Login to your FinApp - Next Gen account';
  static const emailLabel = 'Email';
  static const emailHint = 'Enter your email';
  static const passwordLabel = 'Password';
  static const passwordHint = 'Enter your password';
  static const forgotPassword = 'Forgot Password?';
  static const loginFillAll = 'Please fill in all fields';
  static const signupPrompt = 'Don’t have an account? ';
  static const signupAction = 'Sign up';

  static const signupTitle = 'Sign Up';
  static const signupHeader = 'Create Account ✨';
  static const signupSubtitle = 'Sign up to get started with FinApp - Next Gen';
  static const nameLabel = 'Full Name';
  static const nameHint = 'Enter your full name';
  static const mobileLabel = 'Mobile Number';
  static const mobileHint = 'Enter your mobile number';
  static const emailIdLabel = 'Email ID';
  static const passwordReenterLabel = 'Re-enter Password';
  static const passwordMismatch = 'Passwords do not match';
  static const alreadyHaveAccount = 'Already have an account? ';
  static const loginAction = 'Login';

  // Common Screens
  static const dashboard = 'Dashboard';
  static const orders = 'Orders';
  static const settings = 'Settings';
  static const profile = 'Profile';
  static const more = 'More';

  // Home
  static const homeTitle = 'FinApp';
  static const selectService = 'Select a Service';
  static const fileItr = 'File ITR';
  static const itrVerification = 'ITR E-Verification';
  static const gstFiling = 'GST Filing';
  static const getLoan = 'Get Loan';
  static const serviceSelected = 'selected!';
  static const packages = 'Packages';
  static const offers = 'Offers';
  static const taxExperts = 'Tax Experts';
  static const view = 'View';
  static const orderDetails = 'Order Details';
  static const amount = 'Amount';
  static const date = 'Date';
  static const status = 'Status';

  // Personal Info
  static const personalInfo = 'Personal Information';
  static const enterDetails = 'Please enter your details';
  static const phoneNumber = 'Phone Number';
  static const panNumber = 'PAN Number';
  static const aadharNumber = 'Aadhar Number';
  static const address = 'Address';
  static const save = 'Save';
  
  // Personal Information - Labels
  static const firstName = 'First Name';
  static const middleName = 'Middle Name';
  static const lastName = 'Last Name';
  static const gender = 'Gender';
  static const financialYear = 'Financial Year';
  static const country = 'Country';
  
  // Personal Information - Validation Messages
  static const pleaseEnterFirstName = 'Please enter first name';
  static const pleaseEnterLastName = 'Please enter last name';
  static const pleaseEnterPhoneNumber = 'Please enter phone number';
  static const phoneNumberMustBe10Digits = 'Phone number must be 10 digits';
  static const pleaseEnterEmail = 'Please enter email';
  static const pleaseEnterValidEmail = 'Please enter a valid email';
  static const pleaseEnterPanNumber = 'Please enter PAN number';
  static const panNumberMustBe10Characters = 'PAN number must be 10 characters';
  static const pleaseEnterAadhaarNumber = 'Please enter Aadhaar number';
  static const aadhaarNumberMustBe12Digits = 'Aadhaar number must be 12 digits';
  static const pleaseEnterAddress = 'Please enter address';
  
  // ITR List Screen
  static const myItrRecords = 'My ITR Records';
  static const retry = 'Retry';
  static const noItrRecordsFound = 'No ITR records found';
  static const startByFilingNewItr = 'Start by filing a new ITR';
  static const fileNewItr = 'File New ITR';
  static const continue_ = 'Continue';
  static const mobile = 'Mobile';
  static const pan = 'PAN';
  
  // Error Messages
  static const userIdNotFound = 'User ID not found. Please login again.';
  static const invalidResponseFormat = 'Invalid response format';
  static const anErrorOccurred = 'An error occurred. Please try again.';
  
  // Document Upload
  static const uploadedSuccessfully = 'uploaded successfully';
  
  // Validator Messages
  static const pleaseEnterField = 'Please enter {field}';
  static const invalidEmailFormat = 'Invalid email format';
  static const invalidPanFormat = 'Invalid PAN format (ABCDE1234F)';
  static const aadhaarMustBe12Digits = 'Aadhaar must be 12 digits';
  static const pleaseEnterDateOfBirth = 'Please enter Date of Birth';
  static const dobCannotBeInFuture = 'DOB cannot be in the future';
  static const invalidDateFormat = 'Invalid date format (DD/MM/YYYY)';
  static const pleaseEnterYourEmail = 'Please enter your email';
  static const pleaseEnterAPassword = 'Please enter a password';
  
  // Forget Password Screen
  static const resetPassword = 'Reset Password';
  static const resetYourPassword = 'Reset Your Password';
  static const enterEmailAndNewPassword = 'Enter your email and new password';
  static const newPassword = 'New Password';
  static const enterNewPassword = 'Enter new password';
  static const confirmPassword = 'Confirm Password';
  static const reEnterNewPassword = 'Re-enter new password';
  static const pleaseConfirmYourPassword = 'Please confirm your password';
  static const passwordMustBeAtLeast6Characters = 'Password must be at least 6 characters';
  static const passwordResetSuccessful = 'Password reset successful! Please login with your new password.';
  
  // Home Screen
  static const continueWith = 'Continue with {name}';
  static const selected = 'Selected {name}';

  // Upload Documents
  static const uploadDocuments = 'Upload Documents';
  static const attachTaxDocuments = 'Attach Your Tax Documents';
  static const uploadSubtitle =
      'Upload your Form 16-A, 16-B, and other supporting documents.';
  static const submitAllDocuments = 'Submit All Documents';
  static const upload = 'Upload';
  static const noFiles = 'No files uploaded yet';
  static const infoSaved = 'Information saved';

  // More Screen
  static const faqs = 'FAQs';
  static const shareApp = 'Share App';
  static const customPayment = 'Custom Payment';
  static const rateUs = 'Rate Us';
  static const aboutUs = 'About Us';
  static const privacyPolicy = 'Privacy Policy';
  static const contactSupport = 'Contact Support';
  static const logout = 'Logout';
  static const deleteAccountPermanently = 'Delete Account Permanently';
  static const confirmDeleteAccountTitle = 'Delete your account?';
  static const confirmDeleteAccountWarning = 'This action is permanent. Once you delete your account, all your data will be permanently removed and cannot be recovered.';

  // Payment
  static const payment = 'Payment';
  static const paymentSummary = 'PAYMENT SUMMARY';
  static const eFilingFee = 'E-Filing Fee';
  static const eVerificationFee = 'E-Verification Fee';
  static const totalBeforeGst = 'Total (Before GST)';
  static const gst18 = 'GST @18%';
  static const grandTotal = 'GRAND TOTAL';
  static const optionalServices = 'OPTIONAL SERVICES';
  static const eVerificationFeeFull = 'E-Verification Fee (₹199)';
  static const applyCoupon = 'APPLY COUPON';
  static const couponHint = 'Enter coupon code';
  static const apply = 'Apply';
  static const amountNote =
      'The amount is calculated based on your selections.';
  static const payNow = 'Pay Now';

  // Status
  static const orderStatus = 'Order Status';
  static const trackProgress = 'Track Your Progress';
  static const realtimeUpdates = 'Real-time ITR processing updates';
  static const paymentSuccess = 'Payment Success';
  static const taxExpertAssign = 'Tax Expert Assigned';
  static const documentsVerification = 'Documents Verification';
  static const filingItr = 'Filing ITR';
  static const acknowledgementNo = 'Acknowledgement Generated';
  static const congratulations = 'Congratulations 🎉';
  static const filedSuccessfully =
      'Your Income Tax Return has been successfully filed.';
  static const ackMailSent = '🎊 Acknowledgement number is sent to your email.';

  // Bottom nav
  static const navDashboard = 'Dashboard';
  static const navOrders = 'Orders';
  static const navMore = 'More';
}
