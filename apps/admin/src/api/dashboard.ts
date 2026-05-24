import apiClient from './client';
import { API_ENDPOINTS } from './endpoints';
import type { DashboardStats, ApiResponse } from '../types';

export const dashboardApi = {
  getDashboardStats: async (): Promise<DashboardStats> => {
    const response = await apiClient.get<ApiResponse<DashboardStats>>(API_ENDPOINTS.DASHBOARD);
    // Handle both nested and direct data structures
    if (response.data && 'data' in response.data && response.data.data) {
      return response.data.data;
    }
    // If data is directly in response.data (some APIs return data directly)
    // Cast through unknown first to handle potential direct data structure
    return (response.data as unknown) as DashboardStats;
  },
};

