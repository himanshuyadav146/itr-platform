# tax_client — Development Guide

> **Single source of truth** for architecture, APIs, theme, routing, and UI migration.  
> Use this document for all future development on this project.

**App name (UI):** FinApp - Next Gen  
**Package:** `tax_client`  
**Platform:** Flutter 3.8+ (Dart ^3.8.1)  
**Backend:** `http://allindiaitr.in`  
**Figma (design source):** [tax_app — full file](https://www.figma.com/design/7PMVY5IZeTIPhFazfBGoY7/tax_app?node-id=0-1)  
- File key: `7PMVY5IZeTIPhFazfBGoY7`  
- Page node: `0:1`  
- **UI mode:** dark theme (entire file) — app defaults to `ThemeMode.dark`

---

## Table of contents

1. [Quick start](#quick-start)
2. [Architecture](#architecture)
3. [Project structure](#project-structure)
4. [Routing & screens](#routing--screens)
5. [State management](#state-management)
6. [API layer](#api-layer)
7. [Theme & design tokens](#theme--design-tokens)
8. [UI migration tracker (Figma → App)](#ui-migration-tracker-figma--app)
9. [Known issues & tech debt](#known-issues--tech-debt)
10. [Recommended UI conversion workflow](#recommended-ui-conversion-workflow)
11. [Build & release notes](#build--release-notes)

---

## Quick start

```bash
# Install dependencies
flutter pub get

# Code generation (freezed, json_serializable, riverpod)
dart run build_runner build --delete-conflicting-outputs

# Run (uninstall old build if package id changed)
flutter run
```

**Firebase:** Core, Analytics, Crashlytics, Messaging, Local Notifications are initialized in `main.dart`.

**Splash:** Native splash color `#1E1E2C` (`pubspec.yaml` → `flutter_native_splash`).

---

## Architecture

**Pattern:** Clean Architecture per feature + **Riverpod** for DI/state.

```
Presentation (screens, widgets, ViewModels/StateNotifiers)
        ↓
Domain (entities, repository interfaces, use cases)
        ↓
Data (repository impl, remote data sources, models)
```

**Key packages:** `flutter_riverpod`, `go_router`, `freezed`, `json_serializable`, `dartz` (Either), `google_fonts`, `razorpay_flutter`, `firebase_*`.

**Error handling:** `Either<Failure, T>` in domain; `ErrorHandler` / `ErrorProcessor` in presentation.

---

## Project structure

```
lib/
├── main.dart                          # App entry, Firebase, theme, router
├── core/
│   ├── common/widgets/                # Shared UI (CoreScaffold, PrimaryButton, …)
│   ├── config/
│   │   ├── app_router.dart            # GoRouter routes
│   │   ├── router_provider.dart       # initialLocation: /splash
│   │   ├── strings/app_strings.dart
│   │   └── theme/                     # AppColors, AppTypography, AppTheme, AppSpacing
│   ├── constant/                      # api_constants, app_constants, validation
│   ├── network/                       # ApiClient, token storage, logout, no-internet
│   ├── payments/                      # Razorpay
│   ├── services/push_notification/
│   └── utils/
├── features/
│   ├── auth/              # login, signup, forget password
│   ├── splash/
│   ├── home/
│   ├── personal_info/   # ITR list, personal info form
│   ├── document_upload/
│   ├── packages/          # bottom sheet only (no screen)
│   ├── payment/
│   ├── status/            # ITR timeline
│   ├── orders/
│   ├── more/              # account menu
│   ├── profile/           # stub
│   ├── settings/          # stub
│   └── refer_earn/        # stub
```

---

## Routing & screens

| Route | Screen | Purpose |
|-------|--------|---------|
| `/splash` | `SplashScreen` | Brand splash → `/` or `/login` |
| `/login` | `LoginScreen` | Auth |
| `/register` | `SignUpScreen` | Registration |
| `/forgot-password` | `ForgetPasswordScreen` | Password reset |
| `/` | `HomeScreen` | Dashboard, File ITR, E-Verify |
| `/orders` | `OrdersScreen` | Order list → status |
| `/more` | `MoreScreen` | Account, logout, delete |
| `/itr_list` | `ItrListScreen` | Select existing ITR |
| `/personal_info` | `PersonalInformationScreen` | ITR personal details form |
| `/document_upload` | `UploadDocumentsScreen` | Document upload |
| `/payment` | `PaymentScreen` | `?packageId=` Razorpay |
| `/status` | `StatusScreen` | ITR progress timeline |
| `/profile` | `ProfileScreen` | Stub |
| `/settings` | `SettingsScreen` | Stub |
| `/refer_earn` | `ReferAndEarnScreen` | Stub |

**Initial route:** `/splash` (`router_provider.dart`).

**Navigation patterns:**
- Bottom nav: Home `/`, Orders `/orders`, More `/more`
- `SideDrawer` exists but `includeDrawer: false` everywhere
- **Bug:** `MoreScreen` back navigates to `/dashboard` (route does not exist; use `/`)

---

## State management

| Area | Provider / Notifier | Location |
|------|---------------------|----------|
| Auth | `authViewModelProvider` | `features/auth/presentation/providers/` |
| Personal info / ITR | `personalInfoViewModelProvider` | `features/personal_info/...` |
| Packages | `packagesProvider`, `selectedPackageProvider` | `features/packages/...` |
| Documents | `documentUploadViewModelProvider` | `features/document_upload/...` |
| Orders | `ordersViewModelProvider` | `features/orders/...` |
| Status | `statusViewModelProvider` | `features/status/...` |
| Router | `routerProvider` | `core/config/router_provider.dart` |
| No internet | `noInternetNotifierProvider` | Shows `NoInternetSheet` |
| Logout | `logoutNotifierProvider` | Redirects to `/login` |

**Journey types:** `JourneyType` enum (`FileItr`, `EVerify`, etc.) — E-Verify auto-selects package id `"7"`.

---

## API layer

**Base URL:** `http://allindiaitr.in` (`lib/core/constant/api_constants.dart`)

### Standard response envelope

Every API must return:

```json
{
  "statusCode": 200,
  "status": "success",
  "data": {}
}
```

- `status`: `"success"` | `"error"` only  
- `data`: always an object (never raw array/null at root)

Handled by `ApiResponse` / `BaseResponse` in `lib/core/network/`.

### Endpoints (summary)

| Domain | Path |
|--------|------|
| Login | `/api/auth/login.php` |
| Signup | `/api/auth/signup.php` |
| Forget password | `/api/auth/forget_password.php` |
| Refresh token | `/api/auth/refresh_token.php` |
| Delete account | `/api/auth/delete_account.php` |
| FCM register | `/api/auth/register_fcm.php` |
| Add personal details | `/api/itrdetails/add_personal_details.php` |
| Get personal detail | `/api/itrdetails/get_personal_detail.php` |
| Get ITR by user | `/api/get_itrbyuser.php` |
| Detailed status | `/api/itr_status/get_detailed_status.php` |
| User orders | `/api/itr_status/get_user_orders.php` |
| Documents CRUD | `/api/itrdetails/add_documents.php`, `save_documents.php`, `delete_document.php`, `get_documents.php` |
| Packages | `/api/package/getPackages.php` |
| Payment | `/api/payment/get_payment_info.php`, `initiate_payment.php`, `verify_payment.php`, `get_payment_status.php` |

**Document URLs:** `{baseUrl}/api/uploads/{panNumber}/{fileName}`

**Android:** `usesCleartextTraffic="true"` for HTTP (no custom network security config).

---

## Theme & design tokens (global only)

**Official approach:** One `ThemeData` on `MaterialApp` — [Flutter themes cookbook](https://docs.flutter.dev/cookbook/design/themes).

| File | Role |
|------|------|
| `lib/core/config/theme/app_colors.dart` | Raw palette (used only when building `ThemeData`) |
| `lib/core/config/theme/app_typography.dart` | Inter `TextTheme` |
| `lib/core/config/theme/app_spacing.dart` | Radius / spacing constants |
| `lib/core/config/theme/app_theme.dart` | **Single** `AppTheme.theme` → `ThemeData` + `ColorScheme` |
| `lib/core/config/theme/app_theme_extension.dart` | `ThemeExtension` for auth gradient / glass card |

### Application (`main.dart`)

```dart
MaterialApp.router(
  theme: AppTheme.theme,  // dark / Figma — no per-screen themeMode
  routerConfig: router,
);
```

**Do not** set colors per screen. Use:
- `Theme.of(context).colorScheme`
- `Theme.of(context).textTheme`
- `context.appExtras` (auth-only extension)

### Shared layout widgets (use theme, not local colors)

| Widget | Use for |
|--------|---------|
| `AuthScaffold` | Login, signup, forgot password background |
| `AuthFormCard` | Glass form container on auth |
| `AuthHeader` | Logo + title on auth |
| `CoreScaffold` | All main app screens |
| `CoreTextField` / `PrimaryButton` | Forms (inherit `inputDecorationTheme`, `elevatedButtonTheme`) |

### Color tokens (`AppColors` → `ColorScheme`)

| Token | Hex | Maps to |
|-------|-----|---------|
| `brandNavy` | `#1E1E2C` | `scaffoldBackgroundColor` |
| `brandNavyLight` | `#2D2D44` | `surface` (elevated cards) |
| `navBarBackground` / `navBarGradient` | `#0B1326` | Bottom tab bar (Figma `Nav`) |
| `brandNavyMuted` | `#3D3D5C` | `surfaceContainerHighest` |
| `primary` | `#448AFF` | `primary` |
| `secondary` | `#FF7D2E` | `secondary` |
| `success` / `error` / `info` | semantic | badges, service cards |

### Removed (no longer used)

- `lib/src/core/theme/app_theme.dart` (duplicate)
- `lib/src/.../theme_provider.dart` (per-screen light/dark toggle)
- `auth_background.dart` (replaced by `AuthScaffold` + extension)

### Screens still to migrate off hardcoded `Colors.*`

`OrdersScreen`, `ItrListScreen`, `UploadDocumentsScreen`, `MoreScreen`, `SideDrawer`, `DocumentViewerModal`, `package_bottom_sheet.dart`.

---

## UI migration tracker (Figma → App)

Use this checklist for screen-by-screen conversion. **Figma column** to be filled when file access is restored.

### Figma access checklist

- [ ] Share file with `himanshuyadav146@gmail.com` (can view)
- [ ] Re-run Figma MCP `get_metadata` on file `7PMVY5IZeTIPhFazfBGoY7`
- [ ] Export/screenshot each frame; map frame name → app route
- [ ] Extract variables (colors, typography, spacing) into `AppColors` / `AppSpacing`

### Screen mapping

| Priority | Figma frame (TBD) | App route | Screen | Migration status | Key gaps (current app) |
|----------|-------------------|-----------|--------|------------------|------------------------|
| P0 | TBD | `/splash` | Splash | Partial | Uses theme bg; verify logo size/animation vs Figma |
| P0 | TBD | `/login` | Login | Partial | Custom dark UI; hardcoded gradient/colors; not using `AppColors.authGradient` yet |
| P0 | TBD | `/register` | SignUp | Partial | Same auth shell as login |
| P0 | TBD | `/forgot-password` | ForgetPassword | Partial | Same auth shell |
| P1 | TBD | `/` | Home | Not started | Service cards use random `Colors.blueAccent/green/teal`; gradient header; commented carousel |
| P1 | TBD | `/orders` | Orders | Not started | Custom card layout; status badge colors hardcoded |
| P1 | TBD | `/more` | More | Not started | Profile gradient card; delete/logout sheets; broken `/dashboard` back |
| P2 | TBD | `/itr_list` | ItrList | Not started | `CustomCard` list; FAB; green/blue info chips hardcoded |
| P2 | TBD | `/personal_info` | PersonalInformation | Partial | Uses `Theme.colorScheme` — closest to target pattern |
| P2 | TBD | `/document_upload` | UploadDocuments | Not started | Black upload buttons; overlay opacity hardcoded |
| P2 | TBD | `/payment` | Payment | Partial | Mostly theme-based; shadow opacity hardcoded |
| P2 | TBD | `/status` | Status | Partial | Timeline tiles; Lottie success card |
| P3 | TBD | — | Package bottom sheet | Not started | `package_bottom_sheet.dart` — no dedicated route |
| P3 | TBD | `/profile` | Profile | Stub | Placeholder text only |
| P3 | TBD | `/settings` | Settings | Stub | Placeholder text only |
| P3 | TBD | `/refer_earn` | ReferAndEarn | Stub | Placeholder text only |

### Per-screen change categories (template)

When analyzing each Figma frame, document:

1. **Layout** — spacing, scroll, safe areas, max width  
2. **Typography** — font family, sizes, weights  
3. **Colors** — map to `AppColors` tokens  
4. **Components** — buttons, inputs, cards, nav, sheets  
5. **Assets** — icons, illustrations, Lottie  
6. **States** — empty, loading, error, success  
7. **Interactions** — navigation, bottom sheets, modals  

### Global UI gaps (app-wide)

| Area | Current | Target |
|------|---------|--------|
| Auth vs main app | Two visual systems (dark navy vs light blue) | Single design system from Figma |
| `AppColors` usage | Mostly only in `AppTheme` | All screens import tokens |
| Bottom navigation | Material default + primary | Match Figma tab bar |
| Cards | `CustomCard` radius 30, custom shadow | Align with Figma card component |
| App bar | `CoreAppBar` minimal | Figma header variants per screen |
| Drawer | Built but disabled | Confirm Figma: drawer vs bottom nav only |
| Stubs | Profile, Settings, Refer & Earn | Implement or remove from Figma scope |

---

## Known issues & tech debt

1. **`/dashboard` route** referenced in `MoreScreen` — does not exist.  
3. **`login_screen.dart`** imports `core_scaffold.dart` but does not use it.  
4. **`SideDrawer`** unused; navigation is bottom-nav only.  
5. **Figma MCP** cannot read `tax_app` until file is shared with authenticated user.  
6. **HTTP cleartext** — production should move to HTTPS when backend supports it.  
7. **Keystore / secrets** — `finapp-keystore.jks` is untracked; never commit.

---

## Recommended UI conversion workflow

**Best approach (recommended over big-bang rewrite):**

### Phase 1 — Design system (1–2 days)
1. Fix Figma access; export variables → `AppColors`, `AppSpacing`, `AppTypography`.  
2. Build reusable widgets: `AppButton`, `AppTextField`, `AppCard`, `AppScaffold` matching Figma components.  
3. Migrate **auth screens** first (already closest to Figma navy brand).

### Phase 2 — Shell & navigation (1 day)
1. Bottom nav, app bar, splash per Figma.  
2. Remove or fix dead routes (`/dashboard`).

### Phase 3 — Screen-by-screen (ordered by P0→P3 table)
For each screen:
1. Figma screenshot + `get_design_context` node.  
2. Update layout/widgets only; **keep ViewModels/API calls unchanged**.  
3. PR per screen or per feature group (easier review).  
4. QA on device (light + dark if in scope).

### Phase 4 — Cleanup
1. Delete hardcoded `Colors.*`  
2. Remove stub screens or implement  
3. Delete `lib/src/` legacy  

**Alternatives considered:**

| Approach | Pros | Cons |
|----------|------|------|
| Screen-by-screen PRs ✅ | Safe, reviewable, keeps app shippable | Slower |
| Big-bang UI branch | Fast visual swap | High merge conflict risk |
| Flutter Theme only | Quick | Won’t fix layouts/components |
| New package `design_system/` | Clean separation | More setup upfront |

**Recommendation:** Phase 1–3 with **one PR per screen group** (Auth, Main tabs, ITR flow, Payment/Status).

---

## Build & release notes

- **Version:** `1.0.0+10` (`pubspec.yaml`)  
- **Launcher icons:** `flutter_launcher_icons.yaml`  
- **Codegen:** run `build_runner` after model changes  
- **Package id:** verify `applicationId` in `android/app/build.gradle` before uninstall/install instructions  

### ITR flow (business)

1. Home → File ITR / E-Verify → package bottom sheet (E-Verify uses package id `7`).  
2. `getItrByUser` → count `0` → `/personal_info`; else → `/itr_list`.  
3. Personal info → document upload → payment → status timeline.

### Package feature

- `packagesProvider` loads on home init.  
- Selected package stored in `selectedPackageProvider`.  
- `packageId` sent with personal details and payment.

---

## Document history

| Date | Change |
|------|--------|
| 2026-05-22 | Created single `DEVELOPMENT.md`; consolidated scattered MD docs; theme token refactor; UI migration tracker added |

**Superseded files (removed):** `README.md`, `API_RESPONSE_SPECIFICATION.md`, `GET_ITR_BY_USER_FLOW_EXPLANATION.md`, `FIX_SUMMARY.md`, `RUN_APP_NOW.md`, `QUICK_START_PACKAGES.md`, `PACKAGE_IMPLEMENTATION_SUMMARY.md`, `FINAL_FIX_COMPLETE.md`
