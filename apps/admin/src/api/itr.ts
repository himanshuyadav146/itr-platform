import apiClient from './client';
import { API_ENDPOINTS } from './endpoints';
import type { ITRDetail, ITRWithDetails, ITRFilters, PaginatedResponse, ApiResponse, ITRComment } from '../types';

export const itrApi = {
  getITRs: async (filters?: ITRFilters): Promise<PaginatedResponse<ITRDetail>> => {
    const response = await apiClient.get<ApiResponse<{ itrs: any[]; pagination: any }>>(API_ENDPOINTS.ITRS, {
      params: filters,
    });

    // Map the API response to our expected format
    const { itrs, pagination } = response.data.data;

    // Helper: display status = Success only when ITR filed + acknowledgement no.; Paid when payment success; else Pending
    const getDisplayStatus = (itr: any): string => {
      const ack =
        itr.acknowledgement_number ??
        itr.acknowledgementNumber ??
        itr.acknowledgement ??
        (itr.itrDetails?.[0] && (itr.itrDetails[0].acknowledgement_number ?? itr.itrDetails[0].acknowledgementNumber));
      const ackStr = ack != null && ack !== '' ? String(ack).trim() : '';
      if (ackStr) return 'SUCCESS';

      const payments = itr.payments;
      let payStatus: string | null = null;
      if (payments != null) {
        if (Array.isArray(payments) && payments.length > 0) {
          const first = payments[0];
          payStatus = first.status ?? first.payment_status ?? first.paymentStatus ?? null;
        } else if (typeof payments === 'object') {
          payStatus = payments.status ?? payments.payment_status ?? payments.paymentStatus ?? null;
        }
      }
      const payNormalized = payStatus ? String(payStatus).toUpperCase() : '';
      const paidValues = ['SUCCESS', 'COMPLETED', 'PAID'];
      if (payNormalized && paidValues.includes(payNormalized)) return 'PAID';

      const fromDetails = itr.itrDetails?.[0];
      const raw =
        itr.status ??
        itr.status_enum ??
        itr.statusEnum ??
        fromDetails?.status ??
        fromDetails?.status_enum ??
        fromDetails?.statusEnum;
      return raw ? String(raw).toUpperCase() : 'PENDING';
    };

    // Transform each ITR to match our ITRDetail interface
    const items: ITRDetail[] = itrs.map((itr: any) => {
      // Extract personal details from nested structure - check multiple possible locations
      const personalDetails = itr.personalDetails || itr.personal_detail || itr.personalDetailsData || {};
      
      // Extract userId and panNumber from multiple possible locations
      const userId = itr.userId || itr.UserId || personalDetails.userId || personalDetails.UserId || itr.user_id;
      const panNumber = itr.panNumber || itr.PanNumber || personalDetails.panNumber || personalDetails.PanNumber || itr.pan_number || '';
      
      // Extract both IDs according to backend structure
      // Backend has nested itrDetails array with the actual itrId
      const itrDetails = itr.itrDetails || [];
      const actualItrId = itrDetails.length > 0 ? itrDetails[0].itrId : null;
      
      const personalDetailId = itr.personalDetailId || itr.personal_detail_id || itr.id || itr.personalDetailsId;
      
      // Use actualItrId from itrDetails if available, fallback to personalDetailId
      const itrIdForAssignment = actualItrId || personalDetailId;

      const assignedPro = itr.assignments?.[0]?.professional;
      const nameFromAssignment = assignedPro
        ? [assignedPro.firstName, assignedPro.lastName].filter(Boolean).join(' ')
        : null;

      return {
        id: personalDetailId, // Use personalDetailId as primary display ID
        itrId: itrIdForAssignment, // Store the actual itr_id for assignment API
        userId: userId || 0,
        panNumber: panNumber || '',
        financialYear: personalDetails.financialYear || itr.financialYear || itr.financial_year || 'N/A',
        status: getDisplayStatus(itr),
        createdAt: personalDetails.createdAt || personalDetails.created_at || itr.createdAt || itr.CreatedAt || new Date().toISOString(),
        updatedAt: personalDetails.updatedAt || personalDetails.updated_at || itr.updatedAt || itr.UpdatedAt || new Date().toISOString(),
        acknowledgement_number: itr.acknowledgement_number || itr.acknowledgementNumber || itr.acknowledgement,
        assigned_to: itr.assigned_to || itr.assignedTo || itr.assignedProfessionalId,
        clientName: [
          personalDetails.firstName || personalDetails.first_name || personalDetails.FirstName,
          personalDetails.middleName || personalDetails.middle_name || personalDetails.MiddleName,
          personalDetails.lastName || personalDetails.last_name || personalDetails.LastName
        ].filter(Boolean).join(' ') || itr.clientName || itr.client_name || 'N/A',
        assignedProfessionalName:
          itr.assignedProfessionalName ||
          itr.assigned_to_name ||
          itr.professionalName ||
          itr.professional_name ||
          nameFromAssignment,
        // Store full personal details object for direct access on detail page
        _personalDetails: {
          ...personalDetails,
          userId: userId || personalDetails.userId,
          panNumber: panNumber || personalDetails.panNumber,
        },
        _itrDetails: itrDetails, // Store itrDetails array for debugging
        _rawITRData: itr, // Store raw data for debugging
      } as ITRDetail & { _personalDetails?: any; itrId?: number; _itrDetails?: any[]; _rawITRData?: any };
    });

    return {
      items,
      total: pagination.total,
      page: pagination.page,
      limit: pagination.limit,
      totalPages: pagination.totalPages,
    };
  },

  getITRDetails: async (id: number): Promise<ITRWithDetails> => {
    try {
      // Try the detail endpoint first
      const response = await apiClient.get<ApiResponse<any>>(API_ENDPOINTS.ITR_DETAILS(id));
      
      // Check if response has the expected structure
      if (response.data.data && typeof response.data.data === 'object') {
        const data = response.data.data;
        
        // If it's already in the correct format, return it
        if (data.id || data.personalDetailId) {
          const detailsArr = data.itrDetails || data.itr_details || [];
          const firstDetail = Array.isArray(detailsArr) && detailsArr.length > 0 ? detailsArr[0] : null;
          const rawItrId =
            firstDetail?.itrId ??
            firstDetail?.itr_id ??
            data.itrId ??
            data.itr_id;
          const parsedItrId = rawItrId != null && rawItrId !== '' ? Number(rawItrId) : NaN;
          const resolvedItrId = Number.isFinite(parsedItrId) && parsedItrId > 0 ? parsedItrId : undefined;

          return {
            id: data.id || data.personalDetailId,
            itrId: resolvedItrId,
            userId: data.userId || data.UserId,
            panNumber: data.panNumber || data.PanNumber,
            financialYear: data.financialYear || data.personalDetails?.financialYear || 'N/A',
            status: data.status || data.status_enum || 'PENDING',
            createdAt: data.createdAt || data.personalDetails?.createdAt || new Date().toISOString(),
            updatedAt: data.updatedAt || data.personalDetails?.updatedAt || new Date().toISOString(),
            acknowledgement_number: data.acknowledgement_number || data.acknowledgementNumber,
            assigned_to: data.assigned_to || data.assignedTo || data.assignedProfessionalId,
            clientName: data.clientName || (data.personalDetails ? [
              data.personalDetails.firstName,
              data.personalDetails.middleName,
              data.personalDetails.lastName
            ].filter(Boolean).join(' ') : 'N/A'),
            assignedProfessionalName: data.assignedProfessionalName || data.assignedToName,
            sources: data.sources || [],
            comments: data.comments || [],
            assignment: data.assignment,
          };
        }
      }
      
      // If response structure is different, try to extract from nested structure
      return response.data.data as ITRWithDetails;
    } catch (error) {
      console.error('Error fetching ITR details:', error);
      throw error;
    }
  },

  getITRByUser: async (userId: number): Promise<ITRDetail[]> => {
    const response = await apiClient.get<ApiResponse<ITRDetail[]>>(API_ENDPOINTS.ITR_BY_USER(userId));
    return response.data.data;
  },

  getITRById: async (itrId: number): Promise<ITRWithDetails> => {
    const response = await apiClient.get<ApiResponse<ITRWithDetails>>(API_ENDPOINTS.ITR_BY_ID(itrId));
    return response.data.data;
  },

  updateITR: async (payload: { id: number; status: string; comment?: string }) => {
    const response = await apiClient.put<ApiResponse<any>>(API_ENDPOINTS.ITR_UPDATE, payload);
    return response.data.data;
  },

  addComment: async (itrId: number, comment: string, status: string): Promise<ITRComment> => {
    const response = await apiClient.post<ApiResponse<ITRComment>>(API_ENDPOINTS.ITR_COMMENT, {
      itrId,
      comment_text: comment,
      status_enum: status,
    });
    return response.data.data;
  },

  assignITR: async (itrId: number, professionalId: number): Promise<ApiResponse> => {
    const response = await apiClient.post<ApiResponse>(API_ENDPOINTS.ITR_ASSIGN, {
      itrId,
      professionalId,
    });
    return response.data;
  },

  addAcknowledgement: async (itrId: number, acknowledgementNumber: string): Promise<ApiResponse> => {
    const response = await apiClient.post<ApiResponse>(API_ENDPOINTS.ITR_ACKNOWLEDGEMENT, {
      itrId,
      acknowledgement_number: acknowledgementNumber,
    });
    return response.data;
  },

  submitAcknowledgement: async (payload: {
    itrId: number;
    acknowledgementNumber: string;
    acknowledgementDate: string;
    remarks: string;
    itrForm: string;
    assessmentYear: string;
  }): Promise<ApiResponse> => {
    const response = await apiClient.post<ApiResponse>(API_ENDPOINTS.SUBMIT_ACKNOWLEDGEMENT, payload);
    return response.data;
  },
};

