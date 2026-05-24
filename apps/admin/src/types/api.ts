export interface ApiResponse<T = any> {
  status: 'success' | 'error';
  statusCode: number;
  data: T;
  message?: string;
}

export interface PaginatedResponse<T> {
  items: T[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

export interface DashboardStats {
  totalUsers: number;
  totalITRs: number;
  filedITRs: number;
  pendingITRs: number;
  totalRevenue: number;
  itrsPerMonth: Array<{ month: string; count: number }>;
  revenuePerMonth: Array<{ month: string; amount: number }>;
  statusDistribution: Array<{ status: string; count: number }>;
  itrsByProfessional?: Array<{ professional: string; count: number }>;
}

