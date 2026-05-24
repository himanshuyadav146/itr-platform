import { UserRole, Permission } from '../types/enums';
import { ROLE_PERMISSIONS } from './constants';

// Helper to validate and normalize role string (case-insensitive)
const normalizeRole = (role: string | null | undefined): UserRole | null => {
  if (!role || typeof role !== 'string') {
    console.warn('[Permissions] Invalid role:', { role, type: typeof role });
    return null;
  }
  
  const upperRole = role.toUpperCase().trim() as UserRole;
  const validRoles = Object.values(UserRole);
  
  if (!validRoles.includes(upperRole)) {
    console.warn('[Permissions] Unknown role:', { 
      originalRole: role, 
      normalizedRole: upperRole,
      validRoles 
    });
    return null;
  }
  
  return upperRole;
};

export const hasPermission = (userRole: UserRole | null, permission: Permission): boolean => {
  // Normalize role to handle case-sensitivity and type issues
  const normalizedRole = normalizeRole(userRole as string);
  
  if (!normalizedRole) {
    console.log('[Permissions] No valid role found:', { 
      userRole, 
      permission,
      timestamp: new Date().toISOString()
    });
    return false;
  }
  
  const permissions = ROLE_PERMISSIONS[normalizedRole] || [];
  const hasAccess = permissions.includes(permission);
  
  // Log permission check for debugging
  console.log('[Permissions] Check:', {
    role: normalizedRole,
    permission,
    hasAccess,
    availablePermissions: permissions,
    timestamp: new Date().toISOString()
  });
  
  return hasAccess;
};

export const canViewAllITRs = (role: UserRole | null): boolean => {
  return hasPermission(role, Permission.VIEW_ALL_ITRS);
};

export const canAssignITR = (role: UserRole | null): boolean => {
  return hasPermission(role, Permission.ASSIGN_ITR);
};

export const canEditITR = (role: UserRole | null): boolean => {
  return hasPermission(role, Permission.EDIT_ITR);
};

export const canViewUsers = (role: UserRole | null): boolean => {
  return hasPermission(role, Permission.VIEW_USERS);
};

export const canViewPayments = (role: UserRole | null): boolean => {
  return hasPermission(role, Permission.VIEW_PAYMENTS);
};

