# API Configuration Setup Guide

Simple and straightforward API configuration for development and production.

## How It Works

### Development Mode (localhost)

- **Base URL**: `/api` (automatically proxied to `http://localhost/api`)
- **Example Request**: `/api/admin/dashboard.php` → proxied to → `http://localhost/api/admin/dashboard.php`

The Vite dev server automatically proxies all `/api/*` requests to `http://localhost/api/*`.

### Production Mode (when hosted)

- **Base URL**: Set via `VITE_API_BASE_URL` environment variable
- **Example**: `VITE_API_BASE_URL=https://api.yourdomain.com`
- **Example Request**: `https://api.yourdomain.com/admin/dashboard.php`

## Quick Setup

### Local Development

1. **Start the development server:**
   ```bash
   npm run dev
   ```

   That's it! The proxy is configured to work with `http://localhost/api` by default.

### Production Deployment

1. **Set the production API URL:**
   ```bash
   VITE_API_BASE_URL=https://api.yourdomain.com
   ```
   
   Or if your API is at a path:
   ```bash
   VITE_API_BASE_URL=https://yourdomain.com/api
   ```

2. **Build the application:**
   ```bash
   npm run build
   ```

## Configuration

### Environment Variable: `VITE_API_BASE_URL`

- **Development**: Leave empty/unset (defaults to `/api` which uses the proxy)
- **Production**: **Required** - Set to your production API base URL

**Examples:**
```bash
# Development (default - uses proxy)
VITE_API_BASE_URL=

# Production with subdomain
VITE_API_BASE_URL=https://api.yourdomain.com

# Production with path
VITE_API_BASE_URL=https://yourdomain.com/api
```

## File Structure

- `.env.local` - Local development (git-ignored, optional)
- `.env.production` - Production config (set in CI/CD or hosting platform)
- `vite.config.ts` - Proxy configuration (proxies `/api` to `http://localhost/api`)
- `src/config/api.ts` - Base URL logic
- `src/api/endpoints.ts` - API endpoint paths (e.g., `/admin/dashboard.php`)

## Troubleshooting

### Requests going to wrong URL

- Check browser console for the actual request URL
- Verify `VITE_API_BASE_URL` is set correctly for production
- In development, requests to `/api/*` should be automatically proxied

### CORS Errors

- In development, the proxy handles CORS automatically
- In production, ensure your backend has CORS headers configured

### Backend on different port

If your backend runs on a different port (e.g., `http://localhost:8080/api`), you can:
1. Update `vite.config.ts` proxy target to `http://localhost:8080`
2. Or set `VITE_API_BASE_URL=http://localhost:8080/api` in `.env.local`

## Examples

**Request Flow:**
```
Frontend Code: apiClient.get('/admin/dashboard.php')
↓
With Base URL '/api': /api/admin/dashboard.php
↓
Development: Proxied to → http://localhost/api/admin/dashboard.php
Production: Direct request to → https://api.yourdomain.com/admin/dashboard.php
```
