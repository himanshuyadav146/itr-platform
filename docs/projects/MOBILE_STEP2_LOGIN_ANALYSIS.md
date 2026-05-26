# Mobile Step 2 — Login Screen Analysis

Step 2 report for the **Login screen** in `apps/mobile/tax_client`.

This document combines:

- current implementation analysis
- current API and state flow
- reusable UI inventory
- backend dependency validation
- current blocker for latest Figma access

It should be used before any login screen UI implementation starts.

---

## Status

### Current implementation
- **Login screen exists and works**
- Business logic is wired through Riverpod + use case + repository + remote data source
- Navigation flow is already correct
- UI uses shared auth widgets and global theme

### Current Figma status
- **Latest Figma design is accessible via MCP**
- Authenticated Figma account: `himanshuyadav146@gmail.com`
- Figma file key referenced in project docs: `7PMVY5IZeTIPhFazfBGoY7`
- Login frame node identified: `34:2`
- Top-level page: `0:1`

### What is needed before pixel-perfect login refactor
The design is now readable. Implementation should follow the actual Login frame while preserving existing auth logic.

---

## Existing screen analysis

### File
- `apps/mobile/tax_client/lib/features/auth/presentation/screens/login_screen.dart`

### Current screen structure

The login screen is built from existing shared primitives:

1. `AuthScaffold`
2. `AuthHeader`
3. `AuthFormCard`
4. `CoreTextField` for email
5. `CoreTextField` for password
6. `PrimaryButton` for login CTA
7. `TextButton` links for forgot password and signup

### Current layout summary

The screen is a centered auth layout with:
- app logo + title/subtitle
- glass-style auth card
- email field
- password field with visibility toggle
- forgot password link
- login button
- signup prompt below the card

### Current validation behavior

Form validation is intentionally minimal:
- email must be non-empty
- password must be non-empty

No local email-format validation is enforced in this screen currently.

### Current state behavior

The screen listens to `authViewModelProvider`:

- `AuthLoading` → button loader
- `AuthAuthenticated` → store `logged_in = true` in `SharedPreferences`, then navigate to `/`
- `AuthError` → show `SnackBar`

---

## Existing business logic flow

### UI → state flow

```text
LoginScreen
  -> authViewModelProvider.notifier.login(email, password)
  -> Login use case
  -> AuthRepositoryImpl.login()
  -> AuthRemoteDataSource.login()
  -> ApiClient.post(/api/auth/login.php)
```

### State chain

```text
AuthInitial
  -> AuthLoading
  -> AuthAuthenticated(user, token)
  OR
  -> AuthError(message)
```

### Important conclusion

This is already a good clean path and should remain unchanged during UI refactor.

---

## Existing APIs used

### Primary login API

**Endpoint**
- `POST /api/auth/login.php`

**Defined in**
- `lib/core/constant/api_constants.dart`

**Consumed by**
- `features/auth/data/datasources/auth_remote_data_source.dart`

### Actual request shape

The login screen collects:
- `email`
- `password`

The `Login` use case automatically adds:
- `platform`
- `version`

### Effective request payload

```json
{
  "email": "user@example.com",
  "password": "password123",
  "platform": "android",
  "version": "1.0"
}
```

### Current response dependencies

The repository expects login response data with at least:
- token
- email
- userId
- message
- optional name
- optional mobile

It then:
- saves token
- saves auth response
- saves user data
- sets auth token into `ApiClient`
- registers FCM token after login

### Related background API

After successful login:
- `POST /api/auth/register_fcm.php`

This is not triggered directly by the screen, but by the repository after login.

---

## Current data requirements

### Current screen data inputs

| Field | Source | Required? |
|------|--------|-----------|
| Email | user input | Yes |
| Password | user input | Yes |

### Current screen output actions

| Action | Result |
|--------|--------|
| Login success | Navigate to `/` |
| Login failure | Show snackbar |
| Forgot password tap | Navigate to `/forgot-password` |
| Signup tap | Navigate to `/register` |

### Current APIs used

| Screen | APIs |
|--------|------|
| Login | `POST /api/auth/login.php` |

---

## Existing shared widgets to reuse

These should be reused first before creating any new login-specific widgets:

| Widget | File | Recommendation |
|--------|------|----------------|
| `AuthScaffold` | `core/common/widgets/auth_scaffold.dart` | Keep |
| `AuthHeader` | `core/common/widgets/auth_scaffold.dart` | Keep |
| `AuthFormCard` | `core/common/widgets/auth_scaffold.dart` | Keep |
| `CoreTextField` | `core/common/widgets/core_text_field.dart` | Keep and theme/improve |
| `PrimaryButton` | `core/common/widgets/primary_button.dart` | Keep and theme/improve |
| `AppLogo` | `core/common/widgets/app_logo.dart` | Keep |

