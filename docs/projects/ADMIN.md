# Admin Panel Reference — React Dashboard

Project-specific reference for `apps/admin`. For cross-app docs see [../README.md](../README.md).

---

## Overview

| Property | Value |
|----------|-------|
| **Path** | `apps/admin` |
| **Stack** | React 19, TypeScript, Vite, MUI 7 |
| **Local URL** | `http://localhost:5173/admin/` |
| **Production path** | `/admin/` |
| **State** | Redux Toolkit + TanStack React Query |
| **HTTP** | Axios |

---

## Quick start

```bash
cd apps/admin
npm install
cp .env.example .env.local   # optional
npm run dev
```

Open: http://localhost:5173/admin/

Requires API running at `http://localhost/api`. See [../ENVIRONMENTS.md](../ENVIRONMENTS.md).

---

## Tech stack

| Layer | Library |
|-------|---------|
| UI | MUI 7, Emotion, MUI X Data Grid |
| Routing | react-router-dom 7 |
| State | Redux Toolkit, react-redux |
| Data fetching | TanStack React Query 5 |
| HTTP | Axios |
| Forms | react-hook-form, zod |
| Charts | Recharts |
| Build | Vite (rolldown-vite), React Compiler |

---

## Project structure

```
src/
├── api/
│   ├── client.ts          # Axios instance + interceptors
│   ├── auth.ts            # Login, register, delete
│   ├── endpoints.ts       # ← All API path constants
│   └── assignments.ts     # ITR assignment APIs
├── routes/
│   └── AppRoutes.tsx      # Route definitions + PrivateRoute
├── pages/                 # Page components
├── components/            # Shared UI
├── store/
│   └── authSlice.ts       # Auth state + localStorage
├── hooks/
│   └── useAuth.ts
└── utils/
    └── token.ts           # JWT parse/expiry check
```

---

## Routes

Base path: `/admin/` (Vite `base` + React Router `basename`)

| Path | Page | Access |
|------|------|--------|
| `/login` | LoginPage | Public |
| `/register` | RegisterPage | Public (professional signup) |
| `/forgot-password` | ForgotPasswordPage | Public (UI only) |
| `/delete-account` | DeleteAccountPage | Public (needs login to delete) |
| `/dashboard` | DashboardPage | Authenticated |
| `/users` | UsersPage | `ADMIN` only |
| `/users/:id` | UserDetailPage | `ADMIN` only |
| `/itrs` | ITRsPage | Authenticated |
| `/itrs/:id` | ITRDetailPage | Authenticated |
| `/professionals` | ProfessionalsPage | `ASSIGN_ITR` permission |
| `/packages` | PackagesPage | `ADMIN` only |
| `/packages/new` | PackageFormPage | `ADMIN` only |
| `/packages/:id` | PackageFormPage (edit) | `ADMIN` only |
| `/` | → redirect `/dashboard` | — |

**Route file:** `src/routes/AppRoutes.tsx`

---

## API endpoints

File: `src/api/endpoints.ts`

Base URL: `VITE_API_BASE_URL` or Vite proxy `/api` → `http://localhost`

| Category | Endpoints |
|----------|-----------|
| Auth | `POST /auth/login.php`, `/auth/register_professional.php`, `/auth/delete_account.php` |
| Dashboard | `GET /admin/dashboard.php` |
| Users | `GET/PUT /admin/users.php` |
| ITRs | `GET/PUT /admin/itrs.php`, actions: comment, assign, acknowledgement |
| Assignments | `POST /admin/assign_itr.php`, `GET /admin/get_assignments.php` |
| Personal details | `GET /itrdetails/get_personal_detail.php` |
| Documents | `GET /itrdetails/get_documents.php`, `GET /admin/documents.php` |
| Packages | `GET /package/getPackages.php`, `POST /package/addPackage.php`, `POST /package/deletePackage.php` |

Full mapping → [../SCREEN_API_MAP.md](../SCREEN_API_MAP.md)

---

## Authentication flow

```
LoginPage → authApi.login() → POST /auth/login.php
  → extract token, UserId, role
  → Redux authSlice → localStorage (auth_token, auth_user)
  → navigate to /dashboard
```

**Session:**
- Token stored in `localStorage`
- Axios interceptor attaches `Authorization: Bearer <token>`
- 401 response → clear auth → redirect to login
- JWT expiry checked on app load (`utils/token.ts`)

**Note:** Login uses `/auth/login.php` (not `admin_login.php`). Role from API determines access.

---

## RBAC (roles & permissions)

| Role | Typical access |
|------|----------------|
| `ADMIN` | Full: users, packages, all ITRs, dashboard |
| `CA` | Assigned ITRs, professional workflows |
| `ACCOUNTANT` | Assigned ITRs |
| `TAX_EXPERT` | ITR editing |
| `CLIENT` | Should use mobile app |

Permissions: `VIEW_ALL_ITRS`, `ASSIGN_ITR`, `EDIT_ITR`, etc. — checked in `PrivateRoute` and sidebar.

---

## Environment config

| File | Purpose |
|------|---------|
| `.env.local` | Local dev (gitignored) |
| `.env.production` | Production build (gitignored) |
| `.env.example` | Template (committed) |

**Local (use Vite proxy):**
```env
VITE_API_BASE_URL=
```

**Production build:**
```env
VITE_API_BASE_URL=https://allindiaitr.in
```

Proxy config: `vite.config.ts` — `/api` → `http://localhost`

See `API_SETUP.md` in app folder for details.

---

## Key features

| Feature | Page | Primary API |
|---------|------|-------------|
| Dashboard KPIs | `/dashboard` | `GET /admin/dashboard.php` |
| User management | `/users` | `GET/PUT /admin/users.php` |
| ITR list & detail | `/itrs` | `GET/PUT /admin/itrs.php` |
| Assign professional | ITR detail | `POST /admin/assign_itr.php` |
| Update status | ITR detail | `PUT /admin/update_status_step.php` |
| Document review | ITR detail | `GET /admin/documents.php` |
| Package CRUD | `/packages` | `/package/*` |
| Professional list | `/professionals` | `GET /admin/users.php?role=CA` |

---

## Commands

| Command | Purpose |
|---------|---------|
| `npm run dev` | Dev server with HMR |
| `npm run build` | Type-check + production build → `dist/` |
| `npm run preview` | Preview production build |
| `npm run lint` | ESLint |

---

## Build & deploy

```bash
npm run build
# Output: apps/admin/dist/
# Deploy to web server at /admin/
```

Ensure `.htaccess` or server config handles SPA routing (all paths → `index.html`).

---

## Creating admin user

After API database setup:

```sql
UPDATE users SET Role = 'admin' WHERE Email = 'test@example.com';
```

---

## Related docs

| Doc | Purpose |
|-----|---------|
| [../SCREEN_API_MAP.md](../SCREEN_API_MAP.md) | APIs per admin page |
| [../WORKFLOWS.md](../WORKFLOWS.md) | Admin journeys |
| [../API_CONTRACT.md](../API_CONTRACT.md) | API shapes |
| [../ENVIRONMENTS.md](../ENVIRONMENTS.md) | Env & proxy setup |
| `API_SETUP.md` (in app folder) | Proxy configuration |
| `apps/api/ADMIN_PANEL_SETUP.md` | Admin API setup |
