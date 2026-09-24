import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import type { PayloadAction } from '@reduxjs/toolkit';
import { authApi, getErrorMessage } from '../../services/api';
import { extractJwt, getAuthToken, setAuthToken } from '../../utils/authToken';
import type {
  User,
  AuthCredentials,
  SignupData,
  AuthResponse,
} from '../../types/auth.d';

export interface AuthState {
  user: User | null;
  token: string | null;
  loading: boolean;
  error: string | null;
  isAuthenticated: boolean;
  selectedPackage: any | null;
  selectedAssociate: any | null;
  selectedService: any | null;
}

const initialState: AuthState = {
  user: (() => {
    try {
      const userStr = localStorage.getItem('user');
      return userStr ? JSON.parse(userStr) : null;
    } catch {
      return null;
    }
  })(),
  token: (() => {
    try {
      return getAuthToken();
    } catch {
      return null;
    }
  })(),
  loading: false,
  error: null,
  isAuthenticated: (() => {
    try {
      return !!getAuthToken();
    } catch {
      return false;
    }
  })(),
  selectedPackage: (() => {
    try {
      const pkgStr = localStorage.getItem('selectedPackage');
      return pkgStr ? JSON.parse(pkgStr) : null;
    } catch {
      return null;
    }
  })(),
  selectedAssociate: (() => {
    try {
      const raw = localStorage.getItem('selectedAssociate');
      return raw ? JSON.parse(raw) : null;
    } catch {
      return null;
    }
  })(),
  selectedService: (() => {
    try {
      const raw = localStorage.getItem('selectedService');
      return raw ? JSON.parse(raw) : null;
    } catch {
      return null;
    }
  })(),
};

/**
 * Async Thunk for Login
 */
export const loginUser = createAsyncThunk<
  AuthResponse,
  AuthCredentials,
  { rejectValue: string }
>(
  'auth/loginUser',
  async (credentials: AuthCredentials, { rejectWithValue }) => {
    try {
      const response = await authApi.login(credentials);
      const userId = response.UserId ?? response.user?.UserId ?? response.user?.id;
      const user = response.user || {
        id: userId != null ? String(userId) : undefined,
        UserId: userId,
        name: response.name || '',
        email: credentials.email,
        mobile: response.mobile || '',
      };

      const token = extractJwt(response.token);
      if (!token) {
        throw new Error('Login succeeded but token was missing');
      }

      setAuthToken(token);
      if (userId != null) {
        localStorage.setItem('userId', String(userId).trim());
      }
      localStorage.setItem('user', JSON.stringify(user));
      return { ...response, user, UserId: userId, token };
    } catch (error) {
      return rejectWithValue(getErrorMessage(error));
    }
  }
);

/**
 * Async Thunk for Signup
 */
export const signupUser = createAsyncThunk<
  AuthResponse,
  SignupData,
  { rejectValue: string }
>(
  'auth/signupUser',
  async (data: SignupData, { rejectWithValue }) => {
    try {
      const response = await authApi.signup(data);
      const userId = response.UserId ?? response.user?.UserId ?? response.user?.id;
      const user = response.user || {
        id: userId != null ? String(userId) : undefined,
        UserId: userId,
        name: data.name,
        email: data.email,
        mobile: data.mobile,
      };

      const token = extractJwt(response.token);
      if (token) {
        setAuthToken(token);
      }
      if (userId != null) {
        localStorage.setItem('userId', String(userId).trim());
      }
      localStorage.setItem('user', JSON.stringify(user));
      return { ...response, user, UserId: userId, token: token || response.token };
    } catch (error) {
      return rejectWithValue(getErrorMessage(error));
    }
  }
);

/**
 * Async Thunk for Logout
 */
export const logoutUser = createAsyncThunk<
  null,
  void,
  { rejectValue: string }
>(
  'auth/logoutUser',
  async () => {
    try {
    //  await authApi.logout();
      localStorage.removeItem('authToken');
      localStorage.removeItem('user');
      localStorage.removeItem('userId');
      return null;
    } catch (error) {
      // Clear local storage even if API call fails
      localStorage.removeItem('authToken');
      localStorage.removeItem('user');
      localStorage.removeItem('userId');
      return null;
    }
  }
);



const authSlice = createSlice({
  name: 'auth',
  initialState,
  reducers: {
    setUser: (state, action: PayloadAction<User | null>) => {
      state.user = action.payload;
    },
    setToken: (state, action: PayloadAction<string | null>) => {
      state.token = action.payload;
      state.isAuthenticated = !!action.payload;
    },
    clearError: (state) => {
      state.error = null;
    },
    setLoading: (state, action: PayloadAction<boolean>) => {
      state.loading = action.payload;
    },
    setSelectedPackage: (state, action: PayloadAction<any | null>) => {
      state.selectedPackage = action.payload;
      if (action.payload) {
        localStorage.setItem('selectedPackage', JSON.stringify(action.payload));
      } else {
        localStorage.removeItem('selectedPackage');
      }
    },
    setSelectedAssociate: (state, action: PayloadAction<any | null>) => {
      state.selectedAssociate = action.payload;
      if (action.payload) {
        localStorage.setItem('selectedAssociate', JSON.stringify(action.payload));
      } else {
        localStorage.removeItem('selectedAssociate');
      }
    },
    setSelectedService: (state, action: PayloadAction<any | null>) => {
      state.selectedService = action.payload;
      if (action.payload) {
        localStorage.setItem('selectedService', JSON.stringify(action.payload));
      } else {
        localStorage.removeItem('selectedService');
      }
    },
  },
  extraReducers: (builder) => {
    // Login
    builder
      .addCase(loginUser.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(
        loginUser.fulfilled,
        (state, action: PayloadAction<AuthResponse>) => {
          state.loading = false;
          state.token = extractJwt(action.payload.token);
          state.user = action.payload.user ?? null;
          state.isAuthenticated = true;
          state.error = null;
        }
      )
      .addCase(loginUser.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
        state.isAuthenticated = false;
      });

    // Signup
    builder
      .addCase(signupUser.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(
        signupUser.fulfilled,
        (state, action: PayloadAction<AuthResponse>) => {
          state.loading = false;
          state.token = extractJwt(action.payload.token);
          state.user = action.payload.user ?? null;
          state.isAuthenticated = true;
          state.error = null;
        }
      )
      .addCase(signupUser.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
        state.isAuthenticated = false;
      });

    // Logout
    builder
      .addCase(logoutUser.pending, (state) => {
        state.loading = true;
      })
      .addCase(logoutUser.fulfilled, (state) => {
        state.loading = false;
        state.user = null;
        state.token = null;
        state.isAuthenticated = false;
        state.error = null;
      })
      .addCase(logoutUser.rejected, (state) => {
        state.loading = false;
        state.user = null;
        state.token = null;
        state.isAuthenticated = false;
      });
  },
});

export const { setUser, setToken, clearError, setLoading, setSelectedPackage, setSelectedAssociate, setSelectedService } = authSlice.actions;
export default authSlice.reducer;
