import apiClient from './client';
import { API_ENDPOINTS } from './endpoints';

export type AssociateApprovalStatus = 'pending' | 'approved' | 'rejected' | 'unlisted';

export interface AssociateServiceFee {
  id?: number;
  service_id: number;
  service_name?: string;
  service_description?: string;
  listed_fee: number | null;
  is_active: boolean;
}

export interface AssociateProfile {
  id: number;
  user_id: number;
  name: string;
  first_name?: string;
  last_name?: string;
  email?: string;
  mobile?: string;
  role: string;
  icai_membership_no?: string;
  gstin?: string;
  pan?: string;
  city?: string;
  state?: string;
  bio?: string;
  years_experience?: number;
  approval_status: AssociateApprovalStatus;
  rejection_reason?: string;
  approved_at?: string | null;
  created_at?: string | null;
  services?: AssociateServiceFee[];
}

export interface AssociateKpis {
  pending: number;
  approved: number;
  rejected: number;
  unlisted: number;
}

const unwrap = <T,>(payload: any): T => {
  if (payload?.data) return payload.data as T;
  return payload as T;
};

export const associatesApi = {
  list: async (params?: {
    status?: string;
    search?: string;
    page?: number;
    limit?: number;
  }) => {
    const response = await apiClient.get(API_ENDPOINTS.ASSOCIATES, { params });
    return unwrap<{
      associates: AssociateProfile[];
      kpis: AssociateKpis;
      pagination: { page: number; limit: number; total: number; totalPages: number };
    }>(response.data);
  },

  get: async (id: number) => {
    const response = await apiClient.get(API_ENDPOINTS.ASSOCIATE_DETAILS(id));
    return unwrap<{ associate: AssociateProfile }>(response.data).associate;
  },

  decide: async (userId: number, action: 'approve' | 'reject' | 'unlist', reason?: string) => {
    const response = await apiClient.post(API_ENDPOINTS.ASSOCIATES, { userId, action, reason });
    return unwrap<{ message: string; associate: AssociateProfile }>(response.data);
  },

  getProfile: async () => {
    const response = await apiClient.get(API_ENDPOINTS.ASSOCIATE_PROFILE);
    return unwrap<{ profile: AssociateProfile }>(response.data).profile;
  },

  saveProfile: async (payload: Partial<AssociateProfile> & { years_experience?: number }) => {
    const response = await apiClient.put(API_ENDPOINTS.ASSOCIATE_PROFILE, payload);
    return unwrap<{ message: string; profile: AssociateProfile }>(response.data);
  },

  getMyServices: async () => {
    const response = await apiClient.get(API_ENDPOINTS.ASSOCIATE_MY_SERVICES);
    return unwrap<{ services: AssociateServiceFee[] }>(response.data).services;
  },

  saveMyServices: async (services: AssociateServiceFee[]) => {
    const response = await apiClient.put(API_ENDPOINTS.ASSOCIATE_MY_SERVICES, { services });
    return unwrap<{ message: string; services: AssociateServiceFee[] }>(response.data);
  },

  listCatalog: async () => {
    const response = await apiClient.get(API_ENDPOINTS.ADMIN_SERVICES);
    return unwrap<{ services: Array<{ id: number; name: string; description: string; is_active: boolean }> }>(
      response.data
    ).services;
  },

  addCatalogService: async (name: string, description?: string) => {
    const response = await apiClient.post(API_ENDPOINTS.ADMIN_SERVICES, { name, description });
    return unwrap<{ message: string }>(response.data);
  },

  updateCatalogService: async (id: number, payload: { name?: string; description?: string; is_active?: boolean }) => {
    const response = await apiClient.put(API_ENDPOINTS.ADMIN_SERVICES, { id, ...payload });
    return unwrap<{ message: string }>(response.data);
  },
};
