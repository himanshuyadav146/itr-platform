import { TOKEN_STORAGE_KEY } from './constants';

export const getToken = (): string | null => {
  return localStorage.getItem(TOKEN_STORAGE_KEY);
};

export const setToken = (token: string): void => {
  localStorage.setItem(TOKEN_STORAGE_KEY, token);
};

export const removeToken = (): void => {
  localStorage.removeItem(TOKEN_STORAGE_KEY);
};

export const isTokenExpired = (token: string): boolean => {
  try {
    const parts = token.split('.');
    if (parts.length !== 3) return true;
    
    // Try to parse header first (some tokens have expire in header)
    let expire: number | null = null;
    try {
      const header = JSON.parse(atob(parts[0]));
      if (header.expire) {
        expire = header.expire;
      }
    } catch {
      // Header parsing failed, try payload
    }
    
    // If not found in header, check payload
    if (!expire) {
      const payload = JSON.parse(atob(parts[1]));
      // Check for standard JWT 'exp' claim or custom 'expire' or calculate from 'time'
      expire = payload.exp || payload.expire || (payload.time ? payload.time + 36000 : null);
    }
    
    if (!expire) {
      // Can't determine expiration, assume expired for safety
      return true;
    }
    
    // Convert to milliseconds if it's in seconds (common JWT format)
    const expireMs = expire < 10000000000 ? expire * 1000 : expire;
    
    return Date.now() >= expireMs;
  } catch {
    // If parsing fails, assume expired for security
    return true;
  }
};

