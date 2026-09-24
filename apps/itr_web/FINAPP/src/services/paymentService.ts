import { extractApiMessage, isApiSuccess, makeRequest } from './api';
import { apiUrl } from '../config/baseUrlConstant';

declare global {
  interface Window {
    Razorpay: new (options: RazorpayOptions) => RazorpayInstance;
  }
}

interface RazorpayOptions {
  key: string;
  amount: number;
  currency: string;
  order_id?: string;
  name: string;
  description: string;
  prefill: {
    name?: string;
    email: string;
    contact: string;
  };
  theme: { color: string };
  retry: { enabled: boolean };
  handler: (response: RazorpaySuccessResponse) => void;
  modal: {
    ondismiss: () => void;
    confirm_close?: boolean;
  };
}

interface RazorpayInstance {
  open: () => void;
  on: (event: string, callback: (response: unknown) => void) => void;
}

export interface RazorpaySuccessResponse {
  razorpay_payment_id: string;
  razorpay_order_id: string;
  razorpay_signature: string;
}

export interface PaymentSummaryItem {
  display_title: string;
  display_value: string;
  amount: number;
  type?: string;
}

export interface PaymentInfo {
  packageId: string | number;
  amount: number;
  packageName: string;
  description: string;
  tax: number;
  totalAmount: number;
  paymentSummary?: PaymentSummaryItem[];
  gatewayDetails?: {
    mode?: string;
    gateway?: string;
    key_id?: string;
    order_id?: string;
  };
  orderDetails?: {
    Name: string;
    phone: string;
    email: string;
  };
}

export interface PaymentInitiateResponse {
  success: boolean;
  paymentId?: string;
  /** Internal DB order id (ORD...). Use this for verify_payment.php. */
  orderId: string;
  /** Razorpay Orders API id (order_...). Use this for Checkout order_id. */
  razorpayOrderId?: string;
  amount: number;
  currency: string;
  key: string;
  message?: string;
}

export interface PaymentStatusResponse {
  success: boolean;
  status: string;
  transactionId?: string;
  message?: string;
  error?: string;
}

export interface PaymentHistoryResponse {
  success: boolean;
  payments: Array<{
    id: string;
    packageId: string;
    packageName: string;
    amount: number;
    status: string;
    date: string;
    transactionId?: string;
  }>;
  message?: string;
  error?: string;
}

const asRecord = (value: unknown): Record<string, unknown> =>
  value !== null && typeof value === 'object' ? (value as Record<string, unknown>) : {};

const pickString = (...values: unknown[]): string => {
  for (const value of values) {
    if (typeof value === 'string' && value.trim()) return value.trim();
    if (typeof value === 'number' && Number.isFinite(value)) return String(value);
  }
  return '';
};

const pickNumber = (...values: unknown[]): number => {
  for (const value of values) {
    if (typeof value === 'number' && Number.isFinite(value)) return value;
    if (typeof value === 'string' && value.trim()) {
      const parsed = Number.parseFloat(value.replace(/[^0-9.]/g, ''));
      if (Number.isFinite(parsed)) return parsed;
    }
  }
  return 0;
};

/** Razorpay Checkout order_id must be the Orders API id, never the internal ORD... id. */
export const isRazorpayOrderId = (value?: string): boolean =>
  !!value && /^order_[A-Za-z0-9]+$/.test(value);

const PAN_REGEX = /^[A-Z]{5}[0-9]{4}[A-Z]$/;

export const normalizePanNumber = (value?: string | null): string =>
  (value ?? '').trim().toUpperCase();

export const isValidPanNumber = (value?: string | null): boolean =>
  PAN_REGEX.test(normalizePanNumber(value));

/** Razorpay Checkout needs integer paise. API may send rupees (2358.82) or paise (235882). */
export const toRazorpayPaise = (amount: number, rupeesHint?: number): number => {
  if (!Number.isFinite(amount) || amount <= 0) {
    throw new Error('Invalid payment amount.');
  }

  if (rupeesHint && rupeesHint > 0) {
    const hintPaise = Math.round(rupeesHint * 100);
    if (Math.abs(amount - hintPaise) <= 1) return Math.round(amount);
    if (Math.abs(amount - rupeesHint) <= 0.5) return hintPaise;
  }

  if (!Number.isInteger(amount)) return Math.round(amount * 100);
  if (amount >= 10000) return amount;
  return Math.round(amount * 100);
};

const digitsOnly = (value: string): string => value.replace(/\D/g, '');

