# Mobile UI Refactor Analysis

Step 1 audit for refactoring `apps/mobile/tax_client` to the latest design while preserving business logic, API contracts, navigation, Clean Architecture, and state management.

---

## Goal

Refactor the **entire mobile UI layer** to match the latest design without changing:

- Existing business logic
- Existing API integrations
- Existing navigation flow
- Existing Clean Architecture
- Existing Riverpod state flow
- Existing repositories and use cases
- Existing data layer and models

This document is the baseline reference before any UI implementation work starts.

---

## Project summary

| Item | Value |
|------|-------|
| App | `tax_client` / FinApp - Next Gen |
| Path | `apps/mobile/tax_client` |
| Stack | Flutter 3.8+, Riverpod, GoRouter, Freezed, Firebase |
| Backend | `http://allindiaitr.in` |
| Architecture style | Feature-first, mostly Clean Architecture |
| Theme mode | Dark by default |

---

## Current architecture

The app already follows a mostly clean feature-first structure:

```text
Presentation (screens, widgets, ViewModels/StateNotifiers)
        ↓
Domain (entities, repository interfaces, use cases)
        ↓
Data (repository impl, remote data sources, models)
```

### Architecture status by feature

| Feature | Status | Notes |
|--------|--------|-------|
| `auth` | Strong clean slice | Has data, domain, presentation, entity, repository, use cases |
| `personal_info` | Strong clean slice | Core ITR journey feature |
| `document_upload` | Strong clean slice | Repository/use cases present, plus local provider state |
| `orders` | Mostly clean | Repository + use case present |
| `status` | Partial clean | Has use case, but repository contract lives in data layer |
| `packages` | Thin slice | No domain/repository layer; UI/provider talks to remote data source |
| `payment` | Thin slice | No repository/use-case/viewmodel layer |
| `home` | Presentation/orchestration | Starts package + ITR flow |
| `more` | Presentation only | Logout/delete/web links |
| `profile` | Stub | Route exists, no real functionality |
| `settings` | Stub | Route exists, no real functionality |
| `refer_earn` | Stub | Route exists, no real functionality |
| `splash` | Presentation only | Local auth gate |

### Important conclusion

The app is **good enough for a UI-only refactor** because the core business features are already separated. The biggest risk is not business logic, but architectural inconsistency in a few features (`packages`, `payment`, `status`) and inline UI duplication.

---

## Feature modules found

### `auth`
- Login
- Signup
- Forgot password
- Logout
- Delete account
- Refresh token
- FCM registration after login

### `splash`
- Entry screen
- Checks local login state
- Redirects to `/login` or `/`

### `home`
- Main dashboard
- Starts File ITR / E-Verify journey
- Loads package list

### `personal_info`
- ITR list
- Personal details form
- Existing ITR selection/edit flow

### `document_upload`
- Upload documents
- Save metadata
- View / delete documents

### `packages`
- Package list state
- Package bottom sheet
- Selected package handling

### `payment`
- Payment summary
- Razorpay initiation
- Payment verification

### `status`
- Detailed ITR progress timeline
- Status update rendering
- Assignment status rendering

### `orders`
- List user orders
- Navigate to status

### `more`
- Account menu
- Logout
- Delete account
- Privacy / contact / about web links

### Stub / placeholder features
- `profile`
- `settings`
- `refer_earn`

---

## Existing screens

| Route | Screen | Status |
|------|--------|--------|
| `/splash` | `SplashScreen` | Working |
| `/login` | `LoginScreen` | Working |
| `/register` | `SignUpScreen` | Working |
| `/forgot-password` | `ForgetPasswordScreen` | Working |
| `/` | `HomeScreen` | Working |
| `/orders` | `OrdersScreen` | Working |
| `/more` | `MoreScreen` | Working |
| `/itr_list` | `ItrListScreen` | Working |
| `/personal_info` | `PersonalInformationScreen` | Working |
| `/document_upload` | `UploadDocumentsScreen` | Working |
| `/payment` | `PaymentScreen` | Working |
| `/status` | `StatusScreen` | Working with routing risk |
| `/profile` | `ProfileScreen` | Stub |
| `/settings` | `SettingsScreen` | Stub |
| `/refer_earn` | `ReferAndEarnScreen` | Stub |

