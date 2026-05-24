# Figma — Design Reference

Design source and UI migration guide for the ITR Platform, primarily the **mobile app** (FinApp).

---

## Design file

| Property | Value |
|----------|-------|
| **File name** | tax_app |
| **URL** | [Figma — tax_app](https://www.figma.com/design/7PMVY5IZeTIPhFazfBGoY7/tax_app?node-id=0-1) |
| **File key** | `7PMVY5IZeTIPhFazfBGoY7` |
| **Page node** | `0:1` |
| **Theme** | Dark (entire file) |
| **App name (UI)** | FinApp - Next Gen |

---

## Screen → Figma mapping

Use this when converting Figma frames to Flutter screens. Update the **Figma frame** column when you identify exact node IDs.

| Priority | App route | Screen | Figma frame (TBD) | Migration status |
|----------|-----------|--------|-------------------|------------------|
| P0 | `/splash` | SplashScreen | TBD | Partial |
| P0 | `/login` | LoginScreen | TBD | Partial |
| P0 | `/register` | SignUpScreen | TBD | Partial |
| P0 | `/forgot-password` | ForgetPasswordScreen | TBD | Partial |
| P0 | `/` | HomeScreen | TBD | Partial |
| P1 | — | PackageBottomSheet | TBD | Partial |
| P1 | `/itr_list` | ItrListScreen | TBD | Needs work |
| P1 | `/personal_info` | PersonalInformationScreen | TBD | Needs work |
| P1 | `/document_upload` | UploadDocumentsScreen | TBD | Needs work |
| P1 | `/payment` | PaymentScreen | TBD | Partial |
| P1 | `/status` | StatusScreen | TBD | Partial |
| P2 | `/orders` | OrdersScreen | TBD | Needs work |
| P2 | `/more` | MoreScreen | TBD | Needs work |
| P3 | `/profile` | ProfileScreen | TBD | Stub |
| P3 | `/settings` | SettingsScreen | TBD | Stub |
| P3 | `/refer_earn` | ReferAndEarnScreen | TBD | Stub |

**Admin panel:** No dedicated Figma file linked yet. Admin uses MUI components with standard dashboard patterns.

---

## Design tokens (mobile)

Map Figma variables to Flutter theme files:

| Figma token (expected) | Flutter file | Code token |
|------------------------|--------------|------------|
| Background navy | `app_colors.dart` | `brandNavy` `#1E1E2C` |
| Surface | `app_colors.dart` | `brandNavyLight` `#2D2D44` |
| Primary blue | `app_colors.dart` | `primary` `#448AFF` |
| Secondary orange | `app_colors.dart` | `secondary` `#FF7D2E` |
| Typography | `app_typography.dart` | Inter via `google_fonts` |
| Spacing / radius | `app_spacing.dart` | Constants |
| Auth gradient | `app_theme_extension.dart` | `context.appExtras` |

### Theme application rule

**One global `ThemeData`** on `MaterialApp.router` — do not set colors per screen.

```dart
// lib/main.dart
MaterialApp.router(
  theme: AppTheme.theme,
  routerConfig: router,
);
```

Use:
- `Theme.of(context).colorScheme`
- `Theme.of(context).textTheme`
- `context.appExtras` (auth screens only)

---

## Shared layout widgets

| Widget | File | Use for |
|--------|------|---------|
| `AuthScaffold` | `core/common/widgets/` | Login, signup, forgot password |
| `AuthFormCard` | `core/common/widgets/` | Glass form container |
| `AuthHeader` | `core/common/widgets/` | Logo + title |
| `CoreScaffold` | `core/common/widgets/` | All main app screens |
| `CoreTextField` | `core/common/widgets/` | Form inputs |
| `PrimaryButton` | `core/common/widgets/` | Primary actions |

---

## Screens still using hardcoded colors

Migrate these to theme tokens when doing Figma conversion:

- `OrdersScreen`
- `ItrListScreen`
- `UploadDocumentsScreen`
- `MoreScreen`
- `SideDrawer`
- `DocumentViewerModal`
- `package_bottom_sheet.dart`

---

## UI conversion workflow

When implementing or updating a screen from Figma:

### 1. Get design context

```
Figma URL → fileKey: 7PMVY5IZeTIPhFazfBGoY7, nodeId from frame
```

Use Figma MCP `get_design_context` for reference layout and tokens.

### 2. Check API requirements

Before building UI, read [SCREEN_API_MAP.md](./SCREEN_API_MAP.md) for the route(item) to know which endpoints the flow needs.

### 3. Implement layout only

- Update widgets/layout to match Figma.
- **Keep ViewModels and API calls unchanged** unless the design requires new data.
- Use existing shared widgets where possible.

### 4. Verify on device

- Test dark theme (default).
- Test with real API or local backend.
- Check navigation in/out of the screen.

### 5. Update docs

- Update migration status in this file.
- Update [SCREEN_API_MAP.md](./SCREEN_API_MAP.md) if new APIs were added.

---

## Recommended migration order

1. **Phase 1 — Design system** (1–2 days): Export Figma variables → `AppColors`, `AppSpacing`, `AppTypography`. Build `AppButton`, `AppTextField`, `AppCard`.
2. **Phase 2 — Shell** (1 day): Bottom nav, app bar, splash.
3. **Phase 3 — Screens** (P0 → P3): One PR per screen group (Auth, Main tabs, ITR flow, Payment/Status).
4. **Phase 4 — Cleanup**: Remove hardcoded `Colors.*`, implement or remove stub screens.

---

## Native splash

Configured in `pubspec.yaml`:

```yaml
flutter_native_splash:
  color: "#1E1E2C"
  image: "assets/logo/logo_dark1.png"
```

Matches Figma background navy.

---

## Figma access checklist

- [ ] Share file with team (can view)
- [ ] Map each frame name → app route (update table above)
- [ ] Export color/spacing variables into `AppColors` / `AppSpacing`
- [ ] Screenshot each frame for offline reference

---

## Related docs

- [SCREEN_API_MAP.md](./SCREEN_API_MAP.md) — APIs needed per screen
- [projects/MOBILE.md](./projects/MOBILE.md) — routes, providers, theme files
- `apps/mobile/tax_client/DEVELOPMENT.md` — detailed mobile dev guide
