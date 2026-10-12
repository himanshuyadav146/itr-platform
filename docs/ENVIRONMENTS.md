# Environments

Configuration reference for local, staging, and production across all ITR Platform apps.

---

## Environment overview

| Environment | API URL | Admin URL | Mobile base URL |
|-------------|---------|-----------|-----------------|
| **Local** | `http://localhost/api` | `http://localhost:5173/admin/` | `http://10.0.2.2/api` (Android emulator) |
| **Production** | `http://allindiaitr.in/api` | `https://allindiaitr.in/admin/` | `http://allindiaitr.in` |

> Staging is not configured yet. When added, document URLs here and in each app's config.

---

## Local development

### API (`apps/api`)

| Setting | Value |
|---------|-------|
| Web server | XAMPP Apache |
| Document root | Symlink `apps/api` → `/Applications/XAMPP/xamppfiles/htdocs/api` |
| Database | `itr_services` on localhost MySQL |
| DB user | `root` (default XAMPP) |
| DB password | empty (default XAMPP) |
| JWT key | `testitr_key` (dev only) |
| Payment mode | `test` |

**Setup commands:**

```bash
# Symlink API to XAMPP
ln -sf "$PWD/apps/api" /Applications/XAMPP/xamppfiles/htdocs/api

# Create config from template
cp apps/api/include/config.local.php.example apps/api/include/config.php

# Database setup
open http://localhost/api/setup.php

# Composer deps (payments)
cd apps/api && composer install
```

**Verify:**

```bash
curl http://localhost/api/test_connection.php
```

**macOS permission fix (403 errors):**

```bash
./scripts/fix-xampp-permissions.sh
```

### Admin (`apps/admin`)

| Setting | Value |
|---------|-------|
| Dev server | Vite on port 5173 |
| Base path | `/admin/` |
| API proxy | `/api` → `http://localhost/api` |
| Env file | `.env.local` |

**`.env.local` (development):**

```env
# Leave empty to use Vite proxy
VITE_API_BASE_URL=
```

**Commands:**

```bash
cd apps/admin
npm install
npm run dev
```

Open: http://localhost:5173/admin/

### Mobile (`apps/mobile/tax_client`)

| Setting | Value |
|---------|-------|
| API base | Change in `lib/core/constant/api_constants.dart` |
| Android emulator | `http://10.0.2.2` (maps to host localhost) |
| Physical device | Your machine's LAN IP, e.g. `http://192.168.1.x` |
| Cleartext HTTP | Enabled in Android manifest (dev only) |
| Firebase | `android/app/google-services.json` required |

**For local API testing**, edit `api_constants.dart`:

```dart
static const String baseUrl = 'http://10.0.2.2';  // Android emulator
```

**Commands:**

```bash
cd apps/mobile/tax_client
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

---

## Production

### API

| Setting | Value |
|---------|-------|
| Host | cPanel / Apache on `allindiaitr.in` |
| Path | `/public_html/api/` or equivalent |
| Database | Production MySQL credentials |
| Config files | Created manually on server (not in git) |

**Required files on server (never commit):**

```
include/config.php           # DB credentials + JWT key
include/payment_config.php   # Razorpay live keys
include/firebase_config.php  # FCM service account (optional)
```

**Deploy steps:**

1. Upload/sync PHP code (exclude `vendor/` if installing via Composer on server).
2. Run `composer install --no-dev` on server or upload `vendor/`.
3. Ensure `uploads/` is writable.
4. Import any pending SQL migrations.

See `apps/api/CPANEL_DEPLOYMENT.md` and `apps/api/PAYMENT_DEPLOYMENT.md`.

### Admin

| Setting | Value |
|---------|-------|
| Build output | `apps/admin/dist/` |
| Host path | `/admin/` on web server |
| Env | `VITE_API_BASE_URL` at build time |

**`.env.production`:**

```env
VITE_API_BASE_URL=https://allindiaitr.in
```

**Build & deploy:**

```bash
cd apps/admin
npm run build
# Upload dist/ contents to server /admin/
```

### Mobile

| Setting | Value |
|---------|-------|
| API base | `http://allindiaitr.in` (in `api_constants.dart`) |
| Package ID | `com.finapp.com` |
| Version | `1.0.0+10` (see `pubspec.yaml`) |
| Signing | `android/key.properties` + keystore (gitignored) |

**Release build:**

```bash
flutter build apk --release
# or
flutter build appbundle --release
```

---

## Config files reference

### Must NOT be in git

| File | Contains | Template |
|------|----------|----------|
| `apps/api/include/config.php` | DB password, JWT secret | `config.local.php.example` |
| `apps/api/include/payment_config.php` | Razorpay/Paytm keys | `payment_config.php.example` |
| `apps/api/include/firebase_config.php` | FCM service account | `firebase_config.php.example` |
| `apps/admin/.env.local` | Dev API URL | `.env.example` |
| `apps/admin/.env.production` | Prod API URL | `.env.example` |
| `apps/mobile/tax_client/android/key.properties` | Signing config | — |
| `*.jks` / `*.keystore` | App signing keys | — |

### Safe to commit

| File | Purpose |
|------|---------|
| `*.example` templates | Document required config shape |
| `.env.example` | Documents env vars without values |
| `google-services.json` | Firebase client config (Android) |

---

## Environment variables summary

### Admin (Vite — build-time)

| Variable | Local | Production |
|----------|-------|------------|
| `VITE_API_BASE_URL` | empty (use proxy) | `https://allindiaitr.in` |
| `VITE_LOGIN_PATH` | optional override | `/auth/login.php` |

### API (PHP — runtime)

| Variable / config | Local | Production |
|-------------------|-------|------------|
| `$servername` | `localhost` | production DB host |
| `$username` | `root` | production DB user |
| `$password` | `` | production DB password |
| `$database` | `itr_services` | production DB name |
| `$key` (JWT) | `testitr_key` | strong random string |
| `$payment_mode` | `test` | `live` |

### Mobile (Dart — compile-time)

| Constant | Local (emulator) | Production |
|----------|------------------|------------|
| `ApiConstants.baseUrl` | `http://10.0.2.2` | `http://allindiaitr.in` |

---

## Test credentials (local)

After running `setup_database.sql` or `setup.php`:

| Field | Value |
|-------|-------|
| Email | `test@example.com` |
| Password | `test123` |

**Promote to admin (SQL):**

```sql
UPDATE users SET Role = 'admin' WHERE Email = 'test@example.com';
```

---

## Troubleshooting by environment

| Issue | Environment | Fix |
|-------|-------------|-----|
| 403 on `/api` | Local macOS | Run `./scripts/fix-xampp-permissions.sh` |
| CORS errors | Local admin | Leave `VITE_API_BASE_URL` empty (use proxy) |
| Mobile can't reach API | Local | Use `10.0.2.2` not `localhost` on emulator |
| Payment fails | Local | Set Razorpay **test** keys in `payment_config.php` |
| API down after deploy | Production | Verify `config.php` exists on server |
| Admin blank after deploy | Production | Check `/admin/` base path and `.htaccess` |

---

## Related docs

- [../README.md](../README.md) — full setup guide
- [projects/API.md](./projects/API.md) — API config details
- [projects/ADMIN.md](./projects/ADMIN.md) — admin env & proxy
- [projects/MOBILE.md](./projects/MOBILE.md) — mobile local API setup
