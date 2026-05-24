# Screen → API Map

Quick reference: which APIs each screen needs. **Use this first** when building or updating mobile/admin UI.

---

## Mobile screens

| Route | Screen | APIs on load | APIs on action | Provider / ViewModel |
|-------|--------|--------------|----------------|----------------------|
| `/splash` | SplashScreen | — (local token check) | — | `tokenStorageProvider` |
| `/login` | LoginScreen | — | `POST /auth/login.php` | `authViewModelProvider` |
| `/register` | SignUpScreen | — | `POST /auth/signup.php` | `authViewModelProvider` |
| `/forgot-password` | ForgetPasswordScreen | — | `POST /auth/forget_password.php` | `authViewModelProvider` |
| `/` | HomeScreen | `GET /package/getPackages.php` | — | `packagesProvider`, `journeyTypeProvider` |
| `/` | HomeScreen (File ITR) | `GET /get_itrbyuser.php` | — | `personalInfoViewModelProvider` |
| — | PackageBottomSheet | (uses `packagesProvider`) | — | `selectedPackageProvider` |
| `/itr_list` | ItrListScreen | `GET /get_itrbyuser.php` | — | `personalInfoViewModelProvider` |
| `/personal_info` | PersonalInformationScreen | `GET /itrdetails/get_personal_detail.php` | `POST /itrdetails/add_personal_details.php` | `personalInfoViewModelProvider` |
| `/document_upload` | UploadDocumentsScreen | `GET /itrdetails/get_documents.php` | `POST /itrdetails/add_documents.php`, `save_documents.php`, `delete_document.php` | `documentUploadViewModelProvider` |
| `/payment` | PaymentScreen | `GET /payment/get_payment_info.php?packageId=` | `POST /payment/initiate_payment.php`, `verify_payment.php` | Payment screen state + Razorpay |
| `/status` | StatusScreen | `GET /itr_status/get_detailed_status.php` | — | `statusViewModelProvider` |
| `/orders` | OrdersScreen | `GET /itr_status/get_user_orders.php` | — | `ordersViewModelProvider` |
| `/more` | MoreScreen | — | `POST /auth/delete_account.php` (delete) | `logoutNotifierProvider` |
| `/profile` | ProfileScreen | — | — | Stub |
| `/settings` | SettingsScreen | — | — | Stub |
| `/refer_earn` | ReferAndEarnScreen | — | — | Stub |

### Mobile — global / background APIs

| Trigger | API | Notes |
|---------|-----|-------|
| After login | `POST /auth/register_fcm.php` | FCM token registration |
| Token refresh | `POST /auth/refresh_token.php` | On 401 retry (if implemented) |
| Document preview | `GET {baseUrl}/api/uploads/{pan}/{file}` | Static file URL |
| WebView pages | `/privacy-policy`, `/contact-us`, `/about-us` | Host website, not PHP API |

---

## Admin screens

| Route | Page | APIs on load | APIs on action |
|-------|------|--------------|----------------|
| `/login` | LoginPage | — | `POST /auth/login.php` |
| `/register` | RegisterPage | — | `POST /auth/register_professional.php` |
| `/forgot-password` | ForgotPasswordPage | — | *(not wired yet)* |
| `/delete-account` | DeleteAccountPage | — | `POST /auth/delete_account.php` |
| `/dashboard` | DashboardPage | `GET /admin/dashboard.php` | — |
| `/users` | UsersPage | `GET /admin/users.php` | — |
| `/users/:id` | UserDetailPage | `GET /admin/users.php?id=`, `?stats=true` | `PUT /admin/users.php` |
| `/itrs` | ITRsPage | `GET /admin/itrs.php` | — |
| `/itrs/:id` | ITRDetailPage | `GET /admin/itrs.php?id=`, `GET /get_itrbyitrid.php` | `PUT /admin/itrs.php`, `?action=comment`, `?action=assign` |
| `/itrs/:id` (personal tab) | — | `GET /itrdetails/get_personal_detail.php` | `PUT` via personal details endpoint |
| `/itrs/:id` (docs tab) | — | `GET /admin/documents.php?itrId=`, `GET /itrdetails/get_documents.php` | Download via `?download=true&file=` |
| `/itrs/:id` (assign) | — | `GET /admin/users.php?role=CA` | `POST /admin/assign_itr.php` |
| `/itrs/:id` (status) | — | — | `PUT /admin/update_status_step.php` |
| `/itrs/:id` (ack) | — | — | `POST /admin/submit_acknowledgement.php` |
| `/professionals` | ProfessionalsPage | `GET /admin/users.php?role=ACCOUNTANT\|CA` | — |
| `/packages` | PackagesPage | `GET /package/getPackages.php` | — |
| `/packages/new` | PackageFormPage | — | `POST /package/addPackage.php` |
| `/packages/:id` | PackageFormPage (edit) | `GET /package/getPackages.php` | `POST /package/addPackage.php` |
| `/packages` (delete) | — | — | `POST /package/deletePackage.php` |

