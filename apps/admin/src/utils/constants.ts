import { UserRole, Permission } from '../types/enums';

export const TOKEN_STORAGE_KEY = 'auth_token';
export const USER_STORAGE_KEY = 'auth_user';

export const ROLE_PERMISSIONS: Record<UserRole, Permission[]> = {
  [UserRole.ADMIN]: [
    Permission.VIEW_ALL_ITRS,
    Permission.VIEW_PAYMENTS,
    Permission.ASSIGN_ITR,
    Permission.EDIT_ITR,
    Permission.VIEW_USERS,
    Permission.VIEW_PROFESSIONALS,
    Permission.MANAGE_USERS,
  ],
  [UserRole.CA]: [
    Permission.VIEW_ASSIGNED_ITRS,
    Permission.EDIT_ITR,
  ],
  [UserRole.TAX_EXPERT]: [
    Permission.VIEW_ASSIGNED_ITRS,
    Permission.EDIT_ITR,
  ],
  [UserRole.ACCOUNTANT]: [
    Permission.VIEW_ASSIGNED_ITRS,
    Permission.EDIT_ITR,
  ],
  [UserRole.CLIENT]: [],
};

export const ITR_STATUS_COLORS: Record<string, string> = {
  PENDING: '#ff9800',
  PAID: '#2196f3',
  IN_PROGRESS: '#7b1fa2',
  COMPLETED: '#4caf50',
  // Legacy workflow edit labels
  ASSIGNED: '#2196f3',
  REQUIRED: '#f44336',
  INCORRECT: '#e91e63',
  FILED: '#00897b',
  SUCCESS: '#4caf50',
};

export const ITR_STATUS_LABELS: Record<string, string> = {
  PENDING: 'Pending',
  PAID: 'Paid',
  IN_PROGRESS: 'In Progress',
  COMPLETED: 'Completed',
  ASSIGNED: 'Assigned',
  REQUIRED: 'Required',
  INCORRECT: 'Incorrect',
  FILED: 'Filed',
  SUCCESS: 'Completed',
};

