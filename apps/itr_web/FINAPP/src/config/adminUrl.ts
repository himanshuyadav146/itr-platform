/**
 * Admin panel origin.
 * Local: website is :5174, admin is :5173/admin/
 * Production: same host, /admin/ is the admin build.
 */
export function getAdminOrigin(): string {
  const fromEnv = (import.meta.env.VITE_ADMIN_ORIGIN as string | undefined)?.replace(/\/$/, '');
  if (fromEnv) {
    return fromEnv;
  }
  if (import.meta.env.DEV) {
    return 'http://localhost:5173';
  }
  return window.location.origin;
}

export function getAdminLoginUrl(): string {
  return `${getAdminOrigin()}/admin/login`;
}

export function getAdminUrl(pathname: string): string {
  const path = pathname.startsWith('/') ? pathname : `/${pathname}`;
  return `${getAdminOrigin()}${path}`;
}
