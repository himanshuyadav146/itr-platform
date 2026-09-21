import { apiUrl, PUBLIC_API_PATHS } from '../config/baseUrlConstant';
import { getAuthToken } from '../utils/authToken';

const API_TIMEOUT = 30000;
const MAX_RETRIES = 3;
const RETRY_DELAY = 1000;

export const HttpStatus = {
  OK: 200,
  CREATED: 201,
  BAD_REQUEST: 400,
  UNAUTHORIZED: 401,
  FORBIDDEN: 403,
  NOT_FOUND: 404,
  CONFLICT: 409,
  INTERNAL_SERVER_ERROR: 500,
  SERVICE_UNAVAILABLE: 503,
} as const;

export class ApiError extends Error {
  public status: number;
  public override message: string;
  public data?: any;

  constructor(status: number, message: string, data?: any) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
    this.message = message;
    this.data = data;
  }
}

export interface ApiResponse<T = any> {
  success?: boolean;
  status?: string;
  statusCode?: number;
  data?: T;
  message?: string;
  error?: string;
}

interface RequestOptions extends RequestInit {
  params?: Record<string, any>;
  timeout?: number;
  retries?: number;
}

const abortControllers = new Map<string, AbortController>();

const createQueryString = (params: Record<string, any>): string => {
  const searchParams = new URLSearchParams();
  Object.entries(params).forEach(([key, value]) => {
    if (value !== null && value !== undefined && value !== '') {
      searchParams.append(key, String(value));
    }
  });
  return searchParams.toString();
};

const buildUrl = (endpoint: string, params?: Record<string, any>): string => {
  if (!params) return endpoint;
  const queryString = createQueryString(params);
  if (!queryString) return endpoint;
  return `${endpoint}${endpoint.includes('?') ? '&' : '?'}${queryString}`;
};

const createTimeoutPromise = (ms: number): Promise<never> => {
  return new Promise((_, reject) =>
    setTimeout(() => reject(new Error('Request timeout')), ms)
  );
};

const sleep = (ms: number): Promise<void> => {
  return new Promise((resolve) => setTimeout(resolve, ms));
};

const isPublicEndpoint = (endpoint: string): boolean => {
  return PUBLIC_API_PATHS.some((path) => endpoint.startsWith(path) || endpoint.includes(path));
};

const handleResponse = async <T>(response: Response): Promise<T> => {
  const contentType = response.headers.get('content-type') || '';
  let data: any;

  if (contentType.includes('application/json')) {
    data = await response.json();
  } else {
    const text = await response.text();
    try {
      data = JSON.parse(text);
    } catch {
      data = text;
    }
  }

  if (!response.ok) {
    throw new ApiError(response.status, extractApiMessage(data, `HTTP Error ${response.status}`), data);
  }

  return data;
};

export const makeRequest = async <T>(
  endpoint: string,
  options: RequestOptions = {},
  retryCount = 0
): Promise<T> => {
  const {
    params,
    timeout = API_TIMEOUT,
    retries = MAX_RETRIES,
    ...fetchOptions
  } = options;

  const url = buildUrl(endpoint, params);
  const controller = new AbortController();
  const requestKey = `${fetchOptions.method || 'GET'}-${url}`;

  abortControllers.set(requestKey, controller);

  try {
    const headers: Record<string, string> = {};
    const isFormData = typeof FormData !== 'undefined' && fetchOptions.body instanceof FormData;

    if (!isFormData && fetchOptions.body) {
      headers['Content-Type'] = 'application/json';
    }

    if (
      fetchOptions.headers &&
      typeof fetchOptions.headers === 'object' &&
      !('append' in fetchOptions.headers)
    ) {
      Object.assign(headers, fetchOptions.headers as Record<string, string>);
    }

    const token = getAuthToken();
    if (token && !isPublicEndpoint(endpoint)) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    const fetchPromise = fetch(url, {
      ...fetchOptions,
      headers,
      signal: controller.signal,
    });

    const response = await Promise.race([
      fetchPromise,
      createTimeoutPromise(timeout),
    ]);

    abortControllers.delete(requestKey);
    return await handleResponse<T>(response as Response);
  } catch (error: any) {
    abortControllers.delete(requestKey);

    if (error.name === 'AbortError') {
      throw new ApiError(0, 'Request cancelled');
    }

    if (retryCount < retries && (error.status >= 500 || !error.status)) {
      await sleep(RETRY_DELAY * Math.pow(2, retryCount));
      return makeRequest<T>(endpoint, options, retryCount + 1);
    }

    throw error;
  }
};

export const cancelRequest = (requestKey: string): void => {
  const controller = abortControllers.get(requestKey);
  if (controller) {
    controller.abort();
    abortControllers.delete(requestKey);
  }
};

export const cancelAllRequests = (): void => {
  abortControllers.forEach((controller) => controller.abort());
  abortControllers.clear();
};

export const apiGet = async <T = any>(
  endpoint: string,
  options?: Omit<RequestOptions, 'method' | 'body'>
): Promise<T> => {
  return makeRequest<T>(endpoint, {
    ...options,
    method: 'GET',
  });
};

export const apiPost = async <T = any>(
  endpoint: string,
  data?: any,
  options?: Omit<RequestOptions, 'method' | 'body'>
): Promise<T> => {
  const isFormData = typeof FormData !== 'undefined' && data instanceof FormData;
  return makeRequest<T>(endpoint, {
    ...options,
    method: 'POST',
    body: data === undefined ? undefined : isFormData ? data : JSON.stringify(data),
  });
};