---

## Flow → API checklist

Use when implementing a **complete user flow** from scratch.

### Mobile: File ITR

- [ ] `GET /package/getPackages.php` — package selection
- [ ] `GET /get_itrbyuser.php` — route to list vs new form
- [ ] `POST /itrdetails/add_personal_details.php` — personal info
- [ ] `GET /itrdetails/get_documents.php` — load existing docs
- [ ] `POST /itrdetails/add_documents.php` — upload files
- [ ] `POST /itrdetails/save_documents.php` — save metadata
- [ ] `GET /payment/get_payment_info.php` — payment summary
- [ ] `POST /payment/initiate_payment.php` — Razorpay order
- [ ] `POST /payment/verify_payment.php` — confirm payment
- [ ] `GET /itr_status/get_detailed_status.php` — status timeline

### Mobile: Auth

- [ ] `POST /auth/login.php`
- [ ] `POST /auth/signup.php`
- [ ] `POST /auth/forget_password.php`
- [ ] `POST /auth/register_fcm.php`
- [ ] `POST /auth/delete_account.php`

### Admin: ITR review

- [ ] `POST /auth/login.php`
- [ ] `GET /admin/dashboard.php`
- [ ] `GET /admin/itrs.php`
- [ ] `GET /admin/itrs.php?id=`
- [ ] `GET /itrdetails/get_personal_detail.php`
- [ ] `GET /admin/documents.php?itrId=`
- [ ] `POST /admin/assign_itr.php`
- [ ] `PUT /admin/update_status_step.php`
- [ ] `POST /admin/submit_acknowledgement.php`

---

## API → client usage matrix

| API endpoint | Mobile | Admin |
|--------------|:------:|:-----:|
| `POST /auth/login.php` | ✅ | ✅ |
| `POST /auth/signup.php` | ✅ | — |
| `POST /auth/register_professional.php` | — | ✅ |
| `POST /auth/register_fcm.php` | ✅ | — |
| `GET /package/getPackages.php` | ✅ | ✅ |
| `POST /package/addPackage.php` | — | ✅ |
| `GET /get_itrbyuser.php` | ✅ | ✅ |
| `POST /itrdetails/add_personal_details.php` | ✅ | — |
| `GET /itrdetails/get_personal_detail.php` | ✅ | ✅ |
| `POST /itrdetails/add_documents.php` | ✅ | — |
| `GET /itrdetails/get_documents.php` | ✅ | ✅ |
| `GET /payment/get_payment_info.php` | ✅ | — |
| `POST /payment/initiate_payment.php` | ✅ | — |
| `POST /payment/verify_payment.php` | ✅ | — |
| `GET /itr_status/get_user_orders.php` | ✅ | — |
| `GET /itr_status/get_detailed_status.php` | ✅ | — |
| `GET /admin/dashboard.php` | — | ✅ |
| `GET /admin/users.php` | — | ✅ |
| `GET /admin/itrs.php` | — | ✅ |
| `POST /admin/assign_itr.php` | — | ✅ |
| `PUT /admin/update_status_step.php` | — | ✅ |

---

## Code locations for API constants

| Client | File |
|--------|------|
| Mobile | `apps/mobile/tax_client/lib/core/constant/api_constants.dart` |
| Admin | `apps/admin/src/api/endpoints.ts` |
| API (server) | `apps/api/{module}/*.php` |

---

## Related docs

- [API_CONTRACT.md](./API_CONTRACT.md) — request/response shapes
- [WORKFLOWS.md](./WORKFLOWS.md) — step-by-step journeys
- [FIGMA.md](./FIGMA.md) — design → screen mapping
