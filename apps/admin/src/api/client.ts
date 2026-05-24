import axios, { type AxiosInstance, type InternalAxiosRequestConfig, type AxiosError } from 'axios';
import { API_BASE_URL } from '../config/api';
import { getToken, removeToken } from '../utils/token';
import { getStore } from '../store';
import { logout } from '../store/slices/authSlice';
import { USER_STORAGE_KEY } from '../utils/constants';

const apiClient: AxiosInstance = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 30000,
});

// Track if we're already handling a 401 to prevent loops
let isHandling401 = false;

// Request interceptor to add auth token
apiClient.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    // Don't add token to auth endpoints (login, register, etc.)
    const authEndpoints = ['/auth/login.php', '/auth/admin_login.php', '/auth/register_professional.php', '/login.php'];
    const isAuthEndpoint = authEndpoints.some(endpoint => config.url?.includes(endpoint));
    
    if (!isAuthEndpoint) {
      const token = getToken();
      if (token && config.headers) {
        // Ensure we're using the exact token from localStorage
        config.headers.Authorization = `Bearer ${token}`;
        console.log(`[API Request] ${config.method?.toUpperCase()} ${config.url}`);
        console.log(`[API Request] Token sent: Bearer ${token.substring(0, 30)}...`);
        console.log(`[API Request] Full token length: ${token.length}`);
      } else {
        console.warn(`[API Request] ${config.method?.toUpperCase()} ${config.url} - No token available`);
      }
    } else {
      console.log(`[API Request] ${config.method?.toUpperCase()} ${config.url} - Auth endpoint, skipping token`);
    }
    return config;
  },
  (error: AxiosError) => {
    return Promise.reject(error);
  }
);

// Response interceptor for error handling
apiClient.interceptors.response.use(
  (response) => response,
  (error: AxiosError) => {
    // Handle CORS errors
    if (!error.response && error.message.includes('CORS')) {
      console.error(
        'CORS Error: The backend server is not configured to allow requests from this origin.\n' +
        'Please ensure the backend sends proper CORS headers or use the Vite proxy in development.'
      );
    }

    if (error.response?.status === 401 && !isHandling401) {
      // Don't handle 401 for auth endpoints - they're expected to return 401 on failure
      const authEndpoints = ['/auth/login.php', '/auth/admin_login.php', '/auth/register_professional.php', '/login.php'];
      const isAuthEndpoint = authEndpoints.some(endpoint => error.config?.url?.includes(endpoint));
      
      if (isAuthEndpoint) {
        // Just reject the error for auth endpoints - don't log out
        return Promise.reject(error);
      }
      
      // Prevent multiple simultaneous 401 handling
      isHandling401 = true;
      
      console.error('[Auth] 401 Unauthorized - Detailed Error Info:');
      console.error('[Auth] Request URL:', error.config?.url);
      console.error('[Auth] Request Method:', error.config?.method?.toUpperCase());
      console.error('[Auth] Request Headers:', error.config?.headers);
      console.error('[Auth] Response Status:', error.response?.status);
      console.error('[Auth] Response Headers:', error.response?.headers);
      console.error('[Auth] Response Data:', error.response?.data);
      console.error('[Auth] Current path:', window.location.pathname);
      
      // Check if token exists in localStorage
      const storedToken = getToken();
      console.error('[Auth] Token in localStorage:', storedToken ? `${storedToken.substring(0, 30)}...` : 'NOT FOUND');
      
      // Clear token and user data first
      removeToken();
      localStorage.removeItem(USER_STORAGE_KEY);
      
      // Dispatch logout action to clear Redux state
      try {
        const store = getStore();
        const currentState = store.getState().auth;
        if (currentState.isAuthenticated) {
          console.log('[Auth] Dispatching logout action');
          store.dispatch(logout());
        }
      } catch (e) {
        // If store is not available (e.g., during module initialization), 
        // the logout will happen via localStorage clearing
        console.warn('Could not dispatch logout action:', e);
      }
      
      // Don't redirect here - let PrivateRoute handle it naturally
      // Just clear the state and reject the promise
      // Reset flag after a delay
      setTimeout(() => {
        isHandling401 = false;
      }, 2000);
    }
    return Promise.reject(error);
  }
);

export default apiClient;

