import { ITRStatus } from './enums';

export interface ITRDetail {
  id: number;
  itrId?: number; // Actual ITR ID from itrDetails array for assignment
  userId: number;
  panNumber: string;
  financialYear: string;
  status: ITRStatus | string;
  createdAt: string;
  updatedAt: string;
  acknowledgement_number?: string;
  assigned_to?: number;
  clientName?: string;
  assignedProfessionalName?: string;
}

export interface ITRSource {
  id: number;
  itrId: number;
  sourceType: string;
  sourceName: string;
  amount: number;
  createdAt: string;
}

export interface ITRComment {
  id: number;
  itr_id: number;
  commented_by: number;
  comment_text: string;
  status_enum: ITRStatus;
  created_at: string;
}

export interface ITRAssignment {
  id: number;
  itr_id: number;
  assigned_to: number;
  assigned_by?: number;
  assigned_at: string;
  reassigned_at?: string;
  is_active: boolean;
}

export interface ITRFilters {
  status?: ITRStatus;
  assignedTo?: number;
  userId?: number;
  dateRange?: {
    start: string;
    end: string;
  };
  financialYear?: string;
  page?: number;
  limit?: number;
}

export interface ITRWithDetails extends ITRDetail {
  sources?: ITRSource[];
  comments?: ITRComment[];
  assignment?: ITRAssignment;
  clientName?: string;
  assignedProfessionalName?: string;
}