export const getPaymentInfo = async (
  packageId?: string | number,
  options?: { associateId?: number; serviceId?: number; panNumber?: string }
): Promise<PaymentInfo> => {
  const params: Record<string, unknown> = {};
  if (packageId) params.packageId = packageId;
  if (options?.associateId) params.associateId = options.associateId;
  if (options?.serviceId) params.serviceId = options.serviceId;
  if (options?.panNumber) params.panNumber = options.panNumber;

  const response = await makeRequest<unknown>(apiUrl.getPaymentInfo, {
    params,
    method: 'GET',
  });

  const apiResponse = asRecord(response);
  const data = asRecord(apiResponse.data ?? apiResponse);
  const total = asRecord(data.total);
  const pkg = asRecord(data.package);
  const associate = asRecord(data.associate);

  if (!isApiSuccess(response) && !apiResponse.data) {
    throw new Error(
      pickString(apiResponse.message, apiResponse.error) || 'Failed to fetch payment info'
    );
  }

  if (total.grand_total != null || pkg.name || associate.name) {
    const displayName = pickString(associate.name, pkg.name, data.packageName) || 'Service';
    const serviceLabel = pickString(associate.serviceName);
    return {
      packageId: (pkg.id as string | number) ?? packageId ?? associate.id ?? '',
      amount: pickNumber(total.subtotal, data.amount),
      packageName: serviceLabel ? `${displayName} — ${serviceLabel}` : displayName,
      description: pickString(pkg.description, data.description),
      tax: pickNumber(total.gst_amount),
      totalAmount: pickNumber(total.grand_total, data.amount),
      paymentSummary: Array.isArray(data.payment_summary)
        ? (data.payment_summary as PaymentSummaryItem[])
        : [],
      gatewayDetails: asRecord(data.gateway_details) as PaymentInfo['gatewayDetails'],
      orderDetails: asRecord(data.order_details) as PaymentInfo['orderDetails'],
    };
  }

  const amount = pickNumber(data.amount, data.price);
  return {
    packageId: (data.packageId as string | number) ?? packageId,
    amount,
    packageName: pickString(data.packageName, data.packagename, data.name) || 'Package',
    description: pickString(data.description, data.description1),
    tax: Math.round(amount * 0.18),
    totalAmount: Math.round(amount * 1.18),
  };
};

export const initiatePayment = async (
  packageId: string | number | undefined,
  panNumber?: string,
  options?: { associateId?: number; serviceId?: number; quotedFee?: number }
): Promise<PaymentInitiateResponse> => {
  const normalizedPan = normalizePanNumber(panNumber);
  if (!isValidPanNumber(normalizedPan)) {
    throw new Error('PAN number is required. Please complete personal details first.');
  }

  const body: Record<string, unknown> = {
    panNumber: normalizedPan,
  };
  if (packageId) {
    body.packageId = Number(packageId) || packageId;
  }
  if (options?.associateId) body.associateId = options.associateId;
  if (options?.serviceId) body.serviceId = options.serviceId;
  if (options?.quotedFee != null) body.quotedFee = options.quotedFee;

  const response = await makeRequest<Record<string, unknown>>(apiUrl.initiatePayment, {
    method: 'POST',
    body: JSON.stringify(body),
    retries: 0,
  });

  if (!isApiSuccess(response)) {
    throw new Error(extractApiMessage(response, 'Failed to initiate payment'));
  }

  const data = asRecord(response.data ?? response);
  const gateway = asRecord(data.gateway ?? data.gateway_details ?? data.gatewayDetails);
  const total = asRecord(data.total);

  // Internal ORD... id is stored in payment_info and required by verify_payment.php.
  const orderId = pickString(data.order_id, data.orderId);
  // Razorpay Checkout must receive the Orders API id (order_...), not ORD...
  const razorpayOrderId = pickString(
    data.razorpay_order_id,
    data.razorpayOrderId,
    isRazorpayOrderId(pickString(gateway.order_id, gateway.orderId))
      ? pickString(gateway.order_id, gateway.orderId)
      : ''
  );
  const key = pickString(
    gateway.key_id,
    gateway.keyId,
    data.key_id,
    data.keyId,
    data.key
  );
  const amount = pickNumber(data.amount, total.grand_total);
  const currency = pickString(data.currency) || 'INR';
  const paymentId = pickString(data.payment_id, data.paymentId);

  if (!orderId) throw new Error('Payment order ID is missing from API response.');
  if (!key) throw new Error('Razorpay key ID is missing from API response.');
  if (!amount) throw new Error('Payment amount is missing from API response.');

  return {
    success: true,
    paymentId: paymentId || undefined,
    orderId,
    razorpayOrderId: isRazorpayOrderId(razorpayOrderId) ? razorpayOrderId : undefined,
    amount,
    currency,
    key,
    message: pickString(data.message) || 'Payment initiated successfully.',
  };
};

