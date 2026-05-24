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
  ASSIGNED: '#2196f3',
  REQUIRED: '#f44336',
  INCORRECT: '#e91e63',
  FILED: '#4caf50',
  COMPLETED: '#4caf50',
  PAID: '#f9a825',   // yellow - payment success
  SUCCESS: '#4caf50', // green - ITR filed + acknowledgement generated
};

export const ITR_STATUS_LABELS: Record<string, string> = {
  PENDING: 'Pending',
  ASSIGNED: 'Assigned',
  REQUIRED: 'Required',
  INCORRECT: 'Incorrect',
  FILED: 'Filed',
  COMPLETED: 'Completed',
  PAID: 'Paid',
  SUCCESS: 'Success',
};

