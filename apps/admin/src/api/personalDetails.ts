import apiClient from './client';
import { API_ENDPOINTS } from './endpoints';
import type { ApiResponse } from '../types';

export interface PersonalDetails {
    UserId: number;
    PanNumber: string;
    FirstName?: string;
    MiddleName?: string;
    LastName?: string;
    DateOfBirth?: string;
    Gender?: string;
    Email?: string;
    MobileNumber?: string;
    AadharNumber?: string;
    Address?: string;
    City?: string;
    State?: string;
    PinCode?: string;
    Occupation?: string;
    EmployerName?: string;
    EmployerAddress?: string;
    BankName?: string;
    BankAccountNumber?: string;
    BankIFSC?: string;
    [key: string]: any; // Allow for additional fields from API
}

export const personalDetailsApi = {
    getPersonalDetails: async (userId: number, panNumber: string): Promise<PersonalDetails> => {
        const response = await apiClient.get<ApiResponse<PersonalDetails>>(
            API_ENDPOINTS.PERSONAL_DETAILS(userId, panNumber)
        );
        return response.data.data;
    },

    updatePersonalDetails: async (
        userId: number,
        panNumber: string,
        data: Partial<PersonalDetails>
    ): Promise<PersonalDetails> => {
        const response = await apiClient.put<ApiResponse<PersonalDetails>>(
            API_ENDPOINTS.PERSONAL_DETAILS(userId, panNumber),
            data
        );
        return response.data.data;
    },
};
