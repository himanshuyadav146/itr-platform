import apiClient from './client';
import { API_ENDPOINTS } from './endpoints';
import type { ITRDetail, ITRWithDetails, ITRFilters, PaginatedResponse, ApiResponse } from '../types';
import { resolveDisplayStatusFromApi } from '../utils/itrStatus';

function mapItrRecord(itr: Record<string, unknown>): ITRDetail {
  const personalDetails = (itr.personalDetails || itr.personal_detail || itr.personalDetailsData || {}) as Record<
    string,
    unknown
  >;

  const userId =
    itr.userId || itr.UserId || personalDetails.userId || personalDetails.UserId || itr.user_id;
  const panNumber =
    itr.panNumber ||
    itr.PanNumber ||
    personalDetails.panNumber ||
    personalDetails.PanNumber ||
    itr.pan_number ||
    '';

  const itrDetails = (itr.itrDetails || []) as Array<{ itrId?: number }>;
  const actualItrId = itrDetails.length > 0 ? itrDetails[0].itrId : null;
  const personalDetailId = itr.personalDetailId || itr.personal_detail_id || itr.id || itr.personalDetailsId;
  const itrIdForAssignment = actualItrId || personalDetailId;

  const assignedPro = (itr.assignments as Array<{ professional?: Record<string, string> }> | undefined)?.[0]
    ?.professional;
  const nameFromAssignment = assignedPro
    ? [assignedPro.firstName, assignedPro.lastName].filter(Boolean).join(' ')
    : null;

  const ack =
    itr.acknowledgementNumber ??
    itr.acknowledgement_number ??
    itr.acknowledgement;

  const displayStatus = resolveDisplayStatusFromApi(itr);

  return {
    id: Number(personalDetailId),
    itrId: itrIdForAssignment ? Number(itrIdForAssignment) : undefined,
    userId: Number(userId) || 0,
    panNumber: String(panNumber || ''),
    financialYear: String(
      personalDetails.financialYear || itr.financialYear || itr.financial_year || 'N/A'
    ),
    status: displayStatus,
    statusDisplayText: String(itr.statusDisplayText || ''),
    hasSuccessfulPayment: Boolean(itr.hasSuccessfulPayment),
    createdAt: String(
      personalDetails.createdAt ||
        personalDetails.created_at ||
        itr.createdAt ||
        itr.CreatedAt ||
        new Date().toISOString()
    ),
    updatedAt: String(
      personalDetails.updatedAt ||
        personalDetails.updated_at ||
        itr.updatedAt ||
        itr.UpdatedAt ||
        new Date().toISOString()
    ),
    acknowledgement_number: ack != null ? String(ack) : undefined,
    assigned_to: (itr.assigned_to || itr.assignedTo || itr.assignedProfessionalId) as number | undefined,
    clientName:
      [
        personalDetails.firstName || personalDetails.first_name || personalDetails.FirstName,
        personalDetails.middleName || personalDetails.middle_name || personalDetails.MiddleName,
        personalDetails.lastName || personalDetails.last_name || personalDetails.LastName,
      ]
        .filter(Boolean)
        .join(' ') ||
      String(itr.clientName || itr.client_name || 'N/A'),
    assignedProfessionalName: String(
      itr.assignedProfessionalName ||
        itr.assigned_to_name ||
        itr.professionalName ||
        itr.professional_name ||
        nameFromAssignment ||
        ''
    ) || undefined,
    _personalDetails: {
      ...personalDetails,
      userId: userId || personalDetails.userId,
      panNumber: panNumber || personalDetails.panNumber,
    },
    _itrDetails: itrDetails,
    _rawITRData: itr,
  } as ITRDetail & { _personalDetails?: Record<string, unknown>; _itrDetails?: unknown[]; _rawITRData?: unknown };
}

export const itrApi = {
  getITRs: async (filters?: ITRFilters): Promise<PaginatedResponse<ITRDetail>> => {
    const response = await apiClient.get<ApiResponse<{ itrs: Record<string, unknown>[]; pagination: Record<string, number> }>>(
      API_ENDPOINTS.ITRS,
      { params: filters }
    );

    const { itrs, pagination } = response.data.data;
    let items = itrs.map((itr) => mapItrRecord(itr));

    if (filters?.status) {
      const filterStatus = filters.status.toUpperCase();
      items = items.filter((item) => String(item.status).toUpperCase() === filterStatus);
    }

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
      const response = await apiClient.get<ApiResponse<Record<string, unknown>>>(API_ENDPOINTS.ITR_DETAILS(id));

      if (response.data.data && typeof response.data.data === 'object') {
        const data = response.data.data;
        if (data.id || data.personalDetailId) {
          return mapItrRecord(data) as ITRWithDetails;
        }
      }

      return response.data.data as unknown as ITRWithDetails;
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
    const response = await apiClient.put<ApiResponse<unknown>>(API_ENDPOINTS.ITR_UPDATE, payload);
    return response.data.data;
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