export const apiPut = async <T = any>(
  endpoint: string,
  data?: any,
  options?: Omit<RequestOptions, 'method' | 'body'>
): Promise<T> => {
  return makeRequest<T>(endpoint, {
    ...options,
    method: 'PUT',
    body: JSON.stringify(data),
  });
};

export const apiPatch = async <T = any>(
  endpoint: string,
  data?: any,
  options?: Omit<RequestOptions, 'method' | 'body'>
): Promise<T> => {
  return makeRequest<T>(endpoint, {
    ...options,
    method: 'PATCH',
    body: JSON.stringify(data),
  });
};

export const apiDelete = async <T = any>(
  endpoint: string,
  options?: Omit<RequestOptions, 'method' | 'body'>
): Promise<T> => {
  return makeRequest<T>(endpoint, {
    ...options,
    method: 'DELETE',
  });
};

const unwrapAuthPayload = (res: any) => {
  if (res && typeof res === 'object') {
    if ('data' in res && res.data) return res.data;
    if ('token' in res || 'UserId' in res || 'user' in res) return res;
  }
  return res;
};

export const authApi = {
  login: (credentials: {
    email: string;
    password: string;
    platform: string;
    version: string;
  }) => apiPost<any>(apiUrl.login, credentials).then(unwrapAuthPayload),

  signup: (data: {
    name: string;
    email: string;
    mobile: string;
    password: string;
    platform?: string;
    version?: string;
    role?: string;
  }) => apiPost<any>(apiUrl.signup, data).then(unwrapAuthPayload),

  forgotPassword: (email: string, password: string) =>
    apiPost(apiUrl.forgetPassword, { email, password }),

  refreshToken: () => apiGet(apiUrl.refreshToken),
};

export const itrApi = {
  getByUser: (userId: string) =>
    apiGet<any>(apiUrl.getItrByUser, { params: { userId } }),
};

export const itrDetailsApi = {
  getPersonalDetails: async (panNumber: string, userId?: string) => {
    const params: Record<string, string> = { PanNumber: panNumber };

    if (userId) {
      params.UserId = userId;
    } else {
      const storedUserId = localStorage.getItem('userId');
      if (storedUserId) {
        let id = storedUserId.trim();
        if (id.startsWith('"') && id.endsWith('"')) {
          id = id.slice(1, -1).trim();
        }
        params.UserId = id;
      }
    }

    return apiGet<any>(apiUrl.getPersonalDetail, { params });
  },

  addPersonalDetails: (data: any) => apiPost<any>(apiUrl.addPersonalDetails, data),
};

export const itrDocumentsApi = {
  getDocuments: (panNumber: string) =>
    apiGet<any>(apiUrl.getDocuments, { params: { PanNumber: panNumber } }),

  saveDocuments: (data: any) => apiPost<any>(apiUrl.saveDocuments, data),

  deleteDocument: (data: { id?: string | number; PanNumber: string; fileName: string }) =>
    apiPost<any>(apiUrl.deleteDocument, data),

  uploadDocuments: async (panNumber: string, files: File[], fileNames?: string[]) => {
    const results = [];
    for (let idx = 0; idx < files.length; idx++) {
      const file = files[idx];
      const fd = new FormData();
      fd.append('PanNumber', panNumber);
      fd.append('fileName', fileNames?.[idx] || file.name);
      fd.append('file', file);
      results.push(await uploadFormData(apiUrl.uploadDocument, fd));
    }
    return results.length === 1 ? results[0] : results;
  },
};

export const packagesApi = {
  getPackages: () => apiGet<any>(apiUrl.getPackages),
};

export const uploadFormData = async (
  endpoint: string,
  formData: FormData,
  timeout = API_TIMEOUT
): Promise<any> => {
  const controller = new AbortController();
  const token = getAuthToken();
  const headers: Record<string, string> = {};
  if (token) headers['Authorization'] = `Bearer ${token}`;

  try {
    const timeoutId = setTimeout(() => controller.abort(), timeout);
    const response = await fetch(endpoint, {
      method: 'POST',
      body: formData,
      headers,
      signal: controller.signal,
    });
    clearTimeout(timeoutId);
    return await handleResponse(response);
  } catch (err: any) {
    if (err.name === 'AbortError') throw new ApiError(0, 'Request timeout or cancelled');
    throw err instanceof ApiError ? err : new ApiError(0, err.message || 'Upload failed', err);
  }
};

export const extractApiMessage = (data: any, fallback = 'Request failed'): string => {
  if (!data) return fallback;
  if (typeof data === 'string' && data.trim()) return data;
  const nested = data?.data;
  const candidates = [
    nested?.message,
    nested?.error,
    data?.message,
    data?.error,
  ];
  for (const value of candidates) {
    if (typeof value === 'string' && value.trim() && !['error', 'success', 'fail'].includes(value.trim().toLowerCase())) {
      return value.trim();
    }
  }
  return fallback;
};

export const isApiSuccess = (res: any): boolean => {
  if (!res || typeof res !== 'object') return false;
  const status = String(res.status ?? '').toLowerCase();
  if (status === 'error' || status === 'fail' || status === 'failed') return false;
  if (res.success === false) return false;
  if (typeof res.statusCode === 'number' && res.statusCode >= 400) return false;
  if (res.success === true) return true;
  if (status === 'success') return true;
  if (res.statusCode === 200 || res.statusCode === 201) return true;
  return !!res.data;
};

export const getErrorMessage = (err: any): string => {
  if (!err) return 'Unknown error';
  if (err instanceof ApiError) {
    return extractApiMessage(err.data, err.message || `Error ${err.status}`);
  }
  if (typeof err === 'string') return err;
  if (err.data) return extractApiMessage(err.data, err.message || 'Request failed');
  if (err.message) return String(err.message);
  return String(err);
};
