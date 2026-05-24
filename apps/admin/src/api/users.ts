import apiClient from './client';
import { API_ENDPOINTS } from './endpoints';
import type { User, UserDetails, UserStats, PaginatedResponse, ApiResponse } from '../types';

export const usersApi = {
  getUsers: async (params?: {
    role?: string;
    search?: string;
    page?: number;
    limit?: number;
  }): Promise<PaginatedResponse<User>> => {
    try {
      const response = await apiClient.get<any>(API_ENDPOINTS.USERS, { params });
      
      console.log('[usersApi.getUsers] Raw axios response:', response);
      console.log('[usersApi.getUsers] Response.data:', response?.data);
      console.log('[usersApi.getUsers] Response.data type:', typeof response?.data);
      console.log('[usersApi.getUsers] Response.data keys:', response?.data ? Object.keys(response.data) : 'no data');
      
      // Handle different response structures - the API might return data in various formats
      let items: User[] = [];
      let total = 0;
      let page = params?.page || 1;
      let limit = params?.limit || 1000;
      let totalPages = 1;
      
      // Extract items from different possible response structures
      if (response?.data) {
        const data = response.data;
        
        // Structure 1: { status: 'success', data: { items: [...], pagination: {...} } } - wrapped in ApiResponse
        if (data.data) {
          const innerData = data.data;
          // Check for 'users' array first (API returns this)
          if (Array.isArray(innerData.users)) {
            items = innerData.users;
            total = innerData.pagination?.total || innerData.total || items.length;
            page = innerData.pagination?.page || innerData.page || page;
            limit = innerData.pagination?.limit || innerData.limit || limit;
            totalPages = innerData.pagination?.totalPages || innerData.totalPages || Math.ceil(total / limit);
          } else if (Array.isArray(innerData.items)) {
            items = innerData.items;
            total = innerData.pagination?.total || innerData.total || items.length;
            page = innerData.pagination?.page || innerData.page || page;
            limit = innerData.pagination?.limit || innerData.limit || limit;
            totalPages = innerData.pagination?.totalPages || innerData.totalPages || Math.ceil(total / limit);
          } else if (Array.isArray(innerData)) {
            items = innerData;
            total = items.length;
          }
        }
        // Structure 2: { items: [...], total: X, page: Y, ... } - direct PaginatedResponse
        else if (Array.isArray(data.items)) {
          items = data.items;
          total = data.total || items.length;
          page = data.page || page;
          limit = data.limit || limit;
          totalPages = data.totalPages || Math.ceil(total / limit);
        }
        // Structure 3: Direct array [user1, user2, ...]
        else if (Array.isArray(data)) {
          items = data;
          total = items.length;
        }
        // Structure 4: { users: [...] } or other field names
        else if (data.users && Array.isArray(data.users)) {
          items = data.users;
          total = data.total || items.length;
          page = data.page || page;
          limit = data.limit || limit;
          totalPages = data.totalPages || Math.ceil(total / limit);
        }
        // Structure 5: Try to find any array property
        else {
          for (const key in data) {
            if (Array.isArray(data[key])) {
              items = data[key];
              total = data.total || data.pagination?.total || items.length;
              page = data.page || data.pagination?.page || page;
              limit = data.limit || data.pagination?.limit || limit;
              totalPages = data.totalPages || data.pagination?.totalPages || Math.ceil(total / limit);
              break;
            }
          }
        }
      }
      
      // Map API field names (camelCase) to expected format (PascalCase)
      items = items.map((user: any) => ({
        UserId: user.userId || user.UserId,
        FirstName: user.firstName || user.FirstName || '',
        MiddleName: user.middleName || user.MiddleName || '',
        LastName: user.lastName || user.LastName || '',
        Email: user.email || user.Email || '',
        Mobile: user.mobile || user.Mobile || '',
        role: user.role,
        platform: user.platform,
        CreatedAt: user.createdAt || user.CreatedAt,
        paymentCount: user.paymentCount || 0,
        totalSpent: user.totalSpent || 0,
        assignedCount: user.assignedCount || 0,
        completedCount: user.completedCount || 0,
        totalITRsAssigned: user.assignedCount || 0,
        totalITRsFiled: user.completedCount || 0,
        revenueGenerated: user.totalSpent || 0,
      }));
      
      const result: PaginatedResponse<User> = {
        items: Array.isArray(items) ? items : [],
        total: total || (Array.isArray(items) ? items.length : 0),
        page,
        limit,
        totalPages: totalPages || Math.ceil((total || items.length) / limit) || 1,
      };
      
      console.log('[usersApi.getUsers] Final parsed result:', result);
      console.log('[usersApi.getUsers] Items array:', result.items);
      console.log('[usersApi.getUsers] Items count:', result.items.length);
      console.log('[usersApi.getUsers] First item:', result.items[0]);
      
      return result;
    } catch (error) {
      console.error('[usersApi.getUsers] Error fetching users:', error);
      throw error;
    }
  },

  getUserDetails: async (id: number): Promise<UserDetails> => {
    const response = await apiClient.get<ApiResponse<UserDetails>>(API_ENDPOINTS.USER_DETAILS(id));
    return response.data.data;
  },

  getUserStats: async (id: number): Promise<UserStats> => {
    const response = await apiClient.get<ApiResponse<UserStats>>(API_ENDPOINTS.USER_STATS(id));
    return response.data.data;
  },

  updateUser: async (id: number, data: Partial<User>): Promise<User> => {
    const response = await apiClient.put<ApiResponse<User>>(API_ENDPOINTS.USERS, { id, ...data });
    return response.data.data;
  },
};

