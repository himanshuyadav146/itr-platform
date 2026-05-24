import { useAuth } from './useAuth';
import { Permission, UserRole } from '../types/enums';
import { hasPermission } from '../utils/permissions';

export const usePermissions = () => {
  const { role } = useAuth();

  const checkPermission = (permission: Permission): boolean => {
    const result = hasPermission(role, permission);
    
    // Log permission check for debugging
    console.log('[usePermissions] Permission check:', {
      role,
      roleType: typeof role,
      permission,
      result,
      timestamp: new Date().toISOString()
    });
    
    return result;
  };

  // Type-safe role checks with case-insensitive comparison
  const normalizedRole = role?.toUpperCase().trim();
  const isAdmin = normalizedRole === UserRole.ADMIN;
  const isProfessional = normalizedRole === UserRole.CA || 
                        normalizedRole === UserRole.TAX_EXPERT || 
                        normalizedRole === UserRole.ACCOUNTANT;
  const isClient = normalizedRole === UserRole.CLIENT;

  console.log('[usePermissions] Role status:', {
    originalRole: role,
    normalizedRole,
    isAdmin,
    isProfessional,
    isClient,
    timestamp: new Date().toISOString()
  });

  return {
    hasPermission: checkPermission,
    role,
    isAdmin,
    isProfessional,
    isClient,
  };
};