### Existing navigation flow

#### App entry
`/splash` → `/login` or `/`

#### Auth flow
`/login` → `/register` / `/forgot-password` → successful login → `/`

#### Main ITR flow
`/` → package selection → `getItrByUser`

- if no existing ITRs → `/personal_info`
- if existing ITRs → `/itr_list` → `/personal_info`

Then:
`/personal_info` → `/document_upload` → `/payment?packageId=` → `/status`

#### Other flows
- `/orders` → `/status`
- bottom navigation covers `/`, `/orders`, `/more`

---

## State management implementation

The app uses **Riverpod** as the central state management + DI layer.

### Core providers
- `routerProvider`
- `apiClientProvider`
- `tokenStorageProvider`
- `noInternetNotifierProvider`
- `logoutNotifierProvider`
- `logoutHandlerProvider`

### Feature providers

| Area | Providers / Notifiers |
|------|-----------------------|
| Auth | `loginProvider`, `registerProvider`, `forgetPasswordProvider`, `logoutProvider`, `deleteAccountProvider`, `authViewModelProvider`, `userProvider` |
| Personal info | `addPersonalDetailsProvider`, `getPersonalDetailsProvider`, `getItrByUserProvider`, `journeyTypeProvider`, `personalInfoViewModelProvider` |
| Document upload | `uploadDocumentProvider`, `saveDocumentsProvider`, `getDocumentsProvider`, `deleteDocumentProvider`, `documentUploadViewModelProvider`, `documentsProvider` |
| Packages | `packagesProvider`, `selectedPackageProvider` |
| Orders | `getOrdersProvider`, `ordersViewModelProvider` |
| Status | `getDetailedStatusProvider`, `statusViewModelProvider` |

### State management observation

This is strong enough to preserve as-is during UI refactor. The main caution is that some features combine two state sources (especially `document_upload`), so UI changes should not bypass existing provider flows.

---

## Existing shared widgets

### Core reusable widgets already present

| Widget | File | Keep / Reuse? |
|--------|------|---------------|
| `CoreScaffold` | `lib/core/common/widgets/core_scaffold.dart` | Yes |
| `CoreAppBar` | `lib/core/common/widgets/core_app_bar.dart` | Yes |
| `AuthScaffold` | `lib/core/common/widgets/auth_scaffold.dart` | Yes |
| `AuthFormCard` | `lib/core/common/widgets/auth_scaffold.dart` | Yes |
| `AuthHeader` | `lib/core/common/widgets/auth_scaffold.dart` | Yes |
| `PrimaryButton` | `lib/core/common/widgets/primary_button.dart` | Yes |
| `CoreTextField` | `lib/core/common/widgets/core_text_field.dart` | Yes |
| `CustomCard` | `lib/core/common/widgets/custom_card.dart` | Yes |
| `BottomNavBar` | `lib/core/common/widgets/bottom_nav_bar.dart` | Yes |
| `showCoreBottomSheet` | `lib/core/common/widgets/core_bottom_sheet.dart` | Yes |
| `NoInternetSheet` | `lib/core/common/widgets/no_internet_sheet.dart` | Yes |
| `DocumentViewerModal` | `lib/core/common/widgets/document_viewer_modal.dart` | Reuse, but restyle |
| `AppLogo` | `lib/core/common/widgets/app_logo.dart` | Yes |
| `SideDrawer` | `lib/core/common/widgets/side_drawer.dart` | Legacy / low priority |

### Feature-level reusable widgets already extracted

| Widget | File | Keep / Reuse? |
|--------|------|---------------|
| `PackageBottomSheet` | `features/packages/presentation/widgets/package_bottom_sheet.dart` | Yes, refactor style only |
| `StatusTimelineTile` | `features/status/presentation/widgets/status_timeline_tile.dart` | Yes, refactor style only |
| `DocumentTile` | `features/document_upload/presentation/widgets/document_tile.dart` | Yes, refactor style only |
| `DocumentModelTile` | `features/document_upload/presentation/widgets/document_model_tile.dart` | Yes, refactor style only |