### Login-specific candidates for refinement

If the design requires stronger standardization, these can evolve into richer shared components:

- `AppTextField`
- `PasswordField`
- `AppPrimaryButton`
- `AuthFooterLinks`

But they should be extracted only if multiple auth screens need the same UI pattern.

---

## Theme/design system relevance

The login screen already participates in the shared theme through:

- `AppTheme.theme`
- `AppThemeExtension`
- `AuthScaffold`
- `AuthFormCard`
- `CoreTextField`
- `PrimaryButton`

### Existing theme strengths

- shared auth gradient exists
- glass-card styling exists
- typography comes from `TextTheme`
- button and input decoration are already centralized

### Existing theme gaps visible on login

- spacing still uses raw `SizedBox` values (`48`, `20`, `12`, `24`, `32`)
- icons are still directly assigned inline
- button shape is tuned inline with `borderRadius: 16`
- no responsive helper layer is used

### Refactor implication

Login is a very good first screen to:
- formalize spacing tokens
- formalize auth form field variants
- formalize auth CTA variants
- validate the Figma design system against existing shared widgets

---

## Current UI risks / constraints

### Keep unchanged
- auth state flow
- login use case
- repository logic
- token storage behavior
- FCM registration trigger
- navigation destinations

### Safe to refactor
- spacing
- visual hierarchy
- text styles
- auth card styling
- input field visuals
- CTA styling
- responsive behavior
- iconography

### Avoid changing
- callback sequencing after login
- success/error state handling
- input-to-use-case contract

---

## Backend changes required

### Based on the current screen
**Backend changes required:** **NO**

The current login screen is fully supported by the existing backend.

### Based on the latest design
**Backend changes required:** **TBD until Figma access is available**

Potential examples that would require backend/API review:
- OTP login
- social login
- biometric-only login
- new onboarding flags
- extra user profile fields shown on login
- captcha / device verification

Until the latest design is accessible, we should **not assume** any of these are needed.

---

## Current screen vs new design comparison

### Current screen
- Standard logo + title auth screen
- 2 input fields
- forgot password link
- primary CTA
- signup link

### New design comparison
- Login frame uses a premium dark auth card with atmospheric background glow.
- Heading uses Manrope styling and premium visual hierarchy.
- Inputs are white surfaced fields with muted uppercase external labels.
- CTA is a mint gradient pill button.
- Password row includes an inline forgot-password link.
- A remember-session checkbox is present visually.
- Footer includes centered trust badges under the card.
- Design branding copy is not 1:1 with the ITR app, so the refactor should adapt the visual style while preserving app branding and existing auth functionality.

---

## Implementation guidance once Figma access is available

### Step A — compare design to current login screen
Document:
- exact visual differences
- existing widget reuse opportunities
- missing shared components

### Step B — validate data needs
For login screen, confirm whether the design needs any new data beyond:
- email
- password
- loading state
- error message

### Step C — implement UI only
Allowed changes:
- widget composition
- spacing / alignment
- styling
- responsive layout
- theme tokens

Not allowed:
- changing use case logic
- changing request/response shape
- changing auth state behavior
- changing navigation flow

---

## Recommended Login refactor checklist

- [ ] Confirm Figma file access
- [ ] Identify exact login frame/node
- [ ] Extract login-specific design tokens
- [ ] Map current widgets to design components
- [ ] Decide whether `CoreTextField` can be reused or needs a wrapped variant
- [ ] Decide whether `PrimaryButton` can be reused or needs a wrapped variant
- [ ] Implement layout only
- [ ] Re-test login success, error, forgot password, and signup navigation

---

## Next screens after Login

Once login is complete, continue in this order:

1. Signup
2. Forgot Password
3. Splash
4. Home
5. Package Bottom Sheet

This maximizes auth-shared widget reuse early.

---

## Related files

- `apps/mobile/tax_client/lib/features/auth/presentation/screens/login_screen.dart`
- `apps/mobile/tax_client/lib/features/auth/presentation/providers/auth_provider.dart`
- `apps/mobile/tax_client/lib/features/auth/presentation/viewmodel/auth_view_model.dart`
- `apps/mobile/tax_client/lib/features/auth/domain/usecases/login.dart`
- `apps/mobile/tax_client/lib/features/auth/data/repositories/auth_repository_impl.dart`
- `apps/mobile/tax_client/lib/features/auth/data/datasources/auth_remote_data_source.dart`
- `docs/projects/MOBILE_UI_REFACTOR_ANALYSIS.md`
- `docs/FIGMA.md`