export const getPaymentStatus = async (orderId: string): Promise<PaymentStatusResponse> => {
  const response = await makeRequest<PaymentStatusResponse>(apiUrl.getPaymentStatus, {
    params: { orderId },
    method: 'GET',
  });

  if (!isApiSuccess(response)) {
    throw new Error(response.message ?? response.error ?? 'Failed to fetch payment status');
  }

  return response;
};

export const getPaymentHistory = async (): Promise<PaymentHistoryResponse> => {
  const response = await makeRequest<PaymentHistoryResponse>(apiUrl.getPaymentHistory, {
    method: 'GET',
  });

  if (!isApiSuccess(response)) {
    throw new Error(response.message ?? response.error ?? 'Failed to fetch payment history');
  }

  return response;
};

export const verifyPayment = async (
  orderId: string,
  paymentId: string,
  signature: string,
  razorpayOrderId?: string
): Promise<{ success: boolean; message: string }> => {
  const response = await makeRequest<{
    success?: boolean;
    message?: string;
    error?: string;
  }>(apiUrl.verifyPayment, {
    method: 'POST',
    retries: 0,
    body: JSON.stringify({
      orderId,
      paymentStatus: 'success',
      transactionId: paymentId,
      paymentMethod: 'razorpay',
      gatewayName: 'razorpay',
      gatewayResponse: {
        razorpay_payment_id: paymentId,
        razorpay_order_id: razorpayOrderId || orderId,
        razorpay_signature: signature,
      },
    }),
  });

  if (!isApiSuccess(response)) {
    throw new Error(response.message ?? response.error ?? 'Payment verification failed');
  }

  return {
    success: true,
    message: response.message ?? 'Payment verified successfully',
  };
};

export const loadRazorpayScript = (): Promise<boolean> => {
  return new Promise((resolve) => {
    if (typeof window !== 'undefined' && window.Razorpay) {
      resolve(true);
      return;
    }

    const existing = document.querySelector(
      'script[src="https://checkout.razorpay.com/v1/checkout.js"]'
    );

    if (existing) {
      existing.addEventListener('load', () => resolve(true));
      existing.addEventListener('error', () => resolve(false));
      return;
    }

    const script = document.createElement('script');
    script.src = 'https://checkout.razorpay.com/v1/checkout.js';
    script.async = true;
    script.onload = () => resolve(true);
    script.onerror = () => resolve(false);
    document.body.appendChild(script);
  });
};

export const openRazorpayModal = async (options: {
  key: string;
  /** Razorpay Orders API id (order_...). Omit if the server did not create one. */
  razorpayOrderId?: string;
  amount: number;
  amountRupeesHint?: number;
  currency: string;
  packageName: string;
  name?: string;
  email: string;
  contact: string;
  onSuccess: (paymentData: RazorpaySuccessResponse) => void;
  onError: (error: Error) => void;
}): Promise<void> => {
  const scriptLoaded = await loadRazorpayScript();
  if (!scriptLoaded || !window.Razorpay) {
    throw new Error('Razorpay SDK could not load. Check your internet connection.');
  }

  const amountInPaise = toRazorpayPaise(options.amount, options.amountRupeesHint);
  const contact = digitsOnly(options.contact).slice(-10);
  const razorpayOrderId = isRazorpayOrderId(options.razorpayOrderId)
    ? options.razorpayOrderId
    : undefined;

  let settled = false;
  const fail = (error: Error) => {
    if (settled) return;
    settled = true;
    options.onError(error);
  };

  const checkout = new window.Razorpay({
    key: options.key,
    amount: amountInPaise,
    currency: options.currency || 'INR',
    ...(razorpayOrderId ? { order_id: razorpayOrderId } : {}),
    name: 'FinApp - Next Gen',
    description: `Payment for ${options.packageName}`,
    prefill: {
      name: options.name || '',
      email: options.email || '',
      contact,
    },
    theme: { color: '#059669' },
    retry: { enabled: false },
    handler: (response) => {
      settled = true;
      options.onSuccess(response);
    },
    modal: {
      confirm_close: true,
      ondismiss: () => fail(new Error('Payment cancelled.')),
    },
  });

  checkout.on('payment.failed', (response: unknown) => {
    const errorResponse = response as {
      error?: { description?: string; reason?: string };
    };
    fail(
      new Error(
        errorResponse.error?.description ||
          errorResponse.error?.reason ||
          'Payment failed. Please try again.'
      )
    );
  });

  checkout.open();
};