### Inline widgets worth extracting later

- `_ServiceCard` in Home
- `_ItrListItem` and `_InfoCard` in ITR list
- `_MoreTile` in More
- `_SuccessCard` in Status

These are good candidates for shared UI components once Figma confirms repeated patterns.

---

## Existing common components coverage

### Already available
- Buttons
- Text fields
- Cards
- App bar / scaffold shell
- Bottom navigation
- Bottom sheet wrapper
- No-internet sheet
- Document viewer modal

### Missing as shared primitives
- App loader
- Shared empty state
- Shared error state
- Shared dialog wrapper
- Shared badge / chip / tag system
- Shared section header
- Shared profile / settings / notification tiles
- Shared skeleton / shimmer widgets

### High-value reusable widgets to add during refactor

- `AppLoader`
- `AppEmptyState`
- `AppErrorState`
- `AppDialog`
- `AppSectionHeader`
- `AppBadge` / `AppChip`
- `AppStatusTag`
- `ProfileTile` / `SettingTile`
- `SummaryCard` / `InfoCard`

---

## Theme implementation and design system

The current design system lives under:

- `lib/core/config/theme/app_theme.dart`
- `lib/core/config/theme/app_colors.dart`
- `lib/core/config/theme/app_typography.dart`
- `lib/core/config/theme/app_spacing.dart`
- `lib/core/config/theme/app_theme_extension.dart`

### Current design system pieces

| Token area | Current file |
|-----------|--------------|
| Colors | `app_colors.dart` |
| Typography | `app_typography.dart` |
| Spacing / radius | `app_spacing.dart` |
| Theme | `app_theme.dart` |
| Extra visual tokens | `app_theme_extension.dart` |

### Important observation

There is already a centralized theme, so the refactor should **extend and formalize** it, not rebuild from scratch blindly.

### Design system gap

There is also another sizing token file:

- `lib/core/constant/app_sizes.dart`

This suggests **duplicate token systems**. During UI refactor, one token source should become the single source of truth.

---

## Where hardcoded UI still exists

The following areas still use inline colors, spacing, radii, local shadows, or screen-specific `TextStyle`s:

- `core/common/widgets/side_drawer.dart`
- `core/common/widgets/document_viewer_modal.dart`
- `core/utils/error_handler.dart`
- `features/packages/presentation/widgets/package_bottom_sheet.dart`
- `features/status/presentation/widgets/status_timeline_tile.dart`
- `features/orders/presentation/screens/orders_screen.dart`
- `features/more/presentation/screens/more_screen.dart`
- `features/document_upload/presentation/screens/upload_documents_screen.dart`
- `features/document_upload/presentation/widgets/document_tile.dart`
- `features/document_upload/presentation/widgets/document_model_tile.dart`
- `features/personal_info/presentation/screens/personal_information_screen.dart`
- `features/payment/presentation/screens/payment_screen.dart`
- `features/home/presentation/screens/home_screen.dart`

### Refactor implication

The current shell and theme are reusable, but rich content blocks still need token cleanup and component extraction.

---

## Domain layer

### Strong domain-oriented features
- `auth`
- `personal_info`
- `document_upload`
- `orders`

### Partial / weak domain-oriented features
- `status`
- `packages`
- `payment`

### Existing domain entity example
- `auth/domain/entities/user.dart`

Most other features still use data models directly across layers, especially for UI rendering.

---

## Repository layer

### Repositories present

| Feature | Repository |
|--------|------------|
| Auth | `AuthRepository`, `AuthRepositoryImpl` |
| Personal info | `PersonalInfoRepository`, `PersonalInfoRepositoryImpl` |
| Document upload | `DocumentUploadRepository`, `DocumentUploadRepositoryImpl` |
| Orders | `OrdersRepository`, `OrdersRepositoryImpl` |
| Status | `StatusRepository`, `StatusRepositoryImpl` |

