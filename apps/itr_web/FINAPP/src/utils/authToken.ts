const AUTH_TOKEN_KEY = 'authToken';

const isJwt = (value: string): boolean => value.split('.').length === 3;

const stripBearer = (value: string): string =>
  value.replace(/^Bearer\s+/i, '').trim();

/**
 * The API expects a raw JWT. Some sessions stored the whole login payload
 * in localStorage (`{"token":"eyJ...","userId":"...","user":{...}}`), which
 * makes Token::Verify fail with 401.
 */
export const extractJwt = (raw: unknown): string | null => {
  if (raw == null) return null;

  let value = typeof raw === 'string' ? raw.trim() : '';

  if (!value && typeof raw === 'object') {
    const obj = raw as Record<string, unknown>;
    const nested = obj.token ?? obj.Token ?? (obj.data as Record<string, unknown> | undefined)?.token;
    return extractJwt(nested);
  }

  if (!value) return null;
  value = stripBearer(value);

  if (value.startsWith('{')) {
    try {
      const parsed = JSON.parse(value) as Record<string, unknown>;
      const nested =
        parsed.token ??
        parsed.Token ??
        (parsed.data as Record<string, unknown> | undefined)?.token ??
        (parsed.user as Record<string, unknown> | undefined)?.token;
      return extractJwt(nested);
    } catch {
      return null;
    }
  }

  return isJwt(value) ? value : null;
};

export const getAuthToken = (): string | null => {
  try {
    const stored = localStorage.getItem(AUTH_TOKEN_KEY);
    const token = extractJwt(stored);
    if (token && stored && stored !== token) {
      localStorage.setItem(AUTH_TOKEN_KEY, token);
    }
    return token;
  } catch {
    return null;
  }
};

export const setAuthToken = (raw: unknown): string | null => {
  const token = extractJwt(raw);
  try {
    if (token) {
      localStorage.setItem(AUTH_TOKEN_KEY, token);
    } else {
      localStorage.removeItem(AUTH_TOKEN_KEY);
    }
  } catch {
    // ignore storage failures
  }
  return token;
};
