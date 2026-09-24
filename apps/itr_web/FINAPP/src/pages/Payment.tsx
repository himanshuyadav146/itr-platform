import { useCallback, useEffect, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { useSelector } from 'react-redux';
import type { RootState } from '../store/index';

import {
  getPaymentInfo,
  initiatePayment,
  isValidPanNumber,
  loadRazorpayScript,
  normalizePanNumber,
  openRazorpayModal,
  verifyPayment,
} from '../services/paymentService';

import type { RazorpaySuccessResponse } from '../services/paymentService';
import { getErrorMessage } from '../services/api';

// -----------------------------------------------------------------------------
// Types
// -----------------------------------------------------------------------------

type PackageData = {
  id?: string | number;
  packageId?: string | number;
  PackageId?: string | number;
  packageid?: string | number;
  package_id?: string | number;
  Id?: string | number;
  ID?: string | number;

  packagename?: string;
  packageName?: string;
  PackageName?: string;
  name?: string;
  Name?: string;

  price?: string | number;
  Price?: string | number;
  amount?: string | number;
  Amount?: string | number;
  cost?: string | number;
  Cost?: string | number;

  description?: string;
  description1?: string;
  Description?: string;
};

type PaymentSummaryItem = {
  type?: string;
  display_title?: string;
  display_value?: string;
  amount?: number;
};

type PaymentInfo = {
  packageId: string | number;
  packageName: string;
  description?: string;
  amount: number;
  tax?: number;
  totalAmount: number;
  paymentSummary?: PaymentSummaryItem[];
  orderDetails?: {
    Name?: string;
    phone?: string;
    email?: string;
  };
};

// -----------------------------------------------------------------------------
// Helpers
// -----------------------------------------------------------------------------

const extractPackageId = (
  pkg: PackageData | null | undefined
): string | number | null => {
  if (!pkg) {
    return null;
  }

  return (
    pkg.id ??
    pkg.packageId ??
    pkg.PackageId ??
    pkg.packageid ??
    pkg.package_id ??
    pkg.Id ??
    pkg.ID ??
    null
  );
};

const extractPackageName = (
  pkg: PackageData | null | undefined
): string => {
  if (!pkg) {
    return 'Package';
  }

  return (
    pkg.packagename ||
    pkg.packageName ||
    pkg.PackageName ||
    pkg.name ||
    pkg.Name ||
    'Package'
  );
};

const extractPrice = (
  pkg: PackageData | null | undefined
): number => {
  if (!pkg) {
    return 0;
  }

  const raw =
    pkg.price ??
    pkg.Price ??
    pkg.amount ??
    pkg.Amount ??
    pkg.cost ??
    pkg.Cost ??
    '0';

  const parsed = Number.parseFloat(String(raw));

  return Number.isNaN(parsed) ? 0 : parsed;
};

const stripHtml = (value: string): string => {
  return value.replace(/<[^>]*>/g, '').trim();
};

// -----------------------------------------------------------------------------
// Component
// -----------------------------------------------------------------------------

const Payment = () => {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();

  const {
    user,
    selectedPackage,
    selectedAssociate,
    isAuthenticated,
    token,
  } = useSelector((state: RootState) => state.auth);

  // ---------------------------------------------------------------------------
  // PAN Number
  // ---------------------------------------------------------------------------

  const panFromQuery =
    searchParams.get('PanNumber') ??
    searchParams.get('panNumber') ??
    '';

  const panNumber = normalizePanNumber(
    panFromQuery ||
    user?.PanNumber ||
    user?.pan ||
    (() => {
      try {
        const saved = localStorage.getItem('selectedPersonalDetails');
        if (!saved) return '';
        const details = JSON.parse(saved) as {
          PANNumber?: string;
          PanNumber?: string;
          panNumber?: string;
        };
        return details.PANNumber || details.PanNumber || details.panNumber || '';
      } catch {
        return '';
      }
    })()
  );

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  const [loading, setLoading] = useState(true);
  const [processing, setProcessing] = useState(false);

  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  const [payment, setPayment] =
    useState<PaymentInfo | null>(null);

  // ---------------------------------------------------------------------------
  // Auth Guard
  // ---------------------------------------------------------------------------

  useEffect(() => {
    const storedToken = localStorage.getItem('authToken');

    if (!isAuthenticated && !token && !storedToken) {
      navigate('/login', {
        replace: true,
      });
    }
  }, [isAuthenticated, token, navigate]);

  // ---------------------------------------------------------------------------
  // Initialise Payment
  // ---------------------------------------------------------------------------

  const init = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);

      let associate = selectedAssociate as any;
      if (!associate) {
        try {
          const storedAssociate = localStorage.getItem('selectedAssociate');
          if (storedAssociate) {
            associate = JSON.parse(storedAssociate);
          }
        } catch {
          associate = null;
        }
      }

      let pkg = selectedPackage as PackageData | null;

      // Redux fallback -> localStorage
      if (!pkg) {
        try {
          const storedPackage =
            localStorage.getItem('selectedPackage');

          if (storedPackage) {
            pkg = JSON.parse(storedPackage) as PackageData;
          }
        } catch (storageError) {
          console.warn(
            '[Payment.init] Unable to parse selectedPackage:',
            storageError
          );
        }
      }

      const packageId = extractPackageId(pkg);
      const associateId = associate?.id ? Number(associate.id) : undefined;
      const serviceId = associate?.serviceId ? Number(associate.serviceId) : undefined;

      if (!associateId && !packageId) {
        setError(
          'No associate selected. Please choose a service and associate first.'
        );
        return;
      }

      if (!isValidPanNumber(panNumber)) {
        setError('PAN number not found. Please complete personal details first.');
        return;
      }

      // -----------------------------------------------------------------------
      // Get payment information
      // -----------------------------------------------------------------------

      try {
        const info = await getPaymentInfo(packageId, {
          associateId,
          serviceId,
          panNumber,
        });

        setPayment(info as PaymentInfo);
      } catch (apiError) {
        console.warn(
          '[Payment.init] getPaymentInfo failed. Using package fallback:',
          apiError
        );

        if (!pkg) {
          throw apiError;
        }

        const amount = extractPrice(pkg);
        const tax = Math.round(amount * 0.18);

        setPayment({
          packageId,
          amount,
          packageName: extractPackageName(pkg),
          description:
            pkg.description ||
            pkg.description1 ||
            pkg.Description ||
            '',
          tax,
          totalAmount: amount + tax,
        });
      }

      // -----------------------------------------------------------------------
      // Pre-load Razorpay SDK
      // -----------------------------------------------------------------------

      await loadRazorpayScript();
    } catch (err: unknown) {
      console.error('[Payment.init] Error:', err);

      const message =
        err instanceof Error
          ? err.message
          : 'पेमेंट जानकारी लोड करने में समस्या हुई। कृपया दोबारा कोशिश करें।';

      setError(message);
    } finally {
      setLoading(false);
    }
  }, [selectedPackage, selectedAssociate, panNumber]);

  useEffect(() => {
    void init();
  }, [init]);

  // ---------------------------------------------------------------------------
  // Payment Success
  // ---------------------------------------------------------------------------

  const handlePaymentSuccess = useCallback(
    async (
      payData: RazorpaySuccessResponse,
      orderId: string
    ) => {
      try {
        console.log(
          '[Payment] Verifying payment:',
          payData
        );

        await verifyPayment(
          orderId,
          payData.razorpay_payment_id,
          payData.razorpay_signature,
          payData.razorpay_order_id
        );

        setSuccess(
          '✓ पेमेंट सफल! आपकी ITR फाइलिंग अब प्रोसेस होगी।'
        );

        setProcessing(false);

        setTimeout(() => {
          navigate('/dashboard', {
            replace: true,
          });
        }, 2500);
      } catch (err: unknown) {
        console.error(
          '[Payment] Verification Error:',
          err
        );

        setError(
          `पेमेंट verify नहीं हो पाया (ID: ${payData.razorpay_payment_id})। कृपया support से संपर्क करें।`
        );

        setProcessing(false);
      }
    },
    [navigate]
  );

  // ---------------------------------------------------------------------------
  // Handle Pay
  // ---------------------------------------------------------------------------

  
  const handlePay = async () => {
    if (!payment || processing || success) {
      return;
    }

    if (!isValidPanNumber(panNumber)) {
      setError('PAN number not found. Please complete personal details first.');
      return;
    }

    try {
      setProcessing(true);
      setError(null);

      const response = await initiatePayment(payment.packageId, panNumber, {
        associateId: selectedAssociate?.id ? Number(selectedAssociate.id) : undefined,
        serviceId: selectedAssociate?.serviceId ? Number(selectedAssociate.serviceId) : undefined,
        quotedFee: selectedAssociate?.quotedFee != null ? Number(selectedAssociate.quotedFee) : undefined,
      });

      const internalOrderId = response.orderId;
      const key = response.key;
      const amount = response.amount;
      const currency = response.currency || 'INR';

      if (!internalOrderId || !key || !amount) {
        throw new Error('Payment gateway details are incomplete. Please try again.');
      }

      await openRazorpayModal({
        key,
        razorpayOrderId: response.razorpayOrderId,
        amount,
        amountRupeesHint: payment.totalAmount,
        currency,
        packageName: payment.packageName,
        name: payment.orderDetails?.Name || user?.name || '',
        email: payment.orderDetails?.email || user?.email || '',
        contact: payment.orderDetails?.phone || user?.mobile || '',
        onSuccess: (data: RazorpaySuccessResponse) => {
          void handlePaymentSuccess(data, internalOrderId);
        },
        onError: (razorpayError: Error) => {
          setError(razorpayError.message || 'Payment cancelled.');
          setProcessing(false);
        },
      });
    } catch (error) {
      setError(
        getErrorMessage(error) ||
          'पेमेंट शुरू करने में समस्या हुई। कृपया दोबारा कोशिश करें।'
      );
      setProcessing(false);
    }
  };



  // ---------------------------------------------------------------------------
  // Loading
  // ---------------------------------------------------------------------------

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-950 flex items-center justify-center px-4">
        <div className="text-center">
          <div className="relative w-12 h-12 mx-auto mb-4">
            <div className="absolute inset-0 rounded-full border-4 border-gray-800" />

            <div className="absolute inset-0 rounded-full border-4 border-transparent border-t-emerald-400 animate-spin" />

            <div
              className="absolute inset-1.5 rounded-full border-4 border-transparent border-b-emerald-600 animate-spin"
              style={{
                animationDirection: 'reverse',
                animationDuration: '1.5s',
              }}
            />
          </div>

          <p className="text-gray-300 text-sm font-medium">
            Payment details loading...
          </p>

          <p className="text-gray-600 text-xs mt-1">
            कृपया प्रतीक्षा करें
          </p>
        </div>
      </div>
    );
  }

  // ---------------------------------------------------------------------------
  // Main UI
  // ---------------------------------------------------------------------------

  return (
    <div className="min-h-screen bg-gray-950 relative overflow-hidden">
      {/* Background */}
      <div className="absolute inset-0 pointer-events-none">
        <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[450px] h-[450px] bg-emerald-900/10 rounded-full blur-3xl" />

        <div className="absolute bottom-0 right-0 w-[300px] h-[300px] bg-blue-900/10 rounded-full blur-3xl" />
      </div>

      <div className="relative z-10 py-4 px-4 sm:px-6">
        {/* ------------------------------------------------------------------- */}
        {/* Stepper */}
        {/* ------------------------------------------------------------------- */}

        <div className="max-w-xl mx-auto mb-5">
          <div className="flex items-center justify-center gap-2 text-xs">
            {/* Step 1 */}
            <div className="flex items-center gap-1.5 text-gray-500">
              <span className="w-6 h-6 rounded-full bg-gray-800 border border-gray-700 flex items-center justify-center text-[10px] font-bold">
                1
              </span>

              <span className="hidden sm:inline">
                Details
              </span>
            </div>

            <div className="w-7 h-px bg-gray-700" />

            {/* Step 2 */}
            <div className="flex items-center gap-1.5 text-gray-500">
              <span className="w-6 h-6 rounded-full bg-gray-800 border border-gray-700 flex items-center justify-center text-[10px] font-bold">
                2
              </span>

              <span className="hidden sm:inline">
                Documents
              </span>
            </div>

            <div className="w-7 h-px bg-gray-700" />

            {/* Step 3 */}
            <div className="flex items-center gap-1.5 text-white">
              <span className="w-6 h-6 rounded-full bg-emerald-600 flex items-center justify-center text-[10px] font-bold">
                3
              </span>

              <span className="hidden sm:inline font-medium">
                Payment
              </span>
            </div>
          </div>
        </div>

        {/* ------------------------------------------------------------------- */}
        {/* Header */}
        {/* ------------------------------------------------------------------- */}

        <div className="text-center mb-5">
          <div className="inline-flex items-center justify-center w-11 h-11 rounded-xl bg-emerald-500/10 border border-emerald-500/20 mb-2">
            <svg
              className="w-5 h-5 text-emerald-400"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={1.5}
                d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"
              />
            </svg>
          </div>

          <h1 className="text-2xl font-bold text-white">
            Secure Payment
          </h1>

          <p className="text-gray-500 text-xs mt-1">
            Review your package and complete payment
          </p>
        </div>

        {/* ------------------------------------------------------------------- */}
        {/* Content */}
        {/* ------------------------------------------------------------------- */}

        <div className="max-w-xl mx-auto">
          {/* ----------------------------------------------------------------- */}
          {/* Success */}
          {/* ----------------------------------------------------------------- */}

          {success && (
            <div className="mb-4 p-3.5 bg-emerald-950/60 border border-emerald-700/40 rounded-xl">
              <div className="flex items-center gap-3">
                <span className="flex-shrink-0 w-9 h-9 rounded-full bg-emerald-500/20 flex items-center justify-center">
                  <svg
                    className="w-4.5 h-4.5 text-emerald-400"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2.5}
                      d="M5 13l4 4L19 7"
                    />
                  </svg>
                </span>

                <div>
                  <p className="text-emerald-100 text-sm font-semibold">
                    {success}
                  </p>

                  <p className="text-emerald-400/70 text-xs mt-0.5">
                    Dashboard पर redirect हो रहा है...
                  </p>
                </div>
              </div>
            </div>
          )}

          {/* ----------------------------------------------------------------- */}
          {/* Error */}
          {/* ----------------------------------------------------------------- */}

          {error && (
            <div className="mb-4 p-3.5 bg-red-950/60 border border-red-700/40 rounded-xl">
              <div className="flex items-start gap-3">
                <span className="flex-shrink-0 w-9 h-9 rounded-full bg-red-500/20 flex items-center justify-center">
                  <svg
                    className="w-4.5 h-4.5 text-red-400"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L4.082 16.5c-.77.833.192 2.5 1.732 2.5z"
                    />
                  </svg>
                </span>

                <div className="flex-1 min-w-0">
                  <p className="text-red-200 text-sm font-medium">
                    {error}
                  </p>

                  {error.includes('associate selected') && (
                    <button
                      type="button"
                      onClick={() =>
                        navigate('/services')
                      }
                      className="mt-2 px-3.5 py-2 bg-red-500/15 hover:bg-red-500/25 border border-red-700/50 rounded-lg text-red-200 text-xs font-medium transition-all"
                    >
                      ← Choose a service
                    </button>
                  )}
                  {error.toLowerCase().includes('pan') && (
                    <button
                      type="button"
                      onClick={() => navigate('/personal-details')}
                      className="mt-2 px-3.5 py-2 bg-red-500/15 hover:bg-red-500/25 border border-red-700/50 rounded-lg text-red-200 text-xs font-medium transition-all"
                    >
                      ← Personal details भरें
                    </button>
                  )}
                  {error.toLowerCase().includes('document') && (
                    <button
                      type="button"
                      onClick={() =>
                        navigate(
                          panNumber
                            ? `/documents?PanNumber=${encodeURIComponent(panNumber)}`
                            : '/documents'
                        )
                      }
                      className="mt-2 px-3.5 py-2 bg-red-500/15 hover:bg-red-500/25 border border-red-700/50 rounded-lg text-red-200 text-xs font-medium transition-all"
                    >
                      ← Documents upload करें
                    </button>
                  )}
                </div>
              </div>
            </div>
          )}

          {/* ----------------------------------------------------------------- */}
          {/* Payment Card */}
          {/* ----------------------------------------------------------------- */}

          {payment && (
            <div className="bg-gray-900/80 backdrop-blur-sm border border-gray-800/80 rounded-2xl overflow-hidden shadow-xl shadow-black/20">
              {/* ------------------------------------------------------------- */}
              {/* Package */}
              {/* ------------------------------------------------------------- */}

              <div className="px-4 pt-4 pb-3 bg-gradient-to-r from-emerald-950/40 to-gray-900/40 border-b border-gray-800/60">
                <div className="flex items-start gap-3">
                  {/* Icon */}
                  <div className="flex-shrink-0 w-10 h-10 rounded-lg bg-gradient-to-br from-emerald-500 to-emerald-700 flex items-center justify-center">
                    <svg
                      className="w-5 h-5 text-white"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth={2}
                        d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"
                      />
                    </svg>
                  </div>

                  {/* Details */}
                  <div className="flex-1 min-w-0">
                    <p className="text-[9px] font-medium text-emerald-400/80 uppercase tracking-widest mb-0.5">
                      {selectedAssociate ? 'Selected Associate' : 'Selected Package'}
                    </p>

                    <h2 className="text-lg font-bold text-white truncate">
                      {payment.packageName}
                    </h2>

                    {payment.description && (
                      <p className="text-gray-400 text-xs mt-0.5 line-clamp-1">
                        {stripHtml(
                          payment.description
                        )}
                      </p>
                    )}
                  </div>

                  {/* Active */}
                  <span className="flex-shrink-0 inline-flex items-center gap-1 px-2 py-1 bg-emerald-500/15 border border-emerald-500/30 rounded-full text-emerald-400 text-[9px] font-semibold">
                    <span className="w-1.5 h-1.5 rounded-full bg-emerald-400" />
                    Active
                  </span>
                </div>
              </div>

              {/* ------------------------------------------------------------- */}
              {/* Price */}
              {/* ------------------------------------------------------------- */}

              <div className="p-4 space-y-3">
                <div className="space-y-1">
                  {payment.paymentSummary &&
                  payment.paymentSummary.length > 0 ? (
                    payment.paymentSummary.map(
                      (
                        item,
                        index
                      ) => {
                        if (
                          item.type ===
                          'grand_total'
                        ) {
                          return null;
                        }

                        const title =
                          item.display_title ||
                          '';

                        const isSubtotal =
                          item.type ===
                            'subtotal' ||
                          title
                            .toLowerCase()
                            .includes(
                              'total'
                            );

                        return (
                          <div
                            key={`${title}-${index}`}
                            className={`flex justify-between items-center py-1.5 ${
                              isSubtotal
                                ? 'border-t border-gray-800/60 pt-2.5 mt-1'
                                : ''
                            }`}
                          >
                            <span
                              className={`${
                                isSubtotal
                                  ? 'text-gray-300 font-medium'
                                  : 'text-gray-400'
                              } text-xs flex items-center gap-1.5`}
                            >
                              {!isSubtotal && (
                                <svg
                                  className="w-3.5 h-3.5 text-gray-600"
                                  fill="none"
                                  stroke="currentColor"
                                  viewBox="0 0 24 24"
                                >
                                  <path
                                    strokeLinecap="round"
                                    strokeLinejoin="round"
                                    strokeWidth={1.5}
                                    d="M9 7h6m0 10v-3m-3 3h.01M9 17h.01M9 14h.01M12 14h.01M15 11h.01M12 11h.01M9 11h.01M7 21h10a2 2 0 002-2V5a2 2 0 00-2-2H7a2 2 0 00-2 2v14a2 2 0 002 2z"
                                  />
                                </svg>
                              )}

                              {title}
                            </span>

                            <span
                              className={`text-white ${
                                isSubtotal
                                  ? 'font-bold'
                                  : 'font-semibold'
                              } text-sm`}
                            >
                              {item.display_value ||
                                `₹${(
                                  item.amount ||
                                  0
                                ).toLocaleString(
                                  'en-IN'
                                )}`}
                            </span>
                          </div>
                        );
                      }
                    )
                  ) : (
                    <>
                      {/* Subtotal */}
                      <div className="flex justify-between items-center py-1.5">
                        <span className="text-gray-400 text-xs flex items-center gap-1.5">
                          <svg
                            className="w-3.5 h-3.5 text-gray-600"
                            fill="none"
                            stroke="currentColor"
                            viewBox="0 0 24 24"
                          >
                            <path
                              strokeLinecap="round"
                              strokeLinejoin="round"
                              strokeWidth={1.5}
                              d="M9 7h6m0 10v-3m-3 3h.01M9 17h.01M9 14h.01M12 14h.01M15 11h.01M12 11h.01M9 11h.01M7 21h10a2 2 0 002-2V5a2 2 0 00-2-2v14a2 2 0 002 2z"
                            />
                          </svg>

                          Subtotal
                        </span>

                        <span className="text-white font-semibold text-sm">
                          ₹
                          {payment.amount.toLocaleString(
                            'en-IN'
                          )}
                        </span>
                      </div>

                      {/* GST */}
                      <div className="flex justify-between items-center py-1.5">
                        <span className="text-gray-400 text-xs flex items-center gap-1.5">
                          <svg
                            className="w-3.5 h-3.5 text-gray-600"
                            fill="none"
                            stroke="currentColor"
                            viewBox="0 0 24 24"
                          >
                            <path
                              strokeLinecap="round"
                              strokeLinejoin="round"
                              strokeWidth={1.5}
                              d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16"
                            />
                          </svg>

                          GST (18%)
                        </span>

                        <span className="text-white font-semibold text-sm">
                          ₹
                          {(
                            payment.tax || 0
                          ).toLocaleString(
                            'en-IN'
                          )}
                        </span>
                      </div>
                    </>
                  )}
                </div>

                {/* Divider */}
                <div className="relative py-1">
                  <div className="absolute inset-0 flex items-center">
                    <div className="w-full border-t border-dashed border-gray-700/60" />
                  </div>

                  <div className="relative flex justify-center">
                    <span className="bg-gray-900 px-2 text-gray-600 text-[9px]">
                      TOTAL
                    </span>
                  </div>
                </div>

                {/* Total */}
                <div className="flex justify-between items-center">
                  <span className="text-white font-semibold text-base">
                    Total Amount
                  </span>

                  <div className="text-right">
                    <span className="text-2xl font-bold text-emerald-400">
                      ₹
                      {payment.totalAmount.toLocaleString(
                        'en-IN',
                        {
                          maximumFractionDigits: 2,
                        }
                      )}
                    </span>

                    <p className="text-gray-500 text-[9px] mt-0.5">
                      Inclusive of all taxes
                    </p>
                  </div>
                </div>
              </div>

              {/* ------------------------------------------------------------- */}
              {/* Security */}
              {/* ------------------------------------------------------------- */}

              <div className="mx-4 mb-3 p-3 bg-blue-950/25 border border-blue-800/30 rounded-lg">
                <div className="flex items-center gap-2.5">
                  <div className="flex-shrink-0 w-8 h-8 rounded-lg bg-blue-900/40 flex items-center justify-center">
                    <svg
                      className="w-4 h-4 text-blue-400"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth={2}
                        d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
                      />
                    </svg>
                  </div>

                  <div>
                    <p className="text-xs text-blue-200 font-medium">
                      256-bit SSL Encrypted Payment
                    </p>

                    <p className="text-[10px] text-blue-400/70 mt-0.5">
                      Secured by{' '}
                      <strong>
                        Razorpay
                      </strong>{' '}
                      • Cards, UPI, Net Banking
                    </p>
                  </div>
                </div>
              </div>

              {/* ------------------------------------------------------------- */}
              {/* Payment Methods */}
              {/* ------------------------------------------------------------- */}

              <div className="mx-4 mb-3 flex items-center justify-center gap-3">
                {/* UPI */}
                <div className="w-9 h-9 rounded-lg bg-gray-800/80 border border-gray-700/50 flex items-center justify-center">
                  <span className="text-[10px] font-bold text-gray-300">
                    UPI
                  </span>
                </div>

                {/* Card */}
                <div className="w-9 h-9 rounded-lg bg-gray-800/80 border border-gray-700/50 flex items-center justify-center">
                  <svg
                    className="w-4 h-4 text-gray-400"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={1.5}
                      d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z"
                    />
                  </svg>
                </div>

                {/* Net Banking */}
                <div className="w-9 h-9 rounded-lg bg-gray-800/80 border border-gray-700/50 flex items-center justify-center">
                  <svg
                    className="w-4 h-4 text-gray-400"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={1.5}
                      d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"
                    />
                  </svg>
                </div>

                {/* Wallet */}
                <div className="w-9 h-9 rounded-lg bg-gray-800/80 border border-gray-700/50 flex items-center justify-center">
                  <svg
                    className="w-4 h-4 text-gray-400"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={1.5}
                      d="M3 10h18V6a1 1 0 00-1-1H4a1 1 0 00-1 1v12a1 1 0 001 1h16a1 1 0 001-1v-4M3 10l4-6m14 6h-4a2 2 0 100 4h4"
                    />
                  </svg>
                </div>
              </div>

              {/* ------------------------------------------------------------- */}
              {/* Buttons */}
              {/* ------------------------------------------------------------- */}

              <div className="p-4 pt-1 space-y-2">
                {/* Pay */}
                <button
                  id="pay-now-btn"
                  type="button"
                  onClick={handlePay}
                  disabled={
                    processing || !!success || !isValidPanNumber(panNumber)
                  }
                  className="
                    w-full
                    py-3
                    bg-gradient-to-r
                    from-emerald-500
                    to-emerald-600
                    text-white
                    font-semibold
                    rounded-xl
                    hover:from-emerald-400
                    hover:to-emerald-500
                    disabled:from-gray-700
                    disabled:to-gray-700
                    disabled:text-gray-500
                    disabled:cursor-not-allowed
                    transition-all
                    duration-200
                    active:scale-[0.99]
                    text-sm
                    shadow-lg
                    shadow-emerald-900/20
                    disabled:shadow-none
                  "
                >
                  {processing ? (
                    <span className="flex items-center justify-center gap-2">
                      <svg
                        className="animate-spin h-4 w-4"
                        fill="none"
                        viewBox="0 0 24 24"
                      >
                        <circle
                          className="opacity-25"
                          cx="12"
                          cy="12"
                          r="10"
                          stroke="currentColor"
                          strokeWidth="4"
                        />

                        <path
                          className="opacity-75"
                          fill="currentColor"
                          d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"
                        />
                      </svg>

                      Processing Payment...
                    </span>
                  ) : success ? (
                    <span className="flex items-center justify-center gap-2">
                      <svg
                        className="w-4 h-4"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                      >
                        <path
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth={2.5}
                          d="M5 13l4 4L19 7"
                        />
                      </svg>

                      Payment Successful
                    </span>
                  ) : (
                    <span className="flex items-center justify-center gap-2">
                      <svg
                        className="w-4 h-4"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                      >
                        <path
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth={2}
                          d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
                        />
                      </svg>

                      Pay ₹
                      {payment.totalAmount.toLocaleString(
                        'en-IN'
                      )}
                    </span>
                  )}
                </button>

                {/* Back */}
                <button
                  id="back-to-packages-btn"
                  type="button"
                  onClick={() =>
                    navigate('/services')
                  }
                  disabled={processing}
                  className="
                    w-full
                    py-2.5
                    border
                    border-gray-700/60
                    text-gray-400
                    text-xs
                    rounded-xl
                    hover:bg-gray-800/60
                    hover:text-white
                    hover:border-gray-600
                    disabled:opacity-50
                    transition-all
                    duration-200
                  "
                >
                  ← Back to Packages
                </button>
              </div>
            </div>
          )}

          {/* ----------------------------------------------------------------- */}
          {/* Footer */}
          {/* ----------------------------------------------------------------- */}

          <div className="mt-4 text-center space-y-2">
            <p className="text-gray-600 text-[10px]">
              By proceeding, you agree to our{' '}
              <a
                href="/term-and-condition"
                className="text-gray-500 underline underline-offset-2 hover:text-white transition-colors"
              >
                Terms & Conditions
              </a>{' '}
              and{' '}
              <a
                href="/privacy-policy"
                className="text-gray-500 underline underline-offset-2 hover:text-white transition-colors"
              >
                Privacy Policy
              </a>
            </p>

            <div className="flex items-center justify-center gap-1.5 text-gray-700 text-[10px]">
              <svg
                className="w-3 h-3"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
                />
              </svg>

              <span>
                100% Secure Payment
              </span>

              <span>•</span>

              <span>
                Powered by Razorpay
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Payment;

