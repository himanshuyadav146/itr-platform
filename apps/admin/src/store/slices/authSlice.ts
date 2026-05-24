import { createSlice, type PayloadAction } from '@reduxjs/toolkit';
import type { User } from '../../types';
import { UserRole } from '../../types/enums';
import { getToken, setToken, removeToken, isTokenExpired } from '../../utils/token';
import { USER_STORAGE_KEY } from '../../utils/constants';

interface AuthState {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
  role: UserRole | null;
}

const initialState: AuthState = {
  user: (() => {
    try {
      const stored = localStorage.getItem(USER_STORAGE_KEY);
      return stored ? JSON.parse(stored) : null;
    } catch {
      return null;
    }
  })(),
  token: getToken(),
  isAuthenticated: false,
  role: null,
};

// Helper to normalize role (case-insensitive with validation)
const normalizeRole = (role?: string): UserRole | null => {
  if (!role || typeof role !== 'string') {
    console.warn('[AuthSlice] Invalid role provided:', { role, type: typeof role });
    return null;
  }
  
  const upperRole = role.toUpperCase().trim() as UserRole;
  const validRoles = Object.values(UserRole);
  
  // Validate against known roles
  if (!validRoles.includes(upperRole)) {
    console.error('[AuthSlice] Unknown role received from server:', { 
      originalRole: role,
      normalizedRole: upperRole,
      validRoles 
    });
    return null;
  }
  
  console.log('[AuthSlice] Role normalized successfully:', {
    original: role,
    normalized: upperRole
  });
  
  return upperRole;
};

if (initialState.token) {
  if (isTokenExpired(initialState.token)) {
    removeToken();
    localStorage.removeItem(USER_STORAGE_KEY);
    initialState.token = null;
    initialState.user = null;
  } else {
    initialState.isAuthenticated = true;
    initialState.role = normalizeRole(initialState.user?.role);
  }
}

const authSlice = createSlice({
  name: 'auth',
  initialState,
  reducers: {
    login: (state, action: PayloadAction<{ user: User; token: string }>) => {
      const normalizedRole = normalizeRole(action.payload.user.role);
      
      state.user = action.payload.user;
      state.token = action.payload.token;
      state.isAuthenticated = true;
      state.role = normalizedRole;

      console.log('[AuthSlice] Login successful:', {
        userId: action.payload.user.UserId,
        userEmail: action.payload.user.Email,
        userName: `${action.payload.user.FirstName} ${action.payload.user.LastName}`,
        originalRole: action.payload.user.role,
        normalizedRole,
        timestamp: new Date().toISOString()
      });

      setToken(action.payload.token);
      localStorage.setItem(USER_STORAGE_KEY, JSON.stringify(action.payload.user));
    },
    logout: (state) => {
      state.user = null;
      state.token = null;
      state.isAuthenticated = false;
      state.role = null;

      // Clear auth-related storage
      removeToken();
      localStorage.removeItem(USER_STORAGE_KEY);
      // Clear all storage (localStorage and sessionStorage)
      localStorage.clear();
      sessionStorage.clear();
    },
    setUser: (state, action: PayloadAction<User>) => {
      const normalizedRole = normalizeRole(action.payload.role);
      
      state.user = action.payload;
      state.role = normalizedRole;
      
      console.log('[AuthSlice] User updated:', {
        userId: action.payload.UserId,
        userEmail: action.payload.Email,
        userName: `${action.payload.FirstName} ${action.payload.LastName}`,
        originalRole: action.payload.role,
        normalizedRole,
        timestamp: new Date().toISOString()
      });
      
      localStorage.setItem(USER_STORAGE_KEY, JSON.stringify(action.payload));
    },
    updateToken: (state, action: PayloadAction<string>) => {
      state.token = action.payload;
      setToken(action.payload);
    },
  },
});

export const { login, logout, setUser, updateToken } = authSlice.actions;
export default authSlice.reducer;

