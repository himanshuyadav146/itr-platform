# Mobile App Reference — FinApp (tax_client)

Project-specific reference for `apps/mobile/tax_client`. For cross-app docs see [../README.md](../README.md).

---

## Overview

| Property | Value |
|----------|-------|
| **Display name** | FinApp - Next Gen |
| **Package name** | `tax_client` |
| **Android ID** | `com.finapp.com` |
| **Path** | `apps/mobile/tax_client` |
| **Stack** | Flutter 3.8+, Dart ^3.8.1 |
| **State** | Riverpod |
| **Routing** | GoRouter |
| **Backend** | `http://allindiaitr.in` |
| **Version** | `1.0.0+10` |

---

## Quick start

```bash
cd apps/mobile/tax_client
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

See [../ENVIRONMENTS.md](../ENVIRONMENTS.md) for local API configuration.

For the full pre-implementation UI audit, read [MOBILE_UI_REFACTOR_ANALYSIS.md](./MOBILE_UI_REFACTOR_ANALYSIS.md).

For the first screen-specific Step 2 report, read [MOBILE_STEP2_LOGIN_ANALYSIS.md](./MOBILE_STEP2_LOGIN_ANALYSIS.md).

---

## Project structure

```
lib/
├── main.dart                          # Entry: Firebase, theme, router
├── core/
│   ├── common/widgets/                # CoreScaffold, PrimaryButton, AuthScaffold…
│   ├── config/
│   │   ├── app_router.dart            # GoRouter route definitions
│   │   ├── router_provider.dart       # initialLocation: /splash
│   │   ├── strings/app_strings.dart
│   │   └── theme/                     # AppColors, AppTypography, AppTheme
│   ├── constant/
│   │   ├── api_constants.dart         # ← All API paths
│   │   └── app_constants.dart
│   ├── network/                       # ApiClient, token storage, logout
│   ├── payments/                      # Razorpay integration
│   └── services/push_notification/
└── features/
    ├── auth/
    ├── splash/
    ├── home/
    ├── personal_info/
    ├── document_upload/
    ├── packages/
    ├── payment/
    ├── status/
    ├── orders/
    ├── more/
    ├── profile/          # stub
    ├── settings/         # stub
    └── refer_earn/       # stub
```

Each feature follows **Clean Architecture**: `presentation/` → `domain/` → `data/`.

---

## Routes

| Route | Screen | Initial? |
|-------|--------|----------|
| `/splash` | SplashScreen | ✅ Yes |
| `/login` | LoginScreen | |
| `/register` | SignUpScreen | |
| `/forgot-password` | ForgetPasswordScreen | |
| `/` | HomeScreen | Bottom nav 0 |
| `/orders` | OrdersScreen | Bottom nav 1 |
| `/more` | MoreScreen | Bottom nav 2 |
| `/itr_list` | ItrListScreen | |
| `/personal_info` | PersonalInformationScreen | |
| `/document_upload` | UploadDocumentsScreen | |
| `/payment` | PaymentScreen | Query: `?packageId=` |
| `/status` | StatusScreen | Extra: ITR model or orderId |
| `/profile` | ProfileScreen | Stub |
| `/settings` | SettingsScreen | Stub |
| `/refer_earn` | ReferAndEarnScreen | Stub |

**Router files:** `lib/core/config/app_router.dart`, `router_provider.dart`

---

## API constants

File: `lib/core/constant/api_constants.dart`

```dart
static const String baseUrl = 'http://allindiaitr.in';
static const String api = '/api';
```

Full endpoint list → [../SCREEN_API_MAP.md](../SCREEN_API_MAP.md)

---

## State management (providers)

| Area | Provider | Location |
|------|----------|----------|
| Auth | `authViewModelProvider` | `features/auth/presentation/providers/` |
| Personal info | `personalInfoViewModelProvider` | `features/personal_info/` |
| Packages | `packagesProvider`, `selectedPackageProvider` | `features/packages/` |
| Documents | `documentUploadViewModelProvider` | `features/document_upload/` |
| Orders | `ordersViewModelProvider` | `features/orders/` |
| Status | `statusViewModelProvider` | `features/status/` |
| Router | `routerProvider` | `core/config/router_provider.dart` |
| Journey type | `journeyTypeProvider` | Home / ITR flow |
| No internet | `noInternetNotifierProvider` | Shows `NoInternetSheet` |
| Logout | `logoutNotifierProvider` | Redirects to `/login` |

---

## Key user flows

### File ITR

```
Home → Package sheet → getItrByUser
  → (0 ITRs) personal_info | (>0) itr_list
  → document_upload → payment → status
```

### E-Verify

Same as File ITR but auto-selects package id `"7"`.

See [../WORKFLOWS.md](../WORKFLOWS.md) for diagrams.

---

## Theme & Figma

- **Default:** Dark theme (`AppTheme.theme`)
- **Background:** `#1E1E2C` (brand navy)
- **Figma file:** [tax_app](https://www.figma.com/design/7PMVY5IZeTIPhFazfBGoY7/tax_app) — key `7PMVY5IZeTIPhFazfBGoY7`

See [../FIGMA.md](../FIGMA.md) for screen migration tracker.

---

## Firebase

Initialized in `main.dart`:

| Service | Package |
|---------|---------|
| Core | `firebase_core` |
| Analytics | `firebase_analytics` |
| Crashlytics | `firebase_crashlytics` |
| Messaging | `firebase_messaging` |
| Local notifications | `flutter_local_notifications` |

**Required files:**
- `android/app/google-services.json` ✅
- `ios/Runner/GoogleService-Info.plist` (add for iOS builds)

After login → register FCM via `POST /auth/register_fcm.php`.

---

## Code generation

Run after changing Freezed / JSON / Riverpod annotated models:

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Build & release

```bash
# Debug
flutter run

# Release APK
flutter build apk --release

# App bundle (Play Store)
flutter build appbundle --release
```

**Signing:** `android/key.properties` + keystore (gitignored). See `finapp-keystore.jks`.

---

## Known issues

| Issue | Location | Fix |
|-------|----------|-----|
| Back from More goes to `/dashboard` | `MoreScreen` | Should navigate to `/` |
| Stub screens | profile, settings, refer_earn | Not implemented |
| Hardcoded colors | Orders, ITR list, docs, more | Migrate to theme tokens |

---

## Commands cheat sheet

| Command | Purpose |
|---------|---------|
| `flutter pub get` | Install dependencies |
| `dart run build_runner build --delete-conflicting-outputs` | Codegen |
| `flutter run` | Run debug |
| `flutter test` | Unit tests |
| `flutter analyze` | Static analysis |
| `flutter clean` | Clear build cache |

---

## Related docs

| Doc | Purpose |
|-----|---------|
| [MOBILE_UI_REFACTOR_ANALYSIS.md](./MOBILE_UI_REFACTOR_ANALYSIS.md) | Full Step 1 audit before UI refactor |
| [MOBILE_STEP2_LOGIN_ANALYSIS.md](./MOBILE_STEP2_LOGIN_ANALYSIS.md) | Step 2 login screen analysis + Figma blocker |
| [../SCREEN_API_MAP.md](../SCREEN_API_MAP.md) | APIs per screen |
| [../WORKFLOWS.md](../WORKFLOWS.md) | User journeys |
| [../FIGMA.md](../FIGMA.md) | Design migration |
| [../ENVIRONMENTS.md](../ENVIRONMENTS.md) | Local vs prod config |
| `DEVELOPMENT.md` (in app root) | Detailed architecture guide |
