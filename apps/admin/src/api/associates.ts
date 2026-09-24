import apiClient from './client';
import { API_ENDPOINTS } from './endpoints';
import type { ApiResponse } from '../types/api';

export interface AssociateServiceFee {
  serviceId: number;
  serviceName: string;
  description?: string;
  fee: number;
  isActive: boolean;
}

export interface AssociateProfile {
  id: number;
  name: string;
  firstName?: string;
  lastName?: string;
  email?: string;
  mobile?: string;
  role: string;
  bio: string;
  yearsExperience: number;
  qualification: string;
  licenseNumber: string;
  city: string;
  languages: string[];
  photoUrl?: string;
  verificationStatus: 'pending' | 'approved' | 'rejected';
  isListed: boolean;
  rejectionReason?: string | null;
  services: AssociateServiceFee[];
}

export interface ServiceCatalogItem {
  id: number;
  name: string;
  description?: string;
}

export const associatesApi = {
  getMyProfile: async (): Promise<AssociateProfile> => {
    const response = await apiClient.get<ApiResponse<{ profile: AssociateProfile }>>(
      API_ENDPOINTS.ASSOCIATE_PROFILE
    );
    return response.data.data.profile;
  },

  updateMyProfile: async (payload: {
    bio: string;
    yearsExperience: number;
    qualification: string;
    licenseNumber: string;
    city: string;
    languages: string[] | string;
    photoUrl?: string;
  }): Promise<AssociateProfile> => {
    const response = await apiClient.put<ApiResponse<{ profile: AssociateProfile }>>(
      API_ENDPOINTS.ASSOCIATE_PROFILE,
      payload
    );
    return response.data.data.profile;
  },

  getMyServices: async (): Promise<{ services: AssociateServiceFee[]; catalog: ServiceCatalogItem[] }> => {
    const response = await apiClient.get<
      ApiResponse<{ services: AssociateServiceFee[]; catalog: ServiceCatalogItem[] }>
    >(API_ENDPOINTS.ASSOCIATE_MY_SERVICES);
    return {
      services: response.data.data.services || [],
      catalog: response.data.data.catalog || [],
    };
  },

  updateMyServices: async (
    services: Array<{ serviceId: number; fee: number; isActive: boolean }>
  ): Promise<AssociateServiceFee[]> => {
    const response = await apiClient.put<ApiResponse<{ services: AssociateServiceFee[] }>>(
      API_ENDPOINTS.ASSOCIATE_MY_SERVICES,
      { services }
    );
    return response.data.data.services || [];
  },

  listForAdmin: async (params?: { status?: string; role?: string; search?: string }): Promise<AssociateProfile[]> => {
    const response = await apiClient.get<ApiResponse<{ associates: AssociateProfile[] }>>(
      API_ENDPOINTS.ADMIN_ASSOCIATES,
      { params }
    );
    return response.data.data.associates || [];
  },

  moderate: async (userId: number, action: 'approve' | 'reject' | 'unlist' | 'list', reason?: string) => {
    const response = await apiClient.put<ApiResponse<{ associate: AssociateProfile }>>(
      API_ENDPOINTS.ADMIN_ASSOCIATES,
      { userId, action, rejectionReason: reason }
    );
    return response.data.data.associate;
  },
};
