import apiClient from './client';
import type { ApiResponse, PaginatedResponse } from '../types/api';
import type { Assignment, CreateAssignmentPayload, UpdateAssignmentPayload } from '../types/assignment';

const BASE_URL = '/admin';

export const assignmentsApi = {
    assignITR: async (payload: CreateAssignmentPayload): Promise<{ message: string; assignmentId: number }> => {
        console.log('[assignmentsApi.assignITR] Sending payload:', payload);
        const response = await apiClient.post<ApiResponse<{ message: string; assignmentId: number }>>(
            `${BASE_URL}/assign_itr.php`,
            payload
        );
        console.log('[assignmentsApi.assignITR] Response:', response.data);
        return response.data.data;
    },

    getAssignments: async (params?: {
        page?: number;
        limit?: number;
        itrId?: number;
        professionalId?: number;
        userId?: number;
        status?: string;
        priority?: string;
    }): Promise<PaginatedResponse<Assignment>> => {
        const response = await apiClient.get<ApiResponse<{ assignments: Assignment[]; pagination: any }>>(
            `${BASE_URL}/get_assignments.php`,
            { params }
        );
        return {
            items: response.data.data.assignments,
            total: response.data.data.pagination.total,
            page: response.data.data.pagination.page,
            limit: response.data.data.pagination.limit,
            totalPages: response.data.data.pagination.totalPages,
        };
    },

    updateAssignment: async (payload: UpdateAssignmentPayload): Promise<{ message: string }> => {
        const response = await apiClient.put<ApiResponse<{ message: string }>>(
            `${BASE_URL}/update_assignment.php`,
            payload
        );
        return response.data.data;
    },
};