### Missing / bypassed repository layer
- `packages`
- `payment`

These features currently access remote data sources more directly from provider/screen level.

---

## Use cases

### Auth
- `Login`
- `Register`
- `ForgetPassword`
- `Logout`
- `DeleteAccount`
- `RefreshToken`

### Personal info
- `AddPersonalDetails`
- `GetPersonalDetails`
- `GetItrByUser`

### Document upload
- `UploadDocument`
- `SaveDocuments`
- `GetDocuments`
- `DeleteDocument`

### Orders
- `GetOrders`

### Status
- `GetDetailedStatus`

### Missing use-case layer
- `packages`
- `payment`

---

## Models and DTOs

### Auth
- `login_request_model.dart`
- `signup_request_model.dart`
- `forget_password_request_model.dart`
- `login_data.dart`
- `signup_data.dart`
- `forget_password_data.dart`
- `refresh_token_data.dart`
- `auth_response_model.dart`
- `user_model.dart`
- domain `entities/user.dart`

### Personal info
- `personal_info_request_model.dart`
- `personal_info_data.dart`
- `get_personal_detail_data.dart`
- `get_itr_by_user_data.dart`
- `personal_info_response_model.dart`
- `itr_personal_detail_model.dart`
- `itr_document_model.dart`

### Document upload
- `document_model.dart`
- `document_item_model.dart`
- `upload_document_data.dart`
- `upload_document_response_model.dart`
- `save_documents_request_model.dart`
- `save_documents_data.dart`
- `save_documents_response_model.dart`
- `get_documents_data.dart`
- `get_documents_response_model.dart`
- `delete_document_request_model.dart`
- `delete_document_data.dart`
- `delete_document_response_model.dart`

### Orders
- `order_model.dart`
- nested `OrderAmount`

### Status
- `itr_detailed_status_model.dart`
- nested `ItrStatusInfoModel`
- nested `ItrStatusStepModel`
- nested `StatusUpdateModel`
- nested `AssignmentStatusModel`

### Packages
- `package_model.dart`
- nested `PackagesData`

### Payment
- `payment_info_data.dart`
- `payment_initiate_response.dart`
- `order_details.dart`
- `payment_summary_item.dart`
- `gateway_details.dart`

---

## Existing API integrations

### Auth APIs
- `POST /api/auth/login.php`
- `POST /api/auth/signup.php`
- `POST /api/auth/forget_password.php`
- `POST /api/auth/refresh_token.php`
- `POST /api/auth/delete_account.php`
- `POST /api/auth/register_fcm.php`

### ITR / personal details APIs
- `POST /api/itrdetails/add_personal_details.php`
- `GET /api/itrdetails/get_personal_detail.php`
- `GET /api/get_itrbyuser.php`

### Document APIs
- `POST /api/itrdetails/add_documents.php`
- `POST /api/itrdetails/save_documents.php`
- `POST /api/itrdetails/delete_document.php`
- `GET /api/itrdetails/get_documents.php`

### Package APIs
- `GET /api/package/getPackages.php`

### Payment APIs
- `GET /api/payment/get_payment_info.php`
- `POST /api/payment/initiate_payment.php`
- `GET /api/payment/get_payment_status.php`
- `POST /api/payment/verify_payment.php`

### Status / orders APIs
- `GET /api/itr_status/get_detailed_status.php`
- `GET /api/itr_status/get_user_orders.php`

### External web links
- `/privacy-policy`
- `/contact-us`
- `/about-us`

### Extra direct file URL usage
- `/api/uploads/{panNumber}/{fileName}`

This is used for document preview and bypasses the shared API client.

---

## Screen-wise API usage

