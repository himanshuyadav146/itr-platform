import apiClient from './client';
import { API_ENDPOINTS } from './endpoints';
import type { LoginCredentials, LoginResponse, RegisterProfessionalData, ApiResponse } from '../types';

/** Normalize various API response shapes into LoginResponse so login works regardless of backend format */
function normalizeLoginResponse(raw: unknown): LoginResponse {
  const obj = raw && typeof raw === 'object' ? (raw as Record<string, unknown>) : {};
  const data = (obj.data && typeof obj.data === 'object' ? obj.data : obj) as Record<string, unknown>;
  const status = (obj.status as string) ?? (obj.success === true ? 'success' : 'error');
  const token =
    (data.token as string) ?? (obj.token as string) ?? '';
  const userId = Number(
    data.UserId ?? data.userId ?? data.user_id ?? data.id ?? obj.UserId ?? obj.userId ?? 0
  );
  const email = String(
    data.email ?? data.Email ?? data.mail ?? obj.email ?? obj.Email ?? ''
  );
  const role = (data.role ?? data.Role ?? obj.role ?? obj.Role ?? '') as string | undefined;
  const message = String(data.message ?? obj.message ?? (status === 'success' ? 'OK' : 'Login failed'));

  return {
    status: status === 'success' ? 'success' : 'error',
    statusCode: Number(obj.statusCode ?? obj.status_code ?? 200),
    data: {
      message,
      UserId: userId,
      email,
      token,
      role: role || undefined,
    },
  };
}

export const authApi = {
  login: async (credentials: LoginCredentials): Promise<LoginResponse> => {
    const response = await apiClient.post<unknown>(API_ENDPOINTS.LOGIN, credentials);
    return normalizeLoginResponse(response.data);
  },

  registerProfessional: async (data: RegisterProfessionalData): Promise<ApiResponse> => {
    const response = await apiClient.post<ApiResponse>(API_ENDPOINTS.REGISTER_PROFESSIONAL, data);
    return response.data;
  },

  adminLogin: async (credentials: LoginCredentials): Promise<LoginResponse> => {
    const response = await apiClient.post<LoginResponse>(API_ENDPOINTS.ADMIN_LOGIN, credentials);
    return response.data;
  },

  deleteAccount: async (): Promise<void> => {
    await apiClient.post(API_ENDPOINTS.DELETE_ACCOUNT, {});
  },
};

