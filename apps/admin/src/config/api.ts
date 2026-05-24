/**
 * API Base URL Configuration
 * 
 * - Development: Uses '/api' which is proxied to 'http://localhost/api' via Vite
 * - Production: Must set VITE_API_BASE_URL environment variable (e.g., 'https://api.yourdomain.com' or 'https://yourdomain.com/api')
 */
export const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || (import.meta.env.DEV ? '/api' : '');

if (!import.meta.env.DEV && !import.meta.env.VITE_API_BASE_URL) {
  throw new Error(
    'VITE_API_BASE_URL is not set for production. ' +
    'Please set this environment variable to your production API base URL. ' +
    'Example: VITE_API_BASE_URL=https://api.yourdomain.com'
  );
}