| Screen | Current APIs used |
|--------|-------------------|
| Login | `login.php` |
| Signup | `signup.php` |
| Forgot Password | `forget_password.php` |
| Home | `getPackages.php`, `get_itrbyuser.php` |
| ITR List | `get_itrbyuser.php` |
| Personal Info | `add_personal_details.php` |
| Document Upload | `get_documents.php`, `add_documents.php`, `save_documents.php`, `delete_document.php` |
| Payment | `get_payment_info.php`, `initiate_payment.php`, `verify_payment.php` |
| Status | `get_detailed_status.php` |
| Orders | `get_user_orders.php` |
| More | `delete_account.php` |
| Splash | No API |
| Profile | No API |
| Settings | No API |
| Refer & Earn | No API |

---

## Existing networking layer

### Shared networking pieces
- `ApiClient`
- `BaseResponse<T>`
- `ApiException`
- `NoInternetException`
- `TokenStorage`

### Current behavior
- Request/response logging
- Shared auth header handling
- 401 refresh path in `ApiClient`
- Connectivity handling
- Local token/user/PAN storage

### Risk for UI-only refactor

Do not bypass:
- token storage writes
- PAN persistence
- refresh/logout handling
- existing response wrapper assumptions

Several screens depend on previously stored values rather than route-only state.

---

## Current UI refactor risks

### Confirmed issues

1. **`MoreScreen` back route bug**
   - Navigates to `/dashboard`, but that route does not exist.

2. **`StatusScreen` routing/data coupling**
   - It can receive `orderId`, but current fetch logic still depends on `itrData` in a fragile way.

3. **Auth/session inconsistency**
   - Splash checks `SharedPreferences.logged_in`
   - token state also lives in `TokenStorage`
   - logout is handled through multiple paths

4. **`packages` and `payment` are less clean**
   - Refactor should not accidentally increase coupling

5. **Document preview depends on public upload URL structure**
   - UI redesign must preserve preview behavior unless backend changes

6. **Hardcoded domain assumptions in UI**
   - E-Verify package id `7`
   - document categories such as `form16a`, `form16b`, `others`

---

## Existing shared widgets to preserve

These should be treated as the first reuse layer during UI refactor:

- `CoreScaffold`
- `CoreAppBar`
- `AuthScaffold`
- `AuthFormCard`
- `AuthHeader`
- `PrimaryButton`
- `CoreTextField`
- `CustomCard`
- `BottomNavBar`
- `showCoreBottomSheet`
- `NoInternetSheet`
- `DocumentViewerModal`
- `PackageBottomSheet`
- `StatusTimelineTile`
- `DocumentTile`
- `DocumentModelTile`

---

## Refactor readiness summary

### Safe to keep unchanged
- Navigation routes
- Providers and state notifiers
- Repositories
- Use cases
- API client
- Models / DTOs
- Token storage
- Existing data flow

### Safe to refactor
- Theme tokens
- Shared UI primitives
- Screen layouts
- Spacing / typography / visual hierarchy
- Cards / list items / buttons / form visuals
- Empty / loading / error states
- Responsive layout behavior

### Needs analysis before implementation
- Exact Figma-to-screen mapping
- New data fields required by latest design
- Whether stub screens should remain stub or be designed now
- Whether OTP / notifications / support screens actually exist in the new design

---

## Recommended screen refactor order

Based on the real codebase, the current mobile UI refactor order should be:

1. Splash
2. Login
3. Signup
4. Forgot Password
5. Home
6. Package Bottom Sheet
7. ITR List
8. Personal Info
9. Document Upload
10. Payment
11. Status
12. Orders
13. More
14. Profile / Settings / Refer & Earn (if still in scope)

This order aligns with existing business flow and shared component reuse.

---

## What must be done before Step 2

To proceed with full Figma-driven UI refactor safely, we still need:

1. Full access to the latest design screens
2. Screen-by-screen mapping from design to current routes
3. Design system extraction:
   - colors
   - typography
   - spacing
   - radius
   - shadows
   - component variants
4. Per-screen field audit:
   - current data used
   - new UI-required fields
   - backend changes required: yes / no

---

## Related docs

- `apps/mobile/tax_client/DEVELOPMENT.md`
- `docs/FIGMA.md`
- `docs/SCREEN_API_MAP.md`
- `docs/WORKFLOWS.md`
- `docs/projects/MOBILE.md`
