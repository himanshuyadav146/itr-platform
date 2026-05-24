import type { UserRole } from './enums';
import type { User } from './auth';

export interface UserDetails extends User {
  totalITRsAssigned?: number;
  totalITRsFiled?: number;
  revenueGenerated?: number;
}

export interface UserFilters {
  role?: UserRole;
  search?: string;
  page?: number;
  limit?: number;
}

export interface UserStats {
  totalITRs: number;
  filedITRs: number;
  revenue: number;
}

